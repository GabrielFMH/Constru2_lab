import 'package:flutter/material.dart';
import 'package:organoai/datos/modeloDetalle_Escaneo.dart';
import 'package:url_launcher/url_launcher.dart';

class DetalleEscaneoPage extends StatelessWidget {
  final EscaneoDetalle escaneo;

  const DetalleEscaneoPage({super.key, required this.escaneo});

  @override
  Widget build(BuildContext context) {
    print(
        'DetalleEscaneoPage: latitud=${escaneo.latitud}, longitud=${escaneo.longitud}');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  escaneo.urlImagen,
                  height: 230,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection("Fecha:", escaneo.fecha),
            const SizedBox(height: 12),
            _buildSection("Tipo de Enfermedad:", escaneo.tipoEnfermedad),
            const SizedBox(height: 12),
            _buildSection("Descripción:", escaneo.descripcion),
            const SizedBox(height: 12),
            _buildSection("Tratamiento:", escaneo.tratamiento),
            const SizedBox(height: 24),
            _buildSection("Latitud:", escaneo.latitud?.toString() ?? 'N/A'),
            const SizedBox(height: 24),
            _buildSection("Longitud:", escaneo.longitud?.toString() ?? 'N/A'),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text("Ver ubicación"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  final lat = escaneo.latitud;
                  final lng = escaneo.longitud;
                  print(
                      'Botón Ver ubicación presionado. latitud=$lat, longitud=$lng');

                  if (lat != null && lng != null) {
                    // Intento 1: Esquema geo
                    final geoUrl = 'geo:$lat,$lng';
                    final geoUri = Uri.parse(geoUrl);
                    print('Intentando abrir Google Maps con geo: $geoUri');

                    if (await canLaunchUrl(geoUri)) {
                      print('Abriendo Google Maps con geo...');
                      await launchUrl(geoUri,
                          mode: LaunchMode.externalApplication);
                      return;
                    } else {
                      print(
                          'No se pudo abrir Google Maps con geo, intentando googlemaps://...');
                    }

                    // Intento 2: Esquema googlemaps
                    final gmapsUrl = 'googlemaps://?q=$lat,$lng';
                    final gmapsUri = Uri.parse(gmapsUrl);
                    print(
                        'Intentando abrir Google Maps con googlemaps: $gmapsUri');

                    if (await canLaunchUrl(gmapsUri)) {
                      print('Abriendo Google Maps con googlemaps...');
                      await launchUrl(gmapsUri,
                          mode: LaunchMode.externalApplication);
                      return;
                    } else {
                      print(
                          'No se pudo abrir Google Maps con googlemaps, intentando navegador...');
                    }

                    // Intento 3: Navegador con Google Maps
                    final encodedLat = Uri.encodeComponent(lat.toString());
                    final encodedLng = Uri.encodeComponent(lng.toString());
                    final webUrl =
                        'https://www.google.com/maps/search/?api=1&query=$encodedLat,$encodedLng';
                    final webUri = Uri.parse(webUrl);
                    print('Intentando abrir navegador: $webUri');

                    if (await canLaunchUrl(webUri)) {
                      print('Abriendo navegador...');
                      await launchUrl(webUri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      print('No se pudo abrir el navegador');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('No se pudo abrir el mapa')),
                      );
                    }
                  } else {
                    print('Latitud o longitud nulas');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ubicación no disponible')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}
