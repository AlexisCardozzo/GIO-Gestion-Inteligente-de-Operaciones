const express = require('express');
const router = express.Router();
const PrestamoController = require('../controllers/prestamoController');
const { authMiddleware } = require('../database/middlewares/auth');

// Rutas públicas (para clientes)
router.post('/verificar-identidad', PrestamoController.procesarVerificacionIdentidad);
router.post('/solicitar-prestamo', PrestamoController.procesarSolicitudPrestamo);
router.get('/prestamos-disponibles/:clienteId', PrestamoController.getPrestamosDisponibles);
router.get('/datos-compilados/:clienteId', PrestamoController.getDatosCompilados);

// Rutas protegidas (solo para control interno)
router.get('/solicitudes-pendientes', authMiddleware, PrestamoController.obtenerSolicitudesPendientes);
router.put('/revisar-solicitud/:solicitudId', authMiddleware, PrestamoController.revisarSolicitud);
router.get('/reporte-venta', authMiddleware, PrestamoController.generarReporteVenta);
router.post('/compilar-datos', authMiddleware, PrestamoController.compilarTodosLosDatos);

module.exports = router;