const express = require('express');
const router = express.Router();
const FidelizacionController = require('../controllers/fidelizacionController');
const { authMiddleware } = require('../database/middlewares/auth');

// Rutas de campañas
router.get('/campanias', authMiddleware, FidelizacionController.listarCampanias);
router.get('/campanias/todas', authMiddleware, FidelizacionController.listarTodasCampanias);
router.get('/campanias/inactivas', authMiddleware, FidelizacionController.listarCampaniasInactivas);
router.post('/campanias', authMiddleware, FidelizacionController.crearCampania);
router.get('/campanias/:id', authMiddleware, FidelizacionController.obtenerCampania);
router.put('/campanias/:id', authMiddleware, FidelizacionController.editarCampania);
router.delete('/campanias/:id', authMiddleware, FidelizacionController.eliminarCampania);

// ===== REQUISITOS =====
router.get('/campanias/:campania_id/requisitos', authMiddleware, FidelizacionController.listarRequisitos);
router.post('/campanias/:campania_id/requisitos', authMiddleware, FidelizacionController.crearRequisito);
router.put('/requisitos/:id', authMiddleware, FidelizacionController.editarRequisito);
router.delete('/requisitos/:id', authMiddleware, FidelizacionController.eliminarRequisito);

// ===== BENEFICIOS =====
router.get('/campanias/:campania_id/beneficios', authMiddleware, FidelizacionController.listarBeneficios);
router.post('/campanias/:campania_id/beneficios', authMiddleware, FidelizacionController.crearBeneficio);
router.put('/beneficios/:id', authMiddleware, FidelizacionController.editarBeneficio);
router.delete('/beneficios/:id', authMiddleware, FidelizacionController.eliminarBeneficio);

// ===== PARTICIPANTES DE CAMPAÑA =====
router.get('/campanias/:campania_id/participantes', authMiddleware, FidelizacionController.obtenerParticipantesCampania);

// ===== CLIENTES FIELES =====
router.get('/clientes-fieles', authMiddleware, FidelizacionController.listarClientesFieles);
router.get('/clientes-fieles/:id', authMiddleware, FidelizacionController.obtenerClienteFiel);

// ===== CANJEAR BENEFICIOS =====
router.post('/canjear', authMiddleware, FidelizacionController.canjearBeneficio);

// ===== BENEFICIOS DISPONIBLES PARA CLIENTE =====
router.get('/clientes/:cliente_id/beneficios-disponibles', authMiddleware, FidelizacionController.obtenerBeneficiosDisponibles);

// ===== ESTADÍSTICAS =====
router.get('/estadisticas', authMiddleware, FidelizacionController.obtenerEstadisticas);

// ===== PROGRESO DEL BÚHO =====
router.get('/progreso-buho', authMiddleware, FidelizacionController.obtenerProgresoBuho);

// ===== CLIENTES EN RIESGO =====
router.get('/clientes-riesgo', authMiddleware, FidelizacionController.listarClientesRiesgo);
router.get('/clientes-riesgo/analizar', authMiddleware, FidelizacionController.analizarClientesRiesgo);
router.get('/clientes-riesgo/:cliente_id/opciones-mensaje', authMiddleware, FidelizacionController.obtenerOpcionesMensaje);
router.post('/clientes-riesgo/:cliente_id/mensaje', authMiddleware, FidelizacionController.enviarMensajeRetencion);
router.get('/clientes-riesgo/estadisticas', authMiddleware, FidelizacionController.obtenerEstadisticasRetencion);

module.exports = router;