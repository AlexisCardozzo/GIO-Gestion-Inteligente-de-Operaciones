const Reporte = require('../models/Reporte');
const User = require('../models/User');
const Rol = require('../models/Rol');

class ReporteController {
  static async crearReporte(req, res) {
    try {
      console.log('Headers de autenticación:', req.headers.authorization);
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      const usuario_id = req.user.id;
      console.log('Usuario ID para crear reporte:', usuario_id);
      console.log('Datos del usuario:', req.user);
      const { ventas, ganancia_bruta, ganancia_neta, productos_vendidos, ventas_por_dia } = req.body;
      const reporte = await Reporte.crear({ ventas, ganancia_bruta, ganancia_neta, productos_vendidos, ventas_por_dia, usuario_id });
      console.log('Reporte creado:', reporte);
      res.status(201).json({ success: true, data: reporte });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async listarReportes(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      const usuario_id = req.user.id;
      const reportes = await Reporte.listar(usuario_id);
      res.json({ success: true, data: reportes });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async obtenerReporte(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      const usuario_id = req.user.id;
      const { id } = req.params;
      const reporte = await Reporte.obtenerPorId(id, usuario_id);
      if (!reporte) {
        return res.status(404).json({ success: false, error: 'Reporte no encontrado o no tienes permiso para acceder a él' });
      }
      res.json({ success: true, data: reporte });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async eliminarSegura(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      const usuario_id = req.user.id;
      const { ids } = req.body;
      if (!ids || !Array.isArray(ids) || ids.length === 0) {
        return res.status(400).json({ success: false, error: 'Datos incompletos' });
      }
      await Reporte.moverAPapelera(ids, usuario_id);
      res.json({ success: true, message: 'Reportes movidos a papelera. Se eliminarán definitivamente en 15 días.' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async listarPapelera(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      const usuario_id = req.user.id;
      const reportes = await Reporte.listarPapelera(usuario_id);
      res.json({ success: true, data: reportes });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async restaurar(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      const usuario_id = req.user.id;
      const { ids } = req.body;
      if (!ids || !Array.isArray(ids) || ids.length === 0) {
        return res.status(400).json({ success: false, error: 'Datos incompletos' });
      }
      await Reporte.restaurar(ids, usuario_id);
      res.json({ success: true, message: 'Reportes restaurados correctamente.' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async borrarDefinitivos(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      const usuario_id = req.user.id;
      await Reporte.borrarDefinitivos(usuario_id);
      res.json({ success: true, message: 'Reportes eliminados definitivamente.' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async eliminarDefinitivoPorIds(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      const usuario_id = req.user.id;
      const { ids } = req.body;
      if (!ids || !Array.isArray(ids) || ids.length === 0) {
        return res.status(400).json({ success: false, error: 'Datos incompletos' });
      }
      await Reporte.borrarPorIds(ids, usuario_id);
      res.json({ success: true, message: 'Reportes eliminados permanentemente.' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = ReporteController;