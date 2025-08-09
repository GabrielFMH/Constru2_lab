import 'package:firebase_auth/firebase_auth.dart';
import '../datos/conexion.dart';

class FirebaseAuthService {
  // Constructor privado para implementar Singleton
  FirebaseAuthService._privateConstructor();

  // Instancia única
  static final FirebaseAuthService instance =
      FirebaseAuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registro con email y contraseña
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Se usa el correo para generar un nombre provisional
        String name = email.split('@')[0];
        await FirebaseConexion.instance.addUser(name, email);
      }

      return userCredential.user;
    } on FirebaseAuthException {
      //print('Error de registro: ${e.message}');
      return null;
    }
  }

  // Inicio de sesión
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      //print('Error de inicio de sesión: ${e.message}');
      return null;
    }
  }
}
