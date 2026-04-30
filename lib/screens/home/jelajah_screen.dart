import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/user_service.dart';
import '../chat/chat_screen.dart';

class JelajahScreen extends StatefulWidget {
  const JelajahScreen({super.key});
  @override
  State<JelajahScreen> createState() => _JelajahScreenState();
}

class _JelajahScreenState extends State<JelajahScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _userService = UserService();

  Color _avatarColor(String av) {
    const colors = [AppColors.primary, Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFEC4899)];
    return colors[av.hashCode % colors.length];
  }

  List<Map<String, dynamic>> _filterAndSort(List<Map<String, dynamic>> users, String query) {
    if (query.isEmpty) return users;
    final q = query.toLowerCase();
    final exact = users.where((u) => (u['nama'] as String? ?? '').toLowerCase() == q).toList();
    final starts = users.where((u) {
      final nama = (u['nama'] as String? ?? '').toLowerCase();
      return nama.startsWith(q) && nama != q;
    }).toList();
    final contains = users.where((u) {
      final nama = (u['nama'] as String? ?? '').toLowerCase();
      return nama.contains(q) && !nama.startsWith(q);
    }).toList();
    return [...exact, ...starts, ...contains];
  }

  void _lihatProfil(Map<String, dynamic> u, Map<String, dynamic> myData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfilSheet(
        u: u,
        myData: myData,
        myUid: _myUid,
        userService: _userService,
        avatarColor: _avatarColor(u['avatar'] ?? 'X'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jelajah', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_myUid).snapshots(),
        builder: (context, mySnap) {
          final myData = mySnap.data?.data() as Map<String, dynamic>? ?? {};

          return Column(
            children: [
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Cari nama...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                            onPressed: () { _searchController.clear(); setState(() => _query = ''); },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users')
                      .where('isProfileComplete', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Belum ada pengguna', style: TextStyle(color: AppColors.textSecondary)));
                    }

                    final allUsers = snapshot.data!.docs
                        .where((d) => d.id != _myUid)
                        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                        .toList();

                    final filtered = _filterAndSort(allUsers, _query);
                    final online = allUsers.where((u) => u['status'] == 'online').length;
                    final sibuk = allUsers.where((u) => u['status'] == 'sibuk').length;
                    final offline = allUsers.where((u) => u['status'] == 'offline').length;
                    final myFollowing = List<String>.from(myData['following'] ?? []);

                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statusCount(online, 'Online', AppColors.success),
                              Container(width: 1, height: 30, color: Colors.grey.shade200),
                              _statusCount(sibuk, 'Sibuk', const Color(0xFFF59E0B)),
                              Container(width: 1, height: 30, color: Colors.grey.shade200),
                              _statusCount(offline, 'Offline', AppColors.textSecondary),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                                      const SizedBox(height: 8),
                                      Text('Tidak ada hasil untuk "$_query"', style: const TextStyle(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) {
                                    final u = filtered[i];
                                    final avColor = _avatarColor(u['avatar'] ?? 'X');
                                    final followers = List<String>.from(u['followers'] ?? []);
                                    final isFollowing = myFollowing.contains(u['id']);

                                    return GestureDetector(
                                      onTap: () => _lihatProfil(u, myData),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                        ),
                                        child: Row(
                                          children: [
                                            Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: avColor.withOpacity(0.15),
                                                  child: Text(u['avatar'] ?? 'X', style: TextStyle(color: avColor, fontWeight: FontWeight.w700, fontSize: 14)),
                                                ),
                                                Positioned(
                                                  right: 0, bottom: 0,
                                                  child: Container(
                                                    width: 12, height: 12,
                                                    decoration: BoxDecoration(
                                                      color: u['status'] == 'online' ? AppColors.success : u['status'] == 'sibuk' ? const Color(0xFFF59E0B) : Colors.grey,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 2),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(u['nama'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                                      if (isFollowing) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                                                          child: const Text('Following', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(u['skill'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.people_rounded, size: 12, color: AppColors.textSecondary),
                                                    const SizedBox(width: 3),
                                                    Text('${followers.length}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: u['status'] == 'online' ? AppColors.successLight : u['status'] == 'sibuk' ? const Color(0xFFFEF3C7) : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    u['status'] == 'online' ? 'Online' : u['status'] == 'sibuk' ? 'Sibuk' : 'Offline',
                                                    style: TextStyle(
                                                      fontSize: 10, fontWeight: FontWeight.w600,
                                                      color: u['status'] == 'online' ? AppColors.success : u['status'] == 'sibuk' ? const Color(0xFFF59E0B) : Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCount(int count, String label, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ProfilSheet extends StatelessWidget {
  final Map<String, dynamic> u;
  final Map<String, dynamic> myData;
  final String myUid;
  final UserService userService;
  final Color avatarColor;

  const _ProfilSheet({
    required this.u,
    required this.myData,
    required this.myUid,
    required this.userService,
    required this.avatarColor,
  });

  // 🔥 FUNCTION LAPOR (FINAL - PAKAI FIRESTORE)
  void _laporkan(BuildContext context) {
    final alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Laporkan User',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Melaporkan: ${u['nama'] ?? 'User'}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: alasanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Jelaskan alasan laporan...',
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),

          ElevatedButton(
            onPressed: () async {
              if (alasanController.text.trim().isEmpty) return;

              try {
                final myDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(myUid)
                    .get();

                final myNama = myDoc.data()?['nama'] ?? 'Unknown';

                await FirebaseFirestore.instance.collection('reports').add({
                  'reporterUid': myUid,
                  'reporterName': myNama,
                  'reportedUid': u['id'],
                  'reportedName': u['nama'],
                  'alasan': alasanController.text.trim(),
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context); // tutup dialog
                Navigator.pop(context); // tutup profil

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Laporan berhasil dikirim!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengirim laporan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Kirim laporan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherId = u['id'] as String;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
      builder: (context, mySnap) {
        final latestMyData =
            mySnap.data?.data() as Map<String, dynamic>? ?? myData;

        final myFollowing =
            List<String>.from(latestMyData['following'] ?? []);
        final myLiked =
            List<String>.from(latestMyData['likedUsers'] ?? []);

        final isFollowing = myFollowing.contains(otherId);
        final isLiked = myLiked.contains(otherId);

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(otherId)
              .snapshots(),
          builder: (context, userSnap) {
            final userData =
                userSnap.data?.data() as Map<String, dynamic>? ?? u;

            final followers =
                List<String>.from(userData['followers'] ?? []);
            final following =
                List<String>.from(userData['following'] ?? []);
            final likes =
                List<String>.from(userData['likes'] ?? []);

            final myMatches =
                List<String>.from(latestMyData['matches'] ?? []);
            final isMatched = myMatches.contains(otherId);

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            avatarColor.withOpacity(0.15),
                        child: Text(
                          userData['avatar'] ?? 'X',
                          style: TextStyle(
                            color: avatarColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: userData['status'] == 'online'
                                ? AppColors.success
                                : userData['status'] == 'sibuk'
                                    ? const Color(0xFFF59E0B)
                                    : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    userData['nama'] ?? '',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    userData['skill'] ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _stat('${followers.length}', 'Followers'),
                      _stat('${following.length}', 'Following'),
                      _stat('${likes.length}', 'Likes'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              userService.toggleFollow(otherId),
                          icon: Icon(
                            isFollowing
                                ? Icons.person_remove_outlined
                                : Icons.person_add_outlined,
                            size: 16,
                          ),
                          label: Text(
                              isFollowing ? 'Following' : '+ Follow'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              userService.toggleLike(otherId),
                          icon: Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: isLiked
                                ? Colors.pink
                                : AppColors.textSecondary,
                          ),
                          label:
                              Text(isLiked ? 'Disukai' : 'Like'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isMatched
                          ? () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    user: {
                                      ...userData,
                                      'id': otherId
                                    },
                                  ),
                                ),
                              );
                            }
                          : () async {
                              await userService.addMatch(otherId);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Terhubung dengan ${userData['nama']}!'),
                                  backgroundColor:
                                      AppColors.success,
                                ),
                              );
                            },
                      icon: Icon(
                        isMatched
                            ? Icons.chat_bubble_outline_rounded
                            : Icons.handshake_rounded,
                        size: 16,
                      ),
                      label: Text(isMatched
                          ? 'Kirim pesan'
                          : 'Connect & Chat'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔥 TOMBOL LAPOR FINAL
                  TextButton.icon(
                    onPressed: () => _laporkan(context),
                    icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.error),
                    label: const Text(
                      'Laporkan user ini',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _stat(String num, String label) {
    return Column(
      children: [
        Text(num, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}