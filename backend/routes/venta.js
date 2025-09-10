const express = require('express');
const router = express.Router();
const VentaController = require('../controllers/ventaController');
const { authMiddleware } = require('../database/middlewares/auth');

// Rutas de ventas
router.get('/', authMiddleware, VentaController.listar);
router.get('/total', authMiddleware, VentaController.obtenerTotal);
router.post('/', authMiddleware, VentaController.crear);
router.get('/:id', authMiddleware, VentaController.buscarPorId);
router.get('/resumen', authMiddleware, VentaController.obtenerResumen);

// ===== ESTADÍSTICAS POR FORMA DE PAGO =====
router.get('/estadisticas/forma-pago', authMiddleware, VentaController.obtenerEstadisticasFormaPago);

// ===== BENEFICIOS DE CLIENTE =====
router.get('/cliente/:cliente_id/beneficios', authMiddleware, VentaController.verificarBeneficiosCliente);

module.exports = router;