import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:organoai/logica/logicaConfiguracion.dart';
import 'foto.dart';
import 'historial.dart';
import 'perfil.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: Consumer<SettingsViewModel>(
        builder: (context, viewModel, _) => Scaffold(
          backgroundColor: const Color(0xFFE8F5E9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
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
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text('Notificaciones',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    value: viewModel.notificationsEnabled,
                    onChanged: viewModel.toggleNotifications,
                    activeColor: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading:
                        const Icon(Icons.email_outlined, color: Colors.green),
                    title: const Text('Contacto'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Aquí podrías mostrar un diálogo con contacto
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Eliminar cuenta'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => viewModel.deleteAccount(context),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.black),
                    title: const Text('Cerrar sesión'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => viewModel.logout(context),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 3,
            onTap: (index) {
              Widget? destination;
              switch (index) {
                case 0:
                  destination = const HistorialPage();
                  break;
                case 1:
                  destination = const PhotoGallery();
                  break;
                case 2:
                  destination = const PerfilPage();
                  break;
                case 3:
                  destination = const SettingsScreen();
                  break;
              }
              if (destination != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => destination!),
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
        ),
      ),
    );
  }
}
