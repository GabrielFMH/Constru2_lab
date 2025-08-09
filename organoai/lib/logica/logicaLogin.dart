import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inicio de sesión con email y contraseña
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(
          e.code, e.message)); // Manejo específico de errores de Firebase Auth
    } catch (e) {
      throw Exception(
          'Error inesperado: ${e.toString()}'); // Manejo de otros errores inesperados
    }
  }

  // Manejo de errores de Firebase Auth (actualizado para login)
  String _handleAuthError(String code, String? message) {
    switch (code) {
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'user-disabled':
        return 'Cuenta deshabilitada';
      case 'user-not-found':
        return 'Usuario no registrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'network-request-failed':
        return 'Error de red. Verifique su conexión';
      case 'too-many-requests':
        return 'Demasiados intentos. Intente más tarde';
      case 'operation-not-allowed':
        return 'Método de autenticación no permitido';
      default:
        return 'Error desconocido: $message';
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
