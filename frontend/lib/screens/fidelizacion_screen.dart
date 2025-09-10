import 'package:flutter/material.dart';
import '../services/fidelizacion_service.dart';
import '../utils/format.dart';
import 'fidelizacion_detalle_screen.dart' hide Text;
import 'editar_campania_screen.dart';
import '../utils/colors.dart';

class FidelizacionScreen extends StatefulWidget {
  const FidelizacionScreen({super.key});

  @override
  State<FidelizacionScreen> createState() => _FidelizacionScreenState();
}

class _FidelizacionScreenState extends State<FidelizacionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _campaniasFuture;
  late Future<List<dynamic>> _clientesFielesFuture;
  late Future<Map<String, dynamic>?> _estadisticasFuture;
  String _filtroCampanias = 'activas'; // 'activas' o 'inactivas'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _campaniasFuture = _filtroCampanias == 'activas' 
          ? FidelizacionService.listarCampanias()
          : FidelizacionService.listarCampaniasInactivas();
      _clientesFielesFuture = FidelizacionService.listarClientesFieles();
      _estadisticasFuture = FidelizacionService.obtenerEstadisticas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // Azul profundo
              Color(0xFF3B82F6), // Azul medio
              Color(0xFF60A5FA), // Azul claro
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con estadísticas
              _buildHeader(),
              
              // Tabs
              _buildTabs(),
              
              // Contenido de tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCampaniasTab(),
                    _buildClientesFielesTab(),
                    _buildEstadisticasTab(),
                    _buildClientesRiesgoTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCrearCampania(),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Campaña'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Botón de retroceso
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Volver',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.loyalty,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fidelización',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gestiona tus campañas y clientes fieles',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, dynamic>?>(
            future: _estadisticasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              
              final stats = snapshot.data ?? {};
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Campañas Activas',
                      '${stats['campanias_activas'] ?? 0}',
                      Icons.campaign,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Clientes Fieles',
                      '${stats['total_clientes_participantes'] ?? 0}',
                      Icons.people,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: FidelizacionService.listarClientesRiesgo(),
                      builder: (context, clientesSnapshot) {
                        int clientesEnRiesgo = 0;
                        if (clientesSnapshot.hasData) {
                          clientesEnRiesgo = clientesSnapshot.data!.length;
                        }
                        
                        return _buildStatCard(
                          'Clientes en Riesgo',
                          '$clientesEnRiesgo',
                          Icons.warning_amber,
                          color: Colors.orange,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.15).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.2).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF1E3A8A),
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Campañas'),
          Tab(text: 'Clientes Fieles'),
          Tab(text: 'Estadísticas'),
          Tab(text: 'Clientes en Riesgo'),
        ],
      ),
    );
  }

  Widget _buildCampaniasTab() {
    return Column(
      children: [
        // Filtro de campañas
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.1).round()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'activas',
                      label: Text('Activas'),
                      icon: Icon(Icons.check_circle),
                    ),
                    ButtonSegment<String>(
                      value: 'inactivas',
                      label: Text('Inactivas'),
                      icon: Icon(Icons.pause_circle_outline),
                    ),
                  ],
                  selected: {_filtroCampanias},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _filtroCampanias = newSelection.first;
                      _cargarDatos();
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Color(0xFF1E3A8A);
                        }
                        return Colors.white.withOpacity(0.1);
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.white70;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de campañas
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _campaniasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
              
          if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white70, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar campañas',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final campanias = snapshot.data ?? [];
              
              if (campanias.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _filtroCampanias == 'activas' ? Icons.campaign_outlined : Icons.pause_circle_outline,
                        color: Colors.white70,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filtroCampanias == 'activas' 
                            ? 'No hay campañas activas'
                            : 'No hay campañas inactivas',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _filtroCampanias == 'activas'
                            ? 'Crea una nueva campaña para comenzar'
                            : 'Todas las campañas están activas',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

          return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: campanias.length,
            itemBuilder: (context, index) {
                  final campania = campanias[index];
                  return _buildCampaniaCard(campania);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCampaniaCard(Map<String, dynamic> campania) {
    final bool isActiva = campania['activa'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActiva ? Colors.white : Colors.white.withAlpha((255 * 0.7).round()),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isActiva ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FidelizacionDetalleScreen(campania: campania),
            ),
          ).then((_) => _cargarDatos());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActiva ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: isActiva ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campania['nombre'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isActiva ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActiva ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActiva ? 'ACTIVA' : 'INACTIVA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${campania['fecha_inicio']} - ${campania['fecha_fin']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActiva ? Colors.grey[500] : Colors.grey[500],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'editar') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditarCampaniaScreen(campania: campania),
                          ),
                        ).then((_) => _cargarDatos());
                      } else if (value == 'toggle') {
                        await _toggleCampania(campania);
                      } else if (value == 'eliminar') {
                        _eliminarCampania(campania);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 16),
                            const SizedBox(width: 8),
                            const Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActiva ? Icons.pause : Icons.play_arrow,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(isActiva ? 'Desactivar' : 'Activar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: isActiva ? Colors.grey[500] : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (campania['descripcion'] != null && campania['descripcion'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  campania['descripcion'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isActiva ? Colors.grey[500] : Colors.grey[500],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatItem(
                    'Requisitos',
                    '${campania['total_requisitos'] ?? 0}',
                    Icons.checklist,
                    isActiva,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Beneficios',
                    '${campania['total_beneficios'] ?? 0}',
                    Icons.card_giftcard,
                    isActiva,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Participantes',
                    '${campania['total_clientes_participantes'] ?? 0}',
                    Icons.people,
                    isActiva,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isActiva) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: isActiva ? Colors.grey[500] : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActiva ? Colors.black : Colors.grey[600],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActiva ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editarCampania(Map<String, dynamic> campania) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarCampaniaScreen(
          campania: campania,
          onCampaniaEditada: () {
            setState(() {
              _cargarDatos();
            });
          },
        ),
      ),
    );
  }

  void _eliminarCampania(Map<String, dynamic> campania) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Campaña'),
        content: Text('¿Estás seguro de que quieres eliminar la campaña "${campania['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final eliminado = await FidelizacionService.eliminarCampania(campania['id']);
              if (eliminado) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Campaña eliminada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {
                  _cargarDatos();
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar la campaña'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCampania(Map<String, dynamic> campania) async {
    try {
      final nuevaActiva = !(campania['activa'] == true);
      
      final resultado = await FidelizacionService.editarCampania(
        id: campania['id'],
        nombre: campania['nombre'],
        descripcion: campania['descripcion'] ?? '',
        fechaInicio: campania['fecha_inicio'],
        fechaFin: campania['fecha_fin'],
        activa: nuevaActiva,
      );
      
      if (resultado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevaActiva 
                  ? 'Campaña activada correctamente'
                  : 'Campaña desactivada correctamente'
            ),
            backgroundColor: nuevaActiva ? Colors.green : Colors.orange,
          ),
        );
        _cargarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar el estado de la campaña'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildClientesFielesTab() {
    return FutureBuilder<List<dynamic>>(
      future: _clientesFielesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white70, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar clientes',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final clientes = snapshot.data ?? [];
        
        if (clientes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, color: Colors.white70, size: 64),
                const SizedBox(height: 16),
                Text(
                  'No hay clientes fieles',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los clientes aparecerán aquí cuando realicen compras',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final cliente = clientes[index];
            return _buildClienteFielCard(cliente);
          },
        );
      },
    );
  }

  Widget _buildClienteFielCard(Map<String, dynamic> cliente) {
    final nivel = cliente['nivel_fidelidad'] ?? 'BRONCE';
    final colorNivel = _getColorNivel(nivel);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colorNivel.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  (cliente['nombre'] ?? '?')[0].toUpperCase(),
                  style: TextStyle(
                    color: colorNivel,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cliente['ci_ruc'] ?? 'Sin CI/RUC',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildClienteStat(
                        'Compras',
                        '${cliente['total_compras'] ?? 0}',
                        Icons.shopping_cart,
                      ),
                      const SizedBox(width: 16),
                      _buildClienteStat(
                        'Total',
                        formatMiles(double.tryParse(cliente['total_gastado']?.toString() ?? '0') ?? 0),
                        Icons.attach_money,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildClienteStat(
                        'Puntos',
                        '${cliente['puntos_fidelizacion'] ?? 0}',
                        Icons.stars,
                      ),
                      const SizedBox(width: 16),
                      _buildClienteStat(
                        'Última compra',
                        cliente['ultima_compra']?.toString().substring(0, 10) ?? 'N/A',
                        Icons.calendar_today,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorNivel,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                nivel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorNivel(String nivel) {
    switch (nivel) {
      case 'PLATINO':
        return const Color(0xFFE5E4E2);
      case 'ORO':
        return const Color(0xFFFFD700);
      case 'PLATA':
        return const Color(0xFFC0C0C0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Widget _buildClienteStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 14),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _estadisticasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white70, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar estadísticas',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final niveles = stats['niveles_fidelidad'] ?? {};
        
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildEstadisticaCard(
              'Resumen General',
              [
                _buildEstadisticaItem('Campañas Totales', '${stats['total_campanias'] ?? 0}'),
                _buildEstadisticaItem('Campañas Activas', '${stats['campanias_activas'] ?? 0}'),
                _buildEstadisticaItem('Clientes Participantes', '${stats['total_clientes_participantes'] ?? 0}'),
                _buildEstadisticaItem('Clientes que Cumplieron', '${stats['clientes_que_cumplieron'] ?? 0}'),
              ],
              Icons.analytics,
            ),
            const SizedBox(height: 16),
            _buildEstadisticaCard(
              'Niveles de Fidelidad',
              [
                _buildEstadisticaItem('Platino', '${niveles['PLATINO'] ?? 0}'),
                _buildEstadisticaItem('Oro', '${niveles['ORO'] ?? 0}'),
                _buildEstadisticaItem('Plata', '${niveles['PLATA'] ?? 0}'),
                _buildEstadisticaItem('Bronce', '${niveles['BRONCE'] ?? 0}'),
              ],
              Icons.emoji_events,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstadisticaCard(String title, List<Widget> items, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearCampania() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Campaña de Fidelización'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la campaña',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                child: ListTile(
                      title: const Text('Fecha Inicio'),
                      subtitle: Text(
                        fechaInicio?.toString().split(' ')[0] ?? 'Seleccionar',
                      ),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (fecha != null) {
                          setState(() => fechaInicio = fecha);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fecha Fin'),
                      subtitle: Text(
                        fechaFin?.toString().split(' ')[0] ?? 'Seleccionar',
                      ),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaInicio ?? DateTime.now(),
                          firstDate: fechaInicio ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (fecha != null) {
                          setState(() => fechaFin = fecha);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
                    onPressed: () async {
              if (nombreController.text.isEmpty || fechaInicio == null || fechaFin == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor completa todos los campos')),
                );
                return;
              }
              
              try {
                await FidelizacionService.crearCampania(
                  nombre: nombreController.text,
                  descripcion: descripcionController.text,
                  fechaInicio: fechaInicio!.toString().split(' ')[0],
                  fechaFin: fechaFin!.toString().split(' ')[0],
                );
                
                Navigator.pop(context);
                _cargarDatos();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Campaña creada exitosamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Widget _buildClientesRiesgoTab() {
    return Column(
      children: [
        // Header con botón de análisis
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clientes en Riesgo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Identifica y recupera clientes que no han comprado recientemente',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _analizarClientesRiesgo(),
                icon: Icon(Icons.analytics),
                label: Text('Analizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Lista de clientes en riesgo
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: FidelizacionService.listarClientesRiesgo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white70, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar clientes en riesgo',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              final clientes = snapshot.data ?? [];
              
              if (clientes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        '¡Excelente!',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay clientes en riesgo',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _analizarClientesRiesgo(),
                        child: Text('Analizar Clientes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: clientes.length,
                itemBuilder: (context, index) {
                  final cliente = clientes[index];
                  return _buildClienteRiesgoCard(cliente);
            },
          );
        },
      ),
        ),
      ],
    );
  }

  Widget _buildClienteRiesgoCard(Map<String, dynamic> cliente) {
    final nivelRiesgo = cliente['nivel_riesgo'] ?? 1;
    final diasSinComprar = cliente['dias_sin_comprar'] ?? 0;
    final productoFavorito = cliente['producto_favorito'] ?? 'Sin datos';
    
    Color colorNivel;
    String textoNivel;
    IconData iconoNivel;
    
    switch (nivelRiesgo) {
      case 1:
        colorNivel = Colors.orange;
        textoNivel = 'Riesgo Bajo';
        iconoNivel = Icons.warning;
        break;
      case 2:
        colorNivel = Colors.deepOrange;
        textoNivel = 'Riesgo Medio';
        iconoNivel = Icons.warning_amber;
        break;
      case 3:
        colorNivel = Colors.red;
        textoNivel = 'Riesgo Alto';
        iconoNivel = Icons.dangerous;
        break;
      default:
        colorNivel = Colors.grey;
        textoNivel = 'Sin clasificar';
        iconoNivel = Icons.help;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorNivel.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorNivel.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconoNivel, color: colorNivel, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente['cliente_nombre'] ?? 'Cliente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        textoNivel,
                        style: TextStyle(
                          color: colorNivel,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorNivel.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$diasSinComprar días',
                    style: TextStyle(
                      color: colorNivel,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Producto favorito: $productoFavorito',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _enviarMensajeRetencion(cliente),
                    icon: Icon(Icons.message, size: 16),
                    label: Text('Enviar Mensaje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _verDetallesCliente(cliente),
                  icon: Icon(Icons.info_outline, color: Colors.white70),
                  tooltip: 'Ver detalles',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _analizarClientesRiesgo() async {
    try {
      await FidelizacionService.analizarClientesRiesgo();
      _cargarDatos(); // Recargar datos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Análisis de clientes en riesgo completado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _enviarMensajeRetencion(Map<String, dynamic> cliente) async {
    try {
      // Obtener opciones de mensaje personalizado
      final opcionesData = await FidelizacionService.obtenerOpcionesMensaje(cliente['cliente_id']);
      
      if (opcionesData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar mensajes personalizados')),
        );
        return;
      }

      final opciones = opcionesData['opciones'] as List;
      
      // Mostrar diálogo para seleccionar mensaje
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Selecciona un mensaje personalizado'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mensajes personalizados para ${opcionesData['cliente']['nombre']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...opciones.map((opcion) => Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            opcion['titulo'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getColorUrgencia(opcion['urgencia']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${opcion['descuento']}% OFF',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        opcion['mensaje'],
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                )).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _enviarMensajeSeleccionado(context, cliente, opciones[0]['mensaje']);
              },
              child: Text('Enviar Mensaje 1'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _enviarMensajeSeleccionado(context, cliente, opciones[1]['mensaje']);
              },
              child: Text('Enviar Mensaje 2'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _enviarMensajeSeleccionado(context, cliente, opciones[2]['mensaje']);
              },
              child: Text('Enviar Mensaje 3'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _getColorUrgencia(String urgencia) {
    switch (urgencia) {
      case 'Alta': return Colors.red;
      case 'Media': return Colors.orange;
      case 'Baja': return Colors.green;
      default: return Colors.blue;
    }
  }

  Future<void> _enviarMensajeSeleccionado(BuildContext context, Map<String, dynamic> cliente, String mensaje) async {
    try {
      final resultado = await FidelizacionService.enviarMensajeRetencion(
        clienteId: cliente['cliente_id'],
        mensaje: mensaje,
        nivelRiesgo: cliente['nivel_riesgo'],
      );
      
      if (resultado != null && resultado['enlace_whatsapp'] != null) {
        // Mostrar diálogo con el enlace de WhatsApp
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Mensaje Preparado'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mensaje personalizado para:'),
                  Text('${resultado['cliente_nombre']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text('Descuento: ${resultado['descuento']}%'),
                  Text('Tipo: ${resultado['tipo_cliente']}'),
                  Text('Valor: ${resultado['valor_cliente']}'),
                  SizedBox(height: 16),
                  Text('Haz clic en "Abrir WhatsApp" para enviar el mensaje:'),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mensaje,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Aquí podrías abrir el enlace de WhatsApp
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Enlace de WhatsApp copiado al portapapeles')),
                  );
                },
                icon: Icon(Icons.message, color: Colors.white),
                label: Text('Abrir WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _verDetallesCliente(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${cliente['cliente_nombre']}'),
            Text('Teléfono: ${cliente['cliente_telefono']}'),
            Text('Identificador: ${cliente['cliente_identificador']}'),
            Text('Días sin comprar: ${cliente['dias_sin_comprar']}'),
            Text('Producto favorito: ${cliente['producto_favorito']}'),
            Text('Categoría favorita: ${cliente['categoria_favorita']}'),
            Text('Mensajes enviados: ${cliente['total_mensajes_enviados']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}