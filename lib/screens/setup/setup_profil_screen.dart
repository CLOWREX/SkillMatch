import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_screen.dart';

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

  final Set<String> _selectedHobi = {};

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
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'skill': _selectedSkill,
        'skill2': _selectedSkill2,
        'bio': _bioController.text.trim(),
        'hobi': _selectedHobi.toList(),
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil, coba lagi.')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: i <= _step ? const Color(0xFF7F77DD) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 32),
              Expanded(child: _buildStep()),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F77DD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_step == 2 ? 'Mulai SkillMatch!' : 'Lanjut',
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
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
            const Text('Skill utama kamu apa?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Ini yang akan ditampilkan di profilmu',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            ...['Desain UI/UX', 'Ngoding (Web/App)', 'Editing Video', 'Nulis Konten',
                'Public Speaking', 'Fotografi', 'Data Analisis', 'Multitasking & Manajemen',
                'Social Media', 'Ilustrasi/Gambar'].map((s) => GestureDetector(
              onTap: () => setState(() => _selectedSkill = s),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedSkill == s ? const Color(0xFFEEEDFE) : Colors.white,
                  border: Border.all(
                    color: _selectedSkill == s ? const Color(0xFF7F77DD) : Colors.grey.shade200,
                    width: _selectedSkill == s ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(s,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedSkill == s ? FontWeight.w500 : FontWeight.normal,
                        color: _selectedSkill == s ? const Color(0xFF3C3489) : Colors.black87)),
              ),
            )),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hobi & minat kamu?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Pilih beberapa yang sesuai',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hobi.map((h) {
                final selected = _selectedHobi.contains(h);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) _selectedHobi.remove(h);
                    else _selectedHobi.add(h);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEEEDFE) : Colors.white,
                      border: Border.all(
                        color: selected ? const Color(0xFF7F77DD) : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(h,
                        style: TextStyle(
                            fontSize: 13,
                            color: selected ? const Color(0xFF3C3489) : Colors.black87,
                            fontWeight: selected ? FontWeight.w500 : FontWeight.normal)),
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
            const Text('Ceritain dirimu!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Bio singkat yang akan dilihat orang lain',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: _bioController,
              maxLines: 5,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Contoh: Desainer UI/UX 2 tahun pengalaman, suka bikin tampilan yang clean...',
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Skill tambahan (opsional)',
                style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSkill2.isEmpty ? null : _selectedSkill2,
              hint: const Text('-- Pilih skill tambahan --'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _skills.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _selectedSkill2 = v ?? ''),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _simpanProfil();
    }
  }
}