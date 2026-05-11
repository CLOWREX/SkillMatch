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

  Future<void> _kirimPesan() async {
    final txt = _msgController.text.trim();
    if (txt.isEmpty) return;

    // 🔥 CEK PUNISHMENT DULU SEBELUM CLEAR
    final punishDoc = await FirebaseFirestore.instance
        .collection('punishments')
        .doc(_myUid)
        .get();

    if (punishDoc.exists) {
      final data = punishDoc.data()!;

      if (data['type'] == 'ban_permanent') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun kamu di-ban permanen oleh admin'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (data['type'] == 'suspend_chat') {
        final until = (data['until'] as Timestamp).toDate();
        if (DateTime.now().isBefore(until)) {
          final sisa = until.difference(DateTime.now());
          final sisaHari = sisa.inDays;
          final sisaJam = sisa.inHours % 24;
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat kamu disuspend. Sisa: $sisaHari hari $sisaJam jam'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        } else {
          await FirebaseFirestore.instance
              .collection('punishments')
              .doc(_myUid)
              .delete();
        }
      }
    }

    // ✅ BARU CLEAR DAN KIRIM
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
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      Color(0xFF8B5CF6),
      AppColors.secondary,
      AppColors.pink,
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
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
                  right: 0, bottom: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: u['status'] == 'online'
                          ? AppColors.success
                          : u['status'] == 'sibuk'
                              ? AppColors.warning
                              : AppColors.textHint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
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
                  u['status'] == 'online'
                      ? 'Online'
                      : u['status'] == 'sibuk'
                          ? 'Sibuk'
                          : u['skill'] ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: u['status'] == 'online'
                          ? AppColors.success
                          : u['status'] == 'sibuk'
                              ? AppColors.warning
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }

                final msgs = snapshot.data?.docs ?? [];

                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text('Belum ada pesan',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Mulai percakapan sekarang!',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i].data() as Map<String, dynamic>;
                    final isMe = m['from'] == _myUid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          gradient: isMe ? AppColors.gradientPrimary : null,
                          color: isMe ? null : AppColors.card,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          border: isMe ? null : Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (_) => _kirimPesan(),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _kirimPesan,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}