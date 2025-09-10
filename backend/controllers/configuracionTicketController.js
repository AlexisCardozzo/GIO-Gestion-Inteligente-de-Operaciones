const ConfiguracionTicket = require('../models/ConfiguracionTicket');
const { verificarToken } = require('../database/middlewares/auth');

// Controlador para la configuración de tickets
const configuracionTicketController = {
  // Obtener la configuración de ticket del usuario
  obtenerConfiguracion: async (req, res) => {
    try {
      const usuario_id = req.user.id;
      
      // Obtener la configuración actual
      const configuracion = await ConfiguracionTicket.obtenerConfiguracion(usuario_id);
      
      if (!configuracion) {
        return res.status(404).json({ error: 'No se encontró configuración de ticket para este usuario' });
      }
      
      res.json({ configuracion });
    } catch (error) {
      console.error('Error al obtener configuración de ticket:', error);
      res.status(500).json({ error: 'Error al obtener la configuración de ticket' });
    }
  },
  
  // Guardar o actualizar la configuración de ticket
  guardarConfiguracion: async (req, res) => {
    try {
      const usuario_id = req.user.id;
      const {
        nombre_negocio,
        direccion,
        telefono,
        mensaje_personalizado,
        mostrar_logo,
        mostrar_fecha,
        mostrar_numero_ticket,
        mostrar_vendedor,
        mostrar_cliente,
        pie_pagina
      } = req.body;
      
      // Validar campos requeridos
      if (!nombre_negocio) {
        return res.status(400).json({ error: 'El nombre del negocio es obligatorio' });
      }
      
      // Guardar la configuración
      const configuracion = await ConfiguracionTicket.guardarConfiguracion({
        usuario_id,
        nombre_negocio,
        direccion,
        telefono,
        mensaje_personalizado,
        mostrar_logo,
        mostrar_fecha,
        mostrar_numero_ticket,
        mostrar_vendedor,
        mostrar_cliente,
        pie_pagina
      });
      
      res.json({ 
        mensaje: 'Configuración de ticket guardada correctamente', 
        configuracion 
      });
    } catch (error) {
      console.error('Error al guardar configuración de ticket:', error);
      res.status(500).json({ error: 'Error al guardar la configuración de ticket' });
    }
  }
};

module.exports = configuracionTicketController;