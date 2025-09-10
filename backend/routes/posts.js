const express = require('express');
const router = express.Router();
const PostController = require('../controllers/postController');
const { authMiddleware } = require('../database/middlewares/auth');

// Aplicar middleware de autenticación a todas las rutas
router.use(authMiddleware);

// Rutas para posts
router.post('/', PostController.crear);
router.get('/feed', PostController.obtenerFeed);
router.post('/:post_id/like', PostController.toggleLike);
router.post('/:post_id/comentarios', PostController.crearComentario);

// Rutas para notificaciones
router.get('/notificaciones', PostController.obtenerNotificaciones);

// Rutas para hashtags
router.get('/trending', PostController.obtenerTrendingHashtags);

module.exports = router;
