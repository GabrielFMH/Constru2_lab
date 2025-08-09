import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'package:organoai/vista/login.dart';
import 'package:organoai/logica/logicaFoto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => LogicaFoto()), // Aquí está ViewModel registrado
        // Se puede añadir más ViewModels si lo necesitas
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OrganoAI',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: const LoginPage(), // pantalla inicial
      ),
    );
  }
}
