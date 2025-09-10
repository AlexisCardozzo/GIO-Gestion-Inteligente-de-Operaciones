import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/download_service.dart';
import '../services/ticket_service.dart';

// Eliminamos la importación de dart:html para permitir la compilación en Android
// Usamos una función auxiliar para abrir URLs

class Producto {
  final int id;
  final String nombre;
  final String codigo;
  final double precioVenta;
  final int stock;

  Producto(
      {required this.id,
      required this.nombre,
      required this.codigo,
      required this.precioVenta,
      required this.stock});

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      precioVenta: double.parse(json['precio_venta'].toString()),
      stock: json['stock_minimo'] ?? 0,
    );
  }
}



class CarritoItem {
  final Producto producto;
  int cantidad;
  CarritoItem({required this.producto, this.cantidad = 1});
}

class VentasScreen extends StatefulWidget {
  const VentasScreen({Key? key}) : super(key: key);

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _ciRucController = TextEditingController();
  final TextEditingController _nombreClienteController =
      TextEditingController();
  final TextEditingController _celularClienteController =
      TextEditingController();
  List<Producto> _productos = [];
  List<CarritoItem> _carrito = [];
  bool _buscando = false;
  bool _registrando = false;
  String? _mensaje;
  int? _ultimaVentaId;
  Map<String, dynamic>? _ultimaVenta;
  Map<String, dynamic>? _clienteSeleccionado;
  String _formaPago = 'efectivo'; // Nueva variable para forma de pago
  bool _generandoTicket = false;
  final DownloadService downloadService = DownloadService();


  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
            Color(0xFF60A5FA),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;
            return isMobile ? _buildMobileLayout() : _buildDesktopLayout();
          },
        ),
      ),
    );
  }

  Future<void> _buscarProductos() async {
    if (_busquedaController.text.isEmpty) return;

    setState(() {
      _buscando = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/api/articulos?busqueda=${_busquedaController.text}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _productos = (data['data'] as List)
              .map((json) => Producto.fromJson(json))
              .toList();
        });

        // Debug: mostrar información de la búsqueda
        print(
            'Búsqueda: "${_busquedaController.text}" - Productos encontrados: ${_productos.length}');
        for (var producto in _productos) {
          print('- ${producto.nombre} (${producto.codigo})');
        }
      } else {
        print('Error en búsqueda: Status ${response.statusCode}');
        setState(() {
          _productos = [];
        });
      }
    } catch (e) {
      print('Error de conexión: $e');
      setState(() {
        _productos = [];
      });
    } finally {
      setState(() {
        _buscando = false;
      });
    }
  }

  void _agregarAlCarrito(Producto producto) {
    setState(() {
      // Buscar si el producto ya existe en el carrito
      final existingIndex =
          _carrito.indexWhere((item) => item.producto.id == producto.id);

      if (existingIndex == -1) {
        // Producto no existe en el carrito, agregarlo
        _carrito.add(CarritoItem(producto: producto, cantidad: 1));
      } else {
        // Producto ya existe, incrementar cantidad
        _carrito[existingIndex].cantidad++;
      }
    });
  }

  void _cambiarCantidad(CarritoItem item, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        _carrito.remove(item);
      } else {
        item.cantidad = nuevaCantidad;
      }
    });
  }

  void _mostrarNotificacion(String mensaje, bool esExito) {
    setState(() {
      _mensaje = mensaje;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mensaje = null;
        });
      }
    });
  }

  Future<void> _registrarVenta() async {
    if (_carrito.isEmpty) return;

    setState(() {
      _registrando = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      // Crear cliente si no existe
      int? clienteId = _clienteSeleccionado?['id'];
      if (clienteId == null && _nombreClienteController.text.isNotEmpty) {
        try {
          print('🔄 Creando cliente nuevo...');
          final clienteResponse = await http.post(
            Uri.parse('http://localhost:3000/api/clientes'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'nombre': _nombreClienteController.text,
              'ci_ruc': _ciRucController.text.isNotEmpty
                  ? _ciRucController.text
                  : null,
              'celular': _celularClienteController.text,
              'usuario_id': authProvider.userId, // Asegúrate de que authProvider.userId esté disponible
            }),
          );

          print('📡 Respuesta creación cliente: ${clienteResponse.statusCode}');
          print('📄 Body: ${clienteResponse.body}');

          if (clienteResponse.statusCode == 201) {
            final clienteData = json.decode(clienteResponse.body);
            clienteId = clienteData['data']['id'];
            print('✅ Cliente creado exitosamente: ID $clienteId');
          } else {
            print('❌ Error creando cliente: ${clienteResponse.statusCode}');
            print('❌ Error detalle: ${clienteResponse.body}');
            _mostrarNotificacion(
                'Error al crear cliente. Verifica los datos.', false);
            setState(() {
              _registrando = false;
            });
            return;
          }
        } catch (e) {
          print('❌ Error de conexión creando cliente: $e');
          _mostrarNotificacion('Error de conexión al crear cliente', false);
          setState(() {
            _registrando = false;
          });
          return;
        }
      }

      // Validar que tenemos un cliente válido
      if (clienteId == null) {
        if (_nombreClienteController.text.isEmpty ||
            _celularClienteController.text.isEmpty) {
          _mostrarNotificacion(
              'Debes completar el nombre y celular del cliente', false);
        } else {
          _mostrarNotificacion(
              'Error al crear cliente. Verifica los datos.', false);
        }
        return;
      }

      // Calcular total de la venta
      final total = _carrito.fold<double>(
          0, (sum, item) => sum + (item.producto.precioVenta * item.cantidad));

      // Registrar venta
      final ventaData = {
        'cliente_id': clienteId,
        'total': total,
        'forma_pago': _formaPago, // Incluir la forma de pago
        'articulos': _carrito // Cambiado de 'items' a 'articulos'
            .map((item) => {
                  'producto_id': item.producto.id,
                  'cantidad': item.cantidad,
                  'precio_unitario': item.producto.precioVenta,
                  'subtotal': item.producto.precioVenta * item.cantidad,
                })
            .toList(),
      };

      print('🔄 Enviando datos de venta: ${json.encode(ventaData)}');
      
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/ventas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(ventaData),
      );

      print('📡 Respuesta registro venta: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final ventaData = data['data']['venta'];

        // Preparar datos de la venta para el ticket
        final ventaCompleta = {
          'id': ventaData['id'],
          'fecha': ventaData['fecha_hora'] ?? DateTime.now().toIso8601String(),
          'total': ventaData['total'],
          'forma_pago': ventaData['forma_pago'],
          'usuario_nombre': authProvider.user?.nombre ?? 'Vendedor',
          'cliente_nombre': _nombreClienteController.text,
          'items': _carrito
              .map((item) => {
                    'nombre': item.producto.nombre,
                    'cantidad': item.cantidad,
                    'precio_unitario': item.producto.precioVenta,
                    'subtotal': item.producto.precioVenta * item.cantidad,
                  })
              .toList(),
        };
        
        setState(() {
          _ultimaVentaId = ventaData['id'];
          _ultimaVenta = ventaCompleta;
        });
        _mostrarNotificacion('Venta registrada exitosamente', true);

        // Actualizar movimientos de stock para que se refleje en el módulo de stock
        await _actualizarMovimientosStock();

        // Mostrar diálogo para generar ticket
        _mostrarDialogoTicket(ventaCompleta);

        // Limpiar carrito
        setState(() {
          _carrito.clear();
          _ciRucController.clear();
          _nombreClienteController.clear();
          _celularClienteController.clear();
          _clienteSeleccionado = null;
        });
      } else {
        final errorData = json.decode(response.body);
        _mostrarNotificacion('Error al registrar la venta: ${errorData['error'] ?? 'Error desconocido'}', false);
      }
    } catch (e) {
      print('❌ Error de conexión registrando venta: $e');
      _mostrarNotificacion('Error de conexión: $e', false);
    } finally {
      setState(() {
        _registrando = false;
      });
    }

  }





  Widget _buildSearchPanel(bool isMobile) {


    return Container(
      margin: EdgeInsets.all(isMobile ? 6 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: isMobile ? 15 : 20,
            offset: Offset(0, isMobile ? 5 : 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMobile ? 16 : 20),
                topRight: Radius.circular(isMobile ? 16 : 20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.search, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Búsqueda de Productos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Encuentra y agrega productos al carrito',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Campo de búsqueda
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: TextField(
              controller: _busquedaController,
              onChanged: (value) {
                if (value.length >= 2) {
                  _buscarProductos();
                } else {
                  setState(() {
                    _productos = [];
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código (mín. 2 caracteres)...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _buscando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon:
                            const Icon(Icons.search, color: Color(0xFF3B82F6)),
                        onPressed: _buscarProductos,
                        tooltip: 'Buscar productos',
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // Lista de productos
          Expanded(
            child: _productos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: isMobile ? 48 : 64,
                          color: Colors.grey.withAlpha((255 * 0.5).round()),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Busca productos para comenzar',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final producto = _productos[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF8FAFC)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((255 * 0.1).round()),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                          leading: Container(
                            width: isMobile ? 40 : 50,
                            height: isMobile ? 40 : 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory,
                                color: Colors.white),
                          ),
                          title: Text(
                            producto.nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Código: ${producto.codigo}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: producto.stock > 0
                                      ? const Color(0xFF059669).withAlpha((255 * 0.1).round())
                                      : Colors.red.withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Stock: ${producto.stock}',
                                  style: TextStyle(
                                    color: producto.stock > 0
                                        ? const Color(0xFF059669)
                                        : Colors.red,
                                    fontSize: isMobile ? 10 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${producto.precioVenta.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: producto.stock > 0
                                    ? () => _agregarAlCarrito(producto)
                                    : null,
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 16),
                                label: const Text('Agregar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
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

  Widget _buildCartPanel() {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del carrito
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_cart,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Carrito de Compras',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_carrito.length} producto(s) en el carrito',
                        style: TextStyle(
                          color: Colors.white.withAlpha((255 * 0.9).round()),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_carrito.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido del carrito
          Expanded(
            child: _carrito.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'El carrito está vacío',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega productos para continuar',
                          style: TextStyle(
                            color: Colors.grey.withAlpha((255 * 0.7).round()),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      final item = _carrito[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF8FAFC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.producto.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _cambiarCantidad(item, 0),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'Eliminar del carrito',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Precio: \$${item.producto.precioVenta.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _cambiarCantidad(
                                          item, item.cantidad - 1),
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${item.cantidad}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _cambiarCantidad(
                                          item, item.cantidad + 1),
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Subtotal: \$${(item.producto.precioVenta * item.cantidad).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Total del carrito
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_carrito.fold<double>(0, (sum, item) => sum + (item.producto.precioVenta * item.cantidad)).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientPanel() {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del panel de cliente
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF60A5FA).withAlpha((255 * 0.1).round()),
                  const Color(0xFF93C5FD).withAlpha((255 * 0.05).round())
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Datos del Cliente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),

          // Campos del cliente
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _ciRucController,
                  decoration: InputDecoration(
                    labelText: 'CI/RUC',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.badge),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) async {
                    if (value.length >= 6) {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final token = authProvider.token;

                      final cliente =
                          await ApiService.buscarClientePorCiOCelular(
                              ciRuc: value, token: token);
                      if (cliente != null) {
                        setState(() {
                          _clienteSeleccionado = cliente;
                          _nombreClienteController.text =
                              cliente['nombre'] ?? '';
                          _celularClienteController.text =
                              cliente['celular'] ?? '';
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreClienteController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _celularClienteController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Celular',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) async {
                    if (value.length >= 6) {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final token = authProvider.token;

                      final cliente =
                          await ApiService.buscarClientePorCiOCelular(
                              celular: value, token: token);
                      if (cliente != null) {
                        setState(() {
                          _clienteSeleccionado = cliente;
                          if (_ciRucController.text.isEmpty) {
                            _ciRucController.text = cliente['ci_ruc'] ?? '';
                          }
                          _nombreClienteController.text =
                              cliente['nombre'] ?? '';
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      margin: const EdgeInsets.all(6),
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: _carrito.isNotEmpty ? _registrarVenta : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: const Color(0xFF059669).withAlpha((255 * 0.3).round()),
        ),
        child: _registrando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Registrar Venta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMessagePanel() {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mensaje!.contains('exitosamente')
            ? const Color(0xFF059669).withAlpha((255 * 0.1).round())
            : Colors.red.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _mensaje!.contains('exitosamente')
              ? const Color(0xFF059669).withAlpha((255 * 0.3).round())
              : Colors.red.withAlpha((255 * 0.3).round()),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _mensaje!.contains('exitosamente')
                ? Icons.check_circle
                : Icons.error_outline,
            color: _mensaje!.contains('exitosamente')
                ? const Color(0xFF059669)
                : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _mensaje!,
              style: TextStyle(
                color: _mensaje!.contains('exitosamente')
                    ? const Color(0xFF059669)
                    : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Container(
      margin: const EdgeInsets.all(6),
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text('Descargar Ticket XML'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          _mostrarNotificacion('Descargando ticket XML...', true);
          // Usar el servicio de descargas que maneja diferentes plataformas y entornos
          downloadService.downloadTicketXml(_ultimaVentaId);
        },
      ),
    );
  }

  // Métodos específicos para móvil
  Widget _buildMobileSearchPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header compacto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Buscar Productos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Campo de búsqueda compacto
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaController,
              onChanged: (value) {
                if (value.length >= 2) {
                  _buscarProductos();
                } else {
                  setState(() {
                    _productos = [];
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                  onPressed: _buscarProductos,
                  tooltip: 'Buscar productos',
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ),

          // Lista de productos compacta
          SizedBox(
            height: 200,
            child: _productos.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Busca productos para agregar',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final producto = _productos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(
                            producto.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Stock: ${producto.stock} | \$${producto.precioVenta.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            onPressed: producto.stock > 0
                                ? () => _agregarAlCarrito(producto)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Agregar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildMobileCartPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header compacto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Carrito de Compras',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_carrito.length} items',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Contenido del carrito compacto
          SizedBox(
            height: 150,
            child: _carrito.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'El carrito está vacío',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      final item = _carrito[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(
                            item.producto.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '\$${item.producto.precioVenta.toStringAsFixed(0)} x ${item.cantidad}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _cambiarCantidad(item, item.cantidad - 1),
                                icon: const Icon(Icons.remove, size: 16),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                              Text(
                                '${item.cantidad}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _cambiarCantidad(item, item.cantidad + 1),
                                icon: const Icon(Icons.add, size: 16),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFDCFCE7),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Total compacto
          if (_carrito.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${_carrito.fold<double>(0, (sum, item) => sum + (item.producto.precioVenta * item.cantidad)).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileClientPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header compacto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E3A8A), const Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Datos del Cliente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Campos compactos
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _ciRucController,
                  onChanged: (value) async {
                    if (value.length >= 6) {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final token = authProvider.token;

                      final cliente =
                          await ApiService.buscarClientePorCiOCelular(
                              ciRuc: value, token: token);
                      if (cliente != null) {
                        setState(() {
                          _clienteSeleccionado = cliente;
                          _nombreClienteController.text =
                              cliente['nombre'] ?? '';
                          _celularClienteController.text =
                              cliente['celular'] ?? '';
                        });
                      }
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'CI/RUC',
                    prefixIcon:
                        const Icon(Icons.badge, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF3B82F6), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreClienteController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon:
                        const Icon(Icons.person, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF3B82F6), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _celularClienteController,
                  onChanged: (value) async {
                    if (value.length >= 6) {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final token = authProvider.token;

                      final cliente =
                          await ApiService.buscarClientePorCiOCelular(
                              celular: value, token: token);
                      if (cliente != null) {
                        setState(() {
                          _clienteSeleccionado = cliente;
                          if (_ciRucController.text.isEmpty) {
                            _ciRucController.text = cliente['ci_ruc'] ?? '';
                          }
                          _nombreClienteController.text =
                              cliente['nombre'] ?? '';
                        });
                      }
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Celular',
                    prefixIcon:
                        const Icon(Icons.phone, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF3B82F6), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRegisterButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _carrito.isNotEmpty ? _registrarVenta : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _registrando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Registrar Venta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildMobileMessagePanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mensaje!.contains('éxito')
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _mensaje!.contains('éxito')
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _mensaje!.contains('éxito') ? Icons.check_circle : Icons.error,
            color: _mensaje!.contains('éxito')
                ? const Color(0xFF059669)
                : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _mensaje!,
              style: TextStyle(
                color: _mensaje!.contains('éxito')
                    ? const Color(0xFF059669)
                    : const Color(0xFFDC2626),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDownloadButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _mostrarNotificacion('Descargando ticket XML...', true);
          // Usar el servicio de descargas que maneja diferentes plataformas y entornos
          downloadService.downloadTicketXml(_ultimaVentaId);
        },
        icon: const Icon(Icons.download, color: Colors.white, size: 20),
        label: const Text(
          'Descargar Comprobante',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Método para actualizar movimientos de stock después de una venta
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de retroceso
            

            // Panel de búsqueda compacto
            _buildMobileSearchPanel(),

            // Panel del carrito compacto
            _buildMobileCartPanel(),

            // Panel de cliente compacto
            _buildMobileClientPanel(),

            // Selector de forma de pago móvil
            

            // Botón de registro
            _buildMobileRegisterButton(),

            // Mensajes
            if (_mensaje != null) _buildMobileMessagePanel(),

            // Botón de descarga
            if (_ultimaVentaId != null) _buildMobileDownloadButton(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Botón de retroceso


        // Contenido principal
        Expanded(
          child: Row(
            children: [
              // Panel izquierdo - Productos
              Expanded(
                flex: 2,
                child: _buildSearchPanel(false),
              ), // Cierre del Expanded del panel izquierdo

              // Panel derecho - Carrito, cliente y forma de pago
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 100, // Restamos el espacio del botón de retroceso
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: 300, child: _buildCartPanel()),
                        _buildClientPanel(),
                        
                        _buildRegisterButton(),
                        if (_mensaje != null) _buildMessagePanel(),
                        if (_ultimaVentaId != null) _buildDownloadButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _actualizarMovimientosStock() async {
    try {
      // Esperar un poco para que el backend procese la venta
      await Future.delayed(const Duration(milliseconds: 500));

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      // Hacer múltiples intentos para obtener los movimientos actualizados
      for (int intento = 1; intento <= 3; intento++) {
        print(
            '🔄 Intentando actualizar movimientos de stock (intento $intento/3)...');

        final response = await http.get(
          Uri.parse('http://localhost:3000/api/stock/movimientos/todos'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final movimientos = data['data'] as List;
          print(
              '✅ Movimientos de stock actualizados: ${movimientos.length} movimientos');

          // Si encontramos movimientos, salir del bucle
          if (movimientos.isNotEmpty) {
            break;
          }
        } else {
          print('❌ Error al obtener movimientos: ${response.statusCode}');
        }

        // Esperar antes del siguiente intento
        if (intento < 3) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } catch (e) {
      print('Error al actualizar movimientos de stock: $e');
    }
    return;
  }
  
  // Método para mostrar el diálogo de opciones de ticket
  void _mostrarDialogoTicket(Map<String, dynamic> venta) {
    showDialog(
      context: this.context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ticket de Venta',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              '¿Qué deseas hacer con el ticket de esta venta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('Ver Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _generandoTicket = true;
                });
                try {
                  await TicketService.mostrarVistaPrevia(this.context, venta);
                } catch (e) {
                  _mostrarNotificacion('Error al generar ticket: $e', false);
                } finally {
                  setState(() {
                    _generandoTicket = false;
                  });
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Compartir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _generandoTicket = true;
                });
                try {
                  await TicketService.compartirTicket(venta);
                  _mostrarNotificacion('Ticket compartido exitosamente', true);
                } catch (e) {
                  _mostrarNotificacion('Error al compartir ticket: $e', false);
                } finally {
                  setState(() {
                    _generandoTicket = false;
                  });
                }
              },
            ),
          ],
        );
      },
    );
}



  







}
