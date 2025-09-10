import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Función para formatear números sin decimales innecesarios
String formatNumber(dynamic value) {
  if (value == null) return '0';
  if (value is int) return value.toString();
  if (value is double) {
    // Si es un número entero, mostrar sin decimales
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    // Si tiene decimales, mostrar con separadores de miles
    return NumberFormat('#,##0', 'es').format(value);
  }
  if (value is String) {
    final numValue = double.tryParse(value);
    if (numValue != null) {
      if (numValue == numValue.toInt()) {
        return numValue.toInt().toString();
      }
      return NumberFormat('#,##0', 'es').format(numValue);
    }
  }
  return value.toString();
}

class ProductoStock {
  final int id;
  final String nombre;
  final String codigo;
  final double precioCompra;
  final double precioVenta;
  final int iva;
  final int cantidad;

  ProductoStock({required this.id, required this.nombre, required this.codigo, required this.precioCompra, required this.precioVenta, required this.iva, required this.cantidad});

  factory ProductoStock.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }
    return ProductoStock(
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      precioCompra: parseDouble(json['precio_compra']),
      precioVenta: parseDouble(json['precio_venta']),
      iva: json['iva'] is int ? json['iva'] : int.tryParse(json['iva'].toString()) ?? 0,
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
    );
  }
}

class MovimientoStock {
  final int id;
  final int productoId;
  final String tipo; // 'entrada' o 'salida'
  final int cantidad;
  final String motivo;
  final String fecha;

  MovimientoStock({required this.id, required this.productoId, required this.tipo, required this.cantidad, required this.motivo, required this.fecha});

  factory MovimientoStock.fromJson(Map<String, dynamic> json) {
    return MovimientoStock(
      id: json['id'],
      productoId: json['articulo_id'],
      tipo: json['tipo_movimiento'] ?? json['tipo'] ?? '',
      cantidad: json['cantidad'],
      motivo: json['referencia'] ?? json['motivo'] ?? '',
      fecha: json['fecha_hora'] ?? json['fecha'] ?? '',
    );
  }
}

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  List<ProductoStock> _productos = [];
  bool _cargando = false;
  String _filtro = '';
  bool _soloStockBajo = false;
  TabController? _tabController;
  List<MovimientoStock> _movimientosGlobales = [];
  String _filtroMovimientos = '';

  // Timer para actualización periódica
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarStock();
    _cargarMovimientosGlobales();
    
    // Configurar un timer para actualizar los datos cada 5 segundos
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _cargarMovimientosGlobales();
        _cargarStock(); // También actualizar el stock
      }
    });
  }
  
  @override
  void dispose() {
    // Cancelar el timer cuando se destruye el widget
    _updateTimer?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _cargarStock() async {
    // Verificar si el widget está montado antes de continuar
    if (!mounted) return;
    
    setState(() { _cargando = true; });
    try {
      // Obtener el token de autenticación
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Realizar la solicitud con el token de autenticación
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/stock/productos/stock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Verificar nuevamente si el widget está montado antes de actualizar el estado
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _productos = (data['data'] as List).map((e) => ProductoStock.fromJson(e)).toList();
          _cargando = false;
        });
        
        // Los movimientos se actualizarán automáticamente
      } else {
        print('Error en _cargarStock: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() { _cargando = false; });
        }
      }
    } catch (e) {
      print('Error en _cargarStock: $e');
      if (mounted) {
        setState(() { _cargando = false; });
      }
    }
  }

  // Método para forzar actualización del stock
  Future<void> _refrescarStock() async {
    await _cargarStock();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stock actualizado'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _cargarMovimientosGlobales() async {
    try {
      // Verificar si el widget está montado antes de continuar
      if (!mounted) return;
      
      // Obtener el token de autenticación
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Realizar la solicitud con el token de autenticación
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/stock/movimientos/todos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nuevosMovimientos = (data['data'] as List).map((e) => MovimientoStock.fromJson(e)).toList();
        
        // Verificar nuevamente si el widget está montado antes de actualizar el estado
        if (!mounted) return;
        
        // Actualizar si hay cambios en el número de movimientos o si es la primera carga
        if (nuevosMovimientos.length != _movimientosGlobales.length || _movimientosGlobales.isEmpty) {
          setState(() {
            _movimientosGlobales = nuevosMovimientos;
          });
          print('🔄 Movimientos de stock actualizados: ${nuevosMovimientos.length} movimientos');
          
          // El widget hijo se actualizará automáticamente
        }
      } else {
        print('❌ Error al cargar movimientos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error al cargar movimientos: $e');
    }
  }

  // Método para forzar actualización del resumen de ventas
  void _forzarActualizacionResumen() {
    // El widget hijo se actualizará automáticamente
  }

  double get totalProductos => _productos.fold(0.0, (sum, p) => sum + p.cantidad);
  double get totalInversion => _productos.fold(0.0, (sum, p) => sum + p.precioCompra * p.cantidad);
  double get totalVenta => _productos.fold(0.0, (sum, p) => sum + p.precioVenta * p.cantidad);
  double get totalGananciaBruta => _productos.fold(0.0, (sum, p) => sum + (p.precioVenta - p.precioCompra) * p.cantidad);
  double get totalGananciaNeta => _productos.fold(0.0, (sum, p) => sum + ((p.precioVenta - p.precioCompra) * p.cantidad) - ((p.precioVenta * p.iva / 100) * p.cantidad));
  int get totalProductosCreados => _productos.length;

  Future<void> _registrarMovimiento() async {
    ProductoStock? productoSeleccionado;
    String tipoMovimiento = 'entrada';
    final cantidadController = TextEditingController();
    final motivoController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar movimiento de stock'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ProductoStock>(
                value: productoSeleccionado,
                items: _productos.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
                onChanged: (p) => setStateDialog(() => productoSeleccionado = p),
                decoration: const InputDecoration(labelText: 'Producto'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: tipoMovimiento,
                items: const [
                  DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                  DropdownMenuItem(value: 'salida', child: Text('Salida')),
                ],
                onChanged: (v) => setStateDialog(() => tipoMovimiento = v ?? 'entrada'),
                decoration: const InputDecoration(labelText: 'Tipo de movimiento'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: motivoController,
                decoration: const InputDecoration(labelText: 'Motivo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          Tooltip(
            message: 'Registrar movimiento de stock',
            child: ElevatedButton(
              onPressed: () {
                final producto = productoSeleccionado;
                final tipo = tipoMovimiento;
                final cantidad = int.tryParse(cantidadController.text);
                final motivo = motivoController.text.trim();
                if (producto == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Selecciona un producto.'), duration: Duration(milliseconds: 1200)));
                  return;
                }
                if (tipo != 'entrada' && tipo != 'salida') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Selecciona el tipo de movimiento.'), duration: Duration(milliseconds: 1200)));
                  return;
                }
                if (cantidad == null || cantidad <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Ingresa una cantidad válida y mayor a cero.'), duration: Duration(milliseconds: 1200)));
                  return;
                }
                if (motivo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Ingresa el motivo del movimiento.'), duration: Duration(milliseconds: 1200)));
                  return;
                }
                Navigator.pop(context, {
                  'producto': producto,
                  'tipo': tipo,
                  'cantidad': cantidad,
                  'motivo': motivo,
                });
              },
              child: const Text('Registrar'),
            ),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() { _cargando = true; });
    try {
      // Obtener el token de autenticación
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Realizar la solicitud con el token de autenticación
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/stock/movimientos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'producto_id': (result['producto'] as ProductoStock).id,
          'tipo': result['tipo'],
          'cantidad': result['cantidad'],
          'motivo': result['motivo'],
        }),
      );
      if (response.statusCode == 201) {
        await _cargarStock();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movimiento registrado'), duration: Duration(milliseconds: 1200)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Error al registrar movimiento'), duration: Duration(milliseconds: 1200)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), duration: const Duration(milliseconds: 1200)));
    } finally {
      setState(() { _cargando = false; });
    }
  }

  Future<List<MovimientoStock>> _cargarMovimientos(int productoId) async {
    try {
      // Obtener el token de autenticación
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Realizar la solicitud con el token de autenticación
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/stock/movimientos?producto_id=$productoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => MovimientoStock.fromJson(e)).toList();
      } else {
        print('❌ Error al cargar movimientos del producto: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error al cargar movimientos del producto: $e');
    }
    return [];
  }

  Future<void> _eliminarMovimiento(int movimientoId, int productoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Seguro que deseas eliminar este movimiento de stock?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;
    setState(() { _cargando = true; });
    try {
      // Obtener el token de autenticación
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Realizar la solicitud con el token de autenticación
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/stock/movimientos/$movimientoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        await _cargarStock();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movimiento eliminado'), duration: Duration(milliseconds: 1200)));
      } else {
        print('❌ Error al eliminar movimiento: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Error al eliminar movimiento'), duration: Duration(milliseconds: 1200)));
      }
    } catch (e) {
      print('❌ Error al eliminar movimiento: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), duration: const Duration(milliseconds: 1200)));
    } finally {
      setState(() { _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productosFiltrados = _productos.where((p) {
      final coincideFiltro = _filtro.isEmpty || p.nombre.toLowerCase().contains(_filtro.toLowerCase()) || p.codigo.toLowerCase().contains(_filtro.toLowerCase());
      final coincideStock = !_soloStockBajo || p.cantidad == 0;
      return coincideFiltro && coincideStock;
    }).toList();
    final anchoPantalla = MediaQuery.of(context).size.width;
    final paddingHorizontal = anchoPantalla < 600 ? 8.0 : 24.0;
    final fontSizeTitulo = anchoPantalla < 600 ? 18.0 : 22.0;
    final fontSizeSec = anchoPantalla < 600 ? 14.0 : 18.0;
    final barChartHeight = anchoPantalla < 600 ? 120.0 : 180.0;
    final barMaxHeight = anchoPantalla < 600 ? 80.0 : 140.0;
    final NumberFormat moneyFormat = NumberFormat.currency(locale: 'es', symbol: '', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeTitulo, letterSpacing: 1)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 8,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stock'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Stock
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 10),
              children: [
                Card(
                  color: Colors.white.withOpacity(0.97),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen del Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeSec + 4, color: Colors.indigo)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Productos creados:', style: TextStyle(fontSize: fontSizeSec)),
                            Row(
                              children: [
                                Text(formatNumber(totalProductosCreados)),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _refrescarStock,
                                  icon: const Icon(Icons.refresh, color: Colors.indigo),
                                  tooltip: 'Actualizar stock',
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total de productos en stock:', style: TextStyle(fontSize: fontSizeSec)),
                            Text(formatNumber(totalProductos)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total invertido (potencial):', style: TextStyle(fontSize: fontSizeSec)),
                            Text('Gs ' + moneyFormat.format(totalInversion)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Potencial de venta:', style: TextStyle(fontSize: fontSizeSec)),
                            Text('Gs ' + moneyFormat.format(totalVenta)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ganancia bruta (potencial):', style: TextStyle(fontSize: fontSizeSec)),
                            Text('Gs ' + moneyFormat.format(totalGananciaBruta)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ganancia neta (potencial, con IVA):', style: TextStyle(fontSize: fontSizeSec)),
                            Text('Gs ' + moneyFormat.format(totalGananciaNeta)),
                          ],
                        ),
                        if (totalProductos == 0)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text('⚠️ No hay stock registrado. Agrega movimientos de entrada para reflejar el stock real.', style: TextStyle(color: Colors.redAccent)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (productosFiltrados.isNotEmpty)
                  Card(
                    color: Colors.white.withOpacity(0.97),
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stock por producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeSec + 2, color: Colors.indigo)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: barChartHeight + 60, // Aumentamos la altura para dar más espacio
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: productosFiltrados.map((p) {
                                  final maxCantidad = productosFiltrados.map((e) => e.cantidad).fold<int>(0, max);
                                  final barHeight = maxCantidad > 0 ? (p.cantidad / maxCantidad * barMaxHeight).clamp(0, barMaxHeight).toDouble() : 0.0;
                                  return SizedBox(
                                    width: anchoPantalla < 600 ? 40 : 60, // Ancho fijo para cada columna
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 500),
                                          height: barHeight,
                                          width: anchoPantalla < 600 ? 16 : 24,
                                          decoration: BoxDecoration(
                                            color: p.cantidad == 0 ? Colors.redAccent : Colors.indigo,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 20, // Altura fija para el texto de cantidad
                                          child: RotatedBox(
                                            quarterTurns: 3,
                                            child: Text(
                                              formatNumber(p.cantidad),
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: fontSizeSec - 1,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 30, // Altura fija para el nombre del producto
                                          child: RotatedBox(
                                            quarterTurns: 3,
                                            child: Text(
                                              p.nombre.length > 8 ? p.nombre.substring(0, 8) + '…' : p.nombre,
                                              style: TextStyle(fontSize: fontSizeSec - 2, color: Colors.black87),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar producto por nombre o código',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onChanged: (value) => setState(() => _filtro = value),
                        style: TextStyle(fontSize: fontSizeSec),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Mostrar solo productos con stock 0',
                      child: FilterChip(
                        label: const Text('Stock 0'),
                        selected: _soloStockBajo,
                        onSelected: (v) => setState(() => _soloStockBajo = v),
                        selectedColor: Colors.redAccent.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Detalle por producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeSec + 2, color: Colors.white)),
                const SizedBox(height: 10),
                ...productosFiltrados.map((p) {
                  final gananciaBruta = (p.precioVenta - p.precioCompra) * p.cantidad;
                  final gananciaNeta = gananciaBruta - ((p.precioVenta * p.iva / 100) * p.cantidad);
                  return Card(
                    color: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Icon(
                            p.cantidad == 0 ? Icons.warning_amber_rounded : Icons.inventory_2,
                            color: p.cantidad == 0 ? Colors.redAccent : Colors.indigo,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeSec + 2,
                              color: p.cantidad == 0 ? Colors.redAccent : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Código: ${p.codigo}', style: TextStyle(fontSize: fontSizeSec)),
                          Text('Stock: ' + moneyFormat.format(p.cantidad) + ' unidades', style: TextStyle(fontSize: fontSizeSec)),
                          Text('Compra: Gs ' + moneyFormat.format(p.precioCompra) + ' | Venta: Gs ' + moneyFormat.format(p.precioVenta) + ' | IVA: ${p.iva}%', style: TextStyle(fontSize: fontSizeSec)),
                          Text('Invertido: Gs ' + moneyFormat.format(p.precioCompra * p.cantidad), style: TextStyle(fontSize: fontSizeSec)),
                          Text('Potencial de venta: Gs ' + moneyFormat.format(p.precioVenta * p.cantidad), style: TextStyle(fontSize: fontSizeSec)),
                          Text('Ganancia bruta: Gs ' + moneyFormat.format(gananciaBruta), style: TextStyle(fontSize: fontSizeSec)),
                          Text('Ganancia neta: Gs ' + moneyFormat.format(gananciaNeta), style: TextStyle(fontSize: fontSizeSec)),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                          child: Text('Historial de movimientos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[900], fontSize: fontSizeSec)),
                        ),
                        FutureBuilder<List<MovimientoStock>>(
                          future: _cargarMovimientos(p.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final movimientos = snapshot.data ?? [];
                            if (movimientos.isEmpty && p.cantidad == 0) {
                              return Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Sin movimientos registrados. El stock actual es 0. Puedes registrar una entrada para reflejar el stock real.', style: TextStyle(color: Colors.redAccent)),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add_box),
                                    label: const Text('Registrar entrada inicial'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                                    onPressed: () async {
                                      final cantidadController = TextEditingController();
                                      final motivoController = TextEditingController(text: 'Carga inicial');
                                      final result = await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Registrar entrada inicial'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: cantidadController,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(labelText: 'Cantidad'),
                                              ),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: motivoController,
                                                decoration: const InputDecoration(labelText: 'Motivo'),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                            ElevatedButton(
                                              onPressed: () {
                                                final cantidad = int.tryParse(cantidadController.text);
                                                final motivo = motivoController.text.trim();
                                                if (cantidad == null || cantidad <= 0) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una cantidad válida y mayor a cero.')));
                                                  return;
                                                }
                                                if (motivo.isEmpty) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el motivo del movimiento.')));
                                                  return;
                                                }
                                                Navigator.pop(context, {
                                                  'cantidad': cantidad,
                                                  'motivo': motivo,
                                                });
                                              },
                                              child: const Text('Registrar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (result != null) {
                                        await http.post(
                                          Uri.parse('http://localhost:3000/api/stock/movimientos'),
                                          headers: {'Content-Type': 'application/json'},
                                          body: json.encode({
                                            'producto_id': p.id,
                                            'tipo': 'entrada',
                                            'cantidad': result['cantidad'],
                                            'motivo': result['motivo'],
                                          }),
                                        );
                                        await _cargarStock();
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrada inicial registrada')));
                                      }
                                    },
                                  ),
                                ],
                              );
                            }
                            if (movimientos.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Sin movimientos registrados. El stock actual es 0. Puedes registrar una entrada para reflejar el stock real.', style: TextStyle(color: Colors.redAccent)),
                              );
                            }
                            int entradas = 0;
                            int salidas = 0;
                            for (final m in movimientos) {
                              if (m.tipo == 'entrada') entradas += m.cantidad;
                              if (m.tipo == 'salida') salidas += m.cantidad;
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...movimientos.map((m) => Card(
                                  color: m.tipo == 'entrada' ? Colors.green[50] : Colors.red[50],
                                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(m.tipo == 'entrada' ? Icons.arrow_downward : Icons.arrow_upward, color: m.tipo == 'entrada' ? Colors.green : Colors.red),
                                    title: Text('${m.tipo == 'entrada' ? 'Entrada' : 'Salida'}: ' + formatNumber(m.cantidad), style: TextStyle(color: m.tipo == 'entrada' ? Colors.green[900] : Colors.red[900], fontWeight: FontWeight.bold, fontSize: fontSizeSec)),
                                    subtitle: Text('Motivo: ${m.motivo}\nFecha: ${m.fecha}', style: TextStyle(fontSize: fontSizeSec - 2)),
                                    trailing: Tooltip(
                                      message: 'Eliminar movimiento',
                                      child: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _eliminarMovimiento(m.id, p.id),
                                      ),
                                    ),
                                  ),
                                )),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total entradas: ' + formatNumber(entradas), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: fontSizeSec)),
                                      Text('Total salidas: ' + formatNumber(salidas), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: fontSizeSec)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          // TAB 2: Historial global
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BOTÓN PARA GUARDAR Y MOVER A REPORTES
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt, size: 26),
                      label: const Text('Guardar y mover a reportes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 10,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _movimientosGlobales.isEmpty ? null : () async {
                        await _guardarReporteYLimpiar();
                      },
                    ),
                  ),
                  // RESUMEN DE VENTAS Y GRÁFICA DE PRODUCTOS VENDIDOS
                  _ResumenVentasYGrafica(movimientos: _movimientosGlobales, productos: _productos, moneyFormat: moneyFormat),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Buscar por producto o motivo',
                            prefixIcon: Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          ),
                          onChanged: (value) => setState(() => _filtroMovimientos = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _movimientosGlobales.isEmpty
                      ? const Center(child: Text('No hay movimientos registrados', style: TextStyle(color: Colors.white)))
                      : ListView(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: _movimientosGlobales.where((m) {
                            final producto = _productos.firstWhere((p) => p.id == m.productoId, orElse: () => ProductoStock(id: 0, nombre: '', codigo: '', precioCompra: 0, precioVenta: 0, iva: 0, cantidad: 0));
                            return _filtroMovimientos.isEmpty || 
                              producto.nombre.toLowerCase().contains(_filtroMovimientos.toLowerCase()) ||
                              producto.codigo.toLowerCase().contains(_filtroMovimientos.toLowerCase()) ||
                              m.motivo.toLowerCase().contains(_filtroMovimientos.toLowerCase());
                          }).map((m) {
                            final producto = _productos.firstWhere((p) => p.id == m.productoId, orElse: () => ProductoStock(id: 0, nombre: '', codigo: '', precioCompra: 0, precioVenta: 0, iva: 0, cantidad: 0));
                            return Card(
                              color: m.tipo == 'entrada' ? Colors.green[50] : Colors.red[50],
                              elevation: 8,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                                leading: Tooltip(
                                  message: m.tipo == 'entrada' ? 'Entrada de stock' : 'Salida de stock',
                                  child: Icon(m.tipo == 'entrada' ? Icons.arrow_downward : Icons.arrow_upward, color: m.tipo == 'entrada' ? Colors.green : Colors.red, size: 28),
                                ),
                                title: Text('${m.tipo == 'entrada' ? 'Entrada' : 'Salida'}: ' + formatNumber(m.cantidad), style: TextStyle(color: m.tipo == 'entrada' ? Colors.green[900] : Colors.red[900], fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Text('Producto: ${producto.nombre} | Motivo: ${m.motivo}\nFecha: ${m.fecha}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarReporteYLimpiar() async {
    // Verificar si el widget está montado antes de continuar
    if (!mounted) return;
    
    // Filtrar solo movimientos de salida por venta
    final ventas = _movimientosGlobales.where((m) => m.tipo == 'salida' && m.motivo.contains('venta_id=')).toList();
    if (ventas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay ventas para guardar en el reporte'), duration: Duration(milliseconds: 1500)));
      }
      return;
    }
    
    double totalVendidos = 0;
    double gananciaBruta = 0;
    double gananciaNeta = 0;
    
    // Construir listas directamente sin NINGÚN mapa
    final List<Map<String, dynamic>> productosVendidosList = [];
    final List<Map<String, dynamic>> ventasPorDiaList = [];
    
    for (final m in ventas) {
      totalVendidos += m.cantidad;
      final producto = _productos.firstWhere(
        (p) => p.id == m.productoId,
        orElse: () => ProductoStock(id: 0, nombre: '', codigo: '', precioCompra: 0, precioVenta: 0, iva: 0, cantidad: 0),
      );
      gananciaBruta += (producto.precioVenta - producto.precioCompra) * m.cantidad;
      gananciaNeta += ((producto.precioVenta - producto.precioCompra) * m.cantidad) - ((producto.precioVenta * producto.iva / 100) * m.cantidad);
      
      // Agregar directamente a la lista de productos
      productosVendidosList.add({
        'producto_id': m.productoId.toString(),
        'cantidad': m.cantidad,
      });
      
      // Agregar directamente a la lista de ventas por día
      final fecha = m.fecha.split('T')[0];
      ventasPorDiaList.add({
        'fecha': fecha,
        'total': (producto.precioVenta * m.cantidad).toInt(),
      });
    }
    
    // Usar ApiService para incluir el token de autenticación
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: No hay sesión activa. Por favor inicie sesión nuevamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/reportes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'ventas': totalVendidos,
        'ganancia_bruta': gananciaBruta,
        'ganancia_neta': gananciaNeta,
        'productos_vendidos': productosVendidosList,
        'ventas_por_dia': ventasPorDiaList,
      }),
    );
    
    if (response.statusCode == 201) {
      // Limpiar historial en el backend
      await http.delete(
        Uri.parse('http://localhost:3000/api/stock/movimientos/historial'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;
      
      // Limpiar movimientos locales inmediatamente
      setState(() {
        _movimientosGlobales.clear();
      });
      
      // Esperar un poco más para asegurar que todos los widgets se actualicen
      await Future.delayed(Duration(milliseconds: 100));
      
      // Forzar múltiples actualizaciones para asegurar que el resumen se limpie
      if (mounted) {
        setState(() {});
        await Future.delayed(Duration(milliseconds: 50));
        if (mounted) {
          setState(() {});
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Reporte guardado y historial limpiado exitosamente!', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Mostrar mensaje de error con más detalles
      String errorMsg;
      try {
        final errorData = json.decode(response.body);
        errorMsg = errorData['error'] ?? 'Error desconocido';
      } catch (e) {
        errorMsg = 'Error al procesar la respuesta';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar reporte. Código: ${response.statusCode}. Detalle: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Widget Panel de Salud del Stock
class _StockHealthPanel extends StatelessWidget {
  final List<ProductoStock> productos;
  final NumberFormat moneyFormat;
  const _StockHealthPanel({required this.productos, required this.moneyFormat});

  @override
  Widget build(BuildContext context) {
    final productosSinStock = productos.where((p) => p.cantidad == 0).toList();
    final productosEnRiesgo = productos.where((p) => p.cantidad > 0 && p.cantidad <= 3).toList();
    final productosSaludables = productos.where((p) => p.cantidad > 3).toList();
    return Card(
      color: Colors.white.withAlpha((255 * 0.98).round()),
      elevation: 10,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Text('Salud del Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigo[900])),
                const Spacer(),
                Tooltip(
                  message: '¿Qué significa esto? Aquí verás alertas y consejos automáticos sobre tu stock, para ayudarte a gestionar como un profesional.',
                  child: Icon(Icons.help_outline, color: Colors.indigo[300]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (productosSinStock.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.error, color: Colors.red, size: 22),
                      SizedBox(width: 6),
                      Text('Alerta: productos sin stock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  ...productosSinStock.map((p) => Padding(
                    padding: const EdgeInsets.only(left: 32, top: 2, bottom: 2),
                    child: Row(
                      children: [
                        Text('- ${p.nombre}', style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Reponer', style: TextStyle(color: Colors.indigo)),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Promocionar', style: TextStyle(color: Colors.deepOrange)),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            if (productosEnRiesgo.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                      SizedBox(width: 6),
                      Text('Atención: productos en riesgo de agotarse', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  ...productosEnRiesgo.map((p) => Padding(
                    padding: const EdgeInsets.only(left: 32, top: 2, bottom: 2),
                    child: Row(
                      children: [
                        Text('- ${p.nombre} (stock: ' + formatNumber(p.cantidad) + ')', style: const TextStyle(color: Colors.orange)),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {/* Acción de reponer */},
                          child: const Text('Reponer', style: TextStyle(color: Colors.indigo)),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            if (productosSinStock.isEmpty && productosEnRiesgo.isEmpty)
              Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 22),
                  SizedBox(width: 6),
                  Text('¡Stock saludable! No hay productos en riesgo.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Widget de resumen de ventas y gráfica de productos vendidos
class _ResumenVentasYGrafica extends StatefulWidget {
  final List<MovimientoStock> movimientos;
  final List<ProductoStock> productos;
  final NumberFormat moneyFormat;
  const _ResumenVentasYGrafica({required this.movimientos, required this.productos, required this.moneyFormat});

  @override
  State<_ResumenVentasYGrafica> createState() => _ResumenVentasYGraficaState();
}

class _ResumenVentasYGraficaState extends State<_ResumenVentasYGrafica> {
  Map<String, dynamic> _resumenLocal = { 'totalVendidos': 0, 'gananciaBruta': 0, 'gananciaNeta': 0 };

  @override
  void initState() {
    super.initState();
    _calcularResumenLocal();
  }

  @override
  void didUpdateWidget(_ResumenVentasYGrafica oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los movimientos cambiaron, recalcular el resumen
    if (oldWidget.movimientos.length != widget.movimientos.length || 
        oldWidget.movimientos.isEmpty != widget.movimientos.isEmpty ||
        widget.movimientos.isEmpty) {
      _calcularResumenLocal();
    }
  }

  void _calcularResumenLocal() {
    // Filtrar solo movimientos de salida por venta
    final ventas = widget.movimientos.where((m) => m.tipo == 'salida' && m.motivo.contains('venta_id=')).toList();
    
    // Contar ventas únicas basándose en el venta_id extraído del motivo
    Set<String> ventasUnicas = {};
    for (final m in ventas) {
      // Extraer venta_id del motivo (formato: "venta_id=123")
      final ventaIdMatch = RegExp(r'venta_id=(\d+)').firstMatch(m.motivo);
      if (ventaIdMatch != null) {
        ventasUnicas.add(ventaIdMatch.group(1)!);
      }
    }
    
    double totalVendidos = ventasUnicas.length.toDouble(); // Número de ventas únicas por ID
    double gananciaBruta = 0;
    double gananciaNeta = 0;
    
    // Calcular ganancias sumando todos los movimientos
    for (final m in ventas) {
      final producto = widget.productos.firstWhere(
        (p) => p.id == m.productoId,
        orElse: () => ProductoStock(id: 0, nombre: '', codigo: '', precioCompra: 0, precioVenta: 0, iva: 0, cantidad: 0),
      );
      gananciaBruta += (producto.precioVenta - producto.precioCompra) * m.cantidad;
      gananciaNeta += ((producto.precioVenta - producto.precioCompra) * m.cantidad) - ((producto.precioVenta * producto.iva / 100) * m.cantidad);
    }
    
    setState(() {
      _resumenLocal = {
        'totalVendidos': totalVendidos,
        'gananciaBruta': gananciaBruta,
        'gananciaNeta': gananciaNeta,
      };
    });
    
    print('📊 Resumen actualizado: ${ventasUnicas.length} ventas únicas');
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar solo movimientos de salida por venta para la gráfica
    final ventas = widget.movimientos.where((m) => m.tipo == 'salida' && m.motivo.contains('venta_id=')).toList();
    Map<int, int> productosVendidos = {};
    for (final m in ventas) {
      productosVendidos[m.productoId] = (productosVendidos[m.productoId] ?? 0) + m.cantidad.toInt();
    }
    // Ordenar productos más vendidos
    final productosOrdenados = productosVendidos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      color: Colors.white.withAlpha((255 * 0.98).round()),
      elevation: 12,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.indigo, size: 24),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('Resumen de Ventas', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo[900], letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Resumen de ventas y productos vendidos en el periodo actual. Guarda el reporte para iniciar un nuevo periodo.',
                  child: const Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Actualizar datos de ventas',
                  child: IconButton(
                    onPressed: () {
                      _calcularResumenLocal();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.indigo),
                    iconSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('Total vendidos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                Text(formatNumber(_resumenLocal['totalVendidos'] ?? 0)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Ganancia bruta:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green[900]))),
                Text('Gs ' + widget.moneyFormat.format((_resumenLocal['gananciaBruta'] ?? 0).toInt())),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Ganancia neta (con IVA):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue[900]))),
                Text('Gs ' + widget.moneyFormat.format((_resumenLocal['gananciaNeta'] ?? 0).toInt())),
              ],
            ),
            const SizedBox(height: 16),
            if (productosOrdenados.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productos más vendidos:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 15)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: productosOrdenados.map((entry) {
                          final producto = widget.productos.firstWhere((p) => p.id == entry.key, orElse: () => ProductoStock(id: 0, nombre: '', codigo: '', precioCompra: 0, precioVenta: 0, iva: 0, cantidad: 0));
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: (entry.value * 6).toDouble().clamp(10, 70),
                                  width: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(
                                        formatNumber(entry.value),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    producto.nombre.length > 8 ? producto.nombre.substring(0, 8) + '...' : producto.nombre,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}