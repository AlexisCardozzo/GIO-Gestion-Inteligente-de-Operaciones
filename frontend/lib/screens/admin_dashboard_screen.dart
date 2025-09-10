import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'select_branch_screen.dart';
import 'fidelizacion_screen.dart';
import 'productos_screen.dart';
import 'stock_screen.dart';
import 'reportes_screen.dart';
import 'educacion_financiera_screen.dart';
import 'fondo_solidario_screen.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import '../utils/owl_logo.dart';
import '../services/api_service.dart';
import '../services/fidelizacion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  final List<String> frasesMotivacionales = [
    '¡Hoy es tu día para crecer! 🚀',
    'El éxito es la suma de pequeños esfuerzos diarios.',
    '¡Sigue adelante, emprendedor!',
    'Cada venta te acerca a tu meta.',
    '¡Haz que cada día cuente!',
    'La constancia es la clave del éxito.',
    '¡Tú puedes lograrlo!',
    'El futuro pertenece a quienes creen en sus sueños.',
  ];
  late String fraseHoy;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _showCelebration = false;
  bool _motivacionalExpandida = false;
  int? _ventas;
  bool _cargandoVentas = true;
  double? _metaGanancia;
  bool _cargandoMeta = true;
  final TextEditingController _metaController = TextEditingController();
  double _gananciaTotal = 0;
  bool _editandoMeta = false;
  
  // Variables para el progreso del búho
  Map<String, dynamic>? _progresoBuho;
  bool _cargandoProgresoBuho = true;
  
  // Variables para navegación horizontal
  late PageController _pageController;
  int _currentPage = 1; // 0: Fondo Solidario, 1: Centro de Control, 2: Activa tu Negocio

  @override
  void initState() {
    super.initState();
    fraseHoy = frasesMotivacionales[Random().nextInt(frasesMotivacionales.length)];
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.18)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_bounceController);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    
    // Inicializar PageController para navegación horizontal
    _pageController = PageController(initialPage: 1);
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
      _bounceController.forward();
      setState(() {
        _showCelebration = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showCelebration = false;
          });
        }
      });
    });
    _cargarVentas();
    _cargarMetaGanancia();
    _cargarProgresoBuho();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _progressController.dispose();
    _metaController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargarMetaGanancia() async {
    setState(() { _cargandoMeta = true; });
    final prefs = await SharedPreferences.getInstance();
    final meta = prefs.getDouble('meta_ganancia') ?? 100000;
    if (!mounted) return;
    setState(() {
      _metaGanancia = meta;
      _metaController.text = meta.toString();
      _cargandoMeta = false;
    });
  }

  Future<void> _guardarMetaGanancia() async {
    final meta = double.tryParse(_metaController.text.replaceAll(',', ''));
    if (meta != null && meta > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('meta_ganancia', meta);
      if (mounted) {
        setState(() {
          _metaGanancia = meta;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta guardada correctamente')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una meta válida')));
      }
    }
  }

  Future<void> _cargarVentas() async {
    try {
      setState(() { _cargandoVentas = true; });
      final response = await ApiService.obtenerTotalVentas();
      if (mounted) {
        setState(() {
          _ventas = response is Map ? (response as Map)['total_ventas'] ?? 0 : (response ?? 0);
          _cargandoVentas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _cargandoVentas = false; });
      }
      print('Error al cargar ventas: $e');
    }
  }

  Future<void> _cargarProgresoBuho() async {
    try {
      setState(() { _cargandoProgresoBuho = true; });
      final response = await FidelizacionService.obtenerProgresoBuho();
      if (mounted) {
        setState(() {
          _progresoBuho = response;
          _cargandoProgresoBuho = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _cargandoProgresoBuho = false; });
      }
      print('Error al cargar progreso del búho: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.tipoRolActivo != 'Administrador') {
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SelectBranchScreen()),
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }
    
    final int? ventas = _ventas ?? 0;
    
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
                Color(0xFF223A5E),
                Color(0xFF4F8EDC),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Panel de Administrador',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 1.1,
                          shadows: const [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(1, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (authProvider.nombreSucursalActivo != null && authProvider.nombreRolActivo != null)
                        Chip(
                          label: Text(
                            '${authProvider.nombreSucursalActivo}  |  ${authProvider.nombreRolActivo}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF223A5E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.85),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          avatar: const Icon(Icons.store, color: Color(0xFF4F8EDC), size: 16),
                        ),
                    ],
                  ),
                  // Botón circular para cambiar sucursal/rol
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        authProvider.limpiarSucursalYRol();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const SelectBranchScreen()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.90),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Color(0xFF223A5E),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón para refrescar progreso del búho
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        _cargarProgresoBuho();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🦉 Actualizando progreso del búho...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.90),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.refresh,
                          color: Color(0xFF223A5E),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Indicadores de navegación horizontal
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0, 'Fondo Solidario'),
                const SizedBox(width: 20),
                _buildPageIndicator(1, 'Centro de Control'),
                const SizedBox(width: 20),
                _buildPageIndicator(2, 'Activa tu Negocio'),
              ],
            ),
          ),
          // PageView para navegación horizontal
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Fondo Solidario (Futuro)
                _buildLeftPanel(),
                // Centro de Control (Actual)
                _buildDashboardBuho(ventas),
                // Activa tu Negocio (Sistema Bancario de Microfinanzas)
                _buildPrestamosPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir indicadores de página
  Widget _buildPageIndicator(int pageIndex, String title) {
    final isActive = _currentPage == pageIndex;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Fondo Solidario
  Widget _buildLeftPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header del Fondo Solidario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Red de Historias y Donaciones',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Plataforma digital para emprendedores verificados',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Descripción del sistema
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎯 Características principales:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem('✅ Solo emprendedores verificados por GIO'),
                      _buildFeatureItem('✅ Cualquier usuario registrado puede donar'),
                      _buildFeatureItem('✅ Comisión automática para GIO'),
                      _buildFeatureItem('✅ Plataforma 100% online'),
                      _buildFeatureItem('✅ Diseño tipo red social'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FondoSolidarioScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Administrar'),
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
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navegar a vista pública de historias
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Ver Historias'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
          
          const SizedBox(height: 24),
          
          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Flujo del Sistema:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFlowStep('1. Usuario se registra y solicita verificación'),
                _buildFlowStep('2. GIO revisa y aprueba/rechaza'),
                _buildFlowStep('3. Emprendedor aprobado publica su historia'),
                _buildFlowStep('4. Usuarios donan con comisión automática'),
                _buildFlowStep('5. Emprendedor recibe fondos y agradece'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
  
  Widget _buildFlowStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Dashboard Búho (Actual)
  Widget _buildDashboardBuho(int? ventas) {
    if (_cargandoVentas) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (ventas == null) {
      return const Center(
        child: Text('Error al cargar datos'),
      );
    }

    return Column(
      children: [
        // --- INICIO: Sección motivacional y evolutiva compacta ---
        GestureDetector(
          onTap: () {
            setState(() {
              _motivacionalExpandida = !_motivacionalExpandida;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Card(
              elevation: 6,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Búho más pequeño
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getEntornoColor((_metaGanancia != null && _metaGanancia! > 0) ? (_gananciaTotal / _metaGanancia!).clamp(0, 1) : 0),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: _progresoBuho != null 
                          ? Text(
                              _progresoBuho!['emoji'] ?? '🥚',
                              style: const TextStyle(fontSize: 36),
                            )
                          : const Text('🥚', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                    if (_metaGanancia != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          _getEntornoEmoticon((_gananciaTotal / _metaGanancia!).clamp(0, 1)),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    // Textos y barra compactos o expandidos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _progresoBuho != null 
                              ? (_progresoBuho!['mensaje'] ?? '¡Comienza tu aventura!')
                              : '¡Comienza tu aventura!',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                            maxLines: _motivacionalExpandida ? null : 3,
                            overflow: _motivacionalExpandida ? TextOverflow.visible : TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _progresoBuho != null 
                              ? (_progresoBuho!['progreso'] ?? 0) / 100.0
                              : 0.0,
                            minHeight: 5,
                            backgroundColor: Colors.blue[50],
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(
                              _progresoBuho != null 
                                ? 'Nivel ${_progresoBuho!['nivel']} - ${_progresoBuho!['nombre']}'
                                : 'Nivel 1 - Huevo',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF223A5E)),
                            ),
                            backgroundColor: Colors.amber[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          Text(
                            'El búho crece con cada paso que das en tu negocio. Si te esfuerzas, aprendes y vendes más, verás cómo evoluciona. Tu progreso es su progreso.',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // --- INICIO: Consejo integrado ---
                          if (_progresoBuho != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      getConsejoPorNivel(_progresoBuho!['nivel'] ?? 1),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: _motivacionalExpandida ? null : 2,
                                      overflow: _motivacionalExpandida ? TextOverflow.visible : TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        // Forzar rebuild para obtener nuevo consejo
                                      });
                                    },
                                    icon: Icon(Icons.refresh, color: Colors.orange[700], size: 14),
                                    tooltip: 'Nuevo consejo',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          // --- FIN: Consejo integrado ---
                          Row(
                            children: [
                              const Icon(Icons.tips_and_updates, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _progresoBuho != null 
                                    ? 'Ventas: ${_progresoBuho!['total_ventas']} | Puntos: ${_progresoBuho!['total_puntos']}'
                                    : 'Comienza registrando ventas',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.brown,
                                  ),
                                  maxLines: _motivacionalExpandida ? null : 2,
                                  overflow: _motivacionalExpandida ? TextOverflow.visible : TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // --- FIN: Sección motivacional y evolutiva compacta ---
        // --- INICIO: Sección de tarjetas de módulos ---
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildModuleCard(
                'Productos',
                Icons.inventory_2,
                const Color(0xFF1976D2),
                context: context,
              ),
              _buildModuleCard(
                'Stock',
                Icons.store,
                const Color(0xFF00C48C),
                context: context,
              ),
              _buildModuleCard(
                'Fidelización',
                Icons.card_giftcard,
                const Color(0xFFFFB300),
                context: context,
              ),
              _buildModuleCard(
                'Reportes',
                Icons.bar_chart,
                const Color(0xFF7C3AED),
                context: context,
              ),
              _buildModuleCard(
                'Educación\nFinanciera',
                Icons.school,
                const Color(0xFF059669),
                context: context,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Activa tu Negocio (Sistema Bancario de Microfinanzas)
  Widget _buildPrestamosPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del sistema bancario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sistema de Microfinanzas GIO',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Plataforma Bancaria de Crédito Inteligente',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Indicadores de seguridad
                  Row(
                    children: [
                      _buildSecurityIndicator('SSL', Icons.lock, Colors.green),
                      const SizedBox(width: 12),
                      _buildSecurityIndicator('256-bit', Icons.security, Colors.blue),
                      const SizedBox(width: 12),
                      _buildSecurityIndicator('ISO 27001', Icons.verified, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Estado de verificación de identidad
            _buildIdentityVerificationStatus(),
            const SizedBox(height: 24),
            
            // Score crediticio y análisis (solo si está verificado)
            if (_isIdentityVerified) ...[
              _buildCreditAnalysis(),
              const SizedBox(height: 24),
            ],
            
            // Productos crediticios
            Text(
              'Productos Crediticios Disponibles',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // Préstamo de Formalización
            _buildAdvancedLoanCard(
              title: 'Préstamo de Formalización',
              amount: '1.500.000 Gs',
              description: 'Para legalizar y formalizar tu negocio',
              requirements: [
                'Verificación de identidad completa',
                'Historial de ventas mínimo 3 meses',
                'Flujo de caja positivo',
                'Sin deudas pendientes',
                'Plan de negocio básico'
              ],
              color: const Color(0xFF10B981),
              icon: Icons.gavel,
              isAvailable: _isIdentityVerified && !_hasActiveLoan,
              interestRate: '2.5%',
              term: '12 meses',
            ),
            
            const SizedBox(height: 16),
            
            // Préstamo de Expansión
            _buildAdvancedLoanCard(
              title: 'Préstamo de Expansión',
              amount: '5.000.000 Gs',
              description: 'Para crecer y expandir tu negocio',
              requirements: [
                'Préstamo de formalización pagado',
                'Crecimiento de ventas 20% mínimo',
                'Plan de expansión detallado',
                'Garantías adicionales',
                'Score crediticio > 700'
              ],
              color: const Color(0xFFF59E0B),
              icon: Icons.trending_up,
              isAvailable: _canAccessExpansionLoan,
              interestRate: '3.2%',
              term: '24 meses',
            ),
            
            const SizedBox(height: 16),
            
            // Préstamo Premium
            _buildAdvancedLoanCard(
              title: 'Préstamo Premium',
              amount: '50.000.000 Gs',
              description: 'Para grandes proyectos de expansión',
              requirements: [
                'Ambos préstamos anteriores pagados',
                'Negocio establecido mínimo 2 años',
                'Plan estratégico de crecimiento',
                'Garantías sólidas y avales',
                'Score crediticio > 750'
              ],
              color: const Color(0xFF8B5CF6),
              icon: Icons.diamond,
              isAvailable: _canAccessPremiumLoan,
              interestRate: '4.1%',
              term: '36 meses',
            ),
            
            const SizedBox(height: 24),
            
            // Botón de acción según estado
            if (!_isIdentityVerified) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showIdentityVerificationForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Completar Verificación de Identidad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (!_hasActiveLoan) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showLoanApplicationForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Solicitar Préstamo de Formalización',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              _buildActiveLoanStatus(),
            ],
            
            const SizedBox(height: 16),
            
            // Información de seguridad
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Seguridad Bancaria',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Todos los datos están encriptados con estándares bancarios\n'
                    '• Verificación de identidad obligatoria para prevenir fraude\n'
                    '• Análisis crediticio automatizado con IA avanzada\n'
                    '• Monitoreo continuo de pagos y comprobantes\n'
                    '• Cumplimiento con regulaciones financieras',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Variables de estado para el sistema de préstamos
  bool _isIdentityVerified = false;
  bool _hasActiveLoan = false;
  bool _canAccessExpansionLoan = false;
  bool _canAccessPremiumLoan = false;
  Map<String, dynamic>? _userLoanData;
  Map<String, dynamic>? _userIdentityData;

  Widget _buildIdentityVerificationStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isIdentityVerified ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isIdentityVerified ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isIdentityVerified ? Icons.verified : Icons.warning,
                color: _isIdentityVerified ? Colors.green[600] : Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _isIdentityVerified ? 'Identidad Verificada' : 'Verificación de Identidad Pendiente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isIdentityVerified ? Colors.green[800] : Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isIdentityVerified 
              ? 'Tu identidad ha sido verificada. Puedes acceder a nuestros productos crediticios.'
              : 'Para acceder a nuestros productos crediticios, necesitas completar la verificación de identidad con los siguientes documentos:',
            style: TextStyle(
              fontSize: 14,
              color: _isIdentityVerified ? Colors.green[700] : Colors.orange[700],
            ),
          ),
          if (!_isIdentityVerified) ...[
            const SizedBox(height: 12),
            _buildVerificationItem('Cédula de Identidad (Número)', Icons.credit_card),
            _buildVerificationItem('Nombre completo (debe coincidir con registro)', Icons.person),
            _buildVerificationItem('Foto de CI (Frente)', Icons.camera_alt),
            _buildVerificationItem('Foto de CI (Reverso)', Icons.camera_alt),
            _buildVerificationItem('Datos de ingresos (análisis automático)', Icons.analytics),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditAnalysis() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Análisis Crediticio Avanzado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Score crediticio principal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score Crediticio',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '785',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Excelente - Riesgo Bajo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Métricas detalladas
          Row(
            children: [
              Expanded(
                child: _buildAdvancedMetricCard(
                  title: 'Capacidad de Pago',
                  value: '92%',
                  subtitle: 'Muy Alta',
                  color: Colors.green,
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAdvancedMetricCard(
                  title: 'Riesgo Crediticio',
                  value: '8%',
                  subtitle: 'Muy Bajo',
                  color: Colors.blue,
                  icon: Icons.shield,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAdvancedMetricCard(
                  title: 'Límite Aprobado',
                  value: '5.000.000',
                  subtitle: 'Guaraníes',
                  color: Colors.purple,
                  icon: Icons.credit_card,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLoanStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Préstamo Activo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tienes un préstamo de formalización activo por 1.500.000 Gs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLoanStatusCard('Monto', '1.500.000 Gs', Icons.attach_money),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLoanStatusCard('Estado', 'Aprobado', Icons.check_circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLoanStatusCard('Próximo Pago', '15/12/2024', Icons.schedule),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanStatusCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  void _showIdentityVerificationForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text('Verificación de Identidad'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completa los siguientes datos para verificar tu identidad:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Campo CI
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Número de Cédula de Identidad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo Nombre
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo (debe coincidir con registro)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo Foto CI Frente
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foto de CI (Frente)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Aquí iría la lógica para subir foto
                        },
                        icon: Icon(Icons.camera_alt),
                        label: Text('Subir Foto'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo Foto CI Reverso
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foto de CI (Reverso)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Aquí iría la lógica para subir foto
                        },
                        icon: Icon(Icons.camera_alt),
                        label: Text('Subir Foto'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Información sobre datos automáticos
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.blue[600], size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Datos Automáticos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Los datos de ingresos de los últimos 12 meses se analizarán automáticamente desde tu historial de ventas en el sistema.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isIdentityVerified = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Verificación enviada. Analizando datos automáticamente...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Enviar Verificación'),
            ),
          ],
        );
      },
    );
  }

  void _showLoanApplicationForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.credit_card, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text('Solicitud de Préstamo'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Préstamo de Formalización - 1.500.000 Gs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo Monto
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Monto solicitado (máximo 1.500.000 Gs)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Campo Propósito
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Propósito del préstamo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Campo Plan de Negocio
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Plan de negocio básico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Préstamo:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Tasa de interés: 2.5%\n'
                        '• Plazo: 12 meses\n'
                        '• Cuota mensual: ~140.000 Gs\n'
                        '• Proceso de aprobación: 24-48 horas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasActiveLoan = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Solicitud enviada. Será revisada por nuestro equipo.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Enviar Solicitud'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModuleCard(String title, IconData icon, Color iconColor, {BuildContext? context}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.13),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (context != null && title == 'Productos') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProductosScreen()),
            );
          }
          if (context != null && title == 'Fidelización') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FidelizacionScreen()),
            );
          }
          if (context != null && title == 'Stock') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StockScreen()),
            );
          }
          if (context != null && title == 'Reportes') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportesScreen()),
            );
          }
          if (context != null && title == 'Educación\nFinanciera') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EducacionFinancieraScreen()),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                  letterSpacing: 0.7,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- INICIO: función para determinar entorno visual según progreso ---
  Color _getEntornoColor(double progreso) {
    if (progreso >= 0.95) {
      return Colors.amber.shade200; // Exitoso
    } else if (progreso >= 0.7) {
      return Colors.green.shade100; // Saludable
    } else if (progreso < 0.3) {
      return Colors.grey.shade300; // Negativo
    } else {
      return Colors.blue.shade50; // Normal
    }
  }

  String _getEntornoEmoticon(double progreso) {
    if (progreso >= 0.95) {
      return '🎉'; // Exitoso
    } else if (progreso >= 0.7) {
      return '🌟'; // Saludable
    } else if (progreso < 0.3) {
      return '☁️'; // Negativo
    } else {
      return '';
    }
  }
  // --- FIN: función para determinar entorno visual según progreso ---

  Widget _buildSecurityIndicator(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedLoanCard({
    required String title,
    required String amount,
    required String description,
    required List<String> requirements,
    required Color color,
    required IconData icon,
    required bool isAvailable,
    required String interestRate,
    required String term,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable ? color : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAvailable ? color : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isAvailable ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.grey[800] : Colors.grey[500],
                      ),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? color : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAvailable ? 'Disponible' : 'Bloqueado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: isAvailable ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          
          // Información de tasas y plazos
          Row(
            children: [
              _buildLoanInfo('Tasa de Interés', interestRate, Icons.percent),
              const SizedBox(width: 16),
              _buildLoanInfo('Plazo', term, Icons.schedule),
            ],
          ),
          
          const SizedBox(height: 16),
          Text(
            'Requisitos:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAvailable ? Colors.grey[700] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((req) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: isAvailable ? Colors.green[600] : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req,
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLoanInfo(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- INICIO: Consejos útiles, prácticos y retadores por nivel ---
final List<String> consejosNivel1 = [
  'Habla con tus amigos y familiares sobre tu producto. ¡Tus primeros clientes pueden estar más cerca de lo que crees!',
  'No temas equivocarte, cada error es una lección.',
  'Enfócate en aprender, no solo en ganar.',
  'La paciencia es tu mejor aliada al inicio.',
  'Observa a otros emprendedores exitosos.',
  'Mantén un registro de tus ventas y gastos.',
  'Pregunta a tus clientes qué les gusta de tu producto.',
  'No te compares con otros, cada negocio es único.',
  'Celebra cada venta, por pequeña que sea.',
  'La consistencia es más importante que la perfección.',
  'Aprende a manejar el rechazo, es parte del proceso.',
  'Rodéate de personas que te apoyen.',
  'No gastes más de lo que puedes permitirte.',
  'La calidad es mejor que la cantidad.',
  'Sé honesto con tus clientes.',
  'Mantén tu área de trabajo organizada.',
  'Aprende algo nuevo cada día.',
  'No te rindas ante el primer obstáculo.',
  'La confianza se construye con el tiempo.',
  'Valora el feedback de tus clientes.',
  'Haz una lista de tus fortalezas y úsalas.',
];

final List<String> consejosNivel2 = [
  'Recuerda la regla 80/20: el 20% de tus clientes generan el 80% de tus ventas.',
  'Ofrece promociones limitadas para incentivar compras rápidas.',
  'Crea un sistema de recomendaciones.',
  'Mantén contacto regular con tus mejores clientes.',
  'Analiza qué productos se venden mejor.',
  'Considera expandir tu oferta gradualmente.',
  'Invierte en mejorar tu presentación.',
  'Aprende técnicas básicas de marketing.',
  'Establece metas semanales y mensuales.',
  'No descuides la calidad por la cantidad.',
  'Busca alianzas con otros negocios.',
  'Mantén un inventario actualizado.',
  'Ofrece un servicio al cliente excepcional.',
  'Aprende de tus competidores.',
  'No te endeudes más de lo necesario.',
  'Reinvierte parte de tus ganancias.',
  'Mantén registros detallados.',
  'Piensa en el largo plazo.',
  'No te conformes con el mínimo esfuerzo.',
  'Busca formas de diferenciarte.',
  'La puntualidad genera confianza.',
  'Sé proactivo, no reactivo.',
];

final List<String> consejosNivel3 = [
  'Ofrece promociones limitadas para incentivar compras rápidas. ¡La urgencia motiva!',
  'Piensa en diversificar tu oferta.',
  'Considera contratar ayuda si es necesario.',
  'Invierte en marketing digital.',
  'Crea un plan de crecimiento a 6 meses.',
  'Analiza tus datos de ventas regularmente.',
  'Busca oportunidades de expansión.',
  'Mantén la calidad mientras creces.',
  'Desarrolla tu marca personal.',
  'Aprende sobre finanzas empresariales.',
  'Considera exportar o vender online.',
  'Mantén buenas relaciones con proveedores.',
  'Invierte en tecnología que te ayude.',
  'Desarrolla un equipo de confianza.',
  'No pierdas de vista tus valores.',
  'Busca mentores o asesores.',
  'Mantén un equilibrio entre trabajo y vida.',
  'Piensa en la escalabilidad.',
  'No te estanques en tu zona de confort.',
  'La innovación te mantiene relevante.',
  'Mantén la humildad mientras creces.',
  'Pregunta a tus clientes cómo puedes mejorar.',
  'No temas probar nuevas ideas.',
  'Aprende de tus competidores, pero no los imites.',
  'La flexibilidad es clave para crecer.',
  'Celebra cada avance, por pequeño que sea.',
  'Rodéate de personas que te inspiren.',
  'Haz networking, nunca sabes quién puede ayudarte.',
  'La resiliencia te hará avanzar cuando otros se detienen.',
  'El aprendizaje constante es tu mejor inversión.',
  'La visión a largo plazo te diferencia.',
  'La pasión por lo que haces te da energía.',
  'La disciplina te mantiene en el camino.',
  'La humildad te permite aprender de todos.',
  'La perseverancia te lleva más lejos que el talento.',
  'La innovación nace de la curiosidad.',
  'La adaptabilidad es tu mejor aliada en tiempos de cambio.',
  'La confianza en tu equipo multiplica los resultados.',
  'La generosidad crea relaciones duraderas.',
  'La proactividad abre nuevas puertas.',
  'La autocrítica te ayuda a mejorar.',
  'Haz una lista de tus 5 productos más rentables y enfócate en promocionarlos.',
];

final List<String> consejosNivel4 = [
  'Piensa en diversificar tu oferta o en fidelizar aún más a tus clientes actuales.',
  'Celebra tus logros, pero nunca dejes de aprender.',
  'Comparte tu experiencia con otros emprendedores.',
  'El éxito se multiplica cuando se comparte.',
  'Inspira a otros con tu ejemplo.',
  'Mantén la humildad, incluso en la cima.',
  'La visión a largo plazo te diferencia.',
  'Ayuda a otros a crecer y crecerás tú también.',
  'La gratitud atrae más oportunidades.',
  'Nunca pierdas la pasión por lo que haces.',
  'La ética es la base de un negocio duradero.',
  'La confianza se construye con acciones, no con palabras.',
  'La transparencia fortalece tu reputación.',
  'La generosidad te abre puertas inesperadas.',
  'La perseverancia transforma los sueños en realidad.',
  'La innovación constante mantiene tu negocio relevante.',
  'La empatía te conecta con tu equipo y tus clientes.',
  'La resiliencia te permite superar cualquier obstáculo.',
  'La disciplina te ayuda a mantener el rumbo.',
  'La curiosidad te lleva a descubrir nuevas oportunidades.',
  'La autoconfianza te impulsa a tomar decisiones valientes.',
  'La organización te permite aprovechar mejor tu tiempo.',
  'La comunicación clara evita conflictos.',
  'La proactividad te mantiene un paso adelante.',
  'El éxito es la suma de pequeñas acciones diarias bien hechas.',
];

String getConsejoPorNivel(int nivel) {
  final random = DateTime.now().millisecondsSinceEpoch;
  if (nivel <= 1) {
    return consejosNivel1[random % consejosNivel1.length];
  } else if (nivel == 2) {
    return consejosNivel2[random % consejosNivel2.length];
  } else if (nivel == 3) {
    return consejosNivel3[random % consejosNivel3.length];
  } else {
    return consejosNivel4[random % consejosNivel4.length];
  }
}
// --- FIN: Consejos útiles, prácticos y retadores por nivel ---