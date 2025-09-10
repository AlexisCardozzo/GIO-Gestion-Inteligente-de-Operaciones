const express = require('express');
const router = express.Router();
const ArticuloController = require('../controllers/articuloController');
const { authMiddleware } = require('../database/middlewares/auth');

// Listar todos los artículos (con filtro opcional)
router.get('/', authMiddleware, ArticuloController.listar);

// Buscar artículo por ID
router.get('/:id', authMiddleware, ArticuloController.buscarPorId);

// Crear artículo
router.post('/', authMiddleware, ArticuloController.crear);

// Actualizar artículo
router.put('/:id', authMiddleware, ArticuloController.actualizar);

// Eliminar artículo
router.delete('/:id', authMiddleware, ArticuloController.eliminar);

module.exports = router;