const express = require('express');
const router = express.Router();
const FondoSolidarioController = require('../controllers/fondoSolidarioController');

// ===== RUTAS PÚBLICAS =====

// Listar emprendedores verificados (público)
router.get('/emprendedores/verificados', FondoSolidarioController.listarEmprendedoresVerificados);

// Obtener emprendedor por ID (público)
router.get('/emprendedores/:id', FondoSolidarioController.obtenerEmprendedor);

// Registrar emprendedor (público)
router.post('/emprendedores', FondoSolidarioController.registrarEmprendedor);

// Realizar donación (público)
router.post('/donaciones', FondoSolidarioController.realizarDonacion);

// Agregar agradecimiento (público)
router.post('/donaciones/:id/agradecimiento', FondoSolidarioController.agregarAgradecimiento);

// Obtener estadísticas generales (público)
router.get('/estadisticas', FondoSolidarioController.obtenerEstadisticas);

// Obtener estadísticas de un emprendedor (público)
router.get('/emprendedores/:id/estadisticas', FondoSolidarioController.obtenerEstadisticasEmprendedor);

// ===== RUTAS ADMINISTRATIVAS =====

// Listar todos los emprendedores (admin)
router.get('/emprendedores', FondoSolidarioController.listarEmprendedores);

// Actualizar emprendedor (admin)
router.put('/emprendedores/:id', FondoSolidarioController.actualizarEmprendedor);

// Verificar emprendedor (admin)
router.post('/emprendedores/:id/verificar', FondoSolidarioController.verificarEmprendedor);

// Listar donaciones de un emprendedor (admin)
router.get('/emprendedores/:id/donaciones', FondoSolidarioController.listarDonacionesEmprendedor);

// Listar donaciones de un usuario (admin)
router.get('/usuarios/:id/donaciones', FondoSolidarioController.listarDonacionesUsuario);

// Listar todas las donaciones (admin)
router.get('/admin/donaciones', FondoSolidarioController.listarTodasDonaciones);

// Procesar donación (admin)
router.post('/admin/donaciones/:id/procesar', FondoSolidarioController.procesarDonacion);

module.exports = router;
