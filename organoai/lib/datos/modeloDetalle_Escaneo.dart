class EscaneoDetalle {
  final String tipoEnfermedad;
  final String descripcion;
  final String urlImagen;
  final String fecha;
  final String tratamiento;
  final double? latitud;   // <-- Agregado
  final double? longitud;  // <-- Agregado

  EscaneoDetalle({
    required this.tipoEnfermedad,
    required this.descripcion,
    required this.urlImagen,
    required this.fecha,
    required this.tratamiento,
    this.latitud,         // <-- Agregado
    this.longitud,        // <-- Agregado
  }){
    print('EscaneoDetalle creado: latitud=$latitud, longitud=$longitud');
  }
}