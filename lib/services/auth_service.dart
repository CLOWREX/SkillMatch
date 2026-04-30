import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<String?> cekNamaUnik(String nama) async {
    final q = await _db.collection('users')
        .where('nama', isEqualTo: nama.trim())
        .get();
    if (q.docs.isNotEmpty) return 'Nama sudah dipakai orang lain!';
    return null;
  }

  Future<String?> register(String nama, String email, String password) async {
    try {
      final namaTaken = await cekNamaUnik(nama);
      if (namaTaken != null) return namaTaken;

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final inisial = nama.trim().split(' ')
          .map((w) => w.isNotEmpty ? w[0] : '')
          .join()
          .substring(0, nama.trim().split(' ').length >= 2 ? 2 : 1)
          .toUpperCase();

      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'nama': nama.trim(),
        'email': email.trim(),
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email sudah terdaftar!';
      if (e.code == 'weak-password') return 'Password minimal 6 karakter!';
      return 'Terjadi kesalahan, coba lagi.';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Email tidak terdaftar!';
      if (e.code == 'wrong-password') return 'Password salah!';
      if (e.code == 'invalid-credential') return 'Email atau password salah!';
      return 'Terjadi kesalahan, coba lagi.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}