const express = require('express');
const router = express.Router();
const PublicacionController = require('../controllers/publicacionController');
const { authMiddleware } = require('../database/middlewares/auth');

// ===== RUTAS PÚBLICAS =====

// Listar publicaciones (público)
router.get('/', PublicacionController.listarPublicaciones);

// Obtener publicación por ID (público)
router.get('/:id', PublicacionController.obtenerPublicacion);

// ===== RUTAS AUTENTICADAS =====

// Crear nueva publicación (emprendedor verificado)
router.post('/', authMiddleware, PublicacionController.crearPublicacion);

// Agregar comentario (usuario autenticado)
router.post('/:id/comentarios', authMiddleware, PublicacionController.agregarComentario);

// Reaccionar a publicación (usuario autenticado)
router.post('/:id/reacciones', authMiddleware, PublicacionController.reaccionar);

// ===== RUTAS ADMINISTRATIVAS =====

// Moderar publicación (admin)
router.put('/:id/moderar', authMiddleware, PublicacionController.moderarPublicacion);

module.exports = router;