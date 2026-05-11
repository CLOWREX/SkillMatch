import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_screen.dart';
import '../../core/theme.dart';

class SetupProfilScreen extends StatefulWidget {
  const SetupProfilScreen({super.key});

  @override
  State<SetupProfilScreen> createState() => _SetupProfilScreenState();
}

class _SetupProfilScreenState extends State<SetupProfilScreen> {
  final _bioController = TextEditingController();
  String _selectedSkill = 'Desain UI/UX';
  String _selectedSkill2 = '';
  bool _isLoading = false;
  int _step = 0;

  final List<String> _skills = [
    'Desain UI/UX', 'Ngoding (Web/App)', 'Editing Video',
    'Nulis Konten', 'Public Speaking', 'Fotografi',
    'Data Analisis', 'Multitasking & Manajemen',
    'Social Media', 'Ilustrasi/Gambar',
  ];

  final List<String> _hobi = [
    'Membaca', 'Gaming', 'Olahraga', 'Memasak',
    'Traveling', 'Musik', 'Film', 'Fotografi',
    'Coding', 'Desain', 'Menulis', 'Menggambar',
  ];

  final Map<String, IconData> _skillIcons = {
    'Desain UI/UX': Icons.palette_rounded,
    'Ngoding (Web/App)': Icons.code_rounded,
    'Editing Video': Icons.video_camera_back_rounded,
    'Nulis Konten': Icons.edit_rounded,
    'Public Speaking': Icons.mic_rounded,
    'Fotografi': Icons.camera_alt_rounded,
    'Data Analisis': Icons.bar_chart_rounded,
    'Multitasking & Manajemen': Icons.task_alt_rounded,
    'Social Media': Icons.share_rounded,
    'Ilustrasi/Gambar': Icons.brush_rounded,
  };

  final Map<String, IconData> _hobiIcons = {
    'Membaca': Icons.menu_book_rounded,
    'Gaming': Icons.sports_esports_rounded,
    'Olahraga': Icons.fitness_center_rounded,
    'Memasak': Icons.restaurant_rounded,
    'Traveling': Icons.flight_rounded,
    'Musik': Icons.music_note_rounded,
    'Film': Icons.movie_rounded,
    'Fotografi': Icons.camera_alt_rounded,
    'Coding': Icons.code_rounded,
    'Desain': Icons.brush_rounded,
    'Menulis': Icons.edit_rounded,
    'Menggambar': Icons.draw_rounded,
  };

  final Set<String> _selectedHobi = {};

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _simpanProfil() async {
    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio tidak boleh kosong!')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'skill': _selectedSkill,
        'skill2': _selectedSkill2,
        'bio': _bioController.text.trim(),
        'hobi': _selectedHobi.toList(),
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil, coba lagi.')),
      );
    }
    setState(() => _isLoading = false);
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _simpanProfil();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Step indicator
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      gradient: i <= _step ? AppColors.gradientPrimary : null,
                      color: i <= _step ? null : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 8),
              Text(
                'Langkah ${_step + 1} dari 3',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              Expanded(child: _buildStep()),
              const SizedBox(height: 16),

              // Next button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _step == 2 ? 'Mulai SkillMatch!' : 'Lanjut',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
              child: const Text('Skill utama kamu apa?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 6),
            const Text('Ini yang akan ditampilkan di profilmu',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: _skills.map((s) {
                  final selected = _selectedSkill == s;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSkill = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryLight : AppColors.card,
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.border,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _skillIcons[s] ?? Icons.star_rounded,
                              size: 18,
                              color: selected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(s,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                color: selected ? AppColors.primary : AppColors.textPrimary,
                              )),
                          if (selected) ...[
                            const Spacer(),
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
              child: const Text('Hobi & minat kamu?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 6),
            const Text('Pilih beberapa yang sesuai',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _hobi.map((h) {
                final selected = _selectedHobi.contains(h);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) _selectedHobi.remove(h);
                    else _selectedHobi.add(h);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : AppColors.card,
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hobiIcons[h] ?? Icons.star_rounded,
                          size: 14,
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(h,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
              child: const Text('Ceritain dirimu!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 6),
            const Text('Bio singkat yang akan dilihat orang lain',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 5,
                maxLength: 150,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Contoh: UI/UX designer 2 tahun pengalaman, suka bikin tampilan clean...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Skill tambahan (opsional)',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSkill2.isEmpty ? null : _selectedSkill2,
                  hint: const Text('-- Pilih skill tambahan --',
                      style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                  dropdownColor: AppColors.card,
                  isExpanded: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  items: _skills.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedSkill2 = v ?? ''),
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}