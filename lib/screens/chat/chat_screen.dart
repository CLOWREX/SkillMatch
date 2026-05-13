import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
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
  bool _isSendingImage = false;

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

  // 🔥 CEK PUNISHMENT
  Future<bool> _cekPunishment() async {
    final punishDoc = await FirebaseFirestore.instance
        .collection('punishments')
        .doc(_myUid)
        .get();

    if (!punishDoc.exists) return false;
    final data = punishDoc.data()!;

    if (data['type'] == 'ban_permanent') {
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun kamu di-ban permanen oleh admin'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }

    if (data['type'] == 'suspend_chat') {
      final until = (data['until'] as Timestamp).toDate();
      if (DateTime.now().isBefore(until)) {
        final sisa = until.difference(DateTime.now());
        final sisaHari = sisa.inDays;
        final sisaJam = sisa.inHours % 24;
        if (!mounted) return true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat kamu disuspend. Sisa: $sisaHari hari $sisaJam jam'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return true;
      } else {
        await FirebaseFirestore.instance
            .collection('punishments')
            .doc(_myUid)
            .delete();
      }
    }
    return false;
  }

  // 🔥 KIRIM TEKS
  Future<void> _kirimPesan() async {
    final txt = _msgController.text.trim();
    if (txt.isEmpty) return;
    if (await _cekPunishment()) return;
    _msgController.clear();
    await _userService.sendMessage(_otherUid, txt);
    _scrollToBottom();
  }

  // 🔥 KIRIM FOTO
  Future<void> _kirimFoto() async {
    if (await _cekPunishment()) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isSendingImage = true);

    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=b089d336ae628a18b1cb4f9b0de8f998'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final imageUrl = json['data']['url'] as String;

        // Kirim sebagai pesan dengan type 'image'
        final ids = [_myUid, _otherUid]..sort();
        final chatId = '${ids[0]}_${ids[1]}';
        final now = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'from': _myUid,
          'text': '',
          'imageUrl': imageUrl,
          'type': 'image',
          'createdAt': now,
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .set({
          'participants': [_myUid, _otherUid],
          'lastMessage': '📷 Foto',
          'lastTime': now,
          'unread_$_otherUid': FieldValue.increment(1),
          'unread_$_myUid': 0,
        }, SetOptions(merge: true));

        _scrollToBottom();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal kirim foto, coba lagi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }

    setState(() => _isSendingImage = false);
  }

  void _scrollToBottom() {
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

  // 🔥 DETEKSI LINK
  bool _isUrl(String text) {
    return text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.startsWith('www.');
  }

  Future<void> _bukaLink(String url) async {
    final uri = Uri.parse(url.startsWith('www.') ? 'https://$url' : url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _avatarColor(String av) {
    const colors = [
      AppColors.primary, AppColors.success, AppColors.warning,
      AppColors.error, Color(0xFF8B5CF6), AppColors.secondary, AppColors.pink,
    ];
    return colors[av.hashCode % colors.length];
  }

  // 🔥 BUILD BUBBLE PESAN
  Widget _buildBubble(Map<String, dynamic> m, bool isMe) {
    final type = m['type'] ?? 'text';
    final imageUrl = m['imageUrl'] ?? '';
    final text = m['text'] ?? '';

    // Bubble foto
    if (type == 'image' && imageUrl.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          child: GestureDetector(
            onTap: () => _bukaLink(imageUrl),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 200, height: 150,
                  color: AppColors.card,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 200, height: 100,
                color: AppColors.card,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Bubble teks / link
    final isLink = _isUrl(text);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        gradient: isMe ? AppColors.gradientPrimary : null,
        color: isMe ? null : (isLink ? AppColors.primaryLight : AppColors.card),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe ? null : Border.all(
          color: isLink ? AppColors.primary.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: isLink
          ? GestureDetector(
              onTap: () => _bukaLink(text),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_rounded, size: 16,
                      color: isMe ? Colors.white : AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: isMe ? Colors.white : AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final av = u['avatar'] ?? 'X';
    final avColor = _avatarColor(av);
    final photoUrl = u['photoUrl']?.toString() ?? '';

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
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(av, style: TextStyle(color: avColor, fontSize: 12, fontWeight: FontWeight.w700))
                      : null,
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(
                  u['status'] == 'online' ? 'Online' : u['status'] == 'sibuk' ? 'Sibuk' : u['skill'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: u['status'] == 'online'
                        ? AppColors.success
                        : u['status'] == 'sibuk'
                            ? AppColors.warning
                            : AppColors.textSecondary,
                  ),
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
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final msgs = snapshot.data?.docs ?? [];

                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: const BoxDecoration(
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
                      child: _buildBubble(m, isMe),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // 🔥 Tombol foto
                GestureDetector(
                  onTap: _isSendingImage ? null : _kirimFoto,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _isSendingImage
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.image_rounded, color: AppColors.textSecondary, size: 20),
                  ),
                ),
                const SizedBox(width: 8),

                // Input teks
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
                        hintText: 'Tulis pesan atau link...',
                        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol kirim
                GestureDetector(
                  onTap: _kirimPesan,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
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