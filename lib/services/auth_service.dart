import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  // ── Token Fonnte (jangan di-share ke publik/GitHub) ───
  static const _fonnteToken = '7eKZchZfG5FHS6acRQus';

  // ── Generate OTP 6 digit ──────────────────────────────
  String _generateOtp() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  // ── Format nomor HP ke 628xxx ─────────────────────────
  String formatPhone(String raw) {
    String c = raw.replaceAll(RegExp(r'\D'), '');
    if (c.startsWith('0')) c = '62${c.substring(1)}';
    if (!c.startsWith('62')) c = '62$c';
    return c; // Fonnte tidak pakai +, cukup 628xxx
  }

  // ── CEK NOMOR HP DI-BAN ───────────────────────────────
  Future<bool> isPhoneBanned(String phone) async {
    if (phone.isEmpty) return false;
    final doc = await _db.collection('banned_phones').doc(phone).get();
    return doc.exists;
  }

  // ── CEK NAMA UNIK ─────────────────────────────────────
  Future<String?> cekNamaUnik(String nama) async {
    final q = await _db.collection('users')
        .where('nama', isEqualTo: nama.trim())
        .get();
    if (q.docs.isNotEmpty) return 'Nama sudah dipakai orang lain!';
    return null;
  }

  // ── KIRIM OTP via Fonnte WhatsApp ─────────────────────
  Future<String?> sendOtpWhatsapp(String phone) async {
    try {
      final otp      = _generateOtp();
      final formatted = formatPhone(phone);

      // Simpan OTP ke Firestore sementara (expired 5 menit)
      await _db.collection('otp_temp').doc(formatted).set({
        'otp': otp,
        'phone': formatted,
        'createdAt': FieldValue.serverTimestamp(),
        'expiredAt': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
      });

      // Kirim WA via Fonnte
      final response = await http.post(
        Uri.parse('https://api.fonnte.com/send'),
        headers: {'Authorization': _fonnteToken},
        body: {
          'target': formatted,
          'message': 'Halo! Kode OTP SkillMatch kamu: *$otp*\n\nJangan berikan ke siapapun ya!\nBerlaku 5 menit.',
          'countryCode': '62',
        },
      );

      if (response.statusCode == 200) {
        return null; // sukses
      } else {
        return 'Gagal kirim OTP, coba lagi.';
      }
    } catch (e) {
      return 'Gagal kirim OTP: $e';
    }
  }

  // ── VERIFIKASI OTP ────────────────────────────────────
  Future<String?> verifyOtp(String phone, String inputOtp) async {
    try {
      final formatted = formatPhone(phone);
      final doc = await _db.collection('otp_temp').doc(formatted).get();

      if (!doc.exists) return 'Kode OTP tidak ditemukan, kirim ulang.';

      final data      = doc.data()!;
      final savedOtp  = data['otp'] as String;
      final expiredAt = data['expiredAt'] as int;

      // Cek expired
      if (DateTime.now().millisecondsSinceEpoch > expiredAt) {
        await _db.collection('otp_temp').doc(formatted).delete();
        return 'Kode OTP sudah expired, kirim ulang.';
      }

      // Cek kode
      if (inputOtp.trim() != savedOtp) {
        return 'Kode OTP salah!';
      }

      // Hapus OTP setelah berhasil
      await _db.collection('otp_temp').doc(formatted).delete();
      return null; // sukses
    } catch (e) {
      return 'Gagal verifikasi: $e';
    }
  }

  // ── REGISTER ──────────────────────────────────────────
  Future<String?> register(
    String nama,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final namaTaken = await cekNamaUnik(nama);
      if (namaTaken != null) return namaTaken;

      final formatted = formatPhone(phone);

      // Cek banned phone
      final phoneBanned = await isPhoneBanned(formatted);
      if (phoneBanned) return 'Nomor HP ini telah di-ban oleh admin.';

      // Cek nomor sudah terdaftar
      final phoneExists = await _db.collection('users')
          .where('phone', isEqualTo: formatted)
          .get();
      if (phoneExists.docs.isNotEmpty) return 'Nomor HP sudah terdaftar!';

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final parts   = nama.trim().split(' ');
      final inisial = parts
          .map((w) => w.isNotEmpty ? w[0] : '')
          .join()
          .substring(0, parts.length >= 2 ? 2 : 1)
          .toUpperCase();

      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'nama': nama.trim(),
        'email': email.trim(),
        'phone': formatted,
        'skill': '',
        'skill2': '',
        'bio': '',
        'avatar': inisial,
        'status': 'online',
        'followers': [],
        'following': [],
        'likes': [],
        'likedUsers': [],
        'matches': [],
        'isProfileComplete': false,
        'banned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email sudah terdaftar!';
      if (e.code == 'weak-password')        return 'Password minimal 6 karakter!';
      return 'Terjadi kesalahan, coba lagi.';
    }
  }

  // ── LOGIN ─────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userDoc  = await _db.collection('users').doc(cred.user!.uid).get();
      final userData = userDoc.data();

      if (userData?['banned'] == true) {
        await _auth.signOut();
        return 'Akun kamu telah di-ban permanen oleh admin.';
      }

      final phone = userData?['phone'] as String? ?? '';
      if (phone.isNotEmpty) {
        final phoneBanned = await isPhoneBanned(phone);
        if (phoneBanned) {
          await _auth.signOut();
          return 'Nomor HP kamu telah di-ban oleh admin.';
        }
      }

      final punishDoc = await _db
          .collection('punishments')
          .doc(cred.user!.uid)
          .get();
      if (punishDoc.exists && punishDoc.data()?['type'] == 'ban_permanent') {
        await _auth.signOut();
        return 'Akun kamu telah di-ban permanen oleh admin.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')     return 'Email tidak terdaftar!';
      if (e.code == 'wrong-password')     return 'Password salah!';
      if (e.code == 'invalid-credential') return 'Email atau password salah!';
      return 'Terjadi kesalahan, coba lagi.';
    }
  }

  Future<void> logout() async => await _auth.signOut();

  User? get currentUser           => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}