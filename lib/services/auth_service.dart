import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirestoreService _firestoreService = FirestoreService();

  /// Hozirgi foydalanuvchi
  static User? get currentUser => _auth.currentUser;

  /// Auth holati o'zgarishlarini kuzatish
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Email va parol bilan ro'yxatdan o'tish
  static Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Foydalanuvchi nomini yangilash
    await result.user?.updateDisplayName(name);

    // Firestore da user doc yaratish
    if (result.user != null) {
      await _firestoreService.createOrUpdateUser(result.user!);
    }

    return result;
  }

  /// Email va parol bilan kirish
  static Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Firestore da user doc yangilash
    if (result.user != null) {
      await _firestoreService.createOrUpdateUser(result.user!);
    }

    return result;
  }

  /// Google orqali kirish
  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      // Foydalanuvchi bekor qildi
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);

    // Firestore da user doc yaratish/yangilash
    if (result.user != null) {
      await _firestoreService.createOrUpdateUser(result.user!);
    }

    return result;
  }

  /// Parolni tiklash emaili yuborish
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Chiqish
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
