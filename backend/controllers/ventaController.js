const Venta = require('../models/Venta');
const pool = require('../config/database');
const Gamificacion = require('../models/Gamificacion');

class VentaController {
  // Función para calcular puntos de fidelización
  static async actualizarPuntosFidelizacion(cliente_id, monto_venta, forma_pago) {
    try {
      console.log(`[DEBUG] actualizarPuntosFidelizacion - Cliente: ${cliente_id}, Monto: ${monto_venta}, Forma Pago: ${forma_pago}`);
      // Calcular puntos base: 1 punto por cada 1000 de venta
      let puntos_ganados = Math.floor(monto_venta / 1000);
      console.log(`[DEBUG] Puntos base ganados: ${puntos_ganados}`);
      
      // Bonificaciones por forma de pago
      let bonificacion_pago = 0;
      let mensaje_bonificacion = '';
      
      switch (forma_pago) {
        case 'efectivo':
          // Bonificación por pagar en efectivo (incentivar efectivo)
          bonificacion_pago = Math.floor(puntos_ganados * 0.2); // 20% extra
          mensaje_bonificacion = '¡Bonificación por pago en efectivo! +20% puntos';
          break;
        case 'tarjeta':
          // Bonificación por tarjeta (incentivar digitalización)
          bonificacion_pago = Math.floor(puntos_ganados * 0.15); // 15% extra
          mensaje_bonificacion = '¡Bonificación por pago con tarjeta! +15% puntos';
          break;
        case 'qr':
          // Bonificación por QR (incentivar pagos móviles)
          bonificacion_pago = Math.floor(puntos_ganados * 0.25); // 25% extra
          mensaje_bonificacion = '¡Bonificación por pago QR! +25% puntos';
          break;
        default:
          bonificacion_pago = 0;
          mensaje_bonificacion = '';
      }
      
      const puntos_totales = puntos_ganados + bonificacion_pago;
      
      if (puntos_totales <= 0) {
        console.log(`💰 Cliente ${cliente_id}: Venta de ${monto_venta} (${forma_pago}) - No genera puntos`);
        return;
      }

      console.log(`🎯 Actualizando puntos para cliente ${cliente_id}:`);
      console.log(`   - Puntos base: +${puntos_ganados} (venta: ${monto_venta})`);
      console.log(`   - Bonificación ${forma_pago}: +${bonificacion_pago}`);
      console.log(`   - Total puntos: +${puntos_totales}`);
      if (bonificacion_pago > 0) {
        console.log(`   - ${mensaje_bonificacion}`);
      }

      // Buscar campañas activas donde el cliente esté participando
      const query = `
        SELECT fc.id as campania_id, fcl.puntos_acumulados
        FROM fidelizacion_campanias fc
        LEFT JOIN fidelizacion_clientes fcl ON fc.id = fcl.campania_id AND fcl.cliente_id = $1
        WHERE fc.activa = true
      `;
      
      console.log(`[DEBUG] Buscando campañas activas para cliente ${cliente_id}...`);
      const result = await pool.query(query, [cliente_id]);
      console.log(`[DEBUG] Campañas activas encontradas: ${result.rows.length}`);
      
      if (result.rows.length === 0) {
        console.log(`[DEBUG] No se encontraron campañas activas para el cliente ${cliente_id}. No se actualizarán puntos.`);
      }

      for (const row of result.rows) {
        const campania_id = row.campania_id;
        const puntos_actuales = row.puntos_acumulados || 0;
        const nuevos_puntos = puntos_actuales + puntos_totales;
        
        console.log(`[DEBUG] Procesando campaña ${campania_id}: Puntos actuales: ${puntos_actuales}, Nuevos puntos: ${nuevos_puntos}`);
        // Actualizar o insertar puntos del cliente en la campaña
        const upsertQuery = `
          INSERT INTO fidelizacion_clientes (cliente_id, campania_id, puntos_acumulados, ultima_actualizacion)
          VALUES ($1, $2, $3, NOW())
          ON CONFLICT (cliente_id, campania_id) 
          DO UPDATE SET 
            puntos_acumulados = $3,
            ultima_actualizacion = NOW()
        `;
        
        await pool.query(upsertQuery, [cliente_id, campania_id, nuevos_puntos]);
        console.log(`✅ Cliente ${cliente_id} en campaña ${campania_id}: ${puntos_actuales} → ${nuevos_puntos} puntos`);
      }
      
      console.log(`🎉 Puntos actualizados exitosamente para cliente ${cliente_id}`);
    } catch (error) {
      console.error(`❌ Error actualizando puntos para cliente ${cliente_id}:`, error);
    }
  }

  // ===== VERIFICAR BENEFICIOS DISPONIBLES PARA VENTA =====
  static async verificarBeneficiosCliente(req, res) {
    try {
      const { cliente_id } = req.params;
      const { userId } = req.user; // Obtener el userId del token de autenticación
      
      if (!cliente_id) {
        return res.status(400).json({ 
          success: false, 
          error: 'Cliente ID es obligatorio' 
        });
      }

      // Verificar si el cliente existe y pertenece al usuario
      const clienteQuery = `
        SELECT id, nombre, identificador
        FROM clientes 
        WHERE id = $1 AND usuario_id = $2
      `;
      const clienteResult = await pool.query(clienteQuery, [cliente_id, userId]);
      
      if (clienteResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Cliente no encontrado o no pertenece a este usuario' });
      }

      const cliente = clienteResult.rows[0];

      // Obtener beneficios disponibles que el cliente puede usar, filtrados por usuario
      const beneficiosQuery = `
        SELECT 
          fb.id as beneficio_id,
          fb.tipo as beneficio_tipo,
          fb.valor as beneficio_valor,
          fc.id as campania_id,
          fc.nombre as campania_nombre,
          fc.fecha_inicio,
          fc.fecha_fin,
          fr.tipo as requisito_tipo,
          fr.valor as requisito_valor,
          fcl.cumplio_requisitos,
          fcl.fecha_cumplimiento,
          CASE 
            WHEN fcl.cumplio_requisitos = true AND fcl.fecha_cumplimiento IS NOT NULL THEN true
            ELSE false
          END as beneficio_disponible
        FROM fidelizacion_beneficios fb
        JOIN fidelizacion_campanias fc ON fb.campania_id = fc.id
        JOIN fidelizacion_requisitos fr ON fc.id = fr.campania_id
        LEFT JOIN fidelizacion_clientes fcl ON fc.id = fcl.campania_id AND fcl.cliente_id = $1
        WHERE fc.activa = true 
        AND fc.fecha_inicio <= CURRENT_DATE 
        AND fc.fecha_fin >= CURRENT_DATE
        AND fcl.cumplio_requisitos = true
        AND fc.usuario_id = $2 -- Filtrar campañas por usuario
        ORDER BY fc.fecha_fin ASC, fb.id ASC
      `;
      
      const beneficiosResult = await pool.query(beneficiosQuery, [cliente_id, userId]);
      
      const beneficiosDisponibles = beneficiosResult.rows.map(row => ({
        beneficio_id: row.beneficio_id,
        beneficio_tipo: row.beneficio_tipo,
        beneficio_valor: row.beneficio_valor,
        campania_id: row.campania_id,
        campania_nombre: row.campania_nombre,
        fecha_inicio: row.fecha_inicio,
        fecha_fin: row.fecha_fin,
        requisito_tipo: row.requisito_tipo,
        requisito_valor: row.requisito_valor,
        fecha_cumplimiento: row.fecha_cumplimiento,
        beneficio_disponible: row.beneficio_disponible,
        descripcion: `${row.beneficio_tipo === 'descuento' ? 'Descuento del' : 'Producto:'} ${row.beneficio_valor}${row.beneficio_tipo === 'descuento' ? '%' : ''}`,
        mensaje: `¡Felicidades! Has cumplido el requisito de ${row.requisito_tipo} (${row.requisito_valor}) en la campaña "${row.campania_nombre}". Puedes usar este beneficio hasta el ${new Date(row.fecha_fin).toLocaleDateString()}.`
      }));

      const resultado = {
        cliente: cliente,
        beneficios_disponibles: beneficiosDisponibles,
        total_beneficios: beneficiosDisponibles.length
      };

      console.log(`🎁 Beneficios disponibles para cliente ${cliente_id}: ${beneficiosDisponibles.length} beneficios`);
      res.json({ success: true, data: resultado });
    } catch (error) {
      console.error('Error verificando beneficios del cliente:', error);
      res.status(500).json({ success: false, error: 'Error interno del servidor' });
    }
  }

  static async listar(req, res) {
    try {
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const ventas = await Venta.listar(usuario_id);
      res.json({ success: true, data: ventas });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }



  static async obtenerTotal(req, res) {
    try {
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const total = await Venta.contarVentas(usuario_id);
      res.json({ success: true, data: { total } });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async crear(req, res) {
    try {
      let { sucursal_id, cliente_id, fecha, total, monto, numero_factura, forma_pago } = req.body;
      
      // Obtener usuario_id del token de autenticación
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      // Compatibilidad: si no hay total pero sí monto, usar monto como total
      if (!total && monto) total = monto;
      if (!sucursal_id) sucursal_id = 1;
      
      // Validar forma de pago
      if (!forma_pago) forma_pago = 'efectivo';
      if (!['efectivo', 'tarjeta', 'qr'].includes(forma_pago)) {
        return res.status(400).json({ success: false, error: 'forma_pago debe ser: efectivo, tarjeta o qr' });
      }
      
      if (!cliente_id || !total) {
        return res.status(400).json({ success: false, error: 'cliente_id y total son obligatorios' });
      }

      // Registrar venta y obtener totales calculados por el modelo
      const items = req.body.items || req.body.articulos; // Compatibilidad con ambos nombres
      if (!items) {
        return res.status(400).json({ success: false, error: 'Se requieren items/articulos para la venta' });
      }
      
      const resultado = await Venta.crear({ sucursal_id, usuario_id, cliente_id, fecha, total, numero_factura, forma_pago, items });
      const { venta, totales } = resultado;

      // 🎯 ACTUALIZAR PUNTOS DE FIDELIZACIÓN Y GAMIFICACIÓN
      await VentaController.actualizarPuntosFidelizacion(cliente_id, total, forma_pago);
      
      // 🦉 Actualizar puntos de gamificación (búho) - 1 punto por cada $10
      await Gamificacion.actualizarPuntos(
        usuario_id || req.user.userId, 
        Math.floor(total / 10), 
        total
      );

      console.log('✅ Venta registrada:', venta.id, 'Sucursal:', venta.sucursal_id, 'Usuario:', venta.usuario_id, 'Cliente:', venta.cliente_id, 'Total:', venta.total);
      res.status(201).json({ success: true, data: { venta, ...totales } });
    } catch (error) {
      console.error('❌ Error creando venta:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async buscarPorId(req, res) {
    try {
      const id = req.params.id;
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const venta = await Venta.buscarPorId(id, usuario_id);
      if (!venta) return res.status(404).json({ success: false, error: 'Venta no encontrada' });
      res.json({ success: true, data: venta });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async obtenerResumen(req, res) {
    try {
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const resumen = await Venta.obtenerResumen(usuario_id);
      res.json({ success: true, data: resumen });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  // ===== ESTADÍSTICAS POR FORMA DE PAGO =====
  static async obtenerEstadisticasFormaPago(req, res) {
    try {
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      // Estadísticas generales por forma de pago
      const statsQuery = `
        SELECT 
          forma_pago,
          COUNT(*) as total_ventas,
          SUM(total) as monto_total,
          AVG(total) as promedio_venta,
          MIN(total) as venta_minima,
          MAX(total) as venta_maxima
        FROM ventas 
        WHERE forma_pago IS NOT NULL AND usuario_id = $1
        GROUP BY forma_pago
        ORDER BY monto_total DESC
      `;
      
      const statsResult = await pool.query(statsQuery, [usuario_id]);
      
      // Estadísticas por día (últimos 7 días)
      const statsDiariasQuery = `
        SELECT 
          forma_pago,
          DATE(fecha) as fecha,
          COUNT(*) as ventas_dia,
          SUM(total) as monto_dia
        FROM ventas 
        WHERE fecha >= CURRENT_DATE - INTERVAL '7 days'
        AND forma_pago IS NOT NULL
        AND usuario_id = $1
        GROUP BY forma_pago, DATE(fecha)
        ORDER BY fecha DESC, monto_dia DESC
      `;
      
      const statsDiariasResult = await pool.query(statsDiariasQuery, [usuario_id]);
      
      // Tendencia de preferencias por forma de pago
      const tendenciaQuery = `
        SELECT 
          forma_pago,
          COUNT(*) as total_ventas,
          ROUND(
            (COUNT(*) * 100.0) / (
              SELECT COUNT(*) FROM ventas WHERE forma_pago IS NOT NULL AND usuario_id = $1
            ), 2
          ) as porcentaje_uso
        FROM ventas 
        WHERE forma_pago IS NOT NULL AND usuario_id = $1
        GROUP BY forma_pago
        ORDER BY total_ventas DESC
      `;
      
      const tendenciaResult = await pool.query(tendenciaQuery, [usuario_id]);
      
      // Top clientes por forma de pago
      const topClientesQuery = `
        SELECT 
          v.forma_pago,
          c.nombre as cliente_nombre,
          COUNT(*) as total_ventas_cliente,
          SUM(v.total) as monto_total_cliente
        FROM ventas v
        LEFT JOIN clientes c ON v.cliente_id = c.id
        WHERE v.forma_pago IS NOT NULL AND v.usuario_id = $1
        GROUP BY v.forma_pago, c.nombre, c.id
        HAVING COUNT(*) > 1
        ORDER BY v.forma_pago, monto_total_cliente DESC
        LIMIT 10
      `;
      
      const topClientesResult = await pool.query(topClientesQuery, [usuario_id]);
      
      const resultado = {
        estadisticas_generales: statsResult.rows,
        estadisticas_diarias: statsDiariasResult.rows,
        tendencia_preferencias: tendenciaResult.rows,
        top_clientes_por_forma: topClientesResult.rows,
        resumen: {
          total_ventas: statsResult.rows.reduce((sum, row) => sum + parseInt(row.total_ventas), 0),
          monto_total: statsResult.rows.reduce((sum, row) => sum + parseFloat(row.monto_total), 0),
          formas_pago_utilizadas: statsResult.rows.length
        }
      };
      
      console.log('📊 Estadísticas por forma de pago generadas');
      res.json({ success: true, data: resultado });
    } catch (error) {
      console.error('❌ Error obteniendo estadísticas por forma de pago:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = VentaController;
