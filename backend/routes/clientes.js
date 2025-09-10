const express = require('express');
const router = express.Router();
const ClienteController = require('../controllers/clienteController');
const { authMiddleware } = require('../database/middlewares/auth');

// Crear cliente
router.post('/', authMiddleware, async (req, res) => {
  try {
    // Verificamos autenticación pero no pasamos usuario_id al modelo
    const usuario_id = req.user ? req.user.userId : null;
    
    if (!usuario_id) {
      return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
    }
    
    const { ci_ruc, nombre, celular } = req.body;
    if (!nombre || !celular) {
      return res.status(400).json({ success: false, error: 'Nombre y celular son obligatorios.' });
    }
    // Modificado para no pasar usuario_id
    const cliente = await require('../models/Cliente').crear({ ci_ruc, nombre, celular, usuario_id });
    res.status(201).json({ success: true, data: cliente });
  } catch (error) {
    console.error('Error al crear cliente:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// Listar clientes
router.get('/', authMiddleware, ClienteController.listarClientes);

module.exports = router;