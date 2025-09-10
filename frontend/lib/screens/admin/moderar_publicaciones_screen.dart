import 'package:flutter/material.dart';
import '../../models/publicacion.dart';
import '../../services/publicacion_service.dart';

class ModerarPublicacionesScreen extends StatefulWidget {
  const ModerarPublicacionesScreen({Key? key}) : super(key: key);

  @override
  State<ModerarPublicacionesScreen> createState() => _ModerarPublicacionesScreenState();
}

class _ModerarPublicacionesScreenState extends State<ModerarPublicacionesScreen> {
  List<Publicacion> _publicaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPublicaciones();
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

  Future<void> _eliminarPublicacion(Publicacion publicacion) async {
    try {
      await PublicacionService.eliminarPublicacion(publicacion.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarPublicaciones();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando publicación: $e')),
      );
    }
  }

  void _confirmarEliminacion(Publicacion publicacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _eliminarPublicacion(publicacion);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderar Publicaciones'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarPublicaciones,
              child: _publicaciones.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay publicaciones para moderar',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _publicaciones.length,
                      itemBuilder: (context, index) {
                        final publicacion = _publicaciones[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          child: ListTile(
                            title: Text(
                              publicacion.titulo,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text('Autor: ${publicacion.autorNombre}'),
                                Text('Tipo: ${publicacion.tipo}'),
                                Text('Estado: ${publicacion.estado}'),
                                const SizedBox(height: 8),
                                Text(
                                  publicacion.contenido,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'ver':
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => Scaffold(
                                          appBar: AppBar(
                                            title: Text(publicacion.titulo),
                                            backgroundColor: const Color(0xFF1E3A8A),
                                            foregroundColor: Colors.white,
                                          ),
                                          body: SingleChildScrollView(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Autor: ${publicacion.autorNombre}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tipo: ${publicacion.tipo}',
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                Text(
                                                  'Estado: ${publicacion.estado}',
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  publicacion.contenido,
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                    break;
                                  case 'eliminar':
                                    _confirmarEliminacion(publicacion);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'ver',
                                  child: Text('Ver detalles'),
                                ),
                                const PopupMenuItem(
                                  value: 'eliminar',
                                  child: Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}