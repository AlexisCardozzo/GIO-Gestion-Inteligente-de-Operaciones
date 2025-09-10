import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/emprendedor.dart';
import '../models/donacion.dart';
import '../models/post.dart';
import '../services/fondo_solidario_service.dart';
import '../services/post_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../utils/format.dart';
import '../widgets/post_card.dart';
import '../widgets/trending_hashtags.dart';

final moneyFormat = NumberFormat.currency(
  locale: 'es_PY',
  symbol: '₲',
  decimalDigits: 0,
);

class FondoSolidarioAdminScreen extends StatefulWidget {
  const FondoSolidarioAdminScreen({Key? key}) : super(key: key);

  @override
  State<FondoSolidarioAdminScreen> createState() => _FondoSolidarioAdminScreenState();
}

class _FondoSolidarioAdminScreenState extends State<FondoSolidarioAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Emprendedor> _emprendedores = [];
  List<Donacion> _donaciones = [];
  List<Post> _posts = [];
  Map<String, dynamic> _estadisticas = {};
  bool _cargando = true;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        _cargarPosts(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarPosts() async {
    try {
      final result = await PostService.obtenerFeed(limit: 10);
      setState(() => _posts = result.posts);
    } catch (e) {
      print('Error cargando posts: $e');
    }
  }

  // ... [Mantener los métodos existentes] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // AppBar personalizado
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: GioColors.primaryGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Red de Historias y Donaciones',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Plataforma digital para emprendedores verificados',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text('Fondo Solidario'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _cargarDatos,
              ),
            ],
          ),

          // Estadísticas generales
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen General',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatCard(
                            'Total Recaudado',
                            moneyFormat.format(_estadisticas['total_recaudado'] ?? 0),
                            Icons.monetization_on,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Emprendedores',
                            '${_estadisticas['total_emprendedores'] ?? 0}',
                            Icons.people,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Historias',
                            '${_posts.length}',
                            Icons.article,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Características principales
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Características principales',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.verified_user,
                        title: 'Emprendedores Verificados',
                        subtitle: 'Control de calidad por GIO',
                      ),
                      _buildFeatureItem(
                        icon: Icons.people,
                        title: 'Red Social Integrada',
                        subtitle: 'Interacción entre usuarios',
                      ),
                      _buildFeatureItem(
                        icon: Icons.payment,
                        title: 'Donaciones Seguras',
                        subtitle: 'Procesamiento automático',
                      ),
                      _buildFeatureItem(
                        icon: Icons.cloud,
                        title: 'Plataforma 100% Online',
                        subtitle: 'Acceso desde cualquier dispositivo',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: GioColors.primaryDeep,
                unselectedLabelColor: Colors.grey,
                indicatorColor: GioColors.primaryDeep,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Emprendedores'),
                  Tab(text: 'Historias'),
                  Tab(text: 'Donaciones'),
                  Tab(text: 'Verificaciones'),
                  Tab(text: 'Estadísticas'),
                ],
              ),
            ),
          ),

          // Contenido de tabs
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmprendedoresTab(),
                _buildHistoriasTab(),
                _buildDonacionesTab(),
                _buildVerificacionesTab(),
                _buildEstadisticasTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoAccion(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Acción'),
        backgroundColor: GioColors.primary,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GioColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: GioColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriasTab() {
    return Column(
      children: [
        const TrendingHashtags(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: _posts[index]);
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoAccion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Acción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.person_add,
              title: 'Nuevo Emprendedor',
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoNuevoEmprendedor();
              },
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              icon: Icons.post_add,
              title: 'Nueva Historia',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/feed-social');
              },
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              icon: Icons.campaign,
              title: 'Nueva Campaña',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar creación de campaña
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: GioColors.primary),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... [Resto de métodos existentes] ...
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
