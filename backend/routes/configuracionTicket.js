const express = require('express');
const router = express.Router();
const configuracionTicketController = require('../controllers/configuracionTicketController');
const { authMiddleware } = require('../database/middlewares/auth');

// Rutas para la configuración de tickets
// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Obtener la configuración de ticket del usuario autenticado
router.get('/', configuracionTicketController.obtenerConfiguracion);

// Guardar o actualizar la configuración de ticket
router.post('/', configuracionTicketController.guardarConfiguracion);

module.exports = router;