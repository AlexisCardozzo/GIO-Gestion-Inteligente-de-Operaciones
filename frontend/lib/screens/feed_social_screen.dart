import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/post_service.dart';
import '../models/post.dart';
import '../utils/colors.dart';
import '../widgets/post_card.dart';
import '../widgets/trending_hashtags.dart';

class FeedSocialScreen extends StatefulWidget {
  const FeedSocialScreen({Key? key}) : super(key: key);

  @override
  State<FeedSocialScreen> createState() => _FeedSocialScreenState();
}

class _FeedSocialScreenState extends State<FeedSocialScreen> {
  final _scrollController = ScrollController();
  final _posts = <Post>[];
  bool _cargando = false;
  bool _hayMas = true;
  int _pagina = 1;
  
  @override
  void initState() {
    super.initState();
    _cargarPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarPosts({bool refresh = false}) async {
    if (_cargando) return;
    
    setState(() => _cargando = true);
    
    try {
      if (refresh) {
        _pagina = 1;
        _posts.clear();
      }

      final resultado = await PostService.obtenerFeed(
        page: _pagina,
        limit: 20,
      );

      setState(() {
        _posts.addAll(resultado.posts);
        _hayMas = resultado.hasMore;
        if (_hayMas) _pagina++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const delta = 200.0;

    if (maxScroll - currentScroll <= delta && !_cargando && _hayMas) {
      _cargarPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () => _cargarPosts(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: GioColors.primaryGradient,
                  ),
                ),
                title: const Text(
                  'Red de Historias',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Trending Hashtags
            const SliverToBoxAdapter(
              child: TrendingHashtags(),
            ),

            // Campo para crear nuevo post
            SliverToBoxAdapter(
              child: _buildNuevoPost(),
            ),

            // Lista de posts
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _posts.length) {
                    if (_cargando) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (!_hayMas) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hay más posts'),
                        ),
                      );
                    }
                    return null;
                  }

                  return PostCard(post: _posts[index]);
                },
                childCount: _posts.length + 1,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevoPost(),
        child: const Icon(Icons.add),
        backgroundColor: GioColors.primary,
      ),
    );
  }

  Widget _buildNuevoPost() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: GioColors.primaryLight,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _mostrarDialogoNuevoPost(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    '¿Qué está pasando?',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoNuevoPost() {
    final contenidoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Historia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contenidoController,
              decoration: const InputDecoration(
                hintText: '¿Qué está pasando?',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
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
              if (contenidoController.text.trim().isEmpty) return;

              Navigator.pop(context);
              try {
                await PostService.crear(contenidoController.text);
                _cargarPosts(refresh: true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GioColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }
}
