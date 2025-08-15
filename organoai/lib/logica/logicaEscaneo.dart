import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:organoai/logica/logicaFoto.dart';

/// Servicio encargado de gestionar el almacenamiento y recuperación de escaneos realizados por el usuario.
/// Se comunica con Firebase Firestore para guardar los resultados del análisis y obtenerlos posteriormente.
class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Guarda un nuevo escaneo en la base de datos de Firestore.
  /// 
  /// [tipoEnfermedad]: Nombre de la enfermedad detectada (por ejemplo, "Mildiú").
  /// [descripcion]: Descripción de la enfermedad obtenida desde la base de datos.
  /// [tratamiento]: Recomendaciones de tratamiento para la enfermedad.
  /// [fechaEscaneo]: Fecha y hora en que se realizó el escaneo.
  /// [urlImagen]: URL pública de la imagen subida a ImgBB.
  /// [latitud] y [longitud]: Coordenadas geográficas opcionales donde se tomó la foto (para rastreo).
  /// 
  /// Este método verifica primero si el usuario está autenticado. Si no lo está, lanza una excepción.
  /// Luego guarda los datos en la colección `escaneos` del usuario actual.
  Future<void> guardarEscaneo({
    required String tipoEnfermedad,
    required String descripcion,
    required String tratamiento,
    required DateTime fechaEscaneo,
    required String urlImagen,
    double? latitud, // Opcional: latitud del lugar del escaneo
    double? longitud, // Opcional: longitud del lugar del escaneo
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
        'latitud': latitud, // Guarda coordenadas si están disponibles
        'longitud': longitud,
        'createdAt': FieldValue.serverTimestamp(), // Marca de tiempo del servidor
      });
    } catch (e) {
      throw Exception('Error al guardar el escaneo: ${e.toString()}');
    }
  }

  /// Obtiene todos los escaneos del usuario actual, ordenados por fecha descendente (más recientes primero).
  /// 
  /// Devuelve una lista de mapas (`Map<String, dynamic>`) con los datos de cada escaneo.
  /// Si el usuario no está autenticado, lanza una excepción.
  /// En caso de error en la consulta a Firestore, también se lanza una excepción.
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
          .orderBy('fechaEscaneo', descending: true) // Ordena por fecha más reciente
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error al obtener los escaneos: ${e.toString()}');
    }
  }
}

/// Clase principal que gestiona todo el proceso de escaneo: desde la captura de imagen hasta el guardado del resultado.
/// Utiliza una API externa (ImgBB) para subir imágenes y una IA para analizar enfermedades.
class LogicaEscaneo {
  final ScanService _scanService = ScanService();
  static const String _apiKey = "a2cf28f997aaa0388316413335a4a969";
  static const String _uploadUrl =
      "https://api.imgbb.com/1/upload?key=$_apiKey";

  /// Muestra un diálogo con las recomendaciones del escaneo.
  ///
  /// [context]: Contexto de la pantalla para mostrar el diálogo.
  /// [tipo]: Tipo de enfermedad detectada.
  /// [descripcion]: Descripción de la enfermedad.
  /// [tratamiento]: Tratamiento recomendado.
  void _showRecomendation(
    BuildContext context,
    String tipo,
    String descripcion,
    String tratamiento,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultado del escaneo'),
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
  }

  /// Sube una imagen codificada en Base64 a ImgBB y devuelve la URL pública de la imagen.
  /// 
  /// [apiResponse]: Respuesta de la API que contiene la imagen en formato Base64 (como 'data:image/jpeg;base64,...').
  /// 
  /// Extrae solo el contenido Base64 (sin el prefijo MIME), hace la solicitud HTTP POST a ImgBB,
  /// y si la respuesta es exitosa, extrae la URL de la imagen subida.
  /// Si falla, lanza una excepción con un mensaje descriptivo.
  Future<String> _uploadImageToImgbb(Map<String, dynamic> apiResponse) async {
    try {
      final String? imagenBase64 = apiResponse['imagen'];
      if (imagenBase64 == null) {
        throw Exception("No se encontró la imagen en la respuesta de la API.");
      }

      // Elimina el prefijo MIME (ej: "data:image/jpeg;base64,") para quedarnos solo con los datos
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

  /// Convierte la imagen codificada en Base64 (extraída de la respuesta de la API) a un objeto Uint8List (bytes).
  /// 
  /// [apiResponse]: Respuesta de la API que contiene la imagen como cadena Base64.
  /// 
  /// Devuelve `null` si no hay imagen o si el Base64 no es válido. Útil para mostrar la imagen localmente sin necesidad de subirla.
  Uint8List? obtenerImagenDesdeApi(Map<String, dynamic> apiResponse) {
    final String? imagenBase64 = apiResponse['imagen'];

    if (imagenBase64 == null) return null;
    final String base64String = imagenBase64.split(',').last;
    return base64Decode(base64String);
  }

  /// Formatea la lista de enfermedades detectadas en un texto legible para el usuario.
  /// 
  /// [apiResponse]: Respuesta de la API con el campo 'enfermedades' (lista de strings).
  /// 
  /// Si no hay enfermedades, muestra un mensaje indicando falta de conexión.
  /// De lo contrario, devuelve un string con cada enfermedad enumerada.
  /// También imprime información de depuración en consola.
  String formatearEnfermedades(Map<String, dynamic> apiResponse) {
    final enfermedades = apiResponse['enfermedades'];
    print('API RESPONSE COMPLETO: $apiResponse');
    print('ENFERMEDADES LISTA: $enfermedades');

    if (enfermedades == null || enfermedades.isEmpty) {
      return 'Sin conexion al servidor API (revise su conexion a internet).';
    }

    return 'Enfermedades:\n' +
        enfermedades.map<String>((e) => '  $e').join('\n');
  }

  /// Procesa el escaneo completo: sube la imagen, analiza las enfermedades, muestra resultados y guarda en Firestore.
  /// 
  /// [context]: Contexto de la pantalla para mostrar mensajes y diálogos.
  /// [images]: Lista de archivos de imagen seleccionados (normalmente uno).
  /// [apiResponse]: Respuesta de la API de análisis (con imagen, enfermedades, etc.).
  /// [latitud] y [longitud]: Opcionalmente, coordenadas GPS del lugar donde se tomó la foto.
  /// 
  /// Este método:
  /// 1. Verifica que haya imágenes.
  /// 2. Sube la imagen a ImgBB.
  /// 3. Extrae el tipo de enfermedad (si existe).
  /// 4. Busca descripción y tratamiento en Firestore si la enfermedad es conocida.
  /// 5. Muestra un diálogo con los resultados.
  /// 6. Guarda el escaneo en Firestore.
  /// 7. Notifica al usuario si todo salió bien o hubo errores.
  Future<void> guardarEscaneo(
    BuildContext context,
    List<File> images,
    Map<String, dynamic> apiResponse, {
    double? latitud,
    double? longitud,
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

      // Sube la imagen a ImgBB y obtiene su URL pública
      final String downloadUrl = await _uploadImageToImgbb(apiResponse);

      // Extrae la lista de enfermedades detectadas
      final List<dynamic> enfermedades = apiResponse['enfermedades'] ?? [];
      print('API RESPONSE COMPLETO: $apiResponse');
      print('ENFERMEDADES LISTA: $enfermedades');

      String tipo = 'desconocida';

      // Intenta extraer el nombre real de la enfermedad del texto
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
          // Caso especial: mensaje como "No se detecta oregano"
          tipo = item.toString().trim();
          break;
        }
      }
      print('TIPO EXTRAÍDO: $tipo');

      // Define descripción y tratamiento por defecto
      String descripcion = "No disponible";
      String tratamiento = "No disponible";

      // Busca información adicional en Firestore si la enfermedad no es "sana" ni "desconocida"
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

      // Muestra el resultado al usuario en un cuadro de diálogo
      _showRecomendation(context, tipo, descripcion, tratamiento);

      // Guarda el escaneo en Firestore con todas las variables relevantes
      await _scanService.guardarEscaneo(
        tipoEnfermedad: tipo,
        descripcion: descripcion,
        tratamiento: tratamiento,
        fechaEscaneo: now,
        urlImagen: downloadUrl,
        latitud: latitud,
        longitud: longitud,
      );

      // Notificación de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escaneo guardado exitosamente.")),
      );
    } catch (e) {
      // En caso de error, muestra un mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar escaneo: ${e.toString()}")),
      );
    }
  }

  /// Construye la interfaz visual para mostrar múltiples resultados de escaneo.
  /// 
  /// [resultados]: Lista de mapas con datos de escaneos previos (debe incluir imagen y respuesta).
  /// [context]: Contexto de la pantalla para construir widgets.
  /// 
  /// Si no hay resultados, muestra un mensaje vacío.
  /// De lo contrario, crea una lista de tarjetas (Card) con:
  /// - Imagen del escaneo.
  /// - Resultado textual (enfermedades detectadas).
  /// - Botón "Guardar" para guardar el escaneo si no es "sin oregano".
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

          // Validación básica de datos
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

          // Muestra la imagen usando el método auxiliar
          final imagenesWidget = _buildImageWidgets([image], response);

          // Formatea el mensaje de enfermedades
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
                            latitud: imagenConUbicacion?.latitud,
                            longitud: imagenConUbicacion?.longitud,
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

  /// Crea widgets de imagen (File o Uint8List) para mostrar en la interfaz.
  /// 
  /// [images]: Lista de archivos de imagen locales.
  /// [apiResponse]: Respuesta de la API que puede contener una imagen en Base64.
  /// 
  /// Primero intenta mostrar la imagen desde la respuesta de la API (si está presente).
  /// Si no, muestra las imágenes locales (de archivo).
  /// En ambos casos, maneja errores de carga con un texto alternativo.
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

    // Si no hay imagen en la API, usa las imágenes locales
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
