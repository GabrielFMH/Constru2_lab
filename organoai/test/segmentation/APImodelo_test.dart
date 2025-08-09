import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Segmentación - Prueba de Sobrecarga API', () {
    test(
      'Encuentra el máximo de solicitudes concurrentes exitosas',
      () async {
        final uri =
            Uri.parse('https://flask-cnn-api-latest.onrender.com/predict');
        final imagePath =
            'test/segmentation/test.jfif'; // Cambia la ruta si es necesario
        int concurrentRequests = 1;
        int maxSuccess = 0;
        bool sigue = true;

        while (sigue && concurrentRequests <= 100) {
          // Puedes aumentar el límite
          //print('Probando con $concurrentRequests solicitudes...');
          final List<Future<http.StreamedResponse>> requests = [];
          for (int i = 0; i < concurrentRequests; i++) {
            final request = http.MultipartRequest('POST', uri)
              ..files.add(await http.MultipartFile.fromPath('file', imagePath));
            requests.add(request.send());
          }
          final responses = await Future.wait(requests);
          final allOk = responses.every((r) => r.statusCode == 200);
          if (allOk) {
            maxSuccess = concurrentRequests;
            concurrentRequests++;
          } else {
            sigue = false;
          }
        }
        //print('Máximo de solicitudes concurrentes exitosas: $maxSuccess');
        expect(maxSuccess, greaterThan(0),
            reason: 'La API no soporta ninguna solicitud concurrente');
      },
      timeout: Timeout(Duration(minutes: 3)), // <-- Timeout aumentado aquí
    );
  });
}
