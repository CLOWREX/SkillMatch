import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _userService = UserService();

  late String _otherUid;
  late String _chatId;

  @override
  void initState() {
    super.initState();
    _otherUid = widget.user['id'] ?? widget.user['otherUid'] ?? '';
    final ids = [_myUid, _otherUid]..sort();
    _chatId = '${ids[0]}_${ids[1]}';
    _userService.clearUnread(_otherUid);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔥 UPDATED FUNCTION (CEK PUNISHMENT)
  Future<void> _kirimPesan() async {
    final txt = _msgController.text.trim();
    if (txt.isEmpty) return;

    // 🔥 CEK PUNISHMENT
    final punishDoc = await FirebaseFirestore.instance
        .collection('punishments')
        .doc(_myUid)
        .get();

    if (punishDoc.exists) {
      final data = punishDoc.data()!;

      // ❌ BAN PERMANEN
      if (data['type'] == 'ban_permanent') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun kamu di-ban permanen oleh admin'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // ⚠️ SUSPEND CHAT
      if (data['type'] == 'suspend_chat') {
        final until = (data['until'] as Timestamp).toDate();

        if (DateTime.now().isBefore(until)) {
          final sisa = until.difference(DateTime.now());
          final sisaHari = sisa.inDays;
          final sisaJam = sisa.inHours % 24;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Chat kamu disuspend. Sisa: $sisaHari hari $sisaJam jam'),
              backgroundColor: const Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        } else {
          // ✅ SUDAH SELESAI → HAPUS
          await FirebaseFirestore.instance
              .collection('punishments')
              .doc(_myUid)
              .delete();
        }
      }
    }

    // ✅ KIRIM PESAN
    _msgController.clear();
    await _userService.sendMessage(_otherUid, txt);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _avatarColor(String av) {
    const colors = [
      AppColors.primary,
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFEC4899)
    ];
    return colors[av.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final av = u['avatar'] ?? 'X';
    final avColor = _avatarColor(av);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avColor.withOpacity(0.15),
                  child: Text(av,
                      style: TextStyle(
                          color: avColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: u['status'] == 'online'
                          ? AppColors.success
                          : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u['nama'] ?? '',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(
                  u['status'] == 'online' ? 'Online' : u['skill'] ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: u['status'] == 'online'
                          ? AppColors.success
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }

                final msgs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m =
                        msgs[i].data() as Map<String, dynamic>;
                    final isMe = m['from'] == _myUid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔥 INPUT
          Container(
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: (_) => _kirimPesan(),
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _kirimPesan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}