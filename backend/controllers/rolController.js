const Rol = require('../models/Rol');
const Sucursal = require('../models/Sucursal');
const jwt = require('jsonwebtoken');

class RolController {
  // Crear un nuevo rol en una sucursal
  static async crear(req, res) {
    try {
      const { nombre, password, tipo, sucursal_id } = req.body;
      if (!nombre || !password || !sucursal_id || !tipo) {
        return res.status(400).json({ success: false, error: 'Nombre, contraseña, tipo y sucursal_id son obligatorios' });
      }
      const rol = await Rol.crear({ nombre, password, tipo, sucursal_id });
      console.log('✅ Rol creado:', rol.nombre, 'Sucursal:', rol.sucursal_id, 'ID:', rol.id);
      res.status(201).json({ success: true, data: rol });
    } catch (error) {
      res.status(400).json({ success: false, error: error.message || 'Error creando rol' });
    }
  }

  // Listar roles de una sucursal
  static async listarPorSucursal(req, res) {
    try {
      const { sucursal_id } = req.query;
      if (!sucursal_id) {
        return res.status(400).json({ success: false, error: 'sucursal_id es obligatorio' });
      }
      const roles = await Rol.buscarPorSucursal(sucursal_id);
      res.json({ success: true, data: roles });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Error listando roles' });
    }
  }

  // Autenticar rol
  static async autenticar(req, res) {
    try {
      const { nombre, password, sucursal_id } = req.body;
      console.log('⚡ Intentando autenticar rol:', { nombre, sucursal_id });
      const usuario_id = req.user.userId; // Obtenemos el ID del usuario del token actual
      console.log('👤 Usuario ID del token:', usuario_id);

      if (!nombre || !password || !sucursal_id) {
        return res.status(400).json({ success: false, error: 'Nombre, contraseña y sucursal_id son obligatorios' });
      }

      // Verificar que la sucursal pertenece al usuario
      const sucursal = await Sucursal.buscarPorId(sucursal_id);
      if (!sucursal || sucursal.usuario_id !== usuario_id) {
        return res.status(403).json({ success: false, error: 'No tiene acceso a esta sucursal' });
      }

      const rol = await Rol.autenticar({ nombre, password, sucursal_id });
      if (!rol) {
        return res.status(401).json({ success: false, error: 'Credenciales inválidas' });
      }

      // Generar JWT completo con información del usuario, sucursal y rol
      const token = jwt.sign(
        {
          userId: usuario_id,
          rolId: rol.id,
          nombre: rol.nombre,
          tipo: rol.tipo,
          sucursal_id: rol.sucursal_id
        },
        process.env.JWT_SECRET || 'gio_secret_key',
        { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
      );
      res.json({ success: true, data: { ...rol, token } });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Error autenticando rol' });
    }
  }
}

module.exports = RolController; 