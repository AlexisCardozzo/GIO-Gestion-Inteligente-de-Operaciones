const Cliente = require('../models/Cliente');

class ClienteController {
  static async listarClientes(req, res) {
    try {
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }

      const filtro = req.query.busqueda || '';
      const clientes = await Cliente.listar(filtro, usuario_id);
      res.json({ success: true, data: clientes });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async historialCompras(req, res) {
    try {
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const clienteId = req.params.id;
      const historial = await Cliente.obtenerHistorialCompras(clienteId, usuario_id);
      res.json({ success: true, data: historial });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async editarCliente(req, res) {
    try {
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const id = req.params.id;
      const { nombre, celular } = req.body;
      if (!nombre || !celular) return res.status(400).json({ success: false, error: 'Nombre y celular son obligatorios.' });
      const cliente = await Cliente.editar(id, { nombre, celular }, usuario_id);
      
      if (!cliente) {
        return res.status(404).json({ success: false, error: 'Cliente no encontrado o no pertenece a este usuario' });
      }
      
      res.json({ success: true, data: cliente });
    } catch (error) {
      res.status(400).json({ success: false, error: error.message });
    }
  }

  static async desactivarCliente(req, res) {
    try {
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const id = req.params.id;
      const cliente = await Cliente.desactivar(id, usuario_id);
      
      if (!cliente) {
        return res.status(404).json({ success: false, error: 'Cliente no encontrado o no pertenece a este usuario' });
      }
      
      res.json({ success: true, data: cliente });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = ClienteController;

