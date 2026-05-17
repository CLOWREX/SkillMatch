import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../setup/setup_profil_screen.dart';
import '../../core/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Step: 0 = form isi data, 1 = OTP
  int _step = 0;

  final _namaController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController    = TextEditingController();
  final _otpController      = TextEditingController();

  bool   _isLoading       = false;
  bool   _obscurePassword = true;
  String _formattedPhone  = '';

  final _authService = AuthService();

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── STEP 1: Validasi & kirim OTP via WA ──────────────
  Future<void> _kirimOtp() async {
    final nama     = _namaController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone    = _phoneController.text.trim();

    if (nama.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      _snack('Semua field harus diisi!');
      return;
    }
    if (password.length < 6) {
      _snack('Password minimal 6 karakter!');
      return;
    }
    if (phone.length < 9) {
      _snack('Nomor HP tidak valid!');
      return;
    }

    _formattedPhone = _authService.formatPhone(phone);

    setState(() => _isLoading = true);

    // Cek banned phone
    final banned = await _authService.isPhoneBanned(_formattedPhone);
    if (!mounted) return;
    if (banned) {
      setState(() => _isLoading = false);
      _snack('Nomor HP ini telah di-ban oleh admin.', isError: true);
      return;
    }

    // Kirim OTP via WhatsApp
    final error = await _authService.sendOtpWhatsapp(phone);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      _snack(error, isError: true);
    } else {
      setState(() => _step = 1);
      _snack('Kode OTP dikirim ke WhatsApp kamu!');
    }
  }

  // ── STEP 2: Verifikasi OTP lalu register ─────────────
  Future<void> _verifyAndRegister() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _snack('Masukkan 6 digit kode OTP!');
      return;
    }

    setState(() => _isLoading = true);

    // Verifikasi OTP
    final otpError = await _authService.verifyOtp(
      _phoneController.text.trim(),
      otp,
    );
    if (!mounted) return;

    if (otpError != null) {
      setState(() => _isLoading = false);
      _snack(otpError, isError: true);
      return;
    }

    // Register akun
    final error = await _authService.register(
      _namaController.text,
      _emailController.text,
      _passwordController.text,
      _phoneController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _snack(error, isError: true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupProfilScreen()),
      );
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
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

              ShaderMask(
                shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                child: const Text('SkillMatch',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text(
                _step == 0 ? 'Buat akun baru' : 'Verifikasi WhatsApp',
                style: TextStyle(fontSize: 15, color: context.textSecondary),
              ),
              const SizedBox(height: 32),

              // Step indicator
              Row(
                children: [
                  _stepDot(0),
                  Expanded(child: Container(height: 2,
                      color: _step >= 1 ? AppColors.primary : context.borderColor)),
                  _stepDot(1),
                ],
              ),
              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0 ? _buildFormStep() : _buildOtpStep(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int idx) {
    final isActive = _step >= idx;
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : context.cardColor,
        border: Border.all(color: isActive ? AppColors.primary : context.borderColor),
      ),
      child: Center(
        child: Text('${idx + 1}',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : context.textSecondary,
            )),
      ),
    );
  }

  // ── FORM STEP ────────────────────────────────────────
  Widget _buildFormStep() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Nama lengkap'),
        const SizedBox(height: 8),
        TextField(
          controller: _namaController,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nama unik kamu',
            hintStyle: TextStyle(color: context.textHint),
            prefixIcon: Icon(Icons.person_outline_rounded, color: context.textHint, size: 20),
            filled: true, fillColor: context.cardColor,
          ),
        ),
        const SizedBox(height: 16),

        _label('Email'),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'email@gmail.com',
            hintStyle: TextStyle(color: context.textHint),
            prefixIcon: Icon(Icons.mail_outline_rounded, color: context.textHint, size: 20),
            filled: true, fillColor: context.cardColor,
          ),
        ),
        const SizedBox(height: 16),

        _label('Nomor WhatsApp'),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: '08xxxxxxxxxx',
            hintStyle: TextStyle(color: context.textHint),
            prefixIcon: Icon(Icons.phone_android_rounded, color: Colors.green, size: 20),
            filled: true, fillColor: context.cardColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kode OTP akan dikirim ke WhatsApp nomor ini.',
          style: TextStyle(fontSize: 11, color: context.textHint),
        ),
        const SizedBox(height: 16),

        _label('Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Min. 6 karakter',
            hintStyle: TextStyle(color: context.textHint),
            prefixIcon: Icon(Icons.lock_outline_rounded, color: context.textHint, size: 20),
            filled: true, fillColor: context.cardColor,
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

        _gradientButton(
          label: 'Kirim OTP via WhatsApp',
          icon: Icons.send_rounded,
          onTap: _isLoading ? null : _kirimOtp,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 20),

        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: RichText(
              text: TextSpan(
                text: 'Sudah punya akun? ',
                style: TextStyle(color: context.textSecondary, fontSize: 14),
                children: const [
                  TextSpan(text: 'Masuk',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── OTP STEP ─────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info WA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1525D366),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x4025D366)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kode OTP dikirim ke WhatsApp\n+${_authService.formatPhone(_phoneController.text)}',
                  style: const TextStyle(
                    fontSize: 13, color: Color(0xFF25D366), height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _label('Masukkan kode OTP (6 digit)'),
        const SizedBox(height: 8),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 16,
          ),
          decoration: InputDecoration(
            hintText: '------',
            hintStyle: TextStyle(
              color: context.textHint, fontSize: 32, letterSpacing: 16,
            ),
            filled: true, fillColor: context.cardColor,
            counterText: '',
          ),
        ),
        const SizedBox(height: 32),

        _gradientButton(
          label: 'Verifikasi & Daftar',
          icon: Icons.verified_rounded,
          onTap: _isLoading ? null : _verifyAndRegister,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _isLoading ? null : () => setState(() {
                _step = 0;
                _otpController.clear();
              }),
              icon: Icon(Icons.arrow_back_rounded, size: 16, color: context.textSecondary),
              label: Text('Ganti nomor', style: TextStyle(color: context.textSecondary)),
            ),
            Text('·', style: TextStyle(color: context.textHint)),
            TextButton(
              onPressed: _isLoading ? null : _kirimOtp,
              child: const Text('Kirim ulang OTP',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
        fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500,
      ));

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: 20),
          label: Text(label,
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
              )),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}