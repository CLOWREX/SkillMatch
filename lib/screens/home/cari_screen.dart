import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';

class CariScreen extends StatefulWidget {
  const CariScreen({super.key});
  @override
  State<CariScreen> createState() => _CariScreenState();
}

class _CariScreenState extends State<CariScreen> with SingleTickerProviderStateMixin {
  String? _selectedSkill;
  final _descController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _candidates = [];
  int _currentIdx = 0;
  bool _showResult = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _skills = [
    'Ngoding (Web/App)', 'Desain UI/UX', 'Editing Video',
    'Nulis Konten', 'Public Speaking', 'Fotografi',
    'Data Analisis', 'Multitasking & Manajemen',
    'Social Media', 'Ilustrasi/Gambar',
  ];

  final Map<String, IconData> _skillIcons = {
    'Ngoding (Web/App)': Icons.code_rounded,
    'Desain UI/UX': Icons.palette_rounded,
    'Editing Video': Icons.video_camera_back_rounded,
    'Nulis Konten': Icons.edit_rounded,
    'Public Speaking': Icons.mic_rounded,
    'Fotografi': Icons.camera_alt_rounded,
    'Data Analisis': Icons.bar_chart_rounded,
    'Multitasking & Manajemen': Icons.task_alt_rounded,
    'Social Media': Icons.share_rounded,
    'Ilustrasi/Gambar': Icons.brush_rounded,
  };

  final Map<String, List<String>> _related = {
    'Ngoding (Web/App)': ['Data Analisis', 'Multitasking & Manajemen'],
    'Desain UI/UX': ['Ilustrasi/Gambar', 'Social Media'],
    'Editing Video': ['Fotografi', 'Ilustrasi/Gambar'],
    'Nulis Konten': ['Social Media', 'Public Speaking'],
    'Public Speaking': ['Nulis Konten', 'Multitasking & Manajemen'],
    'Fotografi': ['Editing Video', 'Ilustrasi/Gambar'],
    'Data Analisis': ['Ngoding (Web/App)', 'Multitasking & Manajemen'],
    'Multitasking & Manajemen': ['Public Speaking', 'Nulis Konten'],
    'Social Media': ['Nulis Konten', 'Desain UI/UX'],
    'Ilustrasi/Gambar': ['Desain UI/UX', 'Fotografi'],
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    _descController.dispose();
    super.dispose();
  }

  int _scoreMatch(Map<String, dynamic> u, String req) {
    if (u['skill'] == req) return 100;
    if (u['skill2'] == req) return 80;
    final r = _related[req] ?? [];
    if (r.contains(u['skill'])) return 60;
    if (r.contains(u['skill2'])) return 45;
    return 20;
  }

  Future<void> _cariPartner() async {
    if (_selectedSkill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih skill yang dibutuhkan dulu!')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('isProfileComplete', isEqualTo: true)
        .get();

    final users = snap.docs
        .where((d) => d.id != myUid)
        .map((d) => {'id': d.id, ...d.data()})
        .toList();

    final scored = users.map((u) => {...u, 'score': _scoreMatch(u, _selectedSkill!)}).toList();
    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    setState(() {
      _candidates = scored;
      _currentIdx = 0;
      _isLoading = false;
      _showResult = true;
    });
    _animController.forward(from: 0);
  }

  Color _avatarColor(String av) {
    const colors = [AppColors.primary, Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFEC4899)];
    return colors[av.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('SkillMatch', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('Temukan partner skill terbaik', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _showResult ? _buildHasilPencarian() : _buildFormCari(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCari() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Butuh skill apa hari ini?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('AI akan mencarikan partner terbaik untukmu',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _skills.map((s) {
              final selected = _selectedSkill == s;
              return GestureDetector(
                onTap: () => setState(() => _selectedSkill = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade200, width: selected ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_skillIcons[s] ?? Icons.star, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textPrimary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ceritain projekmu... (opsional)',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _cariPartner,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('AI sedang mencarikan...', style: TextStyle(fontSize: 15)),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 18),
                        SizedBox(width: 8),
                        Text('Carikan partner terbaik', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHasilPencarian() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() { _showResult = false; _animController.reset(); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text('Ubah pencarian', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    _candidates.isEmpty ? '0 / 0' : '${_currentIdx + 1} / ${_candidates.length}',
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_candidates.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('Belum ada user dengan skill ini', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Coba skill lain', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() { _showResult = false; _animController.reset(); }),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Cari lagi'),
                    ),
                  ],
                ),
              )
            else if (_currentIdx < _candidates.length)
              _buildKartu(_candidates[_currentIdx])
            else
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
                    const SizedBox(height: 12),
                    const Text('Semua kandidat sudah ditampilkan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Coba cari dengan skill berbeda', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() { _showResult = false; _animController.reset(); }),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Cari lagi'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKartu(Map<String, dynamic> u) {
    final score = u['score'] as int;
    final scoreLabel = score >= 80 ? 'Sangat cocok' : score >= 60 ? 'Mendekati' : 'Terkait';
    final scoreColor = score >= 80 ? AppColors.success : score >= 60 ? const Color(0xFFF59E0B) : AppColors.error;
    final scoreBg = score >= 80 ? AppColors.successLight : score >= 60 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2);
    final av = u['avatar'] ?? 'X';
    final avColor = _avatarColor(av);
    final followers = (u['followers'] as List?)?.length ?? 0;
    final likes = (u['likes'] as List?)?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [avColor.withOpacity(0.15), avColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: avColor.withOpacity(0.2),
                      child: Text(av, style: TextStyle(color: avColor, fontWeight: FontWeight.w700, fontSize: 22)),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: u['status'] == 'online' ? AppColors.success : u['status'] == 'sibuk' ? const Color(0xFFF59E0B) : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(u['nama'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: scoreBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: scoreColor),
                      const SizedBox(width: 4),
                      Text('$scoreLabel · $score% match', style: TextStyle(fontSize: 12, color: scoreColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u['bio'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    if ((u['skill'] ?? '').isNotEmpty) _chip(u['skill'], AppColors.primaryLight, AppColors.primary),
                    if ((u['skill2'] ?? '').isNotEmpty) _chip(u['skill2'], AppColors.secondaryLight, AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 14, color: Colors.pink.shade300),
                    const SizedBox(width: 4),
                    Text('$likes', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 16),
                    Icon(Icons.people_rounded, size: 14, color: AppColors.primary.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text('$followers followers', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _currentIdx++);
                          _animController.forward(from: 0);
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Lewati'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final myUid = FirebaseAuth.instance.currentUser?.uid;
                          if (myUid == null) return;
                          final partnerId = u['id'].toString();
                          await FirebaseFirestore.instance.collection('users').doc(myUid).update({
                            'matches': FieldValue.arrayUnion([partnerId]),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Terhubung dengan ${u['nama']}!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.handshake_rounded, size: 18),
                        label: const Text('Pilih partner ini'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: AppColors.success.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}