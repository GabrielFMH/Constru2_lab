import 'dart:convert';
import 'package:http/http.dart' as http;

class ConexionApi {
  // URL de la API REST
  final String _url = 'https://w5627fj1-5000.brs.devtunnels.ms/predict';

  // Función para subir la imagen y obtener la respuesta de la API
  Future<Map<String, dynamic>> predictImage(String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse(_url));
    // Adjuntar la imagen al request
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    // Enviar la solicitud HTTP
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // Comprobar el estado y decodificar la respuesta
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error: ${response.statusCode}\n${response.body}');
    }
  }
}
