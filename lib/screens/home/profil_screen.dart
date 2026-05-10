import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});
  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _authService = AuthService();
  bool _isEditing = false;
  late TextEditingController _namaController;
  late TextEditingController _bioController;
  String _selectedSkill = '';
  String _selectedSkill2 = '';
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final List<String> _skills = [
    'Desain UI/UX', 'Ngoding (Web/App)', 'Editing Video',
    'Nulis Konten', 'Public Speaking', 'Fotografi',
    'Data Analisis', 'Multitasking & Manajemen',
    'Social Media', 'Ilustrasi/Gambar',
  ];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Color _avatarColor(String av) {
    const colors = [
      AppColors.primary, Color(0xFF10B981), Color(0xFFF59E0B),
      Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFEC4899),
    ];
    return colors[av.hashCode % colors.length];
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=b089d336ae628a18b1cb4f9b0de8f998'),
        body: {'image': base64Image},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _gantiFotoProfil() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);

    final url = await _uploadImage(File(picked.path));

    if (url != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_myUid)
          .set({'photoUrl': url}, SetOptions(merge: true)); // ✅ FIX
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal upload foto, coba lagi.'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isUploadingPhoto = false);
  }

  Future<void> _simpanProfil(Map<String, dynamic> currentData) async {
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_myUid)
        .set({ // ✅ FIX
      'nama': _namaController.text.trim(),
      'skill': _selectedSkill,
      'skill2': _selectedSkill2,
      'bio': _bioController.text.trim(),
      'isProfileComplete': true,
      'avatar': _namaController.text
          .trim()
          .split(' ')
          .map((w) => w.isNotEmpty ? w[0] : '')
          .join()
          .substring(0, _namaController.text.trim().split(' ').length >= 2 ? 2 : 1)
          .toUpperCase(),
    }, SetOptions(merge: true));
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showPeopleList(String tipe, List<String> uids) async {
    if (uids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belum ada $tipe'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: uids)
        .get();
    final people = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    final title = tipe == 'Followers'
        ? 'Followers kamu'
        : tipe == 'Following'
            ? 'Kamu following'
            : 'Yang menyukaimu';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: people.length,
              itemBuilder: (_, i) {
                final p = people[i];
                final av = p['avatar'] ?? 'X';
                final avColor = _avatarColor(av);
                final photoUrl = p['photoUrl']?.toString() ?? '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avColor.withOpacity(0.15),
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(av,
                            style: TextStyle(
                                color: avColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13))
                        : null,
                  ),
                  title: Text(p['nama'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(p['skill'] ?? '',
                      style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title:
            const Text('Profil', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_myUid)
                .snapshots(),
            builder: (context, snapshot) {
              final data =
                  snapshot.data?.data() as Map<String, dynamic>?;
              return TextButton(
                onPressed: () {
                  if (_isEditing) {
                    _simpanProfil(data ?? {});
                  } else {
                    _namaController.text = data?['nama'] ?? '';
                    _bioController.text = data?['bio'] ?? '';
                    _selectedSkill = data?['skill'] ?? _skills[0];
                    _selectedSkill2 = data?['skill2'] ?? '';
                    setState(() => _isEditing = true);
                  }
                },
                child: Text(
                  _isEditing ? 'Simpan' : 'Edit',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_myUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nama = data['nama'] ?? '';
          final skill = data['skill'] ?? '';
          final skill2 = data['skill2'] ?? '';
          final bio = data['bio'] ?? '';
          final av = data['avatar'] ?? 'X';
          final avColor = _avatarColor(av);
          final photoUrl = data['photoUrl']?.toString() ?? '';
          final followers = List<String>.from(data['followers'] ?? []);
          final following = List<String>.from(data['following'] ?? []);
          final likes = List<String>.from(data['likes'] ?? []);
          final matches = List<String>.from(data['matches'] ?? []);

          if (!_isEditing) {
            _namaController.text = nama;
            _bioController.text = bio;
            if (_selectedSkill.isEmpty)
              _selectedSkill = skill.isNotEmpty ? skill : _skills[0];
            if (_selectedSkill2.isEmpty) _selectedSkill2 = skill2;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Profile Card ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Avatar dengan tombol ganti foto ──
                      GestureDetector(
                        onTap: _isUploadingPhoto ? null : _gantiFotoProfil,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: photoUrl.isEmpty
                                    ? LinearGradient(
                                        colors: [
                                          avColor.withOpacity(0.3),
                                          avColor.withOpacity(0.1)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 2),
                              ),
                              child: ClipOval(
                                child: photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            color: Colors.grey.shade100,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.primary),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(av,
                                              style: TextStyle(
                                                  color: avColor,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800)),
                                        ),
                                      )
                                    : Center(
                                        child: Text(av,
                                            style: TextStyle(
                                                color: avColor,
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800)),
                                      ),
                              ),
                            ),
                            if (_isUploadingPhoto)
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                ),
                              ),
                            if (!_isUploadingPhoto)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 13, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap untuk ganti foto',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 8),
                      Text(nama,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      if (skill.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(skill,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                              onTap: () =>
                                  _showPeopleList('Followers', followers),
                              child: _statCol('${followers.length}', 'Followers',
                                  AppColors.primary)),
                          GestureDetector(
                              onTap: () =>
                                  _showPeopleList('Following', following),
                              child: _statCol('${following.length}', 'Following',
                                  AppColors.secondary)),
                          GestureDetector(
                              onTap: () => _showPeopleList('Likes', likes),
                              child: _statCol(
                                  '${likes.length}', 'Likes', Colors.pink)),
                          _statCol(
                              '${matches.length}', 'Match', AppColors.success),
                        ],
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Edit Form ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04), blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          const Text('Edit Profil',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Nama',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _namaController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _isEditing
                              ? Colors.white
                              : AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Skill utama',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedSkill.isNotEmpty &&
                                _skills.contains(_selectedSkill)
                            ? _selectedSkill
                            : _skills[0],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _isEditing
                              ? Colors.white
                              : AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: _skills
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: _isEditing
                            ? (v) => setState(() => _selectedSkill = v!)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      const Text('Skill tambahan',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedSkill2.isNotEmpty &&
                                _skills.contains(_selectedSkill2)
                            ? _selectedSkill2
                            : null,
                        hint: const Text('-- Opsional --',
                            style: TextStyle(fontSize: 14)),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _isEditing
                              ? Colors.white
                              : AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: _skills
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: _isEditing
                            ? (v) => setState(() => _selectedSkill2 = v ?? '')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      const Text('Bio',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _bioController,
                        enabled: _isEditing,
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _isEditing
                              ? Colors.white
                              : AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _isSaving ? null : () => _simpanProfil(data),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Simpan profil',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_myUid)
                                .set({'status': 'offline'},
                                    SetOptions(merge: true)); // ✅ FIX
                            await _authService.logout();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Keluar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCol(String num, String label, Color color) {
    return Column(
      children: [
        Text(num,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}