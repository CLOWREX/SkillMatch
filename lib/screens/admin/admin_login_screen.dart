import 'package:flutter/material.dart';
import 'admin_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final List<String> _pin = ['', '', '', ''];
  int _currentPos = 0;
  bool _isError = false;

  void _inputPin(String digit) {
    if (_currentPos >= 4) return;
    setState(() {
      _pin[_currentPos] = digit;
      _currentPos++;
      _isError = false;
    });
    if (_currentPos == 4) _checkPin();
  }

  void _deletePin() {
    if (_currentPos <= 0) return;
    setState(() {
      _currentPos--;
      _pin[_currentPos] = '';
      _isError = false;
    });
  }

  void _checkPin() {
    final entered = _pin.join();
    if (entered == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } else {
      setState(() {
        _isError = true;
        for (int i = 0; i < 4; i++) _pin[i] = '';
        _currentPos = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFEEEDFE),
              child: Icon(Icons.admin_panel_settings, color: Color(0xFF7F77DD), size: 32),
            ),
            const SizedBox(height: 20),
            const Text('Masuk sebagai Admin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Masukkan PIN 4 digit',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pin[i].isNotEmpty
                      ? (_isError ? Colors.red : const Color(0xFF7F77DD))
                      : Colors.grey.shade300,
                ),
              )),
            ),
            if (_isError) ...[
              const SizedBox(height: 12),
              const Text('PIN salah, coba lagi',
                  style: TextStyle(fontSize: 13, color: Colors.red)),
            ],
            const SizedBox(height: 40),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 80);
            return GestureDetector(
              onTap: () => k == 'del' ? _deletePin() : _inputPin(k),
              child: Container(
                width: 72, height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: Center(
                  child: k == 'del'
                      ? const Icon(Icons.backspace_outlined, size: 22, color: Colors.black87)
                      : Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w400)),
                ),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }
}