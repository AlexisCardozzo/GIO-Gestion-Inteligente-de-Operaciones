import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/emprendedor.dart';
import '../models/donacion.dart';
import '../services/fondo_solidario_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../utils/format.dart';

// Formato de moneda
final moneyFormat = NumberFormat.currency(
  locale: 'es_PY',
  symbol: '₲',
  decimalDigits: 0,
);

class FondoSolidarioScreen extends StatefulWidget {
  const FondoSolidarioScreen({Key? key}) : super(key: key);

  @override
  State<FondoSolidarioScreen> createState() => _FondoSolidarioScreenState();
}

class _FondoSolidarioScreenState extends State<FondoSolidarioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Emprendedor> _emprendedores = [];
  List<Donacion> _donaciones = [];
  Map<String, dynamic> _estadisticas = {};
  bool _cargando = true;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      await Future.wait([
        _cargarEmprendedores(),
        _cargarDonaciones(),
        _cargarEstadisticas(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarEmprendedores() async {
    try {
      final emprendedores = await FondoSolidarioService.listarEmprendedores(
        estado: _filtroEstado == 'todos' ? null : _filtroEstado,
      );
      setState(() => _emprendedores = emprendedores);
    } catch (e) {
      print('Error cargando emprendedores: $e');
    }
  }

  Future<void> _cargarDonaciones() async {
    try {
      final donaciones = await FondoSolidarioService.listarTodasDonaciones();
      setState(() => _donaciones = donaciones);
    } catch (e) {
      print('Error cargando donaciones: $e');
    }
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final stats = await FondoSolidarioService.obtenerEstadisticas();
      setState(() => _estadisticas = stats);
    } catch (e) {
      print('Error cargando estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Fondo Solidario',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Red de Historias y Donaciones',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _cargarDatos,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Estadísticas generales
                _buildEstadisticasGenerales(),
                
                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: GioColors.primaryDeep,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: GioColors.primaryDeep,
                    tabs: const [
                      Tab(text: 'Emprendedores'),
                      Tab(text: 'Donaciones'),
                      Tab(text: 'Verificaciones'),
                      Tab(text: 'Estadísticas'),
                    ],
                  ),
                ),
                
                // Contenido de tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmprendedoresTab(),
                      _buildDonacionesTab(),
                      _buildVerificacionesTab(),
                      _buildEstadisticasTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEstadisticasGenerales() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: GioColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GioColors.primaryDeep.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Recaudado',
              moneyFormat.format(_estadisticas['total_recaudado'] ?? 0),
              Icons.monetization_on,
              Colors.amber,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Comisión GIO',
              moneyFormat.format(_estadisticas['total_comision'] ?? 0),
              Icons.account_balance,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Emprendedores',
              '${_estadisticas['total_emprendedores'] ?? 0}',
              Icons.people,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmprendedoresTab() {
    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroEstado,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por estado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
                    DropdownMenuItem(value: 'aprobado', child: Text('Aprobados')),
                    DropdownMenuItem(value: 'rechazado', child: Text('Rechazados')),
                  ],
                  onChanged: (value) {
                    setState(() => _filtroEstado = value!);
                    _cargarEmprendedores();
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoNuevoEmprendedor(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GioColors.primaryDeep,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Lista de emprendedores
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _emprendedores.length,
            itemBuilder: (context, index) {
              final emprendedor = _emprendedores[index];
              return _buildEmprendedorCard(emprendedor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmprendedorCard(Emprendedor emprendedor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: GioColors.primaryLight,
          child: Text(
            emprendedor.nombre[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          emprendedor.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emprendedor.email),
            Text('Meta: ${moneyFormat.format(emprendedor.metaRecaudacion)}'),
            Text('Recaudado: ${moneyFormat.format(emprendedor.recaudado)}'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getEstadoColor(emprendedor.estado).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emprendedor.estadoDisplay,
                style: TextStyle(
                  color: _getEstadoColor(emprendedor.estado),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _manejarAccionEmprendedor(value, emprendedor),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'ver', child: Text('Ver detalles')),
            const PopupMenuItem(value: 'editar', child: Text('Editar')),
            if (emprendedor.estado == 'pendiente') ...[
              const PopupMenuItem(value: 'aprobar', child: Text('Aprobar')),
              const PopupMenuItem(value: 'rechazar', child: Text('Rechazar')),
            ],
            if (emprendedor.estado == 'aprobado')
              const PopupMenuItem(value: 'suspender', child: Text('Suspender')),
          ],
        ),
      ),
    );
  }

  Widget _buildDonacionesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _donaciones.length,
      itemBuilder: (context, index) {
        final donacion = _donaciones[index];
        return _buildDonacionCard(donacion);
      },
    );
  }

  Widget _buildDonacionCard(Donacion donacion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: GioColors.success,
          child: Icon(Icons.favorite, color: Colors.white),
        ),
        title: Text(
          'Donación de ${donacion.nombreMostrar}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto: ${moneyFormat.format(donacion.monto)}'),
            Text('Comisión GIO: ${moneyFormat.format(donacion.comisionGio)}'),
            Text('Neto: ${moneyFormat.format(donacion.montoNeto)}'),
            Text('Fecha: ${donacion.fechaDonacion.toString().substring(0, 10)}'),
            if (donacion.mensaje != null)
              Text('Mensaje: ${donacion.mensaje}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getEstadoColor(donacion.estado).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            donacion.estadoDisplay,
            style: TextStyle(
              color: _getEstadoColor(donacion.estado),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificacionesTab() {
    final pendientes = _emprendedores.where((e) => e.estado == 'pendiente').toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendientes.length,
      itemBuilder: (context, index) {
        final emprendedor = pendientes[index];
        return _buildVerificacionCard(emprendedor);
      },
    );
  }

  Widget _buildVerificacionCard(Emprendedor emprendedor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: GioColors.warning,
                  child: Text(
                    emprendedor.nombre[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emprendedor.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(emprendedor.email),
                      Text(emprendedor.telefono),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Historia:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(emprendedor.historia),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _verificarEmprendedor(emprendedor.id, 'aprobado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GioColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Aprobar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _mostrarDialogoRechazar(emprendedor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GioColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEstadisticaCard(
            'Emprendedores por Estado',
            {
              'Pendientes': _emprendedores.where((e) => e.estado == 'pendiente').length,
              'Aprobados': _emprendedores.where((e) => e.estado == 'aprobado').length,
              'Rechazados': _emprendedores.where((e) => e.estado == 'rechazado').length,
            },
          ),
          const SizedBox(height: 16),
          _buildEstadisticaCard(
            'Donaciones por Estado',
            {
              'Pendientes': _donaciones.where((d) => d.estado == 'pendiente').length,
              'Procesadas': _donaciones.where((d) => d.estado == 'procesada').length,
              'Completadas': _donaciones.where((d) => d.estado == 'completada').length,
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaCard(String title, Map<String, int> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return GioColors.warning;
      case 'aprobado': return GioColors.success;
      case 'rechazado': return GioColors.error;
      case 'suspendido': return Colors.grey;
      case 'procesada': return GioColors.info;
      case 'completada': return GioColors.success;
      case 'fallida': return GioColors.error;
      default: return Colors.grey;
    }
  }

  void _mostrarDialogoNuevoEmprendedor() {
    // Implementar diálogo para nuevo emprendedor
  }

  void _manejarAccionEmprendedor(String accion, Emprendedor emprendedor) {
    switch (accion) {
      case 'ver':
        // Navegar a detalles del emprendedor
        break;
      case 'editar':
        // Mostrar diálogo de edición
        break;
      case 'aprobar':
        _verificarEmprendedor(emprendedor.id, 'aprobado');
        break;
      case 'rechazar':
        _mostrarDialogoRechazar(emprendedor);
        break;
      case 'suspender':
        _verificarEmprendedor(emprendedor.id, 'suspendido');
        break;
    }
  }

  Future<void> _verificarEmprendedor(int id, String estado, {String? motivoRechazo}) async {
    try {
      await FondoSolidarioService.verificarEmprendedor(id, estado, motivoRechazo: motivoRechazo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emprendedor ${estado == 'aprobado' ? 'aprobado' : estado == 'rechazado' ? 'rechazado' : 'suspendido'}')),
      );
      _cargarDatos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _mostrarDialogoRechazar(Emprendedor emprendedor) {
    final motivoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Emprendedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Estás seguro de rechazar a ${emprendedor.nombreCompleto}?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _verificarEmprendedor(
                emprendedor.id, 
                'rechazado',
                motivoRechazo: motivoController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GioColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }
}
