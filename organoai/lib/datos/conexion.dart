import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConexion {
  // Constructor privado para implementar Singleton
  FirebaseConexion._privateConstructor();

  // Instancia única
  static final FirebaseConexion instance = FirebaseConexion._privateConstructor();

  // Instancia de FirebaseFirestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Escribir datos
  Future<void> addUser(String name, String email) async {
    await _firestore.collection('users').add({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Leer datos
  Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('users').snapshots();
  }
}