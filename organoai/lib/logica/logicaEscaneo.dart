import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:organoai/logica/logicaFoto.dart';

class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ...existing code...
  Future<void> guardarEscaneo({
    required String tipoEnfermedad,
    required String descripcion,
    required String tratamiento,
    required DateTime fechaEscaneo,
    required String urlImagen,
    double? latitud, // <-- Agrega estos parámetros opcionales
    double? longitud,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('escaneos')
          .add({
        'tipoEnfermedad': tipoEnfermedad,
        'descripcion': descripcion,
        'tratamiento': tratamiento,
        'fechaEscaneo': Timestamp.fromDate(fechaEscaneo),
        'urlImagen': urlImagen,
        'latitud': latitud, // <-- Guarda latitud
        'longitud': longitud, // <-- Guarda longitud
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al guardar el escaneo: ${e.toString()}');
    }
  }
// ...existing code...

  Future<List<Map<String, dynamic>>> obtenerEscaneos() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('escaneos')
          .orderBy('fechaEscaneo', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error al obtener los escaneos: ${e.toString()}');
    }
  }
}

class LogicaEscaneo {
  final ScanService _scanService = ScanService();
  static const String _apiKey = "a2cf28f997aaa0388316413335a4a969";
  static const String _uploadUrl =
      "https://api.imgbb.com/1/upload?key=$_apiKey";

  Future<String> _uploadImageToImgbb(Map<String, dynamic> apiResponse) async {
    try {
      final String? imagenBase64 = apiResponse['imagen'];
      if (imagenBase64 == null) {
        throw Exception("No se encontró la imagen en la respuesta de la API.");
      }
      final String base64String = imagenBase64.split(',').last;

      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {'image': base64String},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'];
          return imageUrl;
        } else {
          throw Exception(
              "Error al subir la imagen: ${jsonResponse['error']['message']}");
        }
      } else {
        throw Exception("Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error al subir la imagen a ImgBB: ${e.toString()}");
    }
  }

  Uint8List? obtenerImagenDesdeApi(Map<String, dynamic> apiResponse) {
    final String? imagenBase64 = apiResponse['imagen'];

    if (imagenBase64 == null) return null;
    final String base64String = imagenBase64.split(',').last;
    return base64Decode(base64String);
  }

  String formatearEnfermedades(Map<String, dynamic> apiResponse) {
    final enfermedades = apiResponse['enfermedades'];
    print('API RESPONSE COMPLETO: $apiResponse');
    print('ENFERMEDADES LISTA: $enfermedades');
    if (enfermedades == null || enfermedades.isEmpty) {
      return 'No hay enfermedades detectadas.';
    }
    return 'Enfermedades:\n' +
        enfermedades.map<String>((e) => '  $e').join('\n');
  }

  Future<void> guardarEscaneo(
    BuildContext context,
    List<File> images,
    Map<String, dynamic> apiResponse, {
    double? latitud, // <-- Nuevo parámetro opcional
    double? longitud, // <-- Nuevo parámetro opcional
  }) async {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay imágenes para guardar.")),
      );
      return;
    }

    try {
      final DateTime now = DateTime.now();
      final File image = images.first;

      final String downloadUrl = await _uploadImageToImgbb(apiResponse);

      final List<dynamic> enfermedades = apiResponse['enfermedades'] ?? [];
      print('API RESPONSE COMPLETO: $apiResponse');
      print('ENFERMEDADES LISTA: $enfermedades');
      String tipo = 'desconocida';

      // Extraer el nombre de la enfermedad
      for (final item in enfermedades) {
        print('Procesando item: $item');
        if (item.toString().contains(':')) {
          final partes = item.toString().split(':');
          if (partes.length > 1) {
            final posible = partes[1].trim();
            if (posible.isNotEmpty && posible.toLowerCase() != 'desconocida') {
              tipo = posible;
              break;
            }
          }
        } else {
          // Si no hay ":", puede ser un mensaje como "No se detecta oregano"
          tipo = item.toString().trim();
          break;
        }
      }
      print('TIPO EXTRAÍDO: $tipo');

      String descripcion = "No disponible";
      String tratamiento = "No disponible";

      // Buscar por coincidencia exacta en Firestore solo si no es sano o desconocido
      if (tipo.toLowerCase() != 'no se detecta oregano' &&
          tipo.toLowerCase() != 'desconocida') {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('enfermedad')
            .where('nombre', isEqualTo: tipo)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          descripcion = data['descripcion'] ?? descripcion;
          tratamiento = data['tratamiento'] ?? tratamiento;
        }
      } else if (tipo.toLowerCase() == 'no se detecta oregano') {
        descripcion = "No se detectó orégano en la imagen.";
        tratamiento = "No aplica.";
      }

      // Mostrar en pantalla
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Resultado del escaneo'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enfermedad detectada: $tipo'),
                const SizedBox(height: 8),
                Text('Descripción: $descripcion'),
                const SizedBox(height: 8),
                Text('Tratamiento: $tratamiento'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );

      await _scanService.guardarEscaneo(
        tipoEnfermedad: tipo,
        descripcion: descripcion,
        tratamiento: tratamiento,
        fechaEscaneo: now,
        urlImagen: downloadUrl,
        latitud: latitud, // <-- Pasa la latitud
        longitud: longitud, // <-- Pasa la longitud
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escaneo guardado exitosamente.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar escaneo: ${e.toString()}")),
      );
    }
  }

  Widget buildScanResults(
      List<Map<String, dynamic>> resultados, BuildContext context) {
    if (resultados.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Resultados del Escaneo"),
          backgroundColor: Colors.green[700],
          centerTitle: true,
        ),
        body: const Center(child: Text("No hay resultados disponibles")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultados del Escaneo"),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: resultados.length,
        itemBuilder: (context, index) {
          final item = resultados[index];

          if (!item.containsKey('image') || !item.containsKey('response')) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Datos inválidos en el resultado"),
            );
          }

          final imagenConUbicacion = item['image'] as ImagenConUbicacion?;
          final image = imagenConUbicacion?.imagen;
          final response = item['response'] as Map<String, dynamic>?;

          if (image == null || response == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Error: Imagen o respuesta no válida"),
            );
          }

          // Usa _buildImageWidgets para mostrar la imagen correcta
          final imagenesWidget = _buildImageWidgets([image], response);

          final mensaje = formatearEnfermedades(response);
          final esSinOregano = mensaje
                  .toLowerCase()
                  .contains('no se detecta oregano') ||
              mensaje.toLowerCase().contains('no hay enfermedades detectadas');

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...imagenesWidget,
                  const SizedBox(height: 10),
                  Text(
                    mensaje,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  if (!esSinOregano)
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Guardar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          await guardarEscaneo(
                            context,
                            [image],
                            response,
                            latitud: imagenConUbicacion?.latitud,   // <-- Pasa la latitud aquí
                            longitud: imagenConUbicacion?.longitud, // <-- Pasa la longitud aquí
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildImageWidgets(
      List<File> images, Map<String, dynamic> apiResponse) {
    if (apiResponse['imagen'] != null) {
      final imgBytes = obtenerImagenDesdeApi(apiResponse);
      print('API RESPONSE COMPLETO: $apiResponse');
      print('Bytes de imagen: $imgBytes');

      if (imgBytes != null) {
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Image.memory(
              imgBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('Error al mostrar la imagen'),
            ),
          ),
        ];
      }
    }

    return images
        .where((image) => image.existsSync())
        .map((image) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Image.file(
                image,
                errorBuilder: (context, error, stackTrace) =>
                    const Text('Error al mostrar la imagen'),
              ),
            ))
        .toList();
  }
}
