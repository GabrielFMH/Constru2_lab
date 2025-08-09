import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../vista/login.dart'; // Asegúrate de importar tu LoginPage

class AuthService {
  // Constructor privado para implementar Singleton
  AuthService._privateConstructor();

  // Instancia única de AuthService
  static final AuthService instance = AuthService._privateConstructor();

  // Cerrar sesión
  Future<void> handleLogout(BuildContext context) async {
    try {
      // Cerrar sesión solo en Firebase
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        // Navegar a LoginPage y limpiar el stack de navegación
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Eliminar cuenta
  Future<void> handleDeleteAccount(BuildContext context) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Mostrar diálogo de confirmación
      final bool? confirmDelete = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Eliminar cuenta',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            content: const Text(
              '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          );
        },
      );

      if (confirmDelete != true) return;

      final String userId = currentUser.uid;

      // Eliminar datos del usuario en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Eliminar cuenta de autenticación
      try {
        await currentUser.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Esta operación requiere reautenticación. Por favor, inicia sesión nuevamente.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
          return;
        }
        rethrow;
      }

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la cuenta: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}