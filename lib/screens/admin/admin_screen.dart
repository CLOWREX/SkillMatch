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
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
          child: const Text('Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
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
            border: Border(
              bottom: BorderSide(
                color: isOn ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOn ? AppColors.primary : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }

  Widget _buildUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Belum ada user', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        final users = (snapshot.data?.docs ?? []).map((d) {
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

        final online = users.where((u) => u['status'] == 'online').length;
        final totalMatch = users.fold(0, (sum, u) => sum + ((u['matches'] as List?)?.length ?? 0));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _statCard('${users.length}', 'Total User', AppColors.primaryLight, AppColors.primary, Icons.people_rounded),
                  const SizedBox(width: 10),
                  _statCard('$online', 'Aktif', AppColors.successLight, AppColors.success, Icons.circle),
                  const SizedBox(width: 10),
                  _statCard('$totalMatch', 'Match', const Color(0x15FBBF24), AppColors.warning, Icons.handshake_rounded),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: users.asMap().entries.map((entry) {
                    final i = entry.key;
                    final u = entry.value;
                    final uid = u['id'];
                    return Column(
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('punishments')
                              .doc(uid)
                              .snapshots(),
                          builder: (context, snap) {
                            String status = '';
                            bool isSuspend = false;
                            if (snap.hasData && snap.data!.exists) {
                              final p = snap.data!.data() as Map<String, dynamic>;
                              if (p['type'] == 'suspend_chat') {
                                final until = (p['until'] as dynamic).toDate();
                                if (DateTime.now().isBefore(until)) {
                                  status = 'SUSPEND';
                                  isSuspend = true;
                                }
                              }
                              if (p['type'] == 'ban_permanent') status = 'BANNED';
                            }
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  (u['nama'] as String).isNotEmpty
                                      ? (u['nama'] as String)[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(u['nama'] ?? '',
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                  if (status.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSuspend
                                            ? const Color(0x15FBBF24)
                                            : AppColors.errorLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isSuspend ? AppColors.warning : AppColors.error,
                                          )),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(u['skill'] ?? '',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                onPressed: () => _showUserActions(context, u, isSuspend),
                              ),
                            );
                          },
                        ),
                        if (i < users.length - 1)
                          Divider(height: 1, color: AppColors.border),
                      ],
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

  void _showUserActions(BuildContext context, Map<String, dynamic> u, bool isSuspend) {
    final uid = u['id'];
    final isBanned = (u['banned'] ?? false) == true;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _actionTile(
              icon: Icons.delete_rounded, iconColor: AppColors.error, bgColor: AppColors.errorLight,
              title: 'Hapus User', subtitle: 'Data user akan dihapus permanen',
              onTap: () { Navigator.pop(context); _showDeleteConfirm(uid, u['nama']); },
            ),
            const SizedBox(height: 8),
            if (!isSuspend) ...[
              _actionTile(icon: Icons.timer_rounded, iconColor: AppColors.warning, bgColor: const Color(0x15FBBF24),
                  title: 'Suspend 1 Hari', subtitle: '',
                  onTap: () { Navigator.pop(context); _hukum(uid, u['nama'], 1); }),
              const SizedBox(height: 8),
              _actionTile(icon: Icons.timer_rounded, iconColor: AppColors.warning, bgColor: const Color(0x15FBBF24),
                  title: 'Suspend 7 Hari', subtitle: '',
                  onTap: () { Navigator.pop(context); _hukum(uid, u['nama'], 7); }),
              const SizedBox(height: 8),
              _actionTile(icon: Icons.timer_rounded, iconColor: AppColors.warning, bgColor: const Color(0x15FBBF24),
                  title: 'Suspend 30 Hari', subtitle: '',
                  onTap: () { Navigator.pop(context); _hukum(uid, u['nama'], 30); }),
            ] else ...[
              _actionTile(icon: Icons.lock_open_rounded, iconColor: AppColors.success, bgColor: AppColors.successLight,
                  title: 'Cabut Suspend', subtitle: '',
                  onTap: () { Navigator.pop(context); _unsuspend(uid, u['nama']); }),
            ],
            const SizedBox(height: 8),
            _actionTile(
              icon: isBanned ? Icons.lock_open_rounded : Icons.gavel_rounded,
              iconColor: isBanned ? AppColors.success : AppColors.error,
              bgColor: isBanned ? AppColors.successLight : AppColors.errorLight,
              title: isBanned ? 'Unban' : 'Ban Permanen', subtitle: '',
              onTap: () { Navigator.pop(context); _banPermanen(uid, u['nama'], !isBanned); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({required IconData icon, required Color iconColor, required Color bgColor,
      required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
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
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (subtitle.isNotEmpty)
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
      'uid': uid, 'type': 'suspend_chat',
      'until': until, 'days': hari,
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nama disuspend $hari hari'), backgroundColor: AppColors.warning),
    );
  }

  Future<void> _unsuspend(String uid, String nama) async {
    await FirebaseFirestore.instance.collection('punishments').doc(uid).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nama sudah bisa chat lagi'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _banPermanen(String uid, String nama, bool ban) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'banned': ban});
    if (ban) {
      await FirebaseFirestore.instance.collection('punishments').doc(uid).set({
        'uid': uid, 'type': 'ban_permanent',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await FirebaseFirestore.instance.collection('punishments').doc(uid).delete();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ban ? '$nama di-ban permanen' : 'Ban $nama dicabut'),
        backgroundColor: ban ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _hapusUser(String uid, String nama) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await FirebaseFirestore.instance.collection('punishments').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nama berhasil dihapus'), backgroundColor: AppColors.error),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus: $e'), backgroundColor: AppColors.textSecondary),
      );
    }
  }

  void _showDeleteConfirm(String uid, String nama) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus User', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Yakin mau hapus $nama?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _hapusUser(uid, nama); },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporan() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
                Text('Belum ada laporan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
            final isPending = status == 'pending';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPending ? AppColors.warning.withOpacity(0.4) : AppColors.border,
                  width: isPending ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending ? const Color(0x15FBBF24) : AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPending ? 'Menunggu' : 'Ditangani',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: isPending ? AppColors.warning : AppColors.success,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(_formatDate(r['createdAt']),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    const Text('Pelapor: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(r['reporterName'] ?? '-',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.flag_outlined, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    const Text('Dilaporkan: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(r['reportedName'] ?? '-',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(r['alasan'] ?? '-',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4))),
                      ],
                    ),
                  ),
                  if (isPending) ...[
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
                                _showUserActions(context, {'id': reportedUid, 'nama': reportedName, 'banned': false}, false);
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

  Future<void> _tandaiSelesai(String reportId) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': 'handled'});
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as dynamic).toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  Widget _buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
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
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Skill paling banyak digunakan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
                                Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                Text('${e.value}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: e.value / maxVal,
                                backgroundColor: AppColors.border,
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
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.handshake_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$totalMatch',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Text('Total match berhasil',
                            style: TextStyle(fontSize: 13, color: Colors.white70)),
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snapshot.data!.docs;
        final filteredDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final type = data['type'] ?? '';
          if (_filter == 'banned' && type != 'ban_permanent') return false;
          if (_filter == 'suspend' && type != 'suspend_chat') return false;
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari username...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.card,
                ),
                onChanged: (val) => setState(() => _search = val.toLowerCase()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _filterBtn('Semua', 'all'),
                _filterBtn('Banned', 'banned'),
                _filterBtn('Suspend', 'suspend'),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: filteredDocs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final uid = data['uid'];
                  final type = data['type'];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();
                      final u = userSnap.data!.data() as Map<String, dynamic>;
                      final nama = (u['nama'] ?? '-').toString();
                      if (_search.isNotEmpty && !nama.toLowerCase().contains(_search)) {
                        return const SizedBox();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: type == 'ban_permanent' ? AppColors.errorLight : const Color(0x15FBBF24),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                type == 'ban_permanent' ? Icons.block_rounded : Icons.timer_rounded,
                                color: type == 'ban_permanent' ? AppColors.error : AppColors.warning,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nama,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: type == 'ban_permanent' ? AppColors.errorLight : const Color(0x15FBBF24),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      type == 'ban_permanent' ? 'BANNED' : 'SUSPEND',
                                      style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w700,
                                        color: type == 'ban_permanent' ? AppColors.error : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
                              onPressed: () => _showUserActions(context,
                                  {'id': uid, 'nama': nama, 'banned': type == 'ban_permanent'},
                                  type == 'suspend_chat'),
                            ),
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
      child: GestureDetector(
        onTap: () => setState(() => _filter = val),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryLight : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }

  Widget _statCard(String num, String label, Color bg, Color fg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withOpacity(0.2)),
        ),
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