const Sucursal = require('../models/Sucursal');

class SucursalController {
  // Crear una nueva sucursal
  static async crear(req, res) {
    try {
      const { nombre, direccion } = req.body;
      const usuario_id = req.user.userId; // Se asume autenticación JWT

      if (!nombre || !direccion) {
        return res.status(400).json({ success: false, error: 'Nombre y dirección son obligatorios' });
      }

      const sucursal = await Sucursal.crear({ nombre, direccion, usuario_id });
      console.log('✅ Sucursal creada:', sucursal.nombre, 'ID:', sucursal.id, 'Usuario:', sucursal.usuario_id);
      res.status(201).json({ success: true, data: sucursal });
    } catch (error) {
      console.error('❌ Error creando sucursal:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Listar sucursales por usuario
  static async listarPorUsuario(req, res) {
    try {
      const usuario_id = req.user.userId;
      const sucursales = await Sucursal.buscarPorUsuario(usuario_id);
      res.json({ success: true, data: sucursales });
    } catch (error) {
      console.error('❌ Error listando sucursales:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }
}

module.exports = SucursalController; 