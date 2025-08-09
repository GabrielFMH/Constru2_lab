/*import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organoai/logica/logicaEscaneo.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser mockUser;
  late ScanServiceTestable scanService;

  setUp(() {
    //print('Inicializando test...');
    // Usuario mock con datos personalizados
    mockUser = MockUser(
      uid: 'test_uid',
      email: 'm@gmail.com',
      displayName: 'marcelo',
      isAnonymous: false,
    );

    auth = MockFirebaseAuth(mockUser: mockUser);
    firestore = FakeFirebaseFirestore();

    scanService = ScanServiceTestable(
      firestore: firestore,
      auth: auth,
    );
  });

  test('obtenerEscaneos devuelve lista de escaneos del usuario', () async {
    //print('Agregando documento falso a Firestore...');
    final escaneosRef =
        firestore.collection('users').doc(mockUser.uid).collection('escaneos');

    await escaneosRef.add({
      'tipoEnfermedad': 'Royas',
      'descripcion': 'Hongos visibles',
      'fechaEscaneo': Timestamp.fromDate(DateTime(2024, 6, 1)),
      'urlImagen': 'https://ejemplo.com/imagen.jpg',
      'createdAt': FieldValue.serverTimestamp(),
    });

    //print('Ejecutando scanService.obtenerEscaneos()...');
    final resultado = await scanService.obtenerEscaneos();

    //print('Resultado obtenido:');
    for (var i = 0; i < resultado.length; i++) {
      //print('Escaneo #$i');
      resultado[i].forEach((key, value) {
        //print('   - $key: $value');
      });
    }

    expect(resultado.length, 1);
    expect(resultado[0]['tipoEnfermedad'], 'Royas');
    expect(resultado[0]['descripcion'], 'Hongos visibles');
    expect(resultado[0]['urlImagen'], 'https://ejemplo.com/imagen.jpg');
    print('Test finalizado correctamente.');
  });
}

/// Subclase para inyectar firestore y auth falsos
class ScanServiceTestable extends ScanService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ScanServiceTestable({required this.firestore, required this.auth});

  @override
  FirebaseFirestore get _firestore => firestore;

  @override
  FirebaseAuth get _auth => auth;
}*/
