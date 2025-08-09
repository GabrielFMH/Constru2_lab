import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/logicaHistorial.dart';
import 'foto.dart';
import 'perfil.dart';
import 'configuracion.dart';
import 'detalle_escaneo.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:organoai/datos/modeloDetalle_Escaneo.dart';

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistorialViewModel(),
      child: Consumer<HistorialViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
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
            body: Container(
              color: const Color(0xFFE8F5E9),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Buscar por fecha (dd/mm/aaaa)',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: viewModel.actualizarFiltroFecha,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: viewModel.filtroEnfermedad,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por enfermedad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: viewModel.enfermedades
                          .map((enf) => DropdownMenuItem(
                                value: enf,
                                child: Text(enf),
                              ))
                          .toList(),
                      onChanged: viewModel.actualizarFiltroEnfermedad,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StreamBuilder<
                          Map<String, List<Map<String, dynamic>>>>(
                        stream: viewModel.escaneosAgrupadosStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text("No hay escaneos registrados."),
                            );
                          }
                          final agrupado = snapshot.data!;
                          return ListView(
                            children: agrupado.entries.map((entry) {
                              final fecha = entry.key;
                              final escaneos = entry.value;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    fecha,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: escaneos.length,
                                      itemBuilder: (context, index) {
                                        final e = escaneos[index];
                                        return Card(
                                          elevation: 2,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            onTap: () {
                                              print(
                                                  'Datos del escaneo seleccionados: $e');
                                              print(
                                                  'Latitud recibida: ${e['latitud']}');
                                              print(
                                                  'Longitud recibida: ${e['longitud']}');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      DetalleEscaneoPage(
                                                    escaneo: EscaneoDetalle(
                                                      tipoEnfermedad:
                                                          e['tipoEnfermedad'] ??
                                                              '',
                                                      descripcion:
                                                          e['descripcion'] ??
                                                              '',
                                                      tratamiento:
                                                          e['tratamiento'] ??
                                                              'No disponible',
                                                      urlImagen:
                                                          e['urlImagen'] ?? '',
                                                      fecha: fecha,
                                                      latitud: (e['latitud']
                                                              as num?)
                                                          ?.toDouble(), // <-- Agregado
                                                      longitud: (e['longitud']
                                                              as num?)
                                                          ?.toDouble(),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: e['urlImagen'] !=
                                                                null &&
                                                            (e['urlImagen']
                                                                    as String)
                                                                .isNotEmpty
                                                        ? NetworkImageByHttp(
                                                            url: e['urlImagen'],
                                                            width: 60,
                                                            height: 60,
                                                          )
                                                        : const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 60),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          e['tipoEnfermedad'] ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text("Fecha: $fecha"),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          e['descripcion'] !=
                                                                  null
                                                              ? "Descripción: ${(e['descripcion'] as String).length > 60 ? '${(e['descripcion'] as String).substring(0, 60)}...' : e['descripcion']}"
                                                              : "Sin descripción",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 13),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistorialPage()),
                    );
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PhotoGallery()),
                    );
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PerfilPage()),
                    );
                    break;
                  case 3:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                    break;
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

class NetworkImageByHttp extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const NetworkImageByHttp({
    required this.url,
    this.width = 70,
    this.height = 70,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _fetchImageBytes(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Icon(Icons.broken_image, size: width, color: Colors.red);
        }
        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Future<Uint8List> _fetchImageBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Error al cargar la imagen');
    }
  }
}
