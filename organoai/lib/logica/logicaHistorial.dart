import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistorialViewModel extends ChangeNotifier {
  String _filtroFecha = '';
  String _filtroEnfermedad = 'Todas';

  final List<String> enfermedades = [
    'Todas',
    'Alternaria',
    'Mosaico',
    'Oidio',
    'Roya',
    'Desconocido'
  ];

  String get filtroFecha => _filtroFecha;
  String get filtroEnfermedad => _filtroEnfermedad;

  set filtroFecha(String value) {
    _filtroFecha = value;
    notifyListeners();
  }

  set filtroEnfermedad(String value) {
    _filtroEnfermedad = value;
    notifyListeners();
  }

  // Devuelve un stream agrupado y filtrado listo para la vista
  Stream<Map<String, List<Map<String, dynamic>>>> escaneosAgrupadosStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('escaneos')
        .orderBy('fechaEscaneo', descending: true)
        .snapshots()
        .map((snapshot) {
      final docsFiltrados = snapshot.docs.where((doc) {
        final data = doc.data();
        final fecha = (data['fechaEscaneo'] as Timestamp).toDate();
        final fechaStr =
            "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
        final tipoEnfermedad = data['tipoEnfermedad'] ?? '';

        final cumpleFecha =
            _filtroFecha.isEmpty || fechaStr.contains(_filtroFecha);
        final cumpleEnfermedad =
            _filtroEnfermedad == 'Todas' || tipoEnfermedad == _filtroEnfermedad;

        return cumpleFecha && cumpleEnfermedad;
      }).toList();

      final Map<String, List<Map<String, dynamic>>> agrupado = {};
      for (var doc in docsFiltrados) {
        final data = doc.data();
        final fecha = (data['fechaEscaneo'] as Timestamp).toDate();
        final fechaStr =
            "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";

        // Asegura que todos los campos existen en el mapa
        final dataConCampos = {
          'fecha': fechaStr,
          'descripcion': data['descripcion'] ?? '',
          'tratamiento': data['tratamiento'] ?? '',
          'urlImagen': data['urlImagen'] ?? '',
          'tipoEnfermedad': data['tipoEnfermedad'] ?? '',
          'latitud': data['latitud'],      // <-- asegúrate de incluir esto
  'longitud': data['longitud'],
        };

        agrupado.putIfAbsent(fechaStr, () => []).add(dataConCampos);
      }

      return agrupado;
    });
  }

  // Métodos para actualizar desde la vista
  void actualizarFiltroFecha(String value) {
    filtroFecha = value.trim();
  }

  void actualizarFiltroEnfermedad(String? value) {
    filtroEnfermedad = value ?? 'Todas';
  }
}
