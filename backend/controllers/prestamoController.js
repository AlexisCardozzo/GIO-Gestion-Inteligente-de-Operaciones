const Cliente = require('../models/Cliente');
const CompiladorDatosBancarios = require('../services/compiladorDatosBancarios');
const pool = require('../config/database');

class PrestamoController {
  
  /**
   * Procesa verificación de identidad (guarda como pendiente)
   */
  static async procesarVerificacionIdentidad(req, res) {
    try {
      const { clienteId, ciNumero, nombre, ciFrenteUrl, ciReversoUrl } = req.body;
      
      const usuario_id = req.user ? req.user.userId : null;
      
      // Validar que el nombre coincida con el registro
      const cliente = await Cliente.obtenerPorId(clienteId, usuario_id);
      if (!cliente) {
        return res.status(404).json({ error: 'Cliente no encontrado o no pertenece a este usuario' });
      }
      
      if (cliente.nombre.toLowerCase() !== nombre.toLowerCase()) {
        return res.status(400).json({ 
          error: 'El nombre no coincide con el registro del sistema' 
        });
      }
      
      // Guardar solicitud de verificación como pendiente
      const datosSolicitud = {
        ci_numero: ciNumero,
        nombre: nombre,
        ci_frente_url: ciFrenteUrl,
        ci_reverso_url: ciReversoUrl
      };
      
      const query = `
        INSERT INTO solicitudes_prestamos 
        (cliente_id, tipo_solicitud, datos_solicitud, estado)
        VALUES ($1, $2, $3, $4)
        RETURNING *
      `;
      
      const result = await pool.query(query, [
        clienteId, 
        'verificacion_identidad', 
        JSON.stringify(datosSolicitud),
        'pendiente'
      ]);
      
      res.json({
        success: true,
        message: 'Solicitud de verificación enviada. Será revisada por nuestro equipo.',
        solicitud_id: result.rows[0].id
      });
      
    } catch (error) {
      console.error('Error procesando verificación:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
  
  /**
   * Procesa solicitud de préstamo (guarda como pendiente)
   */
  static async procesarSolicitudPrestamo(req, res) {
    try {
      const { clienteId, monto, proposito, planNegocio } = req.body;
      
      const usuario_id = req.user ? req.user.userId : null;
      
      const cliente = await Cliente.obtenerPorId(clienteId, usuario_id);
      if (!cliente) {
        return res.status(404).json({ error: 'Cliente no encontrado o no pertenece a este usuario' });
      }
      
      if (!cliente.verificado) {
        return res.status(400).json({ 
          error: 'Cliente debe estar verificado para solicitar préstamos' 
        });
      }
      
      // Validar monto según el tipo de préstamo
      const prestamosDisponibles = await this.obtenerPrestamosDisponibles(clienteId);
      const prestamoSolicitado = prestamosDisponibles.find(p => p.monto === monto);
      
      if (!prestamoSolicitado || !prestamoSolicitado.disponible) {
        return res.status(400).json({ 
          error: 'Monto de préstamo no disponible para este cliente' 
        });
      }
      
      // Compilar datos para análisis
      const datosAnalisis = await CompiladorDatosBancarios.compilarDatosCliente(clienteId);
      
      // Guardar solicitud de préstamo como pendiente
      const query = `
        INSERT INTO solicitudes_prestamos 
        (cliente_id, tipo_solicitud, monto, proposito, plan_negocio, datos_solicitud, datos_analisis, estado)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
      `;
      
      const datosSolicitud = {
        monto: monto,
        proposito: proposito,
        plan_negocio: planNegocio,
        prestamo_tipo: prestamoSolicitado.nombre
      };
      
      const result = await pool.query(query, [
        clienteId,
        'prestamo',
        monto,
        proposito,
        planNegocio,
        JSON.stringify(datosSolicitud),
        JSON.stringify(datosAnalisis),
        'pendiente'
      ]);
      
      res.json({
        success: true,
        message: 'Solicitud de préstamo enviada para revisión',
        solicitud_id: result.rows[0].id
      });
      
    } catch (error) {
      console.error('Error procesando solicitud de préstamo:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
  
  /**
   * Obtiene solicitudes pendientes para revisión
   */
  static async obtenerSolicitudesPendientes(req, res) {
    try {
      const query = `
        SELECT 
          sp.id,
          sp.cliente_id,
          sp.tipo_solicitud,
          sp.monto,
          sp.proposito,
          sp.plan_negocio,
          sp.estado,
          sp.datos_solicitud,
          sp.datos_analisis,
          sp.fecha_solicitud,
          sp.fecha_revision,
          sp.revisado_por,
          sp.comentarios_revision,
          c.nombre as cliente_nombre,
          c.email as cliente_email,
          c.telefono as cliente_telefono,
          c.score_credito,
          c.categoria_riesgo,
          c.ingresos_promedio_mensual
        FROM solicitudes_prestamos sp
        JOIN clientes c ON sp.cliente_id = c.id
        WHERE sp.estado = 'pendiente' AND sp.activo = true
        ORDER BY sp.fecha_solicitud ASC
      `;
      
      const result = await pool.query(query);
      
      res.json({
        success: true,
        solicitudes: result.rows
      });
      
    } catch (error) {
      console.error('Error obteniendo solicitudes pendientes:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
  
  /**
   * Aprueba o rechaza una solicitud
   */
  static async revisarSolicitud(req, res) {
    try {
      const { solicitudId } = req.params;
      const { accion, comentarios } = req.body; // accion: 'aprobar' o 'rechazar'
      const userId = req.user.id; // ID del usuario que revisa
      
      if (!['aprobar', 'rechazar'].includes(accion)) {
        return res.status(400).json({ error: 'Acción inválida' });
      }
      
      // Obtener la solicitud
      const solicitudQuery = `
        SELECT * FROM solicitudes_prestamos 
        WHERE id = $1 AND activo = true
      `;
      const solicitudResult = await pool.query(solicitudQuery, [solicitudId]);
      
      if (solicitudResult.rows.length === 0) {
        return res.status(404).json({ error: 'Solicitud no encontrada' });
      }
      
      const solicitud = solicitudResult.rows[0];
      
      // Actualizar estado de la solicitud
      const updateQuery = `
        UPDATE solicitudes_prestamos 
        SET estado = $1, fecha_revision = $2, revisado_por = $3, comentarios_revision = $4
        WHERE id = $5
        RETURNING *
      `;
      
      await pool.query(updateQuery, [
        accion === 'aprobar' ? 'aprobado' : 'rechazado',
        new Date(),
        userId,
        comentarios || '',
        solicitudId
      ]);
      
      // Si se aprueba, procesar según el tipo
      if (accion === 'aprobar') {
        if (solicitud.tipo_solicitud === 'verificacion_identidad') {
          // Aprobar verificación de identidad
          const datosSolicitud = JSON.parse(solicitud.datos_solicitud);
          const usuario_id = req.user ? req.user.userId : null;
          
          await Cliente.actualizarDatosPrestamos(solicitud.cliente_id, {
            ci_numero: datosSolicitud.ci_numero,
            ci_frente_url: datosSolicitud.ci_frente_url,
            ci_reverso_url: datosSolicitud.ci_reverso_url,
            verificado: true,
            fecha_verificacion: new Date()
          }, usuario_id);
          
          // Compilar datos automáticamente
          await CompiladorDatosBancarios.compilarDatosCliente(solicitud.cliente_id);
          
        } else if (solicitud.tipo_solicitud === 'prestamo') {
          // Aprobar préstamo
          const datosSolicitud = JSON.parse(solicitud.datos_solicitud);
          const usuario_id = req.user ? req.user.userId : null;
          const clienteInfo = await Cliente.obtenerPorId(solicitud.cliente_id, usuario_id);
          
          if (clienteInfo) {
            await Cliente.actualizarDatosPrestamos(solicitud.cliente_id, {
              prestamos_solicitados: clienteInfo.prestamos_solicitados + 1,
              prestamos_aprobados: clienteInfo.prestamos_aprobados + 1
            }, usuario_id);
          }
        }
      }
      
      res.json({
        success: true,
        message: `Solicitud ${accion === 'aprobar' ? 'aprobada' : 'rechazada'} exitosamente`
      });
      
    } catch (error) {
      console.error('Error revisando solicitud:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
  
  /**
   * Obtiene préstamos disponibles para un cliente
   */
  static async obtenerPrestamosDisponibles(clienteId, usuario_id = null) {
    const cliente = await Cliente.obtenerPorId(clienteId, usuario_id);
    if (!cliente || !cliente.verificado) {
      return [];
    }
    
    const prestamos = [
      {
        id: 1,
        nombre: 'Préstamo de Formalización',
        monto: 1500000,
        interes: 2.5,
        plazo: 12,
        disponible: !cliente.prestamos_solicitados || cliente.prestamos_pagados > 0,
        descripcion: 'Para formalizar y legalizar tu negocio'
      },
      {
        id: 2,
        nombre: 'Préstamo de Crecimiento',
        monto: 5000000,
        interes: 3.0,
        plazo: 24,
        disponible: cliente.prestamos_pagados > 0 && cliente.prestamos_vencidos === 0,
        descripcion: 'Para expandir tu negocio (requiere haber pagado el primer préstamo)'
      },
      {
        id: 3,
        nombre: 'Préstamo Premium',
        monto: 50000000,
        interes: 4.5,
        plazo: 36,
        disponible: cliente.prestamos_pagados >= 2 && cliente.score_credito >= 750,
        descripcion: 'Para expansión mayor (requiere excelente historial crediticio)'
      }
    ];
    
    return prestamos;
  }
  
  /**
   * Endpoint para obtener préstamos disponibles
   */
  static async getPrestamosDisponibles(req, res) {
    try {
      const { clienteId } = req.params;
      const usuario_id = req.user ? req.user.userId : null;
      const prestamos = await this.obtenerPrestamosDisponibles(clienteId, usuario_id);
      
      res.json({
        success: true,
        prestamos: prestamos
      });
      
    } catch (error) {
      console.error('Error obteniendo préstamos disponibles:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
  
  /**
   * Endpoint para obtener datos compilados de un cliente
   */
  static async getDatosCompilados(req, res) {
    try {
      const { clienteId } = req.params;
      const usuario_id = req.user ? req.user.userId : null;
      
      const cliente = await Cliente.obtenerPorId(clienteId, usuario_id);
      if (!cliente) {
        return res.status(404).json({ error: 'Cliente no encontrado o no pertenece a este usuario' });
      }
      
      if (!cliente.verificado) {
        return res.status(400).json({ 
          error: 'Cliente debe estar verificado' 
        });
      }
      
      const datosCompilados = await CompiladorDatosBancarios.compilarDatosCliente(clienteId, usuario_id);
      
      res.json({
        success: true,
        datos: datosCompilados
      });
      
    } catch (error) {
      console.error('Error obteniendo datos compilados:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
  
  /**
   * Endpoint para generar reporte de venta a bancos
   */
  static async generarReporteVenta(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ error: 'No autorizado' });
      }
      
      const usuario_id = req.user.userId;
      const reporte = await CompiladorDatosBancarios.generarReporteVenta(usuario_id);
      
      res.json({
        success: true,
        reporte: reporte
      });
      
    } catch (error) {
      console.error('Error generando reporte de venta:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
  
  /**
   * Endpoint para compilar todos los datos
   */
  static async compilarTodosLosDatos(req, res) {
    try {
      const resultados = await CompiladorDatosBancarios.compilarTodosLosDatos();
      
      res.json({
        success: true,
        total_procesados: resultados.length,
        exitosos: resultados.filter(r => r.estado === 'exitoso').length,
        errores: resultados.filter(r => r.estado === 'error').length,
        resultados: resultados
      });
      
    } catch (error) {
      console.error('Error compilando todos los datos:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
}

module.exports = PrestamoController;