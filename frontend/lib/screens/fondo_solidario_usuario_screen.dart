import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/emprendedor.dart';
import '../models/donacion.dart';
import '../services/fondo_solidario_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';

// Formato de moneda
final moneyFormat = NumberFormat.currency(
  locale: 'es_PY',
  symbol: '₲',
  decimalDigits: 0,
);

class FondoSolidarioUsuarioScreen extends StatefulWidget {
  const FondoSolidarioUsuarioScreen({Key? key}) : super(key: key);

  @override
  State<FondoSolidarioUsuarioScreen> createState() => _FondoSolidarioUsuarioScreenState();
}

class _FondoSolidarioUsuarioScreenState extends State<FondoSolidarioUsuarioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Emprendedor> _emprendedores = [];
  List<Donacion> _misDonaciones = [];
  List<Donacion> _donacionesRecibidas = [];
  Map<String, dynamic> _estadisticas = {};
  bool _cargando = true;
  bool _solicitandoSocio = false;
  
  // Controllers para el formulario de solicitud
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _historiaController = TextEditingController();
  final TextEditingController _metaController = TextEditingController();
  
  // Controllers para donación
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();
  bool _donacionAnonima = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _historiaController.dispose();
    _metaController.dispose();
    _montoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      await Future.wait([
        _cargarEmprendedores(),
        _cargarMisDonaciones(),
        _cargarDonacionesRecibidas(),
        _cargarEstadisticas(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando datos: $e')),
      );
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _cargarEmprendedores() async {
    try {
      final emprendedores = await FondoSolidarioService.listarEmprendedoresVerificados();
      setState(() {
        _emprendedores = emprendedores;
      });
    } catch (e) {
      print('Error cargando emprendedores: $e');
    }
  }

  Future<void> _cargarMisDonaciones() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId != null) {
        final donaciones = await FondoSolidarioService.listarDonacionesUsuario(userId);
        setState(() {
          _misDonaciones = donaciones;
        });
      }
    } catch (e) {
      print('Error cargando mis donaciones: $e');
    }
  }

  Future<void> _cargarDonacionesRecibidas() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId != null) {
        // Buscar si el usuario es emprendedor
        final emprendedores = await FondoSolidarioService.listarEmprendedores();
        final miEmprendedor = emprendedores.where((e) => e.userId == userId).firstOrNull;
        
        if (miEmprendedor != null && miEmprendedor.estado == 'aprobado') {
          final donaciones = await FondoSolidarioService.listarDonacionesEmprendedor(miEmprendedor.id);
          setState(() {
            _donacionesRecibidas = donaciones;
          });
        } else {
          setState(() {
            _donacionesRecibidas = [];
          });
        }
      }
    } catch (e) {
      print('Error cargando donaciones recibidas: $e');
    }
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final estadisticas = await FondoSolidarioService.obtenerEstadisticas();
      setState(() {
        _estadisticas = estadisticas;
      });
    } catch (e) {
      print('Error cargando estadísticas: $e');
    }
  }

  Future<void> _solicitarSerSocio() async {
    if (_nombreController.text.isEmpty ||
        _apellidoController.text.isEmpty ||
        _historiaController.text.isEmpty ||
        _metaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _solicitandoSocio = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final meta = double.tryParse(_metaController.text) ?? 0;
      
      await FondoSolidarioService.registrarEmprendedor({
        'user_id': userId,
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'historia': _historiaController.text,
        'meta_recaudacion': meta,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada exitosamente. GIO revisará tu solicitud.'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar formulario
      _nombreController.clear();
      _apellidoController.clear();
      _historiaController.clear();
      _metaController.clear();

      // Cerrar modal
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando solicitud: $e')),
      );
    } finally {
      setState(() {
        _solicitandoSocio = false;
      });
    }
  }

  Future<void> _realizarDonacion(Emprendedor emprendedor) async {
    if (_montoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un monto')),
      );
      return;
    }

    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un monto válido')),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await FondoSolidarioService.realizarDonacion({
        'emprendedor_id': emprendedor.id,
        'donante_id': userId,
        'monto': monto,
        'mensaje': _mensajeController.text,
        'anonimo': _donacionAnonima,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Donación realizada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar formulario
      _montoController.clear();
      _mensajeController.clear();
      _donacionAnonima = false;

      // Cerrar modal y recargar datos
      Navigator.of(context).pop();
      _cargarDatos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error realizando donación: $e')),
      );
    }
  }

  void _mostrarFormularioSolicitud() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar ser Socio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _historiaController,
                decoration: const InputDecoration(
                  labelText: 'Tu Historia',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _metaController,
                decoration: const InputDecoration(
                  labelText: 'Meta de Recaudación (₲)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _solicitandoSocio ? null : _solicitarSerSocio,
            child: _solicitandoSocio
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioDonacion(Emprendedor emprendedor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Donar a ${emprendedor.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto (₲)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mensajeController,
                decoration: const InputDecoration(
                  labelText: 'Mensaje (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Donación anónima'),
                value: _donacionAnonima,
                onChanged: (value) {
                  setState(() {
                    _donacionAnonima = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _realizarDonacion(emprendedor),
            child: const Text('Donar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fondo Solidario'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
                 bottom: TabBar(
           controller: _tabController,
           tabs: const [
             Tab(text: 'Historias', icon: Icon(Icons.article)),
             Tab(text: 'Mis Donaciones', icon: Icon(Icons.favorite)),
             Tab(text: 'Donaciones Recibidas', icon: Icon(Icons.receipt)),
             Tab(text: 'Solicitar Socio', icon: Icon(Icons.person_add)),
           ],
         ),
      ),
             body: _cargando
           ? const Center(child: CircularProgressIndicator())
           : TabBarView(
               controller: _tabController,
               children: [
                 _buildHistoriasTab(),
                 _buildMisDonacionesTab(),
                 _buildDonacionesRecibidasTab(),
                 _buildSolicitarSocioTab(),
               ],
             ),
    );
  }

  Widget _buildHistoriasTab() {
    return RefreshIndicator(
      onRefresh: _cargarEmprendedores,
      child: _emprendedores.isEmpty
          ? const Center(
              child: Text(
                'No hay historias disponibles',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _emprendedores.length,
              itemBuilder: (context, index) {
                final emprendedor = _emprendedores[index];
                return _buildEmprendedorCard(emprendedor);
              },
            ),
    );
  }

  Widget _buildEmprendedorCard(Emprendedor emprendedor) {
    final progreso = emprendedor.metaRecaudacion > 0
        ? (emprendedor.recaudado / emprendedor.metaRecaudacion).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  backgroundColor: const Color(0xFF1E3A8A),
                  child: Text(
                    '${emprendedor.nombre[0]}${emprendedor.apellido[0]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${emprendedor.nombre} ${emprendedor.apellido}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Emprendedor Verificado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              emprendedor.historia,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meta: ${moneyFormat.format(emprendedor.metaRecaudacion)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Recaudado: ${moneyFormat.format(emprendedor.recaudado)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _mostrarFormularioDonacion(emprendedor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Donar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progreso * 100).toStringAsFixed(1)}% completado',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMisDonacionesTab() {
    return RefreshIndicator(
      onRefresh: _cargarMisDonaciones,
      child: _misDonaciones.isEmpty
          ? const Center(
              child: Text(
                'No has realizado donaciones aún',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _misDonaciones.length,
              itemBuilder: (context, index) {
                final donacion = _misDonaciones[index];
                return _buildDonacionCard(donacion);
              },
            ),
    );
  }

  Widget _buildDonacionesRecibidasTab() {
    return RefreshIndicator(
      onRefresh: _cargarDonacionesRecibidas,
      child: _donacionesRecibidas.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No has recibido donaciones',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Las donaciones aparecerán aquí cuando seas socio aprobado',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Resumen de donaciones recibidas
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Recibido',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              moneyFormat.format(_donacionesRecibidas.fold<double>(
                                0, (sum, d) => sum + d.monto)),
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _donacionesRecibidas.length,
                    itemBuilder: (context, index) {
                      final donacion = _donacionesRecibidas[index];
                      return _buildDonacionRecibidaCard(donacion);
                    },
                    shrinkWrap: false,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDonacionCard(Donacion donacion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E3A8A),
          child: Icon(
            Icons.favorite,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Donación de ${moneyFormat.format(donacion.monto)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                         if (donacion.mensaje?.isNotEmpty == true)
               Text(donacion.mensaje!),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(donacion.fechaDonacion)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (donacion.anonimo)
              Text(
                'Donación anónima',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getEstadoColor(donacion.estado),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            donacion.estado,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDonacionRecibidaCard(Donacion donacion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Icon(
                    Icons.favorite,
                    color: Colors.green[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donación recibida',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'De: ${donacion.anonimo ? 'Anónimo' : 'Usuario'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  moneyFormat.format(donacion.monto),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            if (donacion.mensaje?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  donacion.mensaje!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(donacion.fechaDonacion),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(donacion.estado),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donacion.estado,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSolicitarSocioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 32,
                        color: const Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Solicitar ser Socio',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¿Tienes una historia que contar? ¿Quieres recibir apoyo de la comunidad?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Como socio podrás:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem('✅ Compartir tu historia con la comunidad'),
                  _buildBenefitItem('✅ Recibir donaciones de usuarios'),
                  _buildBenefitItem('✅ Establecer metas de recaudación'),
                  _buildBenefitItem('✅ Recibir apoyo y motivación'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _mostrarFormularioSolicitud,
                      icon: const Icon(Icons.send),
                      label: const Text('Solicitar ser Socio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Estadísticas del Fondo Solidario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    'Total de Emprendedores',
                    _estadisticas['totalEmprendedores']?.toString() ?? '0',
                    Icons.people,
                  ),
                  _buildStatItem(
                    'Total Recaudado',
                    moneyFormat.format(_estadisticas['totalRecaudado'] ?? 0),
                    Icons.attach_money,
                  ),
                  _buildStatItem(
                    'Total de Donaciones',
                    _estadisticas['totalDonaciones']?.toString() ?? '0',
                    Icons.favorite,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
