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
  String _search    = '';
  String _filter    = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
          child: const Text('Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: context.surfaceColor,
            child: Row(
              children: [
                _tabBtn('Users', 0),
                _tabBtn('Laporan', 1),
                _tabBtn('Statistik', 2),
                _tabBtn('Hukuman', 3),
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

  // ── TAB BUTTON ────────────────────────────────────────
  Widget _tabBtn(String label, int idx) {
    final isOn = _currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: isOn ? AppColors.primary : Colors.transparent, width: 2,
            )),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOn ? AppColors.primary : context.textSecondary,
              )),
        ),
      ),
    );
  }

  // ── TAB: USERS ────────────────────────────────────────
  Widget _buildUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Belum ada user',
              style: TextStyle(color: context.textSecondary)));
        }

        final users = snapshot.data!.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {
            'id': d.id,
            'nama': data['nama'] ?? '',
            'skill': data['skill'] ?? '',
            'phone': data['phone'] ?? '',
            'status': data['status'] ?? 'offline',
            'matches': data['matches'] ?? [],
            'banned': data['banned'] ?? false,
          };
        }).toList();

        final online     = users.where((u) => u['status'] == 'online').length;
        final totalMatch = users.fold(0, (sum, u) => sum + ((u['matches'] as List?)?.length ?? 0));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stat cards
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

              // User list
              Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: users.asMap().entries.map((entry) {
                    final i   = entry.key;
                    final u   = entry.value;
                    final uid = u['id'] as String;
                    return Column(
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('punishments').doc(uid).snapshots(),
                          builder: (context, snap) {
                            String statusLabel = '';
                            bool isSuspend     = false;
                            if (snap.hasData && snap.data!.exists) {
                              final p    = snap.data!.data() as Map<String, dynamic>;
                              final type = p['type'];
                              if (type == 'suspend_chat') {
                                final until = (p['until'] as dynamic).toDate() as DateTime;
                                if (DateTime.now().isBefore(until)) {
                                  statusLabel = 'SUSPEND';
                                  isSuspend   = true;
                                }
                              }
                              if (type == 'ban_permanent') statusLabel = 'BANNED';
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
                                  Text(u['nama'] as String,
                                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                                  if (statusLabel.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSuspend ? const Color(0x15FBBF24) : AppColors.errorLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(statusLabel,
                                          style: TextStyle(
                                            fontSize: 10, fontWeight: FontWeight.w700,
                                            color: isSuspend ? AppColors.warning : AppColors.error,
                                          )),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u['skill'] as String,
                                      style: TextStyle(color: context.textSecondary, fontSize: 12)),
                                  if ((u['phone'] as String).isNotEmpty)
                                    Text(u['phone'] as String,
                                        style: TextStyle(color: context.textHint, fontSize: 11)),
                                ],
                              ),
                              isThreeLine: (u['phone'] as String).isNotEmpty,
                              trailing: IconButton(
                                icon: Icon(Icons.more_vert, color: context.textSecondary),
                                onPressed: () => _showUserActions(context, u, isSuspend),
                              ),
                            );
                          },
                        ),
                        if (i < users.length - 1)
                          Divider(height: 1, color: context.borderColor),
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

  // ── ACTION SHEET ─────────────────────────────────────
  void _showUserActions(BuildContext context, Map<String, dynamic> u, bool isSuspend) {
    final uid      = u['id'] as String;
    final phone    = u['phone'] as String? ?? '';
    final isBanned = (u['banned'] ?? false) == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(u['nama'] as String,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
            if (phone.isNotEmpty)
              Text(phone, style: TextStyle(fontSize: 12, color: context.textSecondary)),
            const SizedBox(height: 16),

            // Hapus
            _actionTile(
              context: context,
              icon: Icons.delete_rounded, iconColor: AppColors.error, bgColor: AppColors.errorLight,
              title: 'Hapus User', subtitle: 'Data dihapus permanen',
              onTap: () { Navigator.pop(context); _showDeleteConfirm(uid, u['nama'] as String); },
            ),
            const SizedBox(height: 8),

            // Suspend / Unsuspend
            if (!isSuspend) ...[
              _actionTile(context: context,
                  icon: Icons.timer_rounded, iconColor: AppColors.warning, bgColor: const Color(0x15FBBF24),
                  title: 'Suspend 1 Hari', subtitle: '',
                  onTap: () { Navigator.pop(context); _hukum(uid, u['nama'] as String, 1); }),
              const SizedBox(height: 8),
              _actionTile(context: context,
                  icon: Icons.timer_rounded, iconColor: AppColors.warning, bgColor: const Color(0x15FBBF24),
                  title: 'Suspend 7 Hari', subtitle: '',
                  onTap: () { Navigator.pop(context); _hukum(uid, u['nama'] as String, 7); }),
              const SizedBox(height: 8),
              _actionTile(context: context,
                  icon: Icons.timer_rounded, iconColor: AppColors.warning, bgColor: const Color(0x15FBBF24),
                  title: 'Suspend 30 Hari', subtitle: '',
                  onTap: () { Navigator.pop(context); _hukum(uid, u['nama'] as String, 30); }),
            ] else ...[
              _actionTile(context: context,
                  icon: Icons.lock_open_rounded, iconColor: AppColors.success, bgColor: AppColors.successLight,
                  title: 'Cabut Suspend', subtitle: '',
                  onTap: () { Navigator.pop(context); _unsuspend(uid, u['nama'] as String); }),
            ],
            const SizedBox(height: 8),

            // Ban akun (UID)
            _actionTile(
              context: context,
              icon: isBanned ? Icons.lock_open_rounded : Icons.gavel_rounded,
              iconColor: isBanned ? AppColors.success : AppColors.error,
              bgColor: isBanned ? AppColors.successLight : AppColors.errorLight,
              title: isBanned ? 'Unban Akun' : 'Ban Akun (UID)',
              subtitle: 'Akun tidak bisa login',
              onTap: () { Navigator.pop(context); _banPermanen(uid, u['nama'] as String, !isBanned); },
            ),
            const SizedBox(height: 8),

            // 🔥 Ban nomor HP
            if (phone.isNotEmpty)
              _actionTile(
                context: context,
                icon: Icons.phone_disabled_rounded,
                iconColor: AppColors.error,
                bgColor: AppColors.errorLight,
                title: 'Ban Nomor HP',
                subtitle: 'Nomor $phone tidak bisa daftar/login',
                onTap: () { Navigator.pop(context); _banPhone(phone, u['nama'] as String); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
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
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  // ── AKSI ADMIN ────────────────────────────────────────
  Future<void> _hukum(String uid, String nama, int hari) async {
    final until = DateTime.now().add(Duration(days: hari));
    await FirebaseFirestore.instance.collection('punishments').doc(uid).set({
      'uid': uid, 'type': 'suspend_chat',
      'until': until, 'days': hari,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$nama disuspend $hari hari'),
      backgroundColor: AppColors.warning,
    ));
  }

  Future<void> _unsuspend(String uid, String nama) async {
    await FirebaseFirestore.instance.collection('punishments').doc(uid).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$nama sudah bisa chat lagi'),
      backgroundColor: AppColors.success,
    ));
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ban ? '$nama di-ban permanen' : 'Ban $nama dicabut'),
      backgroundColor: ban ? AppColors.error : AppColors.success,
    ));
  }

  // 🔥 BAN NOMOR HP — simpan di koleksi banned_phones
  Future<void> _banPhone(String phone, String nama) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ban Nomor HP', style: TextStyle(color: context.textPrimary)),
        content: Text(
          'Nomor $phone tidak akan bisa daftar atau login lagi.\nYakin?',
          style: TextStyle(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('banned_phones')
                  .doc(phone)
                  .set({
                'phone': phone,
                'bannedFrom': nama,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Nomor $phone berhasil di-ban'),
                backgroundColor: AppColors.error,
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Ban Nomor'),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusUser(String uid, String nama) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await FirebaseFirestore.instance.collection('punishments').doc(uid).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$nama berhasil dihapus'), backgroundColor: AppColors.error,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal hapus: $e'), backgroundColor: context.textSecondary,
      ));
    }
  }

  void _showDeleteConfirm(String uid, String nama) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus User', style: TextStyle(color: context.textPrimary)),
        content: Text('Yakin mau hapus $nama?', style: TextStyle(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _hapusUser(uid, nama); },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── TAB: LAPORAN ─────────────────────────────────────
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 56, color: context.textSecondary),
                const SizedBox(height: 12),
                Text('Belum ada laporan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, i) {
            final r        = reports[i].data() as Map<String, dynamic>;
            final status   = r['status'] ?? 'pending';
            final isPending = status == 'pending';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPending ? AppColors.warning.withOpacity(0.4) : context.borderColor,
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
                          style: TextStyle(fontSize: 11, color: context.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text('Pelapor: ', style: TextStyle(fontSize: 13, color: context.textSecondary)),
                    Text(r['reporterName'] ?? '-',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.flag_outlined, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text('Dilaporkan: ', style: TextStyle(fontSize: 13, color: context.textSecondary)),
                    Text(r['reportedName'] ?? '-',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: context.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(r['alasan'] ?? '-',
                            style: TextStyle(fontSize: 13, color: context.textPrimary, height: 1.4))),
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
                            child: const Text('Selesai', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final reportedUid  = r['reportedUid'] ?? '';
                              final reportedName = r['reportedName'] ?? '';
                              if (reportedUid.isNotEmpty) {
                                await _tandaiSelesai(reports[i].id);
                                if (!mounted) return;
                                _showUserActions(
                                  context,
                                  {'id': reportedUid, 'nama': reportedName, 'phone': '', 'banned': false},
                                  false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Hukuman', style: TextStyle(fontSize: 13)),
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

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as dynamic).toDate() as DateTime;
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  // ── TAB: STATISTIK ────────────────────────────────────
  Widget _buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs  = snapshot.data?.docs ?? [];
        final users = docs.map((d) => d.data() as Map<String, dynamic>).toList();

        final skillCount = <String, int>{};
        for (final u in users) {
          final s  = u['skill'] as String?;
          final s2 = u['skill2'] as String?;
          if (s  != null && s.isNotEmpty)  skillCount[s]  = (skillCount[s]  ?? 0) + 2;
          if (s2 != null && s2.isNotEmpty) skillCount[s2] = (skillCount[s2] ?? 0) + 1;
        }
        final sorted = skillCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final top5   = sorted.take(5).toList();
        final maxVal = top5.isNotEmpty ? top5.first.value : 1;
        final totalMatch = users.fold(0, (sum, u) => sum + ((u['matches'] as List?)?.length ?? 0));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skill paling banyak',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                    const SizedBox(height: 16),
                    if (top5.isEmpty)
                      Text('Belum ada data', style: TextStyle(color: context.textSecondary))
                    else
                      ...top5.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimary)),
                                Text('${e.value}', style: TextStyle(fontSize: 13, color: context.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: e.value / maxVal,
                                backgroundColor: context.borderColor,
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
              const SizedBox(height: 12),

              // 🔥 Tab banned phones
              _buildBannedPhones(),
            ],
          ),
        );
      },
    );
  }

  // 🔥 DAFTAR NOMOR HP YANG DI-BAN
  Widget _buildBannedPhones() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('banned_phones').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_disabled_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text('Nomor HP di-ban (${docs.length})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 12),
              ...docs.map((d) {
                final data  = d.data() as Map<String, dynamic>;
                final phone = data['phone'] as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(phone,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary))),
                      TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('banned_phones').doc(phone).delete();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Ban nomor $phone dicabut'),
                            backgroundColor: AppColors.success,
                          ));
                        },
                        child: const Text('Cabut', style: TextStyle(color: AppColors.success, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── TAB: HUKUMAN ─────────────────────────────────────
  Widget _buildPunished() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('punishments').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final type = data['type'] ?? '';
          if (_filter == 'banned'  && type != 'ban_permanent') return false;
          if (_filter == 'suspend' && type != 'suspend_chat')  return false;
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari username...',
                  hintStyle: TextStyle(color: context.textHint),
                  prefixIcon: Icon(Icons.search, color: context.textSecondary),
                  filled: true,
                  fillColor: context.cardColor,
                ),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
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
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final uid  = data['uid'] as String;
                  final type = data['type'] as String;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();
                      final u    = userSnap.data!.data() as Map<String, dynamic>;
                      final nama = (u['nama'] ?? '-').toString();
                      final phone = (u['phone'] ?? '').toString();
                      if (_search.isNotEmpty && !nama.toLowerCase().contains(_search)) {
                        return const SizedBox();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor),
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
                                  Text(nama, style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary)),
                                  if (phone.isNotEmpty)
                                    Text(phone, style: TextStyle(fontSize: 11, color: context.textHint)),
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
                              icon: Icon(Icons.settings_rounded, color: context.textSecondary),
                              onPressed: () => _showUserActions(
                                context,
                                {'id': uid, 'nama': nama, 'phone': phone, 'banned': type == 'ban_permanent'},
                                type == 'suspend_chat',
                              ),
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
            color: isActive ? AppColors.primaryLight : context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppColors.primary : context.borderColor),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : context.textSecondary,
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