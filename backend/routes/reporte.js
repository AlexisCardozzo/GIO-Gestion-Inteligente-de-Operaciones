const express = require('express');
const router = express.Router();
const ReporteController = require('../controllers/reporteController');
const { authMiddleware } = require('../database/middlewares/auth');

// Crear un nuevo reporte
router.post('/', authMiddleware, ReporteController.crearReporte);
// Listar todos los reportes
router.get('/', authMiddleware, ReporteController.listarReportes);
// Mover un reporte a la papelera con verificación de contraseña
router.post('/papelera', authMiddleware, ReporteController.eliminarSegura);
router.get('/papelera', authMiddleware, ReporteController.listarPapelera);
router.post('/restaurar', authMiddleware, ReporteController.restaurar);
router.delete('/papelera/definitivo', authMiddleware, ReporteController.borrarDefinitivos);
router.post('/papelera/eliminar-definitivo', authMiddleware, ReporteController.eliminarDefinitivoPorIds);
// Obtener un reporte por id
router.get('/:id', authMiddleware, ReporteController.obtenerReporte);

module.exports = router;