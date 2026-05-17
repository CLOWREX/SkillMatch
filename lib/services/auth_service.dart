import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ── CEK NAMA UNIK ─────────────────────────────────────
  Future<String?> cekNamaUnik(String nama) async {
    final q = await _db.collection('users')
        .where('nama', isEqualTo: nama.trim())
        .get();
    if (q.docs.isNotEmpty) return 'Nama sudah dipakai orang lain!';
    return null;
  }

  // ── CEK NOMOR HP DI-BAN ───────────────────────────────
  Future<bool> isPhoneBanned(String phone) async {
    final doc = await _db.collection('banned_phones').doc(phone).get();
    return doc.exists;
  }

  // ── REGISTER (email+password, simpan noHP) ────────────
  Future<String?> register(String nama, String email, String password, String phone) async {
    try {
      final namaTaken = await cekNamaUnik(nama);
      if (namaTaken != null) return namaTaken;

      // Cek apakah nomor HP di-ban
      final phoneBanned = await isPhoneBanned(phone.trim());
      if (phoneBanned) return 'Nomor HP ini telah di-ban oleh admin.';

      // Cek apakah nomor HP sudah terdaftar
      final phoneExists = await _db.collection('users')
          .where('phone', isEqualTo: phone.trim())
          .get();
      if (phoneExists.docs.isNotEmpty) return 'Nomor HP sudah terdaftar!';

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final parts = nama.trim().split(' ');
      final inisial = parts
          .map((w) => w.isNotEmpty ? w[0] : '')
          .join()
          .substring(0, parts.length >= 2 ? 2 : 1)
          .toUpperCase();

      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'nama': nama.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
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
      if (e.code == 'weak-password') return 'Password minimal 6 karakter!';
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

      // Cek banned di koleksi users
      final userDoc = await _db.collection('users').doc(cred.user!.uid).get();
      final userData = userDoc.data();

      if (userData?['banned'] == true) {
        await _auth.signOut();
        return 'Akun kamu telah di-ban permanen oleh admin.';
      }

      // Cek banned nomor HP
      final phone = userData?['phone'] as String? ?? '';
      if (phone.isNotEmpty) {
        final phoneBanned = await isPhoneBanned(phone);
        if (phoneBanned) {
          await _auth.signOut();
          return 'Nomor HP kamu telah di-ban oleh admin.';
        }
      }

      // Cek punishment permanen
      final punishDoc = await _db.collection('punishments').doc(cred.user!.uid).get();
      if (punishDoc.exists && punishDoc.data()?['type'] == 'ban_permanent') {
        await _auth.signOut();
        return 'Akun kamu telah di-ban permanen oleh admin.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Email tidak terdaftar!';
      if (e.code == 'wrong-password') return 'Password salah!';
      if (e.code == 'invalid-credential') return 'Email atau password salah!';
      return 'Terjadi kesalahan, coba lagi.';
    }
  }

  // ── VERIFIKASI OTP (Firebase Phone Auth) ──────────────
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        // Android auto-verify
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verifikasi gagal, coba lagi.');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<String?> verifyOtp(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      // Hanya verify, tidak sign in — karena login utama pakai email
      await _auth.currentUser?.linkWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Kode OTP salah atau expired.';
    } catch (_) {
      return null; // Kalau sudah ter-link sebelumnya, lanjut saja
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}