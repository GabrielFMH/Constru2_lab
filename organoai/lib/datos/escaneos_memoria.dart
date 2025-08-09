import 'dart:io';

class Escaneo {
  final File imagen;
  final String enfermedad;
  final String fecha;
  final String descripcion;
  final String tratamiento;

  Escaneo({
    required this.imagen,
    required this.enfermedad,
    required this.fecha,
    required this.descripcion,
    required this.tratamiento,
  });
}

List<Escaneo> listaEscaneos = [];
