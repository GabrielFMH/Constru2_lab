import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/logicaFoto.dart';

class PhotoGallery extends StatelessWidget {
  final bool esInvitado;

  const PhotoGallery({super.key, this.esInvitado = false});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LogicaFoto>(context);
    viewModel.esInvitado = esInvitado;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.eco, size: 60, color: Color(0xFF1DB954)),
                  SizedBox(height: 8),
                  Text(
                    'OreganoAI',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1DB954),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Diagnóstico inteligente para cultivos de orégano',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 248, 247, 247),
                    borderRadius: BorderRadius.circular(1),
                    border: Border.all(color: Colors.grey.shade400),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: viewModel.imagenesConUbicacion.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay imágenes aún",
                            style: TextStyle(color: Colors.black87),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: viewModel.imagenesConUbicacion.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    viewModel.imagenesConUbicacion[index].imagen,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () =>
                                        viewModel.eliminarImagen(index),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.pickImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Subir desde galería"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => viewModel.scanImages(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Escanear"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (viewModel.esInvitado && index != 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text("Función solo disponible para usuarios registrados"),
              ),
            );
          } else {
            viewModel.onItemTapped(context, index);
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Configuración"),
        ],
      ),
    );
  }
}
