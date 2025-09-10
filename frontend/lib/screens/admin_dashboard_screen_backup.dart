import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'select_branch_screen.dart';
import 'fidelizacion_screen.dart';
import 'productos_screen.dart';
import 'stock_screen.dart';
import 'reportes_screen.dart';
import 'educacion_financiera_screen.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';

import '../services/api_service.dart';
import '../services/fidelizacion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  int _currentPage = 1; // 0: Panel Izquierdo, 1: Dashboard Búho, 2: Panel Préstamos

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
          _ventas = response ?? 0;
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
                _buildPageIndicator(0, 'Panel Izquierdo'),
                const SizedBox(width: 20),
                _buildPageIndicator(1, 'Dashboard Búho'),
                const SizedBox(width: 20),
                _buildPageIndicator(2, 'Panel Préstamos'),
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
                // Panel Izquierdo (Futuro)
                _buildLeftPanel(),
                // Dashboard Búho (Actual)
                _buildDashboardBuho(ventas),
                // Panel Préstamos (Futuro)
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

  // Panel Izquierdo (Futuro)
  Widget _buildLeftPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_ios,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Panel Izquierdo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Funcionalidad futura',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
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

  // Panel Préstamos (Futuro)
  Widget _buildPrestamosPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Panel de Préstamos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sistema de préstamos en desarrollo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
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