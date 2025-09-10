import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/publicacion.dart';
import '../services/publicacion_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';

class PublicacionesScreen extends StatefulWidget {
  const PublicacionesScreen({Key? key}) : super(key: key);

  @override
  State<PublicacionesScreen> createState() => _PublicacionesScreenState();
}

class _PublicacionesScreenState extends State<PublicacionesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Publicacion> _publicaciones = [];
  bool _cargando = true;
  bool _creandoPublicacion = false;

  // Controllers para el formulario de publicación
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  String _tipoPublicacion = 'consejo'; // consejo, progreso, problema

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarPublicaciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _cargarPublicaciones() async {
    setState(() {
      _cargando = true;
    });

    try {
      final publicaciones = await PublicacionService.listarPublicaciones();
      setState(() {
        _publicaciones = publicaciones;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando publicaciones: $e')),
      );
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _crearPublicacion() async {
    if (_tituloController.text.isEmpty || _contenidoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _creandoPublicacion = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await PublicacionService.crearPublicacion({
        'user_id': userId,
        'titulo': _tituloController.text,
        'contenido': _contenidoController.text,
        'tipo': _tipoPublicacion,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar formulario
      _tituloController.clear();
      _contenidoController.clear();
      _tipoPublicacion = 'consejo';

      // Cerrar modal y recargar datos
      Navigator.of(context).pop();
      _cargarPublicaciones();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando publicación: $e')),
      );
    } finally {
      setState(() {
        _creandoPublicacion = false;
      });
    }
  }

  void _mostrarFormularioPublicacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Publicación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _tipoPublicacion,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Publicación',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'consejo', child: Text('Consejo')),
                  DropdownMenuItem(value: 'progreso', child: Text('Historia de Progreso')),
                  DropdownMenuItem(value: 'problema', child: Text('Problema')),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoPublicacion = value ?? 'consejo';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
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
            onPressed: _creandoPublicacion ? null : _crearPublicacion,
            child: _creandoPublicacion
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad de Emprendedores'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Consejos', icon: Icon(Icons.lightbulb)),
            Tab(text: 'Progreso', icon: Icon(Icons.trending_up)),
            Tab(text: 'Problemas', icon: Icon(Icons.help)),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPublicacionesTab('consejo'),
                _buildPublicacionesTab('progreso'),
                _buildPublicacionesTab('problema'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioPublicacion,
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPublicacionesTab(String tipo) {
    final publicacionesFiltradas = _publicaciones
        .where((p) => p.tipo == tipo)
        .toList();

    return RefreshIndicator(
      onRefresh: _cargarPublicaciones,
      child: publicacionesFiltradas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconForTipo(tipo),
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyMessageForTipo(tipo),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: publicacionesFiltradas.length,
              itemBuilder: (context, index) {
                final publicacion = publicacionesFiltradas[index];
                return _buildPublicacionCard(publicacion);
              },
            ),
    );
  }

  IconData _getIconForTipo(String tipo) {
    switch (tipo) {
      case 'consejo':
        return Icons.lightbulb;
      case 'progreso':
        return Icons.trending_up;
      case 'problema':
        return Icons.help;
      default:
        return Icons.article;
    }
  }

  String _getEmptyMessageForTipo(String tipo) {
    switch (tipo) {
      case 'consejo':
        return 'No hay consejos publicados\nSé el primero en compartir tu experiencia';
      case 'progreso':
        return 'No hay historias de progreso\nComparte tus logros con la comunidad';
      case 'problema':
        return 'No hay problemas publicados\nComparte tus dudas para recibir ayuda';
      default:
        return 'No hay publicaciones';
    }
  }

  Widget _buildPublicacionCard(Publicacion publicacion) {
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
                  backgroundColor: _getColorForTipo(publicacion.tipo),
                  child: Icon(
                    _getIconForTipo(publicacion.tipo),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publicacion.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Por: ${publicacion.autorNombre}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              publicacion.contenido,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(publicacion.fechaCreacion),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    publicacion.meGusta ? Icons.favorite : Icons.favorite_border,
                    color: publicacion.meGusta ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleMeGusta(publicacion),
                ),
                Text(
                  publicacion.totalMeGusta.toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () => _mostrarComentarios(publicacion),
                ),
                Text(
                  publicacion.totalComentarios.toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForTipo(String tipo) {
    switch (tipo) {
      case 'consejo':
        return Colors.blue;
      case 'progreso':
        return Colors.green;
      case 'problema':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleMeGusta(Publicacion publicacion) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await PublicacionService.toggleMeGusta(publicacion.id);
      _cargarPublicaciones();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _mostrarComentarios(Publicacion publicacion) {
    // TODO: Implementar vista de comentarios
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comentarios'),
        content: const Text('Función en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}