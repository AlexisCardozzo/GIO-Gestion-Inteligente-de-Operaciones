import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

class PanelControlInternoScreen extends StatefulWidget {
  @override
  _PanelControlInternoScreenState createState() => _PanelControlInternoScreenState();
}

class _PanelControlInternoScreenState extends State<PanelControlInternoScreen> {
  List<dynamic> _solicitudes = [];
  bool _isLoading = true;
  String _filtro = 'todas'; // todas, verificacion, prestamo

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.get('/api/prestamos/solicitudes-pendientes');
      
      if (response['success']) {
        setState(() {
          _solicitudes = response['solicitudes'];
          _isLoading = false;
        });
      } else {
        throw Exception('Error cargando solicitudes');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _revisarSolicitud(int solicitudId, String accion, {String? comentarios}) async {
    try {
      final response = await ApiService.put(
        '/api/prestamos/revisar-solicitud/$solicitudId',
        {
          'accion': accion,
          'comentarios': comentarios ?? '',
        },
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
        _cargarSolicitudes(); // Recargar lista
      } else {
        throw Exception('Error procesando solicitud');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoRevisar(dynamic solicitud) {
    String comentarios = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Revisar Solicitud'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cliente: ${solicitud['cliente_nombre']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Tipo: ${solicitud['tipo_solicitud'] == 'verificacion_identidad' ? 'Verificación de Identidad' : 'Préstamo'}'),
              if (solicitud['monto'] != null) ...[
                SizedBox(height: 8),
                Text('Monto: ${solicitud['monto'].toString()} Gs'),
              ],
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Comentarios (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  comentarios = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _revisarSolicitud(solicitud['id'], 'rechazar', comentarios: comentarios);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Rechazar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _revisarSolicitud(solicitud['id'], 'aprobar', comentarios: comentarios);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Aprobar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDetallesSolicitud(dynamic solicitud) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles de Solicitud'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetalle('Cliente', solicitud['cliente_nombre']),
                _buildDetalle('Email', solicitud['cliente_email']),
                _buildDetalle('Teléfono', solicitud['cliente_telefono']),
                _buildDetalle('Tipo', solicitud['tipo_solicitud'] == 'verificacion_identidad' ? 'Verificación de Identidad' : 'Préstamo'),
                _buildDetalle('Fecha', DateTime.parse(solicitud['fecha_solicitud']).toString().substring(0, 19)),
                if (solicitud['monto'] != null) _buildDetalle('Monto', '${solicitud['monto'].toString()} Gs'),
                if (solicitud['proposito'] != null) _buildDetalle('Propósito', solicitud['proposito']),
                if (solicitud['score_credito'] != null) _buildDetalle('Score Crédito', solicitud['score_credito'].toString()),
                if (solicitud['categoria_riesgo'] != null) _buildDetalle('Categoría Riesgo', solicitud['categoria_riesgo']),
                if (solicitud['ingresos_promedio_mensual'] != null) _buildDetalle('Ingresos Promedio', '${solicitud['ingresos_promedio_mensual'].toString()} Gs'),
                SizedBox(height: 16),
                if (solicitud['datos_solicitud'] != null) ...[
                  Text('Datos de Solicitud:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      json.encode(json.decode(solicitud['datos_solicitud'])),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _mostrarDialogoRevisar(solicitud);
              },
              child: Text('Revisar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetalle(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  List<dynamic> get _solicitudesFiltradas {
    if (_filtro == 'todas') return _solicitudes;
    return _solicitudes.where((s) => s['tipo_solicitud'] == _filtro).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Control Interno'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarSolicitudes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Filtrar: ', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filtro,
                  items: [
                    DropdownMenuItem(value: 'todas', child: Text('Todas')),
                    DropdownMenuItem(value: 'verificacion_identidad', child: Text('Verificaciones')),
                    DropdownMenuItem(value: 'prestamo', child: Text('Préstamos')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filtro = value!;
                    });
                  },
                ),
                Spacer(),
                Text(
                  '${_solicitudesFiltradas.length} solicitudes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Lista de solicitudes
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _solicitudesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.green),
                            SizedBox(height: 16),
                            Text(
                              'No hay solicitudes pendientes',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Todas las solicitudes han sido procesadas',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _solicitudesFiltradas.length,
                        itemBuilder: (context, index) {
                          final solicitud = _solicitudesFiltradas[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: solicitud['tipo_solicitud'] == 'verificacion_identidad' 
                                    ? Colors.orange 
                                    : Colors.blue,
                                child: Icon(
                                  solicitud['tipo_solicitud'] == 'verificacion_identidad' 
                                      ? Icons.verified_user 
                                      : Icons.account_balance,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                solicitud['cliente_nombre'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    solicitud['tipo_solicitud'] == 'verificacion_identidad' 
                                        ? 'Verificación de Identidad' 
                                        : 'Solicitud de Préstamo',
                                  ),
                                  if (solicitud['monto'] != null)
                                    Text(
                                      'Monto: ${solicitud['monto'].toString()} Gs',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  Text(
                                    'Fecha: ${DateTime.parse(solicitud['fecha_solicitud']).toString().substring(0, 16)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.info),
                                    onPressed: () => _mostrarDetallesSolicitud(solicitud),
                                    tooltip: 'Ver detalles',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _revisarSolicitud(solicitud['id'], 'aprobar'),
                                    tooltip: 'Aprobar',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _revisarSolicitud(solicitud['id'], 'rechazar'),
                                    tooltip: 'Rechazar',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 