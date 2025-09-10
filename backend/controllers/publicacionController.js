const Publicacion = require('../models/Publicacion');
const Emprendedor = require('../models/Emprendedor');
class PublicacionController {
  // Crear nueva publicación
  static async crearPublicacion(req, res) {
    try {
      const { tipo, titulo, contenido, imagen_url } = req.body;

      // Validaciones básicas
      if (!tipo || !titulo || !contenido) {
        return res.status(400).json({
          success: false,
          error: 'Todos los campos obligatorios deben estar completos'
        });
      }

      // Verificar si el usuario está autenticado y es emprendedor verificado
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Debe iniciar sesión para crear una publicación'
        });
      }

      const emprendedor = await Emprendedor.findByUserId(req.user.id);
      if (!emprendedor) {
        return res.status(403).json({
          success: false,
          error: 'Solo los emprendedores pueden crear publicaciones'
        });
      }

      if (!emprendedor.verificado || emprendedor.estado !== 'aprobado') {
        return res.status(403).json({
          success: false,
          error: 'Solo los emprendedores verificados pueden crear publicaciones'
        });
      }

      // Crear la publicación
      const publicacion = await Publicacion.create({
        emprendedor_id: emprendedor.id,
        tipo,
        titulo,
        contenido,
        imagen_url
      });

      res.status(201).json({
        success: true,
        data: publicacion,
        message: 'Publicación creada exitosamente'
      });
    } catch (error) {
      console.error('Error creando publicación:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Listar publicaciones
  static async listarPublicaciones(req, res) {
    try {
      const { tipo, limit = 20, offset = 0 } = req.query;
      const publicaciones = await Publicacion.listByType(tipo, parseInt(limit), parseInt(offset));

      res.json({
        success: true,
        data: publicaciones
      });
    } catch (error) {
      console.error('Error listando publicaciones:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Obtener publicación por ID
  static async obtenerPublicacion(req, res) {
    try {
      const { id } = req.params;
      const publicacion = await Publicacion.findById(id);

      if (!publicacion) {
        return res.status(404).json({
          success: false,
          error: 'Publicación no encontrada'
        });
      }

      res.json({
        success: true,
        data: publicacion
      });
    } catch (error) {
      console.error('Error obteniendo publicación:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Agregar comentario
  static async agregarComentario(req, res) {
    try {
      const { id } = req.params;
      const { contenido } = req.body;

      // Validaciones
      if (!contenido || contenido.trim() === '') {
        return res.status(400).json({
          success: false,
          error: 'El comentario no puede estar vacío'
        });
      }

      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Debe iniciar sesión para comentar'
        });
      }

      // Verificar si la publicación existe
      const publicacion = await Publicacion.findById(id);
      if (!publicacion) {
        return res.status(404).json({
          success: false,
          error: 'Publicación no encontrada'
        });
      }

      // Agregar comentario
      const comentario = await Publicacion.addComment({
        publicacion_id: id,
        usuario_id: req.user.id,
        contenido: contenido.trim()
      });

      res.status(201).json({
        success: true,
        data: comentario,
        message: 'Comentario agregado exitosamente'
      });
    } catch (error) {
      console.error('Error agregando comentario:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Reaccionar a publicación
  static async reaccionar(req, res) {
    try {
      const { id } = req.params;

      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Debe iniciar sesión para reaccionar'
        });
      }

      // Verificar si la publicación existe
      const publicacion = await Publicacion.findById(id);
      if (!publicacion) {
        return res.status(404).json({
          success: false,
          error: 'Publicación no encontrada'
        });
      }

      // Toggle reacción
      const publicacionActualizada = await Publicacion.toggleReaction({
        publicacion_id: id,
        usuario_id: req.user.id
      });

      res.json({
        success: true,
        data: publicacionActualizada,
        message: 'Reacción actualizada exitosamente'
      });
    } catch (error) {
      console.error('Error actualizando reacción:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Moderar publicación (admin)
  static async moderarPublicacion(req, res) {
    try {
      const { id } = req.params;
      const { estado, motivo_rechazo } = req.body;

      // Validar rol de administrador
      if (req.user.rol !== 'admin') {
        return res.status(403).json({ success: false, error: 'No tienes permisos para realizar esta acción' });
      }

      // Validar estado
      if (!estado || !['aprobado', 'rechazado', 'pendiente'].includes(estado)) {
        return res.status(400).json({ success: false, error: 'Estado inválido' });
      }

      // Verificar si la publicación existe
      const publicacion = await Publicacion.findById(id);
      if (!publicacion) {
        return res.status(404).json({ success: false, error: 'Publicación no encontrada' });
      }

      // Actualizar estado
      const publicacionActualizada = await Publicacion.updateStatus(id, { estado, motivo_rechazo });

      res.json({ success: true, data: publicacionActualizada, message: `Publicación ${estado} exitosamente` });
    } catch (error) {
      console.error('Error moderando publicación:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }
}

module.exports = PublicacionController;