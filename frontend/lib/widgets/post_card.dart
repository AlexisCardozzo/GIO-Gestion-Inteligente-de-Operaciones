import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../utils/colors.dart';
import '../utils/format.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del post
          ListTile(
            leading: CircleAvatar(
              backgroundColor: GioColors.primaryLight,
              child: Text(
                post.autorNombre[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              post.autorNombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              formatearFecha(post.fechaCreacion),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // Implementar acciones del menú
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reportar',
                  child: Text('Reportar'),
                ),
              ],
            ),
          ),

          // Contenido del post
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              post.contenido,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),

          // Hashtags
          if (post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: post.hashtags.map((hashtag) {
                  return Text(
                    '#$hashtag',
                    style: TextStyle(
                      color: GioColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ),

          // Acciones
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.favorite,
                  count: post.likesCount,
                  isActive: post.liked,
                  onTap: () async {
                    try {
                      await PostService.toggleLike(post.id);
                      // Actualizar estado
                    } catch (e) {
                      // Manejar error
                    }
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment,
                  count: post.comentariosCount,
                  onTap: () => _mostrarComentarios(context),
                ),
              ],
            ),
          ),

          // Comentarios previos
          if (post.comentarios.isNotEmpty) ...[
            const Divider(),
            ...post.comentarios.map((comentario) => ListTile(
              leading: CircleAvatar(
                backgroundColor: GioColors.primaryLight,
                radius: 16,
                child: Text(
                  comentario.autorNombre[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                comentario.contenido,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                formatearFecha(comentario.fechaCreacion),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? GioColors.primary : Colors.grey[600],
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isActive ? GioColors.primary : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarComentarios(BuildContext context) {
    final comentarioController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: comentarioController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () async {
                      if (comentarioController.text.trim().isEmpty) return;

                      try {
                        await PostService.comentar(
                          post.id,
                          comentarioController.text,
                        );
                        Navigator.pop(context);
                        // Actualizar estado
                      } catch (e) {
                        // Manejar error
                      }
                    },
                    icon: const Icon(Icons.send),
                    color: GioColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
