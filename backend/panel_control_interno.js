const readline = require('readline');
const pool = require('./config/database');
const PrestamoController = require('./controllers/prestamoController');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

class PanelControlInterno {
  constructor() {
    this.userId = 1; // ID del usuario que ejecuta el script (tú)
  }

  async iniciar() {
    console.log('\n🔐 PANEL DE CONTROL INTERNO - GIO MICROFINANZAS');
    console.log('================================================\n');
    
    while (true) {
      await this.mostrarMenu();
      const opcion = await this.preguntar('Selecciona una opción: ');
      
      switch (opcion) {
        case '1':
          await this.verSolicitudesPendientes();
          break;
        case '2':
          await this.revisarSolicitud();
          break;
        case '3':
          await this.generarReporteVenta();
          break;
        case '4':
          await this.compilarDatos();
          break;
        case '5':
          await this.verEstadisticas();
          break;
        case '0':
          console.log('\n👋 ¡Hasta luego!');
          process.exit(0);
          break;
        default:
          console.log('\n❌ Opción inválida');
      }
      
      await this.preguntar('\nPresiona ENTER para continuar...');
    }
  }

  async mostrarMenu() {
    console.log('\n📋 MENÚ PRINCIPAL:');
    console.log('1. Ver solicitudes pendientes');
    console.log('2. Revisar/Aprobar solicitud');
    console.log('3. Generar reporte para venta a bancos');
    console.log('4. Compilar datos de todos los clientes');
    console.log('5. Ver estadísticas del sistema');
    console.log('0. Salir');
  }

  async verSolicitudesPendientes() {
    try {
      console.log('\n🔄 Cargando solicitudes pendientes...\n');
      
      const query = `
        SELECT 
          sp.id,
          sp.cliente_id,
          sp.tipo_solicitud,
          sp.monto,
          sp.proposito,
          sp.plan_negocio,
          sp.estado,
          sp.fecha_solicitud,
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
      
      if (result.rows.length === 0) {
        console.log('✅ No hay solicitudes pendientes');
        return;
      }
      
      console.log(`📋 ${result.rows.length} solicitudes pendientes:\n`);
      
      result.rows.forEach((solicitud, index) => {
        console.log(`🔸 SOLICITUD #${solicitud.id}`);
        console.log(`   Cliente: ${solicitud.cliente_nombre}`);
        console.log(`   Email: ${solicitud.cliente_email}`);
        console.log(`   Teléfono: ${solicitud.cliente_telefono}`);
        console.log(`   Tipo: ${solicitud.tipo_solicitud === 'verificacion_identidad' ? 'Verificación de Identidad' : 'Préstamo'}`);
        console.log(`   Fecha: ${solicitud.fecha_solicitud}`);
        
        if (solicitud.monto) {
          console.log(`   Monto: ${solicitud.monto} Gs`);
        }
        
        if (solicitud.score_credito) {
          console.log(`   Score Crédito: ${solicitud.score_credito}`);
        }
        
        if (solicitud.categoria_riesgo) {
          console.log(`   Categoría Riesgo: ${solicitud.categoria_riesgo}`);
        }
        
        if (solicitud.ingresos_promedio_mensual) {
          console.log(`   Ingresos Promedio: ${solicitud.ingresos_promedio_mensual} Gs`);
        }
        
        console.log('');
      });
      
    } catch (error) {
      console.error('❌ Error:', error.message);
    }
  }

  async revisarSolicitud() {
    try {
      const solicitudId = await this.preguntar('Ingresa el ID de la solicitud a revisar: ');
      
      if (!solicitudId || isNaN(solicitudId)) {
        console.log('❌ ID inválido');
        return;
      }
      
      // Obtener detalles de la solicitud
      const query = `
        SELECT 
          sp.*,
          c.nombre as cliente_nombre,
          c.email as cliente_email,
          c.telefono as cliente_telefono,
          c.score_credito,
          c.categoria_riesgo,
          c.ingresos_promedio_mensual
        FROM solicitudes_prestamos sp
        JOIN clientes c ON sp.cliente_id = c.id
        WHERE sp.id = $1 AND sp.activo = true
      `;
      
      const result = await pool.query(query, [solicitudId]);
      
      if (result.rows.length === 0) {
        console.log('❌ Solicitud no encontrada');
        return;
      }
      
      const solicitud = result.rows[0];
      
      console.log('\n📋 DETALLES DE LA SOLICITUD:');
      console.log('============================');
      console.log(`ID: ${solicitud.id}`);
      console.log(`Cliente: ${solicitud.cliente_nombre}`);
      console.log(`Email: ${solicitud.cliente_email}`);
      console.log(`Teléfono: ${solicitud.cliente_telefono}`);
      console.log(`Tipo: ${solicitud.tipo_solicitud === 'verificacion_identidad' ? 'Verificación de Identidad' : 'Préstamo'}`);
      console.log(`Fecha: ${solicitud.fecha_solicitud}`);
      
      if (solicitud.monto) {
        console.log(`Monto: ${solicitud.monto} Gs`);
      }
      
      if (solicitud.proposito) {
        console.log(`Propósito: ${solicitud.proposito}`);
      }
      
      if (solicitud.score_credito) {
        console.log(`Score Crédito: ${solicitud.score_credito}`);
      }
      
      if (solicitud.categoria_riesgo) {
        console.log(`Categoría Riesgo: ${solicitud.categoria_riesgo}`);
      }
      
      if (solicitud.ingresos_promedio_mensual) {
        console.log(`Ingresos Promedio: ${solicitud.ingresos_promedio_mensual} Gs`);
      }
      
      console.log('\n📝 Datos de solicitud:');
      if (solicitud.datos_solicitud) {
        console.log(JSON.stringify(JSON.parse(solicitud.datos_solicitud), null, 2));
      }
      
      console.log('\n📊 Datos de análisis:');
      if (solicitud.datos_analisis) {
        console.log(JSON.stringify(JSON.parse(solicitud.datos_analisis), null, 2));
      }
      
      console.log('\n🤔 DECISIÓN:');
      const decision = await this.preguntar('¿Aprobar (a) o Rechazar (r)? ');
      const comentarios = await this.preguntar('Comentarios (opcional): ');
      
      if (decision.toLowerCase() === 'a') {
        await this.aprobarSolicitud(solicitudId, comentarios);
      } else if (decision.toLowerCase() === 'r') {
        await this.rechazarSolicitud(solicitudId, comentarios);
      } else {
        console.log('❌ Decisión inválida');
      }
      
    } catch (error) {
      console.error('❌ Error:', error.message);
    }
  }

  async aprobarSolicitud(solicitudId, comentarios) {
    try {
      // Obtener la solicitud
      const solicitudQuery = `
        SELECT * FROM solicitudes_prestamos 
        WHERE id = $1 AND activo = true
      `;
      const solicitudResult = await pool.query(solicitudQuery, [solicitudId]);
      
      if (solicitudResult.rows.length === 0) {
        console.log('❌ Solicitud no encontrada');
        return;
      }
      
      const solicitud = solicitudResult.rows[0];
      
      // Actualizar estado
      const updateQuery = `
        UPDATE solicitudes_prestamos 
        SET estado = 'aprobado', fecha_revision = $1, revisado_por = $2, comentarios_revision = $3
        WHERE id = $4
      `;
      
      await pool.query(updateQuery, [
        new Date(),
        this.userId,
        comentarios || '',
        solicitudId
      ]);
      
      // Procesar según el tipo
      if (solicitud.tipo_solicitud === 'verificacion_identidad') {
        const datosSolicitud = JSON.parse(solicitud.datos_solicitud);
        await pool.query(`
          UPDATE clientes 
          SET ci_numero = $1, ci_frente_url = $2, ci_reverso_url = $3, 
              verificado = true, fecha_verificacion = $4
          WHERE id = $5
        `, [
          datosSolicitud.ci_numero,
          datosSolicitud.ci_frente_url,
          datosSolicitud.ci_reverso_url,
          new Date(),
          solicitud.cliente_id
        ]);
        
        // Compilar datos automáticamente
        const CompiladorDatosBancarios = require('./services/compiladorDatosBancarios');
        await CompiladorDatosBancarios.compilarDatosCliente(solicitud.cliente_id);
        
        console.log('✅ Verificación de identidad aprobada y datos compilados');
        
      } else if (solicitud.tipo_solicitud === 'prestamo') {
        await pool.query(`
          UPDATE clientes 
          SET prestamos_solicitados = prestamos_solicitados + 1,
              prestamos_aprobados = prestamos_aprobados + 1
          WHERE id = $1
        `, [solicitud.cliente_id]);
        
        console.log('✅ Préstamo aprobado');
      }
      
    } catch (error) {
      console.error('❌ Error aprobando solicitud:', error.message);
    }
  }

  async rechazarSolicitud(solicitudId, comentarios) {
    try {
      const updateQuery = `
        UPDATE solicitudes_prestamos 
        SET estado = 'rechazado', fecha_revision = $1, revisado_por = $2, comentarios_revision = $3
        WHERE id = $4
      `;
      
      await pool.query(updateQuery, [
        new Date(),
        this.userId,
        comentarios || '',
        solicitudId
      ]);
      
      console.log('❌ Solicitud rechazada');
      
    } catch (error) {
      console.error('❌ Error rechazando solicitud:', error.message);
    }
  }

  async generarReporteVenta(usuario_id = null) {
    try {
      console.log('\n📊 Generando reporte para venta a bancos...\n');
      
      const CompiladorDatosBancarios = require('./services/compiladorDatosBancarios');
      const reporte = await CompiladorDatosBancarios.generarReporteVenta(usuario_id);
      
      console.log('📈 REPORTE PARA VENTA A BANCOS:');
      console.log('================================');
      console.log(`Fecha: ${reporte.fecha_generacion}`);
      console.log(`Total de clientes: ${reporte.total_clientes}`);
      console.log('\n📊 Resumen por categoría:');
      console.log(`- Bajo riesgo: ${reporte.resumen_por_categoria.bajo}`);
      console.log(`- Medio riesgo: ${reporte.resumen_por_categoria.medio}`);
      console.log(`- Alto riesgo: ${reporte.resumen_por_categoria.alto}`);
      console.log('\n💰 Resumen financiero:');
      console.log(`- Ingresos promedio total: ${reporte.resumen_financiero.ingresos_promedio_total} Gs`);
      console.log(`- Score promedio: ${reporte.resumen_financiero.score_promedio}`);
      console.log(`- Crecimiento promedio: ${reporte.resumen_financiero.crecimiento_promedio}%`);
      
      console.log('\n📋 Clientes disponibles para venta:');
      reporte.clientes.forEach((cliente, index) => {
        console.log(`${index + 1}. ${cliente.nombre} - ${cliente.categoria_riesgo} - Score: ${cliente.score_credito}`);
      });
      
    } catch (error) {
      console.error('❌ Error generando reporte:', error.message);
    }
  }

  async compilarDatos() {
    try {
      console.log('\n🔄 Compilando datos de todos los clientes...\n');
      
      const CompiladorDatosBancarios = require('./services/compiladorDatosBancarios');
      const resultados = await CompiladorDatosBancarios.compilarTodosLosDatos();
      
      console.log('📊 RESULTADOS DE COMPILACIÓN:');
      console.log('==============================');
      console.log(`Total procesados: ${resultados.length}`);
      console.log(`Exitosos: ${resultados.filter(r => r.estado === 'exitoso').length}`);
      console.log(`Errores: ${resultados.filter(r => r.estado === 'error').length}`);
      
      if (resultados.filter(r => r.estado === 'error').length > 0) {
        console.log('\n❌ Errores encontrados:');
        resultados.filter(r => r.estado === 'error').forEach(error => {
          console.log(`- ${error.nombre}: ${error.error}`);
        });
      }
      
    } catch (error) {
      console.error('❌ Error compilando datos:', error.message);
    }
  }

  async verEstadisticas() {
    try {
      console.log('\n📈 ESTADÍSTICAS DEL SISTEMA:');
      console.log('==============================\n');
      
      // Estadísticas de clientes
      const clientesQuery = await pool.query('SELECT COUNT(*) as total FROM clientes WHERE activo = true AND usuario_id = $1', [this.userId]);
      const clientesVerificadosQuery = await pool.query('SELECT COUNT(*) as total FROM clientes WHERE verificado = true AND activo = true AND usuario_id = $1', [this.userId]);
      const solicitudesQuery = await pool.query('SELECT COUNT(*) as total FROM solicitudes_prestamos WHERE activo = true');
      const solicitudesPendientesQuery = await pool.query("SELECT COUNT(*) as total FROM solicitudes_prestamos WHERE estado = 'pendiente' AND activo = true");
      
      console.log(`👥 Total de clientes: ${clientesQuery.rows[0].total}`);
      console.log(`✅ Clientes verificados: ${clientesVerificadosQuery.rows[0].total}`);
      console.log(`📋 Total de solicitudes: ${solicitudesQuery.rows[0].total}`);
      console.log(`⏳ Solicitudes pendientes: ${solicitudesPendientesQuery.rows[0].total}`);
      
      // Estadísticas de préstamos
      const prestamosQuery = await pool.query(`
        SELECT 
          SUM(prestamos_solicitados) as solicitados,
          SUM(prestamos_aprobados) as aprobados,
          SUM(prestamos_pagados) as pagados,
          SUM(prestamos_vencidos) as vencidos
        FROM clientes WHERE activo = true
      `);
      
      const prestamos = prestamosQuery.rows[0];
      console.log('\n💰 PRÉSTAMOS:');
      console.log(`- Solicitados: ${prestamos.solicitados || 0}`);
      console.log(`- Aprobados: ${prestamos.aprobados || 0}`);
      console.log(`- Pagados: ${prestamos.pagados || 0}`);
      console.log(`- Vencidos: ${prestamos.vencidos || 0}`);
      
    } catch (error) {
      console.error('❌ Error obteniendo estadísticas:', error.message);
    }
  }

  preguntar(pregunta) {
    return new Promise((resolve) => {
      rl.question(pregunta, (respuesta) => {
        resolve(respuesta);
      });
    });
  }
}

// Ejecutar el panel
const panel = new PanelControlInterno();
panel.iniciar().catch(console.error);