import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../utils/colors.dart';

class TrendingHashtags extends StatefulWidget {
  const TrendingHashtags({Key? key}) : super(key: key);

  @override
  State<TrendingHashtags> createState() => _TrendingHashtagsState();
}

class _TrendingHashtagsState extends State<TrendingHashtags> {
  List<Map<String, dynamic>> _hashtags = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHashtags();
  }

  Future<void> _cargarHashtags() async {
    try {
      final hashtags = await PostService.obtenerTrendingHashtags();
      setState(() {
        _hashtags = hashtags;
        _cargando = false;
      });
    } catch (e) {
      print('Error cargando hashtags: $e');
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hashtags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _hashtags.length,
        itemBuilder: (context, index) {
          final hashtag = _hashtags[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: CircleAvatar(
                backgroundColor: GioColors.primary,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              label: Text('#${hashtag['nombre']}'),
              backgroundColor: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
