const express = require('express');
const router = express.Router();
const SucursalController = require('../controllers/sucursalController');
const { authMiddleware } = require('../database/middlewares/auth');

// Crear sucursal
router.post('/', authMiddleware, SucursalController.crear);

// Listar sucursales del usuario autenticado
router.get('/', authMiddleware, SucursalController.listarPorUsuario);

module.exports = router;