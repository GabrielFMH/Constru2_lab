import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilViewModel extends ChangeNotifier {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  bool isLoading = true;

  Future<void> cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        nombreController.text = doc['nombre'] ?? '';
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> guardarCambios(BuildContext context) async {
    final nuevoNombre = nombreController.text.trim();
    final nuevaContrasena = contrasenaController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (nuevoNombre.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user!.uid)
            .update({
          'nombre': nuevoNombre,
        });
      }

      if (nuevaContrasena.isNotEmpty) {
        await user!.updatePassword(nuevaContrasena);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados exitosamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }
}
