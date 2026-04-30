import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/user_service.dart';
import '../chat/chat_screen.dart';

class PesanScreen extends StatelessWidget {
  const PesanScreen({super.key});

  Color _avatarColor(String av) {
    const colors = [AppColors.primary, Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFEC4899)];
    return colors[av.hashCode % colors.length];
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else {
        return '';
      }
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userService = UserService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userService.getMyChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('Belum ada percakapan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Match dulu dengan partner!', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, i) {
              final c = chats[i];
              final av = c['avatar'] ?? 'X';
              final avColor = _avatarColor(av);
              final unreadCount = c['unreadCount'] ?? 0;
              final hasUnread = unreadCount > 0;
              final lastMessage = c['lastMessage'] ?? '';
              final timeStr = _formatTime(c['lastTime']);
              final otherUid = c['otherUid'] ?? '';

              return GestureDetector(
                onTap: () {
                  userService.clearUnread(otherUid);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(user: {...c, 'id': otherUid})),
                  );
                },
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
                            radius: 26,
                            backgroundColor: avColor.withOpacity(0.15),
                            child: Text(av, style: TextStyle(color: avColor, fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: c['status'] == 'online' ? AppColors.success : c['status'] == 'sibuk' ? const Color(0xFFF59E0B) : Colors.grey,
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
                            Text(c['nama'] ?? '',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 3),
                            Text(
                              lastMessage.isEmpty ? 'Mulai percakapan...' : lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (timeStr.isNotEmpty)
                            Text(timeStr,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: hasUnread ? AppColors.primary : AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          if (hasUnread)
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: Text('$unreadCount',
                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}