const express = require('express');
const router = express.Router();
const StockController = require('../controllers/stockController');
const { authMiddleware } = require('../database/middlewares/auth');

router.post('/movimientos', authMiddleware, StockController.registrarMovimiento);
router.get('/movimientos', authMiddleware, StockController.obtenerMovimientos);
router.get('/movimientos/todos', authMiddleware, StockController.obtenerMovimientosGlobales);
router.get('/productos', authMiddleware, StockController.obtenerStock);
router.get('/stock', authMiddleware, StockController.obtenerStock); // Alias para compatibilidad
router.delete('/movimientos/historial', authMiddleware, StockController.eliminarHistorialVentas);
// Alias para compatibilidad con el frontend antiguo
router.get('/productos/stock', authMiddleware, StockController.obtenerStock);

module.exports = router;