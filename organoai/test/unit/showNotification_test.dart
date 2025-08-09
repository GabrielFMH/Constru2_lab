import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Importa la clase refactorizada
import 'package:organoai/logica/logicaNotificaciones.dart';

// La generación de mocks sigue igual. ¡Bien hecho aquí!
@GenerateNiceMocks([MockSpec<FlutterLocalNotificationsPlugin>()])
import 'showNotification_test.mocks.dart';

void main() {
  late NotificacionesService notificacionesService;
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUp(() {
    // 1. Instanciar el mock
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    // 2. Inyectar el mock a través del constructor
    notificacionesService = NotificacionesService.withPlugin(mockPlugin);
  });

  // Este test es perfecto, no necesita cambios.
  test('showNotification no hace nada si las notificaciones están deshabilitadas', () async {
    // Arrange
    notificacionesService.notificationsEnabled = false;

    // Act
    await notificacionesService.showNotification(id: 1, title: 'Test', body: 'Body');

    // Assert
    verifyNever(mockPlugin.show(any, any, any, any));
  });

  // Pruebas de inicialización mejoradas
  group('Inicialización:', () {
    test('showNotification llama a init y luego a show si no está inicializado y la inicialización es exitosa', () async {
      // Arrange
      notificacionesService.notificationsEnabled = true;
      // Simulamos que la inicialización del plugin será exitosa
      when(mockPlugin.initialize(any)).thenAnswer((_) async => true);

      // Act
      await notificacionesService.showNotification(id: 2, title: 'Init', body: 'Body');

      // Assert
      // Verifica que el método de inicialización del plugin fue llamado
      verify(mockPlugin.initialize(any)).called(1);
      // Verifica que, tras el éxito, la notificación se mostró
      verify(mockPlugin.show(2, 'Init', 'Body', any)).called(1);
    });

    test('showNotification llama a init pero NO a show si la inicialización falla', () async {
      // Arrange
      notificacionesService.notificationsEnabled = true;
      // Simulamos que la inicialización del plugin fallará
      when(mockPlugin.initialize(any)).thenAnswer((_) async => false);

      // Act
      await notificacionesService.showNotification(id: 3, title: 'Fail', body: 'Body');

      // Assert
      // Verifica que se intentó inicializar
      verify(mockPlugin.initialize(any)).called(1);
      // Verifica que la notificación NUNCA se mostró debido al fallo
      verifyNever(mockPlugin.show(any, any, any, any));
    });
  });

  // Este test está bien, solo lo adaptamos al stubbing local.
  test('showNotification muestra la notificación si está habilitada e inicializada', () async {
    // Arrange
    notificacionesService.notificationsEnabled = true;
    // Forzamos el estado de 'inicializado' para esta prueba
    when(mockPlugin.initialize(any)).thenAnswer((_) async => true);
    await notificacionesService.showNotification(); // una llamada para inicializar
    
    // Act
    await notificacionesService.showNotification(id: 4, title: 'Ok', body: 'Body');

    // Assert
    // El 'show' se llamó dos veces en total (una en el arrange, una en el act)
    verify(mockPlugin.show(4, 'Ok', 'Body', any)).called(1);
  });

  // Este test es perfecto, no necesita cambios.
  test('showNotification usa valores por defecto si no se proveen argumentos', () async {
    // Arrange
    notificacionesService.notificationsEnabled = true;
    when(mockPlugin.initialize(any)).thenAnswer((_) async => true);

    // Act
    await notificacionesService.showNotification();

    // Assert
    verify(mockPlugin.show(0, null, null, any)).called(1);
  });

  // Este test es excelente, demuestra un buen manejo de errores.
  test('showNotification maneja la excepción del plugin sin crashear', () async {
    // Arrange
    notificacionesService.notificationsEnabled = true;
    when(mockPlugin.initialize(any)).thenAnswer((_) async => true);
    
    // Simulamos que el plugin lanzará un error cuando se llame a 'show'
    when(mockPlugin.show(any, any, any, any)).thenThrow(Exception('Plugin error'));

    // Act y Assert
    // Verificamos que al llamar a la función, no se lanza una excepción no controlada
    await expectLater(
      notificacionesService.showNotification(id: 5, title: 'Error', body: 'Body'),
      completes,
    );
    
    // Y verificamos que, a pesar del error, el intento de llamar a 'show' sí ocurrió
    verify(mockPlugin.show(5, 'Error', 'Body', any)).called(1);
  });
}