import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../chat/chat_screen.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  Color _avatarColor(String av) {
    const colors = [AppColors.primary, Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFEC4899)];
    return colors[av.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Match Saya', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final myData = snapshot.data!.data() as Map<String, dynamic>;
          final matchIds = List<String>.from(myData['matches'] ?? []);

          if (matchIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake_outlined, size: 56, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('Belum ada match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Cari partner dulu!', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: matchIds).get(),
            builder: (context, matchSnap) {
              if (matchSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final matchUsers = matchSnap.data?.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList() ?? [];

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: matchUsers.length,
                itemBuilder: (context, i) {
                  final u = matchUsers[i];
                  final av = u['avatar'] ?? 'X';
                  final avColor = _avatarColor(av);
                  final followingList = List<String>.from(myData['following'] ?? []);
                  final isFollowing = followingList.contains(u['id']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                              radius: 26,
                              backgroundColor: avColor.withOpacity(0.15),
                              child: Text(av, style: TextStyle(color: avColor, fontWeight: FontWeight.w700, fontSize: 14)),
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
                                  Text(u['nama'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                              Text('${u['skill'] ?? ''}${(u['skill2'] ?? '').isNotEmpty ? ' · ${u['skill2']}' : ''}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final ref = FirebaseFirestore.instance.collection('users').doc(myUid);
                                if (isFollowing) {
                                  await ref.update({'following': FieldValue.arrayRemove([u['id']])});
                                } else {
                                  await ref.update({'following': FieldValue.arrayUnion([u['id']])});
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isFollowing ? AppColors.primaryLight : Colors.transparent,
                                  border: Border.all(color: isFollowing ? AppColors.primary : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : '+ Follow',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isFollowing ? AppColors.primary : AppColors.textSecondary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(user: u))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}