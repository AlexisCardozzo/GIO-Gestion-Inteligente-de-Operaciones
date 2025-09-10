import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/format.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List<dynamic> _reportes = [];
  bool _cargando = false;
  double _totalGananciaNeta = 0.0;
  double _totalGananciaBruta = 0.0;

  Set<int> _seleccionados = {};
  bool get _todosSeleccionados => _reportes.isNotEmpty && _seleccionados.length == _reportes.length;
  List<dynamic> _reportesPapelera = [];
  Set<int> _seleccionadosPapelera = {};
  bool _viendoPapelera = false;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() { _cargando = true; });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: No hay sesión activa. Por favor inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() { _cargando = false; });
        return;
      }
      
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/reportes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reportes = data['data'];
          _totalGananciaNeta = _reportes.fold(0.0, (sum, r) => sum + (double.tryParse(r['ganancia_neta'].toString()) ?? 0));
          _totalGananciaBruta = _reportes.fold(0.0, (sum, r) => sum + (double.tryParse(r['ganancia_bruta'].toString()) ?? 0));
          _cargando = false;
        });
      } else {
        // Mostrar mensaje de error con más detalles
        String errorMsg;
        try {
          final errorData = json.decode(response.body);
          errorMsg = errorData['error'] ?? 'Error desconocido';
        } catch (e) {
          errorMsg = 'Error al procesar la respuesta';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar reportes. Código: ${response.statusCode}. Detalle: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        setState(() { _cargando = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error de conexión: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() { _cargando = false; });
    }
  }

  Future<void> _cargarPapelera() async {
    setState(() { _cargando = true; });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: No hay sesión activa. Por favor inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() { _cargando = false; });
        return;
      }
      
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/reportes/papelera'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reportesPapelera = data['data'];
          _cargando = false;
        });
      } else {
        // Mostrar mensaje de error con más detalles
        String errorMsg;
        try {
          final errorData = json.decode(response.body);
          errorMsg = errorData['error'] ?? 'Error desconocido';
        } catch (e) {
          errorMsg = 'Error al procesar la respuesta';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar papelera. Código: ${response.statusCode}. Detalle: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        setState(() { _cargando = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error de conexión: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() { _cargando = false; });
    }
  }

  Future<void> _eliminarSeleccionadosSinPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar los reportes seleccionados?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/reportes/papelera'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'ids': _seleccionados.toList(),
            // No enviar password
          }),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reportes eliminados correctamente.')));
          setState(() {
            _seleccionados.clear();
          });
          await _cargarReportes();
        } else {
          String errorMsg = 'Error al eliminar.';
          try {
            final data = json.decode(response.body);
            errorMsg = data['mensaje'] ?? data['error'] ?? response.body ?? errorMsg;
          } catch (_) {
            errorMsg = response.body;
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión.')));
      }
    }
  }

  Future<void> _restaurarSeleccionadosPapelera() async {
    if (_seleccionadosPapelera.isEmpty) return;
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/reportes/restaurar'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'ids': _seleccionadosPapelera.toList()}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reportes restaurados correctamente.')));
        setState(() { _seleccionadosPapelera.clear(); });
        await _cargarPapelera();
        await _cargarReportes();
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error al restaurar.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión.')));
    }
  }

  Future<void> _eliminarPermanenteSeleccionados() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminación permanente'),
        content: const Text('¿Estás seguro de que deseas eliminar definitivamente los reportes seleccionados? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
            child: const Text('Eliminar definitivamente'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/reportes/papelera/eliminar-definitivo'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode({'ids': _seleccionadosPapelera.toList()}),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reportes eliminados permanentemente.')));
          setState(() { _seleccionadosPapelera.clear(); });
          await _cargarPapelera();
        } else {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error al eliminar permanentemente.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión.')));
      }
    }
  }

  void _verDetalleReporte(dynamic reporte) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: _DetalleReporte(reporte: reporte),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 8,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        actions: [
          IconButton(
            icon: Icon(_viendoPapelera ? Icons.assignment : Icons.delete_outline),
            tooltip: _viendoPapelera ? 'Ver reportes activos' : 'Ver papelera',
            onPressed: () async {
              setState(() { _viendoPapelera = !_viendoPapelera; });
              if (_viendoPapelera) {
                await _cargarPapelera();
              } else {
                await _cargarReportes();
              }
            },
          ),
          if (!_viendoPapelera && _reportes.isNotEmpty)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _todosSeleccionados,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _seleccionados = _reportes.map<int>((r) => r['id'] as int).toSet();
                        } else {
                          _seleccionados.clear();
                        }
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.indigo,
                  ),
                  const Text('Todos', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  if (_seleccionados.isNotEmpty)
                    Flexible(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text('Eliminar seleccionados', overflow: TextOverflow.ellipsis),
                        onPressed: _eliminarSeleccionadosSinPassword,
                      ),
                    ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          if (_viendoPapelera && _reportesPapelera.isNotEmpty)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _reportesPapelera.isNotEmpty && _seleccionadosPapelera.length == _reportesPapelera.length,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _seleccionadosPapelera = _reportesPapelera.map<int>((r) => r['id'] as int).toSet();
                        } else {
                          _seleccionadosPapelera.clear();
                        }
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.indigo,
                  ),
                  const Text('Todos', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  if (_seleccionadosPapelera.isNotEmpty)
                    Flexible(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                        icon: const Icon(Icons.restore, size: 20),
                        label: const Text('Restaurar seleccionados', overflow: TextOverflow.ellipsis),
                        onPressed: _restaurarSeleccionadosPapelera,
                      ),
                    ),
                  const SizedBox(width: 12),
                  if (_seleccionadosPapelera.isNotEmpty)
                    Flexible(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                        icon: const Icon(Icons.delete_forever, size: 20),
                        label: const Text('Eliminar permanentemente', overflow: TextOverflow.ellipsis),
                        onPressed: _eliminarPermanenteSeleccionados,
                      ),
                    ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_cargando)
                  const Center(child: CircularProgressIndicator()),
                if (!_viendoPapelera && _reportes.isEmpty && !_cargando)
                  const Center(child: Text('No hay reportes guardados', style: TextStyle(color: Colors.white)))
                else if (_viendoPapelera && _reportesPapelera.isEmpty && !_cargando)
                  const Center(child: Text('La papelera está vacía', style: TextStyle(color: Colors.white)))
                else if (!_viendoPapelera) ...[
                  // Lista de reportes individuales con selección múltiple
                  ..._reportes.map((r) => Card(
                        color: _seleccionados.contains(r['id']) ? Colors.red[50] : Colors.white,
                        elevation: 10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                        child: ListTile(
                          leading: Checkbox(
                            value: _seleccionados.contains(r['id']),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _seleccionados.add(r['id'] as int);
                                } else {
                                  _seleccionados.remove(r['id'] as int);
                                }
                              });
                            },
                            activeColor: Colors.red[700],
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                          title: Text('Reporte del ${r['fecha'].toString().substring(0, 10)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                          subtitle: Text('Ventas: ${formatMiles(parseNum(r['ventas']))} | Bruta: Gs ${formatMiles(parseNum(r['ganancia_bruta']))} | Neta: Gs ${formatMiles(parseNum(r['ganancia_neta']))}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                          trailing: Tooltip(
                            message: 'Ver detalles y gráficas de este reporte',
                            child: IconButton(
                              icon: const Icon(Icons.bar_chart, color: Colors.indigo, size: 30),
                              onPressed: () => _verDetalleReporte(r),
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                  // Gráficas globales
                  _GraficaGlobalIngresos(reportes: _reportes),
                  const SizedBox(height: 40),
                ]
                else ...[
                  // Lista de reportes en papelera con selección múltiple
                  ..._reportesPapelera.map((r) => Card(
                        color: _seleccionadosPapelera.contains(r['id']) ? Colors.green[50] : Colors.white,
                        elevation: 10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                        child: ListTile(
                          leading: Checkbox(
                            value: _seleccionadosPapelera.contains(r['id']),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _seleccionadosPapelera.add(r['id'] as int);
                                } else {
                                  _seleccionadosPapelera.remove(r['id'] as int);
                                }
                              });
                            },
                            activeColor: Colors.green[700],
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                          title: Text('Reporte del ${r['fecha'].toString().substring(0, 10)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                          subtitle: Text('Ventas: ${formatMiles(parseNum(r['ventas']))} | Bruta: Gs ${formatMiles(parseNum(r['ganancia_bruta']))} | Neta: Gs ${formatMiles(parseNum(r['ganancia_neta']))}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                          trailing: Tooltip(
                            message: 'No disponible en papelera',
                            child: const Icon(Icons.delete_outline, color: Colors.grey, size: 30),
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetalleReporte extends StatelessWidget {
  final dynamic reporte;
  const _DetalleReporte({required this.reporte});

  @override
  Widget build(BuildContext context) {
    // Manejar productos_vendidos y ventas_por_dia como listas
    final productosVendidos = (reporte['productos_vendidos'] is String)
        ? List<Map<String, dynamic>>.from(json.decode(reporte['productos_vendidos']))
        : List<Map<String, dynamic>>.from(reporte['productos_vendidos']);
    final ventasPorDia = (reporte['ventas_por_dia'] is String)
        ? List<Map<String, dynamic>>.from(json.decode(reporte['ventas_por_dia']))
        : List<Map<String, dynamic>>.from(reporte['ventas_por_dia']);

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título principal con fondo blanco
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.indigo, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Reporte del ${reporte['fecha'].toString().substring(0, 10)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                        color: Colors.indigo,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Tarjeta con datos principales
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total vendidos:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '${reporte['ventas']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ganancia bruta:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          'Gs ${reporte['ganancia_bruta']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ganancia neta (con IVA):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          'Gs ${reporte['ganancia_neta']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Tarjeta de productos más vendidos
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos más vendidos:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 120,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: productosVendidos.map((producto) {
                            return Tooltip(
                              message: 'Vendidos: ${producto['cantidad']}',
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      height: (int.tryParse(producto['cantidad'].toString()) ?? 1) * 6.0,
                                      width: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.indigo,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.indigo.withAlpha((255 * 0.3).round()),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            producto['cantidad'].toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(
                                        producto['producto_id'].toString().length > 10
                                            ? producto['producto_id'].toString().substring(0, 10) + '…'
                                            : producto['producto_id'].toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Tarjeta de ventas por día
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timeline, color: Colors.blue, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Ventas por día:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: 'Gráfica lineal de ventas diarias en el periodo de este reporte.',
                          child: const Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 140,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: ventasPorDia.map((venta) {
                          return Tooltip(
                            message: 'Gs ${venta['total']} en ${venta['fecha']}',
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: (int.tryParse(venta['total'].toString()) ?? 1) * 0.01,
                                    width: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withAlpha((255 * 0.3).round()),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    venta['fecha'].toString().substring(5),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraficaGlobalIngresos extends StatelessWidget {
  final List<dynamic> reportes;
  const _GraficaGlobalIngresos({required this.reportes});

  @override
  Widget build(BuildContext context) {
    // Agrupar por fecha y sumar ingresos brutos y netos
    final Map<String, double> ingresosBrutosPorDia = {};
    final Map<String, double> ingresosNetosPorDia = {};
    for (final r in reportes) {
      final fecha = r['fecha'].toString().substring(0, 10);
      final bruta = double.tryParse(r['ganancia_bruta'].toString()) ?? 0;
      final neta = double.tryParse(r['ganancia_neta'].toString()) ?? 0;
      ingresosBrutosPorDia[fecha] = (ingresosBrutosPorDia[fecha] ?? 0) + bruta;
      ingresosNetosPorDia[fecha] = (ingresosNetosPorDia[fecha] ?? 0) + neta;
    }
    final fechas = ingresosBrutosPorDia.keys.toList()..sort();
    final brutos = fechas.map((f) => ingresosBrutosPorDia[f] ?? 0).toList();
    final netos = fechas.map((f) => ingresosNetosPorDia[f] ?? 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gráfica global de ingresos brutos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        const SizedBox(height: 10),
        _GraficoLinealTrading(
          fechas: fechas,
          valores: brutos,
          colorLinea: Colors.greenAccent,
          colorSombra: Colors.greenAccent.withAlpha((255 * 0.18).round()),
          label: 'Bruto',
        ),
        const SizedBox(height: 30),
        const Text('Gráfica global de ingresos netos (con IVA)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        const SizedBox(height: 10),
        _GraficoLinealTrading(
          fechas: fechas,
          valores: netos,
          colorLinea: Colors.blueAccent,
          colorSombra: Colors.blueAccent.withAlpha((255 * 0.18).round()),
          label: 'Neto',
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _GraficoLinealTrading extends StatefulWidget {
  final List<String> fechas;
  final List<double> valores;
  final Color colorLinea;
  final Color colorSombra;
  final String label;
  const _GraficoLinealTrading({required this.fechas, required this.valores, required this.colorLinea, required this.colorSombra, required this.label});

  @override
  State<_GraficoLinealTrading> createState() => _GraficoLinealTradingState();
}

class _GraficoLinealTradingState extends State<_GraficoLinealTrading> with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _controller;
  late Animation<double> _animation;
  List<double> _oldValores = [];

  @override
  void initState() {
    super.initState();
    _oldValores = List<double>.from(widget.valores);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _GraficoLinealTrading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valores.length != widget.valores.length || !_listEquals(oldWidget.valores, widget.valores)) {
      _oldValores = List<double>.from(oldWidget.valores);
      _controller.forward(from: 0);
    }
  }

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.01) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxValor = widget.valores.isEmpty ? 1.0 : widget.valores.reduce(max).toDouble();
    final minValor = widget.valores.isEmpty ? 0.0 : widget.valores.reduce(min).toDouble();
    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B3A), Color(0xFF1B263B), Color(0xFF274690)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.12).round()),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final valoresAnim = List<double>.generate(widget.valores.length, (i) {
                    final old = i < _oldValores.length ? _oldValores[i] : widget.valores[i];
                    return old + (widget.valores[i] - old) * _animation.value;
                  });
                  return GestureDetector(
                    onTapDown: (details) => _handleTouch(details.localPosition, context, valoresAnim, maxValor, minValor),
                    onPanUpdate: (details) => _handleTouch(details.localPosition, context, valoresAnim, maxValor, minValor),
                    onTapUp: (_) => setState(() => _hoveredIndex = null),
                    onPanEnd: (_) => setState(() => _hoveredIndex = null),
                    child: CustomPaint(
                      size: const Size(double.infinity, 140),
                      painter: _LineaTradingPainter(
                        valores: valoresAnim,
                        colorLinea: widget.colorLinea,
                        colorSombra: widget.colorSombra,
                        maxValor: maxValor,
                        minValor: minValor,
                        hoveredIndex: _hoveredIndex,
                        fechas: widget.fechas,
                        label: widget.label,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: widget.fechas.map((f) => Text(f.substring(5), style: const TextStyle(fontSize: 12, color: Colors.white70))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTouch(Offset pos, BuildContext context, List<double> valores, double maxValor, double minValor) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final dx = size.width / (valores.length - 1);
    int? closest;
    double minDist = double.infinity;
    for (int i = 0; i < valores.length; i++) {
      final x = i * dx;
      final y = size.height - 20 - ((valores[i] - minValor) / ((maxValor == minValor) ? 1 : (maxValor - minValor)) * (size.height - 20));
      final dist = (Offset(x, y) - pos).distance;
      if (dist < minDist && dist < 24) {
        minDist = dist;
        closest = i;
      }
    }
    setState(() {
      _hoveredIndex = closest;
    });
  }
}

class _LineaTradingPainter extends CustomPainter {
  final List<double> valores;
  final Color colorLinea;
  final Color colorSombra;
  final double maxValor;
  final double minValor;
  final int? hoveredIndex;
  final List<String> fechas;
  final String label;
  _LineaTradingPainter({required this.valores, required this.colorLinea, required this.colorSombra, required this.maxValor, required this.minValor, required this.hoveredIndex, required this.fechas, required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.length < 2) return;
    final dx = size.width / (valores.length - 1);
    double scale = maxValor == minValor ? 1 : (size.height - 20) / (maxValor - minValor);

    // Sombra bajo la línea
    final sombraPath = Path();
    for (int i = 0; i < valores.length; i++) {
      final x = i * dx;
      final y = size.height - 20 - ((valores[i] - minValor) * scale);
      if (i == 0) {
        sombraPath.moveTo(x, size.height - 20);
        sombraPath.lineTo(x, y);
      } else {
        sombraPath.lineTo(x, y);
      }
    }
    sombraPath.lineTo(size.width, size.height - 20);
    sombraPath.close();
    final sombraPaint = Paint()
      ..color = colorSombra
      ..style = PaintingStyle.fill;
    canvas.drawPath(sombraPath, sombraPaint);

    // Línea curva (Catmull-Rom spline)
    final paint = Paint()
      ..color = colorLinea
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < valores.length; i++) {
      final x = i * dx;
      final y = size.height - 20 - ((valores[i] - minValor) * scale);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * dx;
        final prevY = size.height - 20 - ((valores[i - 1] - minValor) * scale);
        final cpx1 = prevX + dx / 2;
        final cpy1 = prevY;
        final cpx2 = x - dx / 2;
        final cpy2 = y;
        path.cubicTo(cpx1, cpy1, cpx2, cpy2, x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Ejes
    final ejePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 20), Offset(size.width, size.height - 20), ejePaint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height - 20), ejePaint);

    // Puntos
    final pointPaint = Paint()
      ..color = colorLinea
      ..style = PaintingStyle.fill;
    for (int i = 0; i < valores.length; i++) {
      final x = i * dx;
      final y = size.height - 20 - ((valores[i] - minValor) * scale);
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
    }

    // Tooltip
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < valores.length) {
      final x = hoveredIndex! * dx;
      final y = size.height - 20 - ((valores[hoveredIndex!] - minValor) * scale);
      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - 32), width: 90, height: 38),
        const Radius.circular(8),
      );
      final tooltipPaint = Paint()..color = Colors.white;
      canvas.drawRRect(tooltipRect, tooltipPaint);
      final textSpan = TextSpan(
        text: '${fechas[hoveredIndex!]}\nGs ${valores[hoveredIndex!]}',
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
      );
      final tp = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout(maxWidth: 90);
      tp.paint(canvas, Offset(x - tp.width / 2, y - 32 + 7));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}