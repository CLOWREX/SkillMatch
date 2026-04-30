import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  String _search = '';
  String _filter = 'all'; // all | banned | suspend

  Color _avatarColor(String av) {
    const colors = [AppColors.primary, Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFEC4899)];
    return colors[av.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                _tabBtn('Semua User', 0),
                _tabBtn('Laporan', 1),
                _tabBtn('Statistik', 2),
                _tabBtn('Dihukum', 3),
              ],
            ),
          ),
          Expanded(
            child: _currentIndex == 0
                ? _buildUsers()
                : _currentIndex == 1
                    ? _buildLaporan()
                    : _currentIndex == 2
                        ? _buildStats()
                        : _buildPunished(),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final isOn = _currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isOn ? AppColors.primary : Colors.transparent, width: 2)),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isOn ? AppColors.primary : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildUsers() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('users').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final users = snapshot.data!.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;

        return {
          'id': d.id,
          'nama': data['nama'] ?? '',
          'skill': data['skill'] ?? '',
          'status': data['status'] ?? 'offline',
          'matches': data['matches'] ?? [],
          'banned': data['banned'] ?? false,
        };
      }).toList();

      final online =
          users.where((u) => u['status'] == 'online').length;

      final totalMatch = users.fold(
          0, (sum, u) => sum + ((u['matches'] as List?)?.length ?? 0));

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ STAT CARD BALIK
            Row(
              children: [
                _statCard('${users.length}', 'Total User',
                    Colors.blue.shade100, Colors.blue, Icons.people),
                const SizedBox(width: 10),
                _statCard('$online', 'Aktif',
                    Colors.green.shade100, Colors.green, Icons.circle),
                const SizedBox(width: 10),
                _statCard('$totalMatch', 'Match',
                    Colors.orange.shade100, Colors.orange, Icons.handshake),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ LIST USER
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: users.map((u) {
                  final uid = u['id'];

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('punishments')
                        .doc(uid)
                        .snapshots(),
                    builder: (context, snap) {
                      String status = '';
                      bool isSuspend = false;

                      if (snap.hasData && snap.data!.exists) {
                        final p =
                            snap.data!.data() as Map<String, dynamic>;

                        if (p['type'] == 'suspend_chat') {
                          final until =
                              (p['until'] as Timestamp).toDate();
                          if (DateTime.now().isBefore(until)) {
                            status = 'SUSPEND';
                            isSuspend = true;
                          }
                        }

                        if (p['type'] == 'ban_permanent') {
                          status = 'BANNED';
                        }
                      }

                      return ListTile(
                        title: Row(
                          children: [
                            Text(u['nama'] ?? ''),
                            if (status.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: TextStyle(
                                  color: isSuspend
                                      ? Colors.orange
                                      : Colors.red,
                                  fontSize: 11,
                                ),
                              )
                            ]
                          ],
                        ),
                        subtitle: Text(u['skill'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () =>
                              _showUserActions(context, u, isSuspend),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  void _showUserActions(
    BuildContext context, Map<String, dynamic> u, bool isSuspend) {
  final uid = u['id'];
  final isBanned = (u['banned'] ?? false) == true;

  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
            _actionTile(
              icon: Icons.delete,
              iconColor: Colors.red,
              bgColor: Colors.red.shade100,
              title: 'Hapus User',
              subtitle: 'Data user akan dihapus permanen',
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(uid, u['nama']);
              },
            ),

          // 🔥 SUSPEND OPTIONS
          if (!isSuspend) ...[
            _actionTile(
              icon: Icons.timer,
              iconColor: Colors.orange,
              bgColor: Colors.orange.shade100,
              title: 'Suspend 1 Hari',
              subtitle: '',
              onTap: () {
                Navigator.pop(context);
                _hukum(uid, u['nama'], 1);
              },
            ),
            _actionTile(
              icon: Icons.timer,
              iconColor: Colors.orange,
              bgColor: Colors.orange.shade100,
              title: 'Suspend 7 Hari',
              subtitle: '',
              onTap: () {
                Navigator.pop(context);
                _hukum(uid, u['nama'], 7);
              },
            ),
            _actionTile(
              icon: Icons.timer,
              iconColor: Colors.orange,
              bgColor: Colors.orange.shade100,
              title: 'Suspend 30 Hari',
              subtitle: '',
              onTap: () {
                Navigator.pop(context);
                _hukum(uid, u['nama'], 30);
              },
            ),
          ] else ...[
            _actionTile(
              icon: Icons.lock_open,
              iconColor: Colors.green,
              bgColor: Colors.green.shade100,
              title: 'Cabut Suspend',
              subtitle: '',
              onTap: () {
                Navigator.pop(context);
                _unsuspend(uid, u['nama']);
              },
            ),
          ],

          const SizedBox(height: 10),

          // 🔥 BAN
          _actionTile(
            icon: isBanned ? Icons.lock_open : Icons.gavel,
            iconColor: isBanned ? Colors.green : Colors.red,
            bgColor:
                isBanned ? Colors.green.shade100 : Colors.red.shade100,
            title: isBanned ? 'Unban' : 'Ban Permanen',
            subtitle: '',
            onTap: () {
              Navigator.pop(context);
              _banPermanen(uid, u['nama'], !isBanned);
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _actionTile({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _hukum(String uid, String nama, int hari) async {
    
    final until = DateTime.now().add(Duration(days: hari));
    await FirebaseFirestore.instance.collection('punishments').doc(uid).set({
      'uid': uid,
      'type': 'suspend_chat',
      'until': Timestamp.fromDate(until),
      'days': hari,
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nama disuspend chat $hari hari'),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _unsuspend(String uid, String nama) async {
      await FirebaseFirestore.instance
          .collection('punishments')
          .doc(uid)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nama sudah bisa chat lagi'),
          backgroundColor: Colors.green,
        ),
      );
    }

  Future<void> _banPermanen(String uid, String nama, bool ban) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'banned': ban});
    if (ban) {
      await FirebaseFirestore.instance.collection('punishments').doc(uid).set({
        'uid': uid,
        'type': 'ban_permanent',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await FirebaseFirestore.instance.collection('punishments').doc(uid).delete();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ban ? '$nama di-ban permanen' : 'Ban $nama dicabut'),
        backgroundColor: ban ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _hapusUser(String uid, String nama) async {
  try {
    // 🔥 hapus data user
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    // 🔥 hapus punishment kalau ada
    await FirebaseFirestore.instance.collection('punishments').doc(uid).delete();

    // 🔥 optional: hapus chat (kalau kamu punya collection chat)
    // await FirebaseFirestore.instance.collection('chats').doc(uid).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nama berhasil dihapus'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal hapus user: $e'),
        backgroundColor: Colors.grey,
      ),
    );
  }
}

void _showDeleteConfirm(String uid, String nama) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus User'),
      content: Text('Yakin mau hapus $nama?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _hapusUser(uid, nama);
          },
          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

  Widget _buildLaporan() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final reports = snapshot.data?.docs ?? [];
        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 56, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('Belum ada laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, i) {
            final r = reports[i].data() as Map<String, dynamic>;
            final status = r['status'] ?? 'pending';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: status == 'pending' ? const Color(0xFFFEF3C7) : Colors.grey.shade100, width: status == 'pending' ? 1.5 : 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'pending' ? const Color(0xFFFEF3C7) : AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status == 'pending' ? 'Menunggu' : 'Ditangani',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: status == 'pending' ? const Color(0xFFF59E0B) : AppColors.success),
                        ),
                      ),
                      const Spacer(),
                      Text(_formatDate(r['createdAt']), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Pelapor: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(r['reporterName'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text('Dilaporkan: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(r['reportedName'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(r['alasan'] ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4))),
                      ],
                    ),
                  ),
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _tandaiSelesai(reports[i].id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(color: AppColors.success),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Tandai selesai', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final reportedUid = r['reportedUid'] ?? '';
                              final reportedName = r['reportedName'] ?? '';
                              if (reportedUid.isNotEmpty) {
                                await _tandaiSelesai(reports[i].id);
                                _showUserActionsFromReport(context, reportedUid, reportedName);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Beri hukuman', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUserActionsFromReport(BuildContext context, String uid, String nama) {
  _showUserActions(
    context,
    {'id': uid, 'nama': nama, 'banned': false},
    false,
    );
  }

  Future<void> _tandaiSelesai(String reportId) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': 'handled'});
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  Widget _buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('isProfileComplete', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snapshot.data?.docs ?? [];
        final users = docs.map((d) => d.data() as Map<String, dynamic>).toList();
        final skillCount = <String, int>{};
        for (final u in users) {
          final s = u['skill'] as String?;
          final s2 = u['skill2'] as String?;
          if (s != null && s.isNotEmpty) skillCount[s] = (skillCount[s] ?? 0) + 2;
          if (s2 != null && s2.isNotEmpty) skillCount[s2] = (skillCount[s2] ?? 0) + 1;
        }
        final sorted = skillCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sorted.take(5).toList();
        final maxVal = top5.isNotEmpty ? top5.first.value : 1;
        final totalMatch = users.fold(0, (sum, u) => sum + ((u['matches'] as List?)?.length ?? 0));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Skill paling banyak digunakan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    if (top5.isEmpty)
                      const Text('Belum ada data', style: TextStyle(color: AppColors.textSecondary))
                    else
                      ...top5.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text('${e.value}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: e.value / maxVal,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF818CF8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.handshake_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$totalMatch', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Text('Total match berhasil', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPunished() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('punishments').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data!.docs;

      // 🔍 FILTER + SEARCH
      final filteredDocs = docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final type = data['type'] ?? '';

        if (_filter == 'banned' && type != 'ban_permanent') return false;
        if (_filter == 'suspend' && type != 'suspend_chat') return false;

        return true;
      }).toList();

      return Column(
        children: [

          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _search = val.toLowerCase();
                });
              },
            ),
          ),

          // 🔘 FILTER
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterBtn('Semua', 'all'),
              _filterBtn('Banned', 'banned'),
              _filterBtn('Suspend', 'suspend'),
            ],
          ),

          const SizedBox(height: 10),

          // 📜 LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: filteredDocs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final uid = data['uid'];
                final type = data['type'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return const SizedBox();

                    final u = userSnap.data!.data() as Map<String, dynamic>;
                    final nama = (u['nama'] ?? '-').toString();

                    // 🔍 SEARCH FILTER
                    if (_search.isNotEmpty &&
                        !nama.toLowerCase().contains(_search)) {
                      return const SizedBox();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            type == 'ban_permanent'
                                ? Icons.block
                                : Icons.timer,
                            color: type == 'ban_permanent'
                                ? Colors.red
                                : Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nama,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  type == 'ban_permanent'
                                      ? 'BANNED'
                                      : 'SUSPEND',
                                  style: TextStyle(
                                    color: type == 'ban_permanent'
                                        ? Colors.red
                                        : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () => _showUserActions(
                              context,
                              {
                                'id': uid,
                                'nama': nama,
                                'banned': type == 'ban_permanent'
                              },
                              type == 'suspend_chat',
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      );
    },
  );
}

Widget _filterBtn(String label, String val) {
  final isActive = _filter == val;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: ElevatedButton(
      onPressed: () => setState(() => _filter = val),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : Colors.grey.shade300,
      ),
      child: Text(label),
    ),
  );
}

  Widget _statCard(String num, String label, Color bg, Color fg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(height: 6),
            Text(num, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
            Text(label, style: TextStyle(fontSize: 11, color: fg.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}