const express = require('express');
const router = express.Router();
const SucursalRolController = require('../controllers/sucursalRolController');
const { authMiddleware } = require('../database/middlewares/auth');

// Obtener sucursales y roles disponibles
router.get('/', authMiddleware, SucursalRolController.getSucursalesRoles);

// Seleccionar sucursal y rol
router.post('/seleccionar', authMiddleware, SucursalRolController.seleccionar);

module.exports = router;
