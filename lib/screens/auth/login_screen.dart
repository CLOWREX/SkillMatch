import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../admin/admin_login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../setup/setup_profil_screen.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi!')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final error = await _authService.login(_emailController.text, _passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 🔥 CEK BAN dari collection punishments
    final punishDoc = await FirebaseFirestore.instance
        .collection('punishments')
        .doc(uid)
        .get();

    if (punishDoc.exists && punishDoc.data()?['type'] == 'ban_permanent') {
      await _authService.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun kamu telah di-ban permanen oleh admin.'),
          backgroundColor: Color(0xFFF87171),
        ),
      );
      return;
    }

    // 🔥 CEK field banned di users
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.data()?['banned'] == true) {
      await _authService.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun kamu telah di-ban permanen oleh admin.'),
          backgroundColor: Color(0xFFF87171),
        ),
      );
      return;
    }

    final isComplete = userDoc.data()?['isProfileComplete'] ?? false;
    if (!mounted) return;

    if (isComplete) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const SetupProfilScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),

              // Title
              ShaderMask(
                shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
                child: const Text(
                  'SkillMatch',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masuk ke akunmu',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),

              // Email field
              const Text('Email',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'email@gmail.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textHint, size: 20),
                  filled: true,
                  fillColor: AppColors.card,
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              const Text('Password',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textHint, size: 20),
                  filled: true,
                  fillColor: AppColors.card,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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
                        : const Text(
                            'Masuk',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Register link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Belum punya akun? ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Daftar',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Admin login
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
                  child: const Text(
                    'Masuk sebagai Admin',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}