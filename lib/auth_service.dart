import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  String? get userEmail => currentUser?.email;
  String? get userName => currentUser?.displayName;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    if (!_googleSignInInitialized) {
      await _googleSignIn.initialize();
      _googleSignInInitialized = true;
    }
  }

  // Connexion avec email et mot de passe
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erreur de connexion: ${e.message}');
      }
      rethrow;
    }
  }

  // Inscription avec email et mot de passe
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erreur d\'inscription: ${e.message}');
      }
      rethrow;
    }
  }

  // Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // S'assurer que Google Sign In est initialisé
      await _initializeGoogleSignIn();

      // Déclencher le flux d'authentification
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Créer un nouveau credential
      // Note: Dans la version 7.x, seul l'idToken est disponible directement
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Une fois connecté, retourner le UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur de connexion Google: $e');
      }
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur de déconnexion: $e');
      }
      rethrow;
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erreur de réinitialisation: ${e.message}');
      }
      rethrow;
    }
  }
}
