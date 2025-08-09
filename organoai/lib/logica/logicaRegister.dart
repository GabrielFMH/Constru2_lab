import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro con email y contraseña
  Future<User?> registerWithEmail(String email, String password, String nombre) async {
    try {
      // 1. Crear usuario en Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Enviar correo de verificación
      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      // 3. Guardar datos adicionales en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nombre': nombre,
        'email': email,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code, e.message));
    } catch (e) {
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  // Reenviar correo de verificación
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw Exception('Usuario no autenticado o correo ya verificado');
    }
  }

  // Manejo de errores de Firebase Auth
  String _handleAuthError(String code, String? message) {
    switch (code) {
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'email-already-in-use':
        return 'El correo ya está registrado.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacte con soporte.';
      case 'network-request-failed':
        return 'Error de red. Verifique su conexión a internet.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intente más tarde.';
      default:
        return 'Error desconocido: $message';
    }
  }
}