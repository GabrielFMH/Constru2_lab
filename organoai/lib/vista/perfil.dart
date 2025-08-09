import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/logicaPerfil.dart';
import 'foto.dart';
import 'historial.dart';
import 'configuracion.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerfilViewModel()..cargarDatosUsuario(),
      child: Consumer<PerfilViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFE8F5E9),
            appBar: AppBar(
              backgroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
              title: const Column(
                children: [
                  Icon(Icons.eco, size: 30, color: Color(0xFF1DB954)),
                  SizedBox(height: 2),
                  Text(
                    'OreganoAI',
                    style: TextStyle(
                      color: Color(0xFF1DB954),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nombre:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: viewModel.nombreController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Ingresa tu nombre',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Nueva Contraseña:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: viewModel.contrasenaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Ingresa nueva contraseña',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => viewModel.guardarCambios(context),
                            child: const Text(
                              'Guardar Cambios',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: 2,
              onTap: (index) {
                Widget? destino;
                switch (index) {
                  case 0:
                    destino = const HistorialPage();
                    break;
                  case 1:
                    destino = const PhotoGallery();
                    break;
                  case 2:
                    destino = const PerfilPage();
                    break;
                  case 3:
                    destino = const SettingsScreen();
                    break;
                }
                if (destino != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => destino!),
                  );
                }
              },
              backgroundColor: Colors.white,
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.black,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.history), label: "Historial"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.camera_alt), label: "Tomar Foto"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: "Perfil"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: "Configuración"),
              ],
            ),
          );
        },
      ),
    );
  }
}
