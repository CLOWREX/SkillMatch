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
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading           = false;
  bool _obscurePassword     = true;
  final _authService        = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Login + cek ban di AuthService (termasuk cek ban nomor HP)
    final error = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final isComplete = userDoc.data()?['isProfileComplete'] ?? false;

    if (!mounted) return;
    if (isComplete) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SetupProfilScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),

              // Title
              ShaderMask(
                shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                child: const Text('SkillMatch',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text('Masuk ke akunmu',
                  style: TextStyle(fontSize: 15, color: context.textSecondary)),
              const SizedBox(height: 48),

              // Email
              Text('Email',
                  style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'email@gmail.com',
                  hintStyle: TextStyle(color: context.textHint),
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: context.textHint, size: 20),
                  filled: true,
                  fillColor: context.cardColor,
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Text('Password',
                  style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: context.textHint),
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: context.textHint, size: 20),
                  filled: true,
                  fillColor: context.cardColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.textHint, size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login button
              SizedBox(
                width: double.infinity, height: 52,
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
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Masuk',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Register link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Belum punya akun? ',
                      style: TextStyle(color: context.textSecondary, fontSize: 14),
                      children: const [
                        TextSpan(text: 'Daftar',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
                  child: Text('Masuk sebagai Admin',
                      style: TextStyle(color: context.textHint, fontSize: 12)),
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