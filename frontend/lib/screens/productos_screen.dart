import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({Key? key}) : super(key: key);

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _precioCompraController = TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _ivaController = TextEditingController();

  List<Map<String, dynamic>> _productos = [];
  bool _agregando = false;
  int? _editandoIndex;
  int? _editandoId;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final productos = await ApiService.obtenerProductos();
    setState(() {
      _productos = List<Map<String, dynamic>>.from(productos);
    });
  }

  Future<void> _agregarOActualizarProducto() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _agregando = true; });
      
      try {
        final nombre = _nombreController.text;
        final codigo = _codigoController.text;
        final precioCompra = double.parse(_precioCompraController.text);
        final precioVenta = double.parse(_precioVentaController.text);
        final cantidad = int.parse(_cantidadController.text);
        final iva = double.parse(_ivaController.text);
        
        bool exito = false;
        String mensaje = '';
        
        if (_editandoId == null) {
          final nuevo = await ApiService.crearProducto(
            nombre: nombre,
            codigo: codigo,
            precioCompra: precioCompra,
            precioVenta: precioVenta,
            cantidad: cantidad,
            iva: iva,
          );
          exito = nuevo != null;
          mensaje = exito ? '¡Producto agregado con éxito! Sigue creciendo tu inventario.' : 'Error al agregar producto';
        } else {
          final actualizado = await ApiService.actualizarProducto(
            id: _editandoId!,
            nombre: nombre,
            codigo: codigo,
            precioCompra: precioCompra,
            precioVenta: precioVenta,
            cantidad: cantidad,
            iva: iva,
          );
          exito = actualizado != null;
          mensaje = exito ? '¡Producto actualizado con éxito!' : 'Error al actualizar producto';
        }
        
        if (exito) {
          _nombreController.clear();
          _codigoController.clear();
          _precioCompraController.clear();
          _precioVentaController.clear();
          _cantidadController.clear();
          _ivaController.clear();
          _editandoIndex = null;
          _editandoId = null;
          await _cargarProductos();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: exito ? (_editandoId == null ? Colors.blueAccent : Colors.green) : Colors.red,
          ),
        );
      } catch (e) {
        String errorMessage = 'Error inesperado';
        if (e.toString().contains('Error de validación') || e.toString().contains('Error del servidor')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else if (e.toString().contains('Error de conexión')) {
          errorMessage = 'Error de conexión con el servidor. Verifica que el backend esté ejecutándose.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        setState(() { _agregando = false; });
      }
    }
  }

  void _editarProducto(int index) {
    final p = _productos[index];
    setState(() {
      _nombreController.text = p['nombre'] ?? '';
      _codigoController.text = p['codigo'] ?? '';
      _precioCompraController.text = p['precio_compra']?.toString() ?? '';
      _precioVentaController.text = p['precio_venta']?.toString() ?? '';
      _cantidadController.text = (p['stock_minimo'] ?? p['cantidad'] ?? '').toString();
      _ivaController.text = (p['iva'] ?? '0').toString();
      _editandoIndex = index;
      _editandoId = p['id'];
    });
  }

  Future<void> _eliminarProducto(int index) async {
    final id = _productos[index]['id'];
    final nombre = _productos[index]['nombre'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este producto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final exito = await ApiService.eliminarProducto(id);
    if (exito) {
      await _cargarProductos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto "$nombre" eliminado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar producto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 500,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _nombreController,
                                  decoration: const InputDecoration(labelText: 'Nombre del producto'),
                                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _codigoController,
                                  decoration: const InputDecoration(labelText: 'Código'),
                                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _precioCompraController,
                                  decoration: const InputDecoration(labelText: 'Precio de compra'),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Campo obligatorio';
                                    final n = double.tryParse(v);
                                    return (n == null || n < 0) ? 'Ingrese un valor válido' : null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _precioVentaController,
                                  decoration: const InputDecoration(labelText: 'Precio de venta'),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Campo obligatorio';
                                    final n = double.tryParse(v);
                                    return (n == null || n < 0) ? 'Ingrese un valor válido' : null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _cantidadController,
                                  decoration: const InputDecoration(labelText: 'Cantidad'),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Campo obligatorio';
                                    final n = int.tryParse(v);
                                    return (n == null || n < 0) ? 'Ingrese un valor válido' : null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _ivaController,
                                  decoration: const InputDecoration(labelText: 'IVA (%)'),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Campo obligatorio';
                                    final n = double.tryParse(v);
                                    return (n == null || n < 0 || n > 100) ? 'Ingrese un valor válido (0-100)' : null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _agregando ? null : _agregarOActualizarProducto,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: _editandoId == null ? const Color(0xFF1976D2) : Colors.green,
                                  ),
                                  child: _agregando
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(_editandoId == null ? 'Agregar producto' : 'Guardar cambios', style: const TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Productos agregados',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _productos.isEmpty
                          ? const Text('Aún no hay productos agregados.', style: TextStyle(color: Colors.white70))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _productos.length,
                              itemBuilder: (context, i) {
                                final p = _productos[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: const Icon(Icons.inventory_2, color: Color(0xFF1976D2)),
                                    title: Text(p['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Código: \t${p['codigo'] ?? ''}\nCompra: ${p['precio_compra'] ?? ''}  Venta: ${p['precio_venta'] ?? ''}  IVA: ${p['iva'] ?? '0'}%  Cantidad: ${(p['stock_minimo'] ?? p['cantidad'] ?? '')}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.green),
                                          tooltip: 'Editar',
                                          onPressed: () => _editarProducto(i),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Eliminar',
                                          onPressed: () => _eliminarProducto(i),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 