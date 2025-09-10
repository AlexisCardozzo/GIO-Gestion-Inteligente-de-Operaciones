const pool = require('../config/database');
const Emprendedor = require('../models/Emprendedor');
const User = require('../models/User');

class FondoSolidarioController {
  // ===== EMPRENDEDORES =====

  // Listar todos los emprendedores (admin)
  static async listarEmprendedores(req, res) {
    try {
      const { estado } = req.query;
      const emprendedores = await Emprendedor.listByStatus(estado);

      res.json({
        success: true,
        data: emprendedores
      });
    } catch (error) {
      console.error('Error listando emprendedores:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Listar emprendedores verificados (público)
  static async listarEmprendedoresVerificados(req, res) {
    try {
      const emprendedores = await Emprendedor.listVerified();

      res.json({
        success: true,
        data: emprendedores
      });
    } catch (error) {
      console.error('Error listando emprendedores verificados:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Obtener emprendedor por ID
  static async obtenerEmprendedor(req, res) {
    try {
      const { id } = req.params;
      const emprendedor = await Emprendedor.findById(id);

      if (!emprendedor) {
        return res.status(404).json({
          success: false,
          error: 'Emprendedor no encontrado'
        });
      }

      res.json({
        success: true,
        data: emprendedor
      });
    } catch (error) {
      console.error('Error obteniendo emprendedor:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Registrar emprendedor
  static async registrarEmprendedor(req, res) {
    try {
      const {
        nombre,
        apellido,
        email,
        telefono,
        historia,
        meta_descripcion,
        meta_recaudacion,
        categoria,
        ubicacion
      } = req.body;

      // Validaciones básicas
      if (!nombre || !apellido || !email || !telefono || !historia) {
        return res.status(400).json({
          success: false,
          error: 'Todos los campos obligatorios deben estar completos'
        });
      }

      // Verificar si el usuario está autenticado
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Debe iniciar sesión para registrarse como emprendedor'
        });
      }

      // Verificar si el usuario ya es emprendedor
      const existingEmprendedor = await Emprendedor.findByUserId(req.user.id);
      if (existingEmprendedor) {
        return res.status(400).json({
          success: false,
          error: 'Ya estás registrado como emprendedor'
        });
      }

      // Crear el emprendedor
      const emprendedor = await Emprendedor.create({
        user_id: req.user.id,
        nombre,
        apellido,
        email,
        telefono,
        historia,
        meta_descripcion,
        meta_recaudacion,
        categoria,
        ubicacion
      });

      res.status(201).json({
        success: true,
        data: emprendedor,
        message: 'Solicitud de emprendedor registrada exitosamente. En revisión.'
      });
    } catch (error) {
      console.error('Error registrando emprendedor:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Verificar emprendedor (admin)
  static async verificarEmprendedor(req, res) {
    try {
      const { id } = req.params;
      const { estado, motivo_rechazo } = req.body;

      // Validar rol de administrador
      if (req.user.rol !== 'admin') {
        return res.status(403).json({
          success: false,
          error: 'No tienes permisos para realizar esta acción'
        });
      }

      // Validar estado
      if (!estado || !['aprobado', 'rechazado', 'suspendido'].includes(estado)) {
        return res.status(400).json({
          success: false,
          error: 'Estado inválido'
        });
      }

      // Verificar si el emprendedor existe
      const emprendedor = await Emprendedor.findById(id);
      if (!emprendedor) {
        return res.status(404).json({
          success: false,
          error: 'Emprendedor no encontrado'
        });
      }

      // Actualizar estado
      const emprendedorActualizado = await Emprendedor.updateStatus(id, {
        estado,
        motivo_rechazo: estado === 'rechazado' ? motivo_rechazo : null
      });

      res.json({
        success: true,
        data: emprendedorActualizado,
        message: `Emprendedor ${estado} exitosamente`
      });
    } catch (error) {
      console.error('Error verificando emprendedor:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Actualizar emprendedor
  static async actualizarEmprendedor(req, res) {
    try {
      const { id } = req.params;
      const updates = req.body;

      // Validar que el usuario sea el propietario del perfil o un admin
      if (req.user.rol !== 'admin' && req.user.id !== updates.user_id) {
        return res.status(403).json({ success: false, error: 'No tienes permisos para actualizar este perfil' });
      }

      const emprendedorActualizado = await Emprendedor.update(id, updates);

      if (!emprendedorActualizado) {
        return res.status(404).json({ success: false, error: 'Emprendedor no encontrado' });
      }

      res.json({ success: true, data: emprendedorActualizado, message: 'Perfil de emprendedor actualizado exitosamente' });
    } catch (error) {
      console.error('Error actualizando emprendedor:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Realizar donación
  static async realizarDonacion(req, res) {
    try {
      const { emprendedor_id, monto, mensaje } = req.body;
      if (!req.user) {
        return res.status(401).json({ success: false, error: 'No autorizado' });
      }
      if (!emprendedor_id || !monto) {
        return res.status(400).json({ success: false, error: 'Emprendedor y monto son obligatorios' });
      }

      const donacion = await Emprendedor.addDonation(emprendedor_id, req.user.id, monto, mensaje);
      res.status(201).json({ success: true, data: donacion, message: 'Donación realizada exitosamente' });
    } catch (error) {
      console.error('Error realizando donación:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Agregar agradecimiento
  static async agregarAgradecimiento(req, res) {
    try {
      const { id } = req.params; // ID de la donación
      const { agradecimiento } = req.body;

      if (!agradecimiento) {
        return res.status(400).json({ success: false, error: 'El mensaje de agradecimiento es obligatorio' });
      }

      // Lógica para agregar el agradecimiento a la donación
      // Esto asume que tienes un método en Emprendedor o un modelo de Donacion para esto
      const donacionActualizada = await Emprendedor.addAgradecimientoToDonation(id, agradecimiento);

      if (!donacionActualizada) {
        return res.status(404).json({ success: false, error: 'Donación no encontrada' });
      }

      res.json({ success: true, data: donacionActualizada, message: 'Agradecimiento agregado exitosamente' });
    } catch (error) {
      console.error('Error agregando agradecimiento:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Obtener estado de verificación (para el emprendedor)
  static async obtenerEstadoVerificacion(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'No autorizado'
        });
      }

      const emprendedor = await Emprendedor.findByUserId(req.user.id);
      if (!emprendedor) {
        return res.status(404).json({
          success: false,
          error: 'No estás registrado como emprendedor'
        });
      }

      res.json({
        success: true,
        data: {
          estado: emprendedor.estado,
          verificado: emprendedor.verificado,
          fecha_verificacion: emprendedor.fecha_verificacion,
          motivo_rechazo: emprendedor.motivo_rechazo
        }
      });
    } catch (error) {
      console.error('Error obteniendo estado de verificación:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
  // Obtener estadísticas generales
  static async obtenerEstadisticas(req, res) {
    try {
      const stats = await Emprendedor.getGeneralStats();
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('Error obteniendo estadísticas generales:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Obtener estadísticas de un emprendedor
  static async obtenerEstadisticasEmprendedor(req, res) {
    try {
      const { id } = req.params;
      const stats = await Emprendedor.getEmprendedorStats(id);
      if (!stats) {
        return res.status(404).json({ success: false, error: 'Emprendedor no encontrado' });
      }
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('Error obteniendo estadísticas de emprendedor:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Listar donaciones de un emprendedor (admin)
  static async listarDonacionesEmprendedor(req, res) {
    try {
      const { id } = req.params;
      const donaciones = await Emprendedor.listDonationsByEmprendedor(id);
      res.json({ success: true, data: donaciones });
    } catch (error) {
      console.error('Error listando donaciones de emprendedor:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Listar donaciones de un usuario (admin)
  static async listarDonacionesUsuario(req, res) {
    try {
      const { id } = req.params;
      const donaciones = await Emprendedor.listDonationsByUser(id);
      res.json({ success: true, data: donaciones });
    } catch (error) {
      console.error('Error listando donaciones de usuario:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Listar todas las donaciones (admin)
  static async listarTodasDonaciones(req, res) {
    try {
      const donaciones = await Emprendedor.listAllDonations();
      res.json({ success: true, data: donaciones });
    } catch (error) {
      console.error('Error listando todas las donaciones:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // Procesar donación (admin)
  static async procesarDonacion(req, res) {
    try {
      const { id } = req.params;
      const { estado } = req.body; // 'aprobada' o 'rechazada'

      if (!estado || !['aprobada', 'rechazada'].includes(estado)) {
        return res.status(400).json({ success: false, error: 'Estado de donación inválido' });
      }

      const donacionActualizada = await Emprendedor.processDonation(id, estado);
      res.json({ success: true, data: donacionActualizada, message: `Donación ${estado} exitosamente` });
    } catch (error) {
      console.error('Error procesando donación:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }
}

module.exports = FondoSolidarioController;
