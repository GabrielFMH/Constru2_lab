import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../datos/conexionApi.dart';
import '../logica/logicaEscaneo.dart';
import '../logica/logicaNotificaciones.dart';
import '../vista/perfil.dart';
import '../vista/historial.dart';
import '../vista/configuracion.dart';
import 'package:geolocator/geolocator.dart';

// Clase que almacena una imagen junto con su ubicación opcional
class ImagenConUbicacion {
  final File imagen;
  final Position? ubicacion;

  ImagenConUbicacion({required this.imagen, this.ubicacion});

  double? get latitud => ubicacion?.latitude;
  double? get longitud => ubicacion?.longitude;
}

// Lógica principal para manejar imágenes y escaneo
class LogicaFoto with ChangeNotifier {
  final List<ImagenConUbicacion> _imagenesConUbicacion = [];
  List<ImagenConUbicacion> get imagenesConUbicacion => _imagenesConUbicacion;

  bool esInvitado = false; // Estado de usuario invitado o registrado
  final ImagePicker _picker = ImagePicker();

  // Elimina una imagen de la lista y actualiza la UI
  void eliminarImagen(int index) {
    _imagenesConUbicacion.removeAt(index);
    notifyListeners();
  }

  // Toma una foto con la cámara y guarda su ubicación si es posible
  Future<void> takePhoto(BuildContext context) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      Position? posicion;
      try {
        // Solicita permisos de ubicación
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          posicion = await Geolocator.getCurrentPosition();
        }
      } catch (e) {
        posicion = null; // Si falla la ubicación, se guarda sin ella
      }

      _imagenesConUbicacion.add(
        ImagenConUbicacion(imagen: File(pickedFile.path), ubicacion: posicion),
      );
      notifyListeners();
    }
  }

  // Selecciona varias imágenes de la galería (sin ubicación)
  Future<void> pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      _imagenesConUbicacion.addAll(
        pickedFiles.map(
          (file) =>
              ImagenConUbicacion(imagen: File(file.path), ubicacion: null),
        ),
      );
      notifyListeners();
    }
  }

  // Escanea todas las imágenes guardadas en memoria
  Future<void> scanImages(BuildContext context) async {
    if (_imagenesConUbicacion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay imágenes para escanear")),
      );
      return;
    }

    // Notifica al usuario que comenzó el escaneo
    final notiService = NotificacionesService.instance;
    await notiService.showNotification(
      title: 'Escaneo iniciado',
      body: 'Procesando imágenes...',
    );

    final logicaEscaneo = LogicaEscaneo();
    final List<Map<String, dynamic>> resultados = [];

    // Procesa cada imagen enviándola al API
    for (final image in _imagenesConUbicacion) {
      try {
        final response = await ConexionApi().predictImage(image.imagen.path);

        resultados.add({
          'image': image,
          'response': response,
          'latitud': image.ubicacion?.latitude,
          'longitud': image.ubicacion?.longitude,
        });
      } catch (e) {
        resultados.add({
          'image': image,
          'response': {'error': e.toString()},
          'latitud': image.ubicacion?.latitude,
          'longitud': image.ubicacion?.longitude,
        });
      }
    }

    // Notifica que el escaneo terminó
    await notiService.showNotification(
      title: 'Escaneo completo',
      body: 'Se analizaron todas las imágenes.',
    );

    // Muestra los resultados en la siguiente pantalla
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => logicaEscaneo.buildScanResults(resultados, context),
      ),
    );
  }

  // Controla la navegación entre las pestañas del menú inferior
  Future<void> onItemTapped(BuildContext context, int index) async {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistorialPage()),
        );
        break;
      case 1:
        await takePhoto(context); // Tomar foto directamente
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PerfilPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }
}
