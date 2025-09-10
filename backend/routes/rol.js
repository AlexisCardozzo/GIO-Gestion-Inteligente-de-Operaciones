const express = require('express');
const router = express.Router();
const RolController = require('../controllers/rolController');
const { authMiddleware } = require('../database/middlewares/auth');

// Crear rol en una sucursal
router.post('/', authMiddleware, RolController.crear);

// Listar roles de una sucursal
router.get('/', authMiddleware, RolController.listarPorSucursal);

// Autenticar rol
router.post('/login', authMiddleware, RolController.autenticar);

module.exports = router;