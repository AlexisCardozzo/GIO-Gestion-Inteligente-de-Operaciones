const FidelizacionCampania = require('../models/FidelizacionCampania');
const FidelizacionBeneficio = require('../models/FidelizacionBeneficio');
const FidelizacionRequisito = require('../models/FidelizacionRequisito');
const FidelizacionCliente = require('../models/FidelizacionCliente');
const MensajesPersonalizados = require('../services/mensajesPersonalizados');
const Gamificacion = require('../models/Gamificacion');
const pool = require('../config/database');

class FidelizacionController {
  // ===== CAMPAÑAS =====
  static async listarCampanias(req, res) {
    try {
      const { activa } = req.query; // Permitir filtrar por estado
      
      let whereClause = 'WHERE fc.activa = true'; // Por defecto solo activas
      let params = [];
      
      if (activa !== undefined) {
        whereClause = 'WHERE fc.activa = $1';
        params.push(activa === 'true');
      }
      
      const query = `
        SELECT 
          fc.*,
          COALESCE(requisitos_count.total_requisitos, 0) as total_requisitos,
          COALESCE(beneficios_count.total_beneficios, 0) as total_beneficios,
          COALESCE(clientes_count.total_clientes_participantes, 0) as total_clientes_participantes
        FROM fidelizacion_campanias fc
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_requisitos
          FROM fidelizacion_requisitos
          GROUP BY campania_id
        ) requisitos_count ON fc.id = requisitos_count.campania_id
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_beneficios
          FROM fidelizacion_beneficios
          GROUP BY campania_id
        ) beneficios_count ON fc.id = beneficios_count.campania_id
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_clientes_participantes
          FROM fidelizacion_clientes
          WHERE puntos_acumulados > 0
          GROUP BY campania_id
        ) clientes_count ON fc.id = clientes_count.campania_id
        ${whereClause}
        ORDER BY fc.creada_en DESC
      `;
      const result = await pool.query(query, params);
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('Error listando campañas:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async listarTodasCampanias(req, res) {
    try {
      const query = `
        SELECT 
          fc.*,
          COALESCE(requisitos_count.total_requisitos, 0) as total_requisitos,
          COALESCE(beneficios_count.total_beneficios, 0) as total_beneficios,
          COALESCE(clientes_count.total_clientes_participantes, 0) as total_clientes_participantes
        FROM fidelizacion_campanias fc
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_requisitos
          FROM fidelizacion_requisitos
          GROUP BY campania_id
        ) requisitos_count ON fc.id = requisitos_count.campania_id
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_beneficios
          FROM fidelizacion_beneficios
          GROUP BY campania_id
        ) beneficios_count ON fc.id = beneficios_count.campania_id
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_clientes_participantes
          FROM fidelizacion_clientes
          GROUP BY campania_id
        ) clientes_count ON fc.id = clientes_count.campania_id
        ORDER BY fc.creada_en DESC
      `;
      const result = await pool.query(query);
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('Error listando todas las campañas:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async listarCampaniasInactivas(req, res) {
    try {
      const query = `
        SELECT
          fc.*,
          COALESCE(requisitos_count.total_requisitos, 0) as total_requisitos,
          COALESCE(beneficios_count.total_beneficios, 0) as total_beneficios,
          COALESCE(clientes_count.total_clientes_participantes, 0) as total_clientes_participantes
        FROM fidelizacion_campanias fc
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_requisitos
          FROM fidelizacion_requisitos
          GROUP BY campania_id
        ) requisitos_count ON fc.id = requisitos_count.campania_id
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_beneficios
          FROM fidelizacion_beneficios
          GROUP BY campania_id
        ) beneficios_count ON fc.id = beneficios_count.campania_id
        LEFT JOIN (
          SELECT campania_id, COUNT(*) as total_clientes_participantes
          FROM fidelizacion_clientes
          WHERE puntos_acumulados > 0
          GROUP BY campania_id
        ) clientes_count ON fc.id = clientes_count.campania_id
        WHERE fc.activa = false
        ORDER BY fc.creada_en DESC
      `;
      const result = await pool.query(query);
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('Error listando campañas inactivas:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async crearCampania(req, res) {
    try {
      const { nombre, descripcion, fecha_inicio, fecha_fin } = req.body;
      
      // Validaciones básicas
      if (!nombre || !fecha_inicio || !fecha_fin) {
        return res.status(400).json({ 
          success: false, 
          error: 'Nombre, fecha de inicio y fecha de fin son obligatorios' 
        });
      }

      // Validar que fecha_fin > fecha_inicio
      if (new Date(fecha_fin) <= new Date(fecha_inicio)) {
        return res.status(400).json({ 
          success: false, 
          error: 'La fecha de fin debe ser posterior a la fecha de inicio' 
        });
      }

      // Validar que fecha_inicio no sea en el pasado
      const hoy = new Date();
      hoy.setHours(0, 0, 0, 0);
      const fechaInicioDate = new Date(fecha_inicio);
      
      // Comentado temporalmente para permitir fechas pasadas durante desarrollo
      // if (fechaInicioDate < hoy) {
      //   return res.status(400).json({ 
      //     success: false, 
      //     error: 'La fecha de inicio no puede ser en el pasado' 
      //   });
      // }

      const query = `
        INSERT INTO fidelizacion_campanias (nombre, descripcion, fecha_inicio, fecha_fin)
        VALUES ($1, $2, $3, $4)
        RETURNING *
      `;
      const result = await pool.query(query, [nombre, descripcion, fecha_inicio, fecha_fin]);
      
      console.log('✅ Campaña creada:', result.rows[0].nombre);
      res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) {
      console.error('Error creando campaña:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async obtenerCampania(req, res) {
    try {
      const { id } = req.params;
      const query = 'SELECT * FROM fidelizacion_campanias WHERE id = $1';
      const result = await pool.query(query, [id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Campaña no encontrada' });
      }
      
      res.json({ success: true, data: result.rows[0] });
    } catch (error) {
      console.error('Error obteniendo campaña:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async editarCampania(req, res) {
    try {
      const { id } = req.params;
      const { nombre, descripcion, fecha_inicio, fecha_fin, activa } = req.body;
      
      // Validaciones
      if (!nombre || !fecha_inicio || !fecha_fin) {
        return res.status(400).json({ 
          success: false, 
          error: 'Nombre, fecha de inicio y fecha de fin son obligatorios' 
        });
      }

      // Validar que fecha_fin > fecha_inicio
      if (new Date(fecha_fin) <= new Date(fecha_inicio)) {
        return res.status(400).json({ 
          success: false, 
          error: 'La fecha de fin debe ser posterior a la fecha de inicio' 
        });
      }

      const query = `
        UPDATE fidelizacion_campanias 
        SET nombre = $1, descripcion = $2, fecha_inicio = $3, fecha_fin = $4, activa = $5
        WHERE id = $6
        RETURNING *
      `;
      const result = await pool.query(query, [nombre, descripcion, fecha_inicio, fecha_fin, activa, id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Campaña no encontrada' });
      }
      
      console.log('✅ Campaña actualizada:', result.rows[0].nombre);
      res.json({ success: true, data: result.rows[0] });
    } catch (error) {
      console.error('Error actualizando campaña:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async eliminarCampania(req, res) {
    try {
      const { id } = req.params;
      
      // Soft delete - marcar como inactiva en lugar de eliminar
      const query = `
        UPDATE fidelizacion_campanias 
        SET activa = false
        WHERE id = $1
        RETURNING *
      `;
      const result = await pool.query(query, [id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Campaña no encontrada' });
      }
      
      console.log('✅ Campaña desactivada:', result.rows[0].nombre);
      res.json({ success: true, message: 'Campaña desactivada correctamente' });
    } catch (error) {
      console.error('Error desactivando campaña:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== REQUISITOS =====
  static async listarRequisitos(req, res) {
    try {
      const { campania_id } = req.params;
      const query = 'SELECT * FROM fidelizacion_requisitos WHERE campania_id = $1 ORDER BY creado_en DESC';
      const result = await pool.query(query, [campania_id, req.userId]);
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('Error listando requisitos:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async crearRequisito(req, res) {
    try {
      const { campania_id } = req.params;
      const { tipo, valor } = req.body;
      
      if (!tipo || !valor) {
        return res.status(400).json({ 
          success: false, 
          error: 'Tipo y valor son obligatorios' 
        });
      }

      const query = `
        INSERT INTO fidelizacion_requisitos (campania_id, tipo, valor)
        VALUES ($1, $2, $3)
        RETURNING *
      `;
      const result = await pool.query(query, [campania_id, tipo, valor]);
      
      console.log('✅ Requisito creado:', result.rows[0]);
      res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) {
      console.error('Error creando requisito:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async editarRequisito(req, res) {
    try {
      const { id } = req.params;
      const { tipo, valor } = req.body;
      
      if (!tipo || !valor) {
        return res.status(400).json({ 
          success: false, 
          error: 'Tipo y valor son obligatorios' 
        });
      }

      const query = `
        UPDATE fidelizacion_requisitos 
        SET tipo = $1, valor = $2
        WHERE id = $3
        RETURNING *
      `;
      const result = await pool.query(query, [tipo, valor, id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Requisito no encontrado' });
      }
      
      console.log('✅ Requisito actualizado:', result.rows[0]);
      res.json({ success: true, data: result.rows[0] });
    } catch (error) {
      console.error('Error actualizando requisito:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async eliminarRequisito(req, res) {
    try {
      const { id } = req.params;
      
      const query = 'DELETE FROM fidelizacion_requisitos WHERE id = $1 RETURNING *';
      const result = await pool.query(query, [id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Requisito no encontrado' });
      }
      
      console.log('✅ Requisito eliminado:', result.rows[0]);
      res.json({ success: true, message: 'Requisito eliminado correctamente' });
    } catch (error) {
      console.error('Error eliminando requisito:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== BENEFICIOS =====
  static async listarBeneficios(req, res) {
    try {
      const { campania_id } = req.params;
      const query = 'SELECT * FROM fidelizacion_beneficios WHERE campania_id = $1 ORDER BY creado_en DESC';
      const result = await pool.query(query, [campania_id]);
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('Error listando beneficios:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async crearBeneficio(req, res) {
    try {
      const { campania_id } = req.params;
      const { tipo, valor } = req.body;
      
      if (!tipo || !valor) {
        return res.status(400).json({ 
          success: false, 
          error: 'Tipo y valor son obligatorios' 
        });
      }

      const query = `
        INSERT INTO fidelizacion_beneficios (campania_id, tipo, valor)
        VALUES ($1, $2, $3)
        RETURNING *
      `;
      const result = await pool.query(query, [campania_id, tipo, valor]);
      
      console.log('✅ Beneficio creado:', result.rows[0]);
      res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) {
      console.error('Error creando beneficio:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async editarBeneficio(req, res) {
    try {
      const { id } = req.params;
      const { tipo, valor } = req.body;
      
      if (!tipo || !valor) {
        return res.status(400).json({ 
          success: false, 
          error: 'Tipo y valor son obligatorios' 
        });
      }

      const query = `
        UPDATE fidelizacion_beneficios 
        SET tipo = $1, valor = $2
        WHERE id = $3
        RETURNING *
      `;
      const result = await pool.query(query, [tipo, valor, id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Beneficio no encontrado' });
      }
      
      console.log('✅ Beneficio actualizado:', result.rows[0]);
      res.json({ success: true, data: result.rows[0] });
    } catch (error) {
      console.error('Error actualizando beneficio:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async eliminarBeneficio(req, res) {
    try {
      const { id } = req.params;
      
      const query = 'DELETE FROM fidelizacion_beneficios WHERE id = $1 RETURNING *';
      const result = await pool.query(query, [id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Beneficio no encontrado' });
      }
      
      console.log('✅ Beneficio eliminado:', result.rows[0]);
      res.json({ success: true, message: 'Beneficio eliminado correctamente' });
    } catch (error) {
      console.error('Error eliminando beneficio:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== CLIENTES FIELES =====
  static async listarClientesFieles(req, res) {
    try {
      const { userId } = req.user; // Obtener el userId del token de autenticación

      // Consulta optimizada con índices y límites
      const query = `
        SELECT 
          c.id,
          c.nombre,
          COALESCE(c.ci_ruc, 'N/A') as ci_ruc,
          COALESCE(c.celular, 'N/A') as celular,
          COUNT(v.id) as total_compras,
          COALESCE(SUM(v.total), 0) as total_gastado,
          MAX(v.fecha) as ultima_compra,
          MIN(v.fecha) as primera_compra,
          COALESCE(fcl.puntos_acumulados, 0) as puntos_fidelizacion,
          CASE 
            WHEN COALESCE(fcl.puntos_acumulados, 0) >= 100 THEN 'PLATINO'
            WHEN COALESCE(fcl.puntos_acumulados, 0) >= 50 THEN 'ORO'
            WHEN COALESCE(fcl.puntos_acumulados, 0) >= 20 THEN 'PLATA'
            ELSE 'BRONCE'
          END as nivel_fidelidad
        FROM clientes c
        LEFT JOIN ventas v ON c.id = v.cliente_id
        LEFT JOIN (
          SELECT 
            cliente_id,
            SUM(puntos_acumulados) as puntos_acumulados
          FROM fidelizacion_clientes
          GROUP BY cliente_id
        ) fcl ON c.id = fcl.cliente_id
        WHERE (c.activo = true OR c.activo IS NULL) AND c.usuario_id = $1
        GROUP BY c.id, c.nombre, c.ci_ruc, c.celular, fcl.puntos_acumulados, fcl.puntos_acumulados, c.usuario_id
        HAVING COUNT(v.id) > 0
        ORDER BY total_gastado DESC, total_compras DESC
        LIMIT 100
      `;
      
      console.log('🔍 Ejecutando consulta de clientes fieles...');
      const result = await pool.query(query, [userId]);
      console.log(`✅ Clientes fieles obtenidos: ${result.rows.length}`);
      
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('❌ Error listando clientes fieles:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async obtenerClienteFiel(req, res) {
    try {
      const { cliente_id } = req.params;
      const query = `
        SELECT 
          c.*,
          COUNT(v.id) as total_compras,
          COALESCE(SUM(v.total), 0) as total_gastado,
          MAX(v.fecha) as ultima_compra,
          MIN(v.fecha) as primera_compra,
          COALESCE(SUM(fcl.puntos_acumulados), 0) as puntos_fidelizacion,
          CASE 
            WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 100 THEN 'PLATINO'
            WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 50 THEN 'ORO'
            WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 20 THEN 'PLATA'
            ELSE 'BRONCE'
          END as nivel_fidelidad
        FROM clientes c
        LEFT JOIN ventas v ON c.id = v.cliente_id
        LEFT JOIN fidelizacion_clientes fcl ON c.id = fcl.cliente_id
        WHERE c.id = $1 AND c.activo = true
        GROUP BY c.id, c.nombre, c.ci_ruc, c.celular, fcl.puntos_acumulados
      `;
      const result = await pool.query(query, [cliente_id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Cliente no encontrado' });
      }
      
      res.json({ success: true, data: result.rows[0] });
    } catch (error) {
      console.error('Error obteniendo cliente fiel:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== CANJEAR BENEFICIOS =====
  static async canjearBeneficio(req, res) {
    try {
      const { cliente_id, beneficio_id } = req.body;
      
      if (!cliente_id || !beneficio_id) {
        return res.status(400).json({ 
          success: false, 
          error: 'Cliente ID y Beneficio ID son obligatorios' 
        });
      }

      // Verificar si el cliente cumple los requisitos
      const clienteQuery = `
        SELECT 
          c.id,
          COUNT(v.id) as total_compras,
          COALESCE(SUM(v.total), 0) as total_gastado
        FROM clientes c
        LEFT JOIN ventas v ON c.id = v.cliente_id
        WHERE c.id = $1
        GROUP BY c.id
      `;
      const clienteResult = await pool.query(clienteQuery, [cliente_id, req.userId]);
      
      if (clienteResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Cliente no encontrado' });
      }

      const cliente = clienteResult.rows[0];

      // Obtener el beneficio y sus requisitos
      const beneficioQuery = `
        SELECT 
          fb.*,
          fc.nombre as campania_nombre,
          fr.tipo as requisito_tipo,
          fr.valor as requisito_valor
        FROM fidelizacion_beneficios fb
        JOIN fidelizacion_campanias fc ON fb.campania_id = fc.id
        JOIN fidelizacion_requisitos fr ON fc.id = fr.campania_id
        WHERE fb.id = $1 AND fc.activa = true
      `;
      const beneficioResult = await pool.query(beneficioQuery, [beneficio_id]);
      
      if (beneficioResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Beneficio no encontrado' });
      }

      const beneficio = beneficioResult.rows[0];

      // Verificar si cumple los requisitos
      let cumpleRequisitos = false;
      if (beneficio.requisito_tipo === 'compras') {
        cumpleRequisitos = cliente.total_compras >= beneficio.requisito_valor;
      } else if (beneficio.requisito_tipo === 'monto') {
        cumpleRequisitos = cliente.total_gastado >= beneficio.requisito_valor;
      }

      if (!cumpleRequisitos) {
        return res.status(400).json({ 
          success: false, 
          error: 'El cliente no cumple los requisitos para este beneficio' 
        });
      }

      // Registrar el canje
      const canjeQuery = `
        INSERT INTO fidelizacion_clientes (cliente_id, campania_id, cumplio_requisitos, fecha_cumplimiento)
        VALUES ($1, $2, true, NOW())
        ON CONFLICT (cliente_id, campania_id) 
        DO UPDATE SET 
          cumplio_requisitos = true,
          fecha_cumplimiento = NOW()
      `;
      await pool.query(canjeQuery, [cliente_id, beneficio.campania_id]);

      console.log('✅ Beneficio canjeado:', { cliente_id, beneficio_id });
      res.json({ 
        success: true, 
        data: { 
          canjeado: true,
          beneficio: beneficio,
          cliente: cliente
        } 
      });
    } catch (error) {
      console.error('Error canjeando beneficio:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== BENEFICIOS DISPONIBLES PARA CLIENTE =====
  static async obtenerBeneficiosDisponibles(req, res) {
    try {
      const { cliente_id } = req.params;
      const { userId } = req.user; // Obtener el userId del token de autenticación
      
      if (!cliente_id) {
        return res.status(400).json({
          success: false,
          error: 'Cliente ID es obligatorio'
        });
      }

      // Obtener estadísticas del cliente
      const clienteQuery = `
        SELECT 
          c.id,
          c.nombre,
          COUNT(v.id) as total_compras,
          COALESCE(SUM(v.total), 0) as total_gastado
        FROM clientes c
        LEFT JOIN ventas v ON c.id = v.cliente_id
        WHERE c.id = $1 AND c.usuario_id = $2
        GROUP BY c.id, c.nombre
      `;
      const clienteResult = await pool.query(clienteQuery, [cliente_id, userId]);
      
      if (clienteResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Cliente no encontrado' });
      }

      const cliente = clienteResult.rows[0];

      // Obtener beneficios disponibles con sus requisitos
      const beneficiosQuery = `
        SELECT 
          fb.id as beneficio_id,
          fb.tipo as beneficio_tipo,
          fb.valor as beneficio_valor,
          fc.id as campania_id,
          fc.nombre as campania_nombre,
          fc.activa as campania_activa,
          fr.tipo as requisito_tipo,
          fr.valor as requisito_valor,
          'Requisito de ' || fr.tipo as requisito_descripcion,
          CASE 
            WHEN fr.tipo = 'compras' THEN ${cliente.total_compras} >= fr.valor
            WHEN fr.tipo = 'monto' THEN ${cliente.total_gastado} >= fr.valor
            ELSE false
          END as cumple_requisitos
        FROM fidelizacion_beneficios fb
        JOIN fidelizacion_campanias fc ON fb.campania_id = fc.id
        JOIN fidelizacion_requisitos fr ON fc.id = fr.campania_id
        WHERE fc.activa = true
        ORDER BY fc.nombre, fb.id
      `;
      
      const beneficiosResult = await pool.query(beneficiosQuery);

      // Agrupar beneficios por campaña
      const beneficiosPorCampania = {};
      beneficiosResult.rows.forEach(row => {
        if (!beneficiosPorCampania[row.campania_id]) {
          beneficiosPorCampania[row.campania_id] = {
            campania_id: row.campania_id,
            campania_nombre: row.campania_nombre,
            campania_activa: row.campania_activa,
            beneficios: []
          };
        }
        
        beneficiosPorCampania[row.campania_id].beneficios.push({
          beneficio_id: row.beneficio_id,
          beneficio_tipo: row.beneficio_tipo,
          beneficio_valor: row.beneficio_valor,
          requisito_tipo: row.requisito_tipo,
          requisito_valor: row.requisito_valor,
          requisito_descripcion: row.requisito_descripcion,
          cumple_requisitos: row.cumple_requisitos
        });
      });

      const resultado = {
        cliente: cliente,
        beneficios_disponibles: Object.values(beneficiosPorCampania)
      };

      console.log(`🎁 Beneficios disponibles para cliente ${cliente_id}: ${beneficiosResult.rows.length} beneficios`);
      res.json({ success: true, data: resultado });
    } catch (error) {
      console.error('Error obteniendo beneficios disponibles:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== ESTADÍSTICAS =====
  static async obtenerEstadisticas(req, res) {
    try {
      console.log('🔍 Obteniendo estadísticas...');
      
      // Consulta simplificada para estadísticas básicas
      const statsQuery = `
        SELECT 
          COUNT(DISTINCT fc.id) as total_campanias,
          COUNT(DISTINCT CASE WHEN fc.activa = true THEN fc.id END) as campanias_activas,
          COUNT(DISTINCT fcl.cliente_id) as total_clientes_participantes,
          COUNT(DISTINCT CASE WHEN fcl.cumplio_requisitos = true THEN fcl.cliente_id END) as clientes_que_cumplieron
        FROM fidelizacion_campanias fc
        LEFT JOIN fidelizacion_clientes fcl ON fc.id = fcl.campania_id
      `;
      
      console.log('📊 Ejecutando consulta de estadísticas...');
      const statsResult = await pool.query(statsQuery);
      console.log('✅ Estadísticas básicas obtenidas');
      
      // Consulta corregida para niveles de fidelidad basada en puntos
      const nivelesQuery = `
        SELECT 
          nivel_fidelidad,
          COUNT(*) as cantidad_clientes
        FROM (
          SELECT 
            c.id,
            CASE 
              WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 100 THEN 'PLATINO'
              WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 50 THEN 'ORO'
              WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 20 THEN 'PLATA'
              ELSE 'BRONCE'
            END as nivel_fidelidad
          FROM clientes c
          LEFT JOIN ventas v ON c.id = v.cliente_id
          LEFT JOIN (
            SELECT 
              cliente_id,
              SUM(puntos_acumulados) as puntos_acumulados
            FROM fidelizacion_clientes
            GROUP BY cliente_id
          ) fcl ON c.id = fcl.cliente_id
          WHERE (c.activo = true OR c.activo IS NULL) AND c.usuario_id = $1
          GROUP BY c.id
          HAVING COUNT(v.id) > 0
        ) as clientes_con_nivel
        GROUP BY nivel_fidelidad
        ORDER BY 
          CASE nivel_fidelidad
            WHEN 'PLATINO' THEN 1
            WHEN 'ORO' THEN 2
            WHEN 'PLATA' THEN 3
            WHEN 'BRONCE' THEN 4
          END
      `;
      
      console.log('🏆 Ejecutando consulta de niveles...');
      const nivelesResult = await pool.query(nivelesQuery, [req.userId]);
      console.log('✅ Niveles de fidelidad obtenidos');
      
      const niveles = {};
      nivelesResult.rows.forEach(row => {
        niveles[row.nivel_fidelidad] = parseInt(row.cantidad_clientes) || 0;
      });

      const estadisticas = {
        ...statsResult.rows[0],
        niveles_fidelidad: niveles
      };
      
      console.log('📈 Estadísticas completas:', estadisticas);
      res.json({ success: true, data: estadisticas });
    } catch (error) {
      console.error('❌ Error obteniendo estadísticas:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== PARTICIPANTES DE CAMPAÑA =====
  static async obtenerParticipantesCampania(req, res) {
    try {
      const { campania_id } = req.params;
      
      const query = `
        SELECT 
          c.id,
          c.nombre,
          COALESCE(c.identificador, 'Sin CI/RUC') as ci_ruc,
          COALESCE(c.telefono, 'Sin celular') as celular,
          fcl.puntos_acumulados,
          fcl.ultima_actualizacion,
          COUNT(v.id) as total_ventas,
          COALESCE(SUM(v.total), 0) as total_gastado
        FROM fidelizacion_clientes fcl
        JOIN clientes c ON fcl.cliente_id = c.id
        LEFT JOIN ventas v ON c.id = v.cliente_id
        WHERE fcl.campania_id = $1 AND fcl.puntos_acumulados > 0 AND c.usuario_id = $2
        GROUP BY c.id, c.nombre, c.identificador, c.telefono, fcl.puntos_acumulados, fcl.ultima_actualizacion
        ORDER BY fcl.puntos_acumulados DESC, c.nombre ASC
      `;
      
      const result = await pool.query(query, [campania_id]);
      
      console.log(`👥 Participantes de campaña ${campania_id}: ${result.rows.length} clientes`);
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('Error obteniendo participantes de campaña:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== PROGRESO DEL BÚHO =====
  static async obtenerProgresoBuho(req, res) {
    try {
      console.log('🦉 Obteniendo progreso del búho...');
      
      // Obtener progreso de gamificación
      console.log('🦉 Obteniendo progreso para usuario:', req.user.userId);
      const progreso = await Gamificacion.obtenerProgreso(req.user.userId);
      
      // Calcular nivel del búho basado en ventas y puntos
      const totalVentas = progreso.total_ventas || 0;
      const totalPuntos = progreso.total_puntos || 0;
      const totalMonto = 0; // No necesario para gamificación básica
      
      console.log('🦉 Progreso obtenido de gamificación:', {
        totalVentas,
        totalPuntos,
        nivel: progreso.nivel
      });
      
      console.log('📊 Datos del búho:', {
        totalVentas,
        totalPuntos,
        totalMonto
      });
      
      // Sistema de niveles del búho
      let nivelBuho = 1;
      let nombreNivel = 'Huevo';
      let porcentajeProgreso = 0;
      let puntosParaSiguiente = 0;
      let mensaje = '';
      
      if (totalVentas >= 50 && totalPuntos >= 100) {
        nivelBuho = 5;
        nombreNivel = 'Búho Legendario';
        porcentajeProgreso = 1.0;
        mensaje = '¡Eres un maestro del negocio! Comparte tu sabiduría con otros emprendedores.';
      } else if (totalVentas >= 30 && totalPuntos >= 60) {
        nivelBuho = 4;
        nombreNivel = 'Búho Sabio';
        porcentajeProgreso = Math.min((totalVentas - 30) / 20 + (totalPuntos - 60) / 40, 1.0);
        puntosParaSiguiente = 100 - totalPuntos;
        mensaje = '¡Tu búho es sabio! Continúa expandiendo tu negocio.';
      } else if (totalVentas >= 15 && totalPuntos >= 30) {
        nivelBuho = 3;
        nombreNivel = 'Búho Adulto';
        porcentajeProgreso = Math.min((totalVentas - 15) / 15 + (totalPuntos - 30) / 30, 1.0);
        puntosParaSiguiente = 60 - totalPuntos;
        mensaje = '¡Tu búho ya vuela alto! Mantén el impulso.';
      } else if (totalVentas >= 5 && totalPuntos >= 10) {
        nivelBuho = 2;
        nombreNivel = 'Polluelo';
        porcentajeProgreso = Math.min((totalVentas - 5) / 10 + (totalPuntos - 10) / 20, 1.0);
        puntosParaSiguiente = 30 - totalPuntos;
        mensaje = '¡Tu polluelo está creciendo! Sigue alimentándolo con ventas.';
      } else {
        nivelBuho = 1;
        nombreNivel = 'Huevo';
        porcentajeProgreso = Math.min(totalVentas / 5 + totalPuntos / 10, 1.0);
        puntosParaSiguiente = 10 - totalPuntos;
        mensaje = '¡Todo gran negocio empieza con un primer paso! No te detengas.';
      }
      
      const progresoBuho = {
        nivel: nivelBuho,
        nombre: nombreNivel,
        progreso: Math.round(porcentajeProgreso * 100),
        total_ventas: totalVentas,
        total_puntos: totalPuntos,
        total_monto: totalMonto,
        puntos_para_siguiente: Math.max(0, puntosParaSiguiente),
        ventas_para_siguiente: Math.max(0, 5 - totalVentas),
        mensaje: mensaje,
        emoji: nivelBuho === 1 ? '🥚' : nivelBuho === 2 ? '🐣' : nivelBuho === 3 ? '🦉' : nivelBuho === 4 ? '🦉✨' : '🦉👑'
      };
      
      console.log('🦉 Progreso del búho:', progresoBuho);
      res.json({ success: true, data: progresoBuho });
    } catch (error) {
      console.error('❌ Error obteniendo progreso del búho:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  // ===== CLIENTES EN RIESGO =====
  static async listarClientesRiesgo(req, res) {
    try {
      console.log('🔄 Listando clientes en riesgo...');
      
      const query = `
        SELECT 
          cr.*,
          c.nombre as cliente_nombre,
          c.telefono as cliente_telefono,
          c.identificador as cliente_identificador,
          COALESCE(mr.total_mensajes, 0) as total_mensajes_enviados,
          CASE 
            WHEN mr.ultimo_mensaje IS NULL THEN 'Nunca'
            ELSE TO_CHAR(mr.ultimo_mensaje, 'DD/MM/YYYY HH24:MI')
          END as ultimo_mensaje
        FROM clientes_riesgo cr
        INNER JOIN clientes c ON cr.cliente_id = c.id
        LEFT JOIN (
          SELECT 
            cliente_id,
            COUNT(*) as total_mensajes,
            MAX(fecha_envio) as ultimo_mensaje
          FROM mensajes_retencion
          GROUP BY cliente_id
        ) mr ON cr.cliente_id = mr.cliente_id
        WHERE cr.activo = true
        ORDER BY cr.nivel_riesgo DESC, cr.dias_sin_comprar DESC
      `;
      
      const result = await pool.query(query);
      
      console.log(`✅ ${result.rows.length} clientes en riesgo encontrados`);
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('❌ Error listando clientes en riesgo:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async analizarClientesRiesgo(req, res) {
    try {
      console.log('🔄 Analizando clientes en riesgo...');
      
      // Limpiar análisis anterior
      await pool.query('DELETE FROM clientes_riesgo WHERE activo = true');
      
      // Identificar clientes que no han comprado en los últimos días con información detallada
      const query = `
        WITH ultimas_compras AS (
          SELECT 
            cliente_id,
            MAX(fecha) as ultima_compra,
            EXTRACT(DAY FROM (NOW() - MAX(fecha))) as dias_sin_comprar,
            COUNT(*) as total_compras,
            AVG(total) as promedio_compra,
            SUM(total) as total_gastado
          FROM ventas
          WHERE cliente_id IS NOT NULL
          GROUP BY cliente_id
        ),
        productos_favoritos AS (
          SELECT 
            v.cliente_id,
            'Producto General' as producto_nombre,
            'Categoría General' as categoria,
            COUNT(*) as frecuencia_compra,
            MAX(v.fecha) as ultima_compra,
            AVG(v.total) as promedio_por_compra
          FROM ventas v
          WHERE v.cliente_id IS NOT NULL
          AND v.fecha >= NOW() - INTERVAL '30 days'
          GROUP BY v.cliente_id
        ),
        productos_top AS (
          SELECT 
            cliente_id,
            producto_nombre,
            categoria,
            frecuencia_compra,
            promedio_por_compra,
            ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY frecuencia_compra DESC) as rn
          FROM productos_favoritos
        ),
        patrones_compra AS (
          SELECT 
            cliente_id,
            CASE 
              WHEN total_compras >= 10 THEN 'Cliente Frecuente'
              WHEN total_compras >= 5 THEN 'Cliente Regular'
              WHEN total_compras >= 2 THEN 'Cliente Ocasional'
              ELSE 'Cliente Nuevo'
            END as tipo_cliente,
            CASE 
              WHEN promedio_compra >= 500 THEN 'Alto Valor'
              WHEN promedio_compra >= 200 THEN 'Medio Valor'
              WHEN promedio_compra >= 50 THEN 'Bajo Valor'
              ELSE 'Valor Mínimo'
            END as valor_cliente
          FROM ultimas_compras
        )
        INSERT INTO clientes_riesgo (
          cliente_id, 
          nivel_riesgo, 
          dias_sin_comprar, 
          producto_favorito, 
          categoria_favorita,
          total_compras,
          promedio_compra,
          total_gastado,
          tipo_cliente,
          valor_cliente
        )
        SELECT 
          uc.cliente_id,
          CASE 
            WHEN uc.dias_sin_comprar >= 10 THEN 3
            WHEN uc.dias_sin_comprar >= 7 THEN 2
            WHEN uc.dias_sin_comprar >= 4 THEN 1
            ELSE 0
          END as nivel_riesgo,
          uc.dias_sin_comprar,
          COALESCE(pt.producto_nombre, 'Sin datos') as producto_favorito,
          COALESCE(pt.categoria, 'Sin datos') as categoria_favorita,
          uc.total_compras,
          ROUND(uc.promedio_compra::numeric, 2) as promedio_compra,
          ROUND(uc.total_gastado::numeric, 2) as total_gastado,
          pc.tipo_cliente,
          pc.valor_cliente
        FROM ultimas_compras uc
        LEFT JOIN productos_top pt ON uc.cliente_id = pt.cliente_id AND pt.rn = 1
        LEFT JOIN patrones_compra pc ON uc.cliente_id = pc.cliente_id
        WHERE uc.dias_sin_comprar >= 4
        AND uc.cliente_id IN (SELECT id FROM clientes WHERE activo = true)
      `;
      
      const result = await pool.query(query);
      
      console.log(`✅ Análisis completado. ${result.rowCount} clientes en riesgo identificados`);
      res.json({ 
        success: true, 
        message: `Análisis completado. ${result.rowCount} clientes en riesgo identificados`,
        data: { clientes_analizados: result.rowCount }
      });
    } catch (error) {
      console.error('❌ Error analizando clientes en riesgo:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async obtenerOpcionesMensaje(req, res) {
    try {
      const { cliente_id } = req.params;
      
      console.log(`📝 Obteniendo opciones de mensaje para cliente ${cliente_id}...`);
      
      // Obtener datos completos del cliente
      const clienteQuery = `
        SELECT 
          cr.*,
          c.nombre as cliente_nombre,
          c.telefono as cliente_telefono,
          c.identificador as cliente_identificador
        FROM clientes_riesgo cr
        INNER JOIN clientes c ON cr.cliente_id = c.id
        WHERE cr.cliente_id = $1 AND cr.activo = true
      `;
      
      const clienteResult = await pool.query(clienteQuery, [cliente_id]);
      const cliente = clienteResult.rows[0];
      
      if (!cliente) {
        return res.status(404).json({ success: false, error: 'Cliente no encontrado o no está en riesgo' });
      }

      // Generar múltiples opciones de mensaje personalizado
      const opciones = MensajesPersonalizados.generarOpcionesMensaje(cliente, 3);
      
      console.log(`✅ ${opciones.length} opciones de mensaje generadas para ${cliente.cliente_nombre}`);
      
      res.json({ 
        success: true, 
        message: 'Opciones de mensaje generadas exitosamente',
        data: {
          cliente: {
            nombre: cliente.cliente_nombre,
            telefono: cliente.cliente_telefono,
            nivel_riesgo: cliente.nivel_riesgo,
            tipo_cliente: cliente.tipo_cliente,
            valor_cliente: cliente.valor_cliente,
            dias_sin_comprar: cliente.dias_sin_comprar,
            total_compras: cliente.total_compras,
            promedio_compra: cliente.promedio_compra
          },
          opciones: opciones
        }
      });
    } catch (error) {
      console.error('❌ Error obteniendo opciones de mensaje:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async enviarMensajeRetencion(req, res) {
    try {
      const { cliente_id } = req.params;
      const { mensaje, nivel_riesgo } = req.body;
      
      console.log(`📱 Enviando mensaje de retención a cliente ${cliente_id}...`);
      
      // Obtener datos completos del cliente para personalización
      const clienteQuery = `
        SELECT 
          cr.*,
          c.nombre as cliente_nombre,
          c.telefono as cliente_telefono,
          c.identificador as cliente_identificador
        FROM clientes_riesgo cr
        INNER JOIN clientes c ON cr.cliente_id = c.id
        WHERE cr.cliente_id = $1 AND cr.activo = true
      `;
      
      const clienteResult = await pool.query(clienteQuery, [cliente_id]);
      const cliente = clienteResult.rows[0];
      
      if (!cliente) {
        return res.status(404).json({ success: false, error: 'Cliente no encontrado o no está en riesgo' });
      }

      // Generar mensaje personalizado si no se proporciona uno
      const mensajeFinal = mensaje || MensajesPersonalizados.generarMensajePersonalizado(cliente);
      
      // Guardar mensaje en historial
      const insertQuery = `
        INSERT INTO mensajes_retencion (cliente_id, nivel_riesgo, mensaje_enviado)
        VALUES ($1, $2, $3)
        RETURNING id
      `;
      
      const result = await pool.query(insertQuery, [cliente_id, nivel_riesgo || cliente.nivel_riesgo, mensajeFinal]);
      
      // Crear enlace de WhatsApp
      const mensajeCodificado = encodeURIComponent(mensajeFinal);
      const enlaceWhatsApp = `https://wa.me/${cliente.cliente_telefono}?text=${mensajeCodificado}`;
      
      console.log(`✅ Mensaje personalizado guardado y enlace de WhatsApp generado para ${cliente.cliente_nombre}`);
      
      res.json({ 
        success: true, 
        message: 'Mensaje personalizado guardado exitosamente',
        data: {
          mensaje_id: result.rows[0].id,
          cliente_nombre: cliente.cliente_nombre,
          cliente_telefono: cliente.cliente_telefono,
          enlace_whatsapp: enlaceWhatsApp,
          mensaje_generado: mensajeFinal,
          nivel_riesgo: cliente.nivel_riesgo,
          tipo_cliente: cliente.tipo_cliente,
          valor_cliente: cliente.valor_cliente,
          descuento: MensajesPersonalizados._getDescuentoPorRiesgo(cliente.nivel_riesgo)
        }
      });
    } catch (error) {
      console.error('❌ Error enviando mensaje de retención:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async obtenerEstadisticasRetencion(req, res) {
    try {
      console.log('📊 Obteniendo estadísticas de retención...');
      
      const query = `
        SELECT 
          COUNT(*) as total_clientes_riesgo,
          COUNT(CASE WHEN nivel_riesgo = 1 THEN 1 END) as nivel_1,
          COUNT(CASE WHEN nivel_riesgo = 2 THEN 1 END) as nivel_2,
          COUNT(CASE WHEN nivel_riesgo = 3 THEN 1 END) as nivel_3,
          AVG(dias_sin_comprar) as promedio_dias_sin_comprar,
          COUNT(CASE WHEN dias_sin_comprar >= 10 THEN 1 END) as clientes_criticos
        FROM clientes_riesgo
        WHERE activo = true
      `;
      
      const result = await pool.query(query);
      const stats = result.rows[0];
      
      // Obtener estadísticas de mensajes
      const mensajesQuery = `
        SELECT 
          COUNT(*) as total_mensajes_enviados,
          COUNT(CASE WHEN respuesta_cliente = true THEN 1 END) as mensajes_respondidos,
          COUNT(CASE WHEN fecha_envio >= NOW() - INTERVAL '7 days' THEN 1 END) as mensajes_ultima_semana
        FROM mensajes_retencion
      `;
      
      const mensajesResult = await pool.query(mensajesQuery);
      const mensajesStats = mensajesResult.rows[0];
      
      const estadisticas = {
        ...stats,
        ...mensajesStats,
        tasa_respuesta: mensajesStats.total_mensajes_enviados > 0 
          ? Math.round((mensajesStats.mensajes_respondidos / mensajesStats.total_mensajes_enviados) * 100)
          : 0
      };
      
      console.log('✅ Estadísticas de retención obtenidas');
      res.json({ success: true, data: estadisticas });
    } catch (error) {
      console.error('❌ Error obteniendo estadísticas de retención:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }
}

module.exports = FidelizacionController;