const pool = require('../config/database');
const Cliente = require('../models/Cliente');

class CompiladorDatosBancarios {
  
  /**
   * Compila todos los datos financieros de un cliente para venta a bancos
   * @param {number} clienteId - ID del cliente
   * @param {number} usuario_id - ID del usuario para filtrar los clientes
   */
  static async compilarDatosCliente(clienteId, usuario_id = null) {
    try {
      const cliente = await Cliente.obtenerPorId(clienteId, usuario_id);
      if (!cliente) {
        throw new Error('Cliente no encontrado o no pertenece a este usuario');
      }

      // Obtener ventas de los últimos 24 meses
      const fechaLimite = new Date();
      fechaLimite.setMonth(fechaLimite.getMonth() - 24);
      
      const ventas = await pool.query(`
        SELECT id, fecha, total, cliente_id
        FROM ventas 
        WHERE cliente_id = $1 AND fecha >= $2
        ORDER BY fecha ASC
      `, [clienteId, fechaLimite]);

      // Calcular métricas financieras
      const datosFinancieros = this.calcularMetricasFinancieras(ventas.rows);
      
      // Calcular score crediticio
      const scoreCredito = this.calcularScoreCredito(cliente, datosFinancieros);
      
      // Determinar categoría de riesgo
      const categoriaRiesgo = this.determinarCategoriaRiesgo(scoreCredito);
      
      // Estructurar datos para venta
      const datosParaVenta = {
        // Datos básicos
        id_cliente: cliente.id,
        nombre: cliente.nombre,
        email: cliente.email,
        telefono: cliente.telefono,
        
        // Datos demográficos
        edad: cliente.fecha_nacimiento ? this.calcularEdad(cliente.fecha_nacimiento) : null,
        nivel_educativo: cliente.nivel_educativo,
        estado_civil: cliente.estado_civil,
        dependientes: cliente.dependientes,
        
        // Datos del negocio
        tipo_negocio: cliente.tipo_negocio,
        antiguedad_negocio: cliente.antiguedad_negocio,
        empleados: cliente.empleados,
        ubicacion_negocio: cliente.ubicacion_negocio,
        
        // Métricas financieras
        ingresos_promedio_mensual: datosFinancieros.ingresosPromedioMensual,
        crecimiento_mensual: datosFinancieros.crecimientoMensual,
        liquidez_promedio: datosFinancieros.liquidezPromedio,
        frecuencia_transacciones: datosFinancieros.frecuenciaTransacciones,
        monto_promedio_venta: datosFinancieros.montoPromedioVenta,
        
        // Análisis de tendencias
        tendencia_crecimiento: datosFinancieros.tendenciaCrecimiento,
        estacionalidad: datosFinancieros.estacionalidad,
        volatilidad_ingresos: datosFinancieros.volatilidadIngresos,
        
        // Score crediticio
        score_credito: scoreCredito,
        categoria_riesgo: categoriaRiesgo,
        
        // Historial de préstamos
        prestamos_solicitados: cliente.prestamos_solicitados || 0,
        prestamos_aprobados: cliente.prestamos_aprobados || 0,
        prestamos_pagados: cliente.prestamos_pagados || 0,
        prestamos_vencidos: cliente.prestamos_vencidos || 0,
        
        // Capacidad de pago
        capacidad_pago_mensual: datosFinancieros.capacidadPagoMensual,
        ratio_deuda_ingresos: datosFinancieros.ratioDeudaIngresos,
        
        // Potencial de crecimiento
        potencial_escalabilidad: this.calcularPotencialEscalabilidad(cliente, datosFinancieros),
        
        // Fecha de compilación
        fecha_compilacion: new Date(),
        periodo_analisis: '24_meses'
      };

      // Actualizar cliente con datos compilados
      await Cliente.actualizarDatosPrestamos(clienteId, {
        ingresos_promedio_mensual: datosFinancieros.ingresosPromedioMensual,
        crecimiento_mensual: datosFinancieros.crecimientoMensual,
        liquidez_promedio: datosFinancieros.liquidezPromedio,
        frecuencia_transacciones: datosFinancieros.frecuenciaTransacciones,
        monto_promedio_venta: datosFinancieros.montoPromedioVenta,
        score_credito: scoreCredito,
        categoria_riesgo: categoriaRiesgo,
        datos_para_venta: datosParaVenta,
        fecha_ultima_actualizacion_datos: new Date()
      });

      return datosParaVenta;
      
    } catch (error) {
      console.error('Error compilando datos bancarios:', error);
      throw error;
    }
  }

  /**
   * Calcula métricas financieras detalladas
   */
  static calcularMetricasFinancieras(ventas) {
    if (ventas.length === 0) {
      return {
        ingresosPromedioMensual: 0,
        crecimientoMensual: 0,
        liquidezPromedio: 0,
        frecuenciaTransacciones: 0,
        montoPromedioVenta: 0,
        tendenciaCrecimiento: 'estable',
        estacionalidad: 'baja',
        volatilidadIngresos: 0,
        capacidadPagoMensual: 0,
        ratioDeudaIngresos: 0
      };
    }

    // Agrupar ventas por mes
    const ventasPorMes = {};
    ventas.forEach(venta => {
      const mes = venta.fecha.toISOString().substring(0, 7); // YYYY-MM
      if (!ventasPorMes[mes]) {
        ventasPorMes[mes] = { total: 0, cantidad: 0 };
      }
      ventasPorMes[mes].total += parseFloat(venta.total);
      ventasPorMes[mes].cantidad += 1;
    });

    const meses = Object.keys(ventasPorMes).sort();
    const ingresosMensuales = meses.map(mes => ventasPorMes[mes].total);
    
    // Cálculos básicos
    const ingresosPromedioMensual = ingresosMensuales.reduce((a, b) => a + b, 0) / ingresosMensuales.length;
    const montoPromedioVenta = ventas.reduce((sum, v) => sum + parseFloat(v.total), 0) / ventas.length;
    const frecuenciaTransacciones = ventas.length / Math.max(meses.length, 1);

    // Cálculo de crecimiento mensual
    let crecimientoMensual = 0;
    if (ingresosMensuales.length > 1) {
      const crecimientos = [];
      for (let i = 1; i < ingresosMensuales.length; i++) {
        const crecimiento = ((ingresosMensuales[i] - ingresosMensuales[i-1]) / ingresosMensuales[i-1]) * 100;
        crecimientos.push(crecimiento);
      }
      crecimientoMensual = crecimientos.reduce((a, b) => a + b, 0) / crecimientos.length;
    }

    // Análisis de tendencias
    const tendenciaCrecimiento = this.analizarTendencia(ingresosMensuales);
    const estacionalidad = this.analizarEstacionalidad(ingresosMensuales);
    const volatilidadIngresos = this.calcularVolatilidad(ingresosMensuales);

    // Capacidad de pago (estimación conservadora)
    const capacidadPagoMensual = ingresosPromedioMensual * 0.3; // 30% de ingresos
    const liquidezPromedio = ingresosPromedioMensual * 0.2; // 20% de ingresos

    return {
      ingresosPromedioMensual,
      crecimientoMensual,
      liquidezPromedio,
      frecuenciaTransacciones,
      montoPromedioVenta,
      tendenciaCrecimiento,
      estacionalidad,
      volatilidadIngresos,
      capacidadPagoMensual,
      ratioDeudaIngresos: 0 // Se calcula cuando hay préstamos activos
    };
  }

  /**
   * Calcula score crediticio (0-1000)
   */
  static calcularScoreCredito(cliente, datosFinancieros) {
    let score = 500; // Puntuación base

    // Factores financieros (40% del score)
    if (datosFinancieros.ingresosPromedioMensual > 10000000) score += 150;
    else if (datosFinancieros.ingresosPromedioMensual > 5000000) score += 100;
    else if (datosFinancieros.ingresosPromedioMensual > 1000000) score += 50;

    if (datosFinancieros.crecimientoMensual > 10) score += 100;
    else if (datosFinancieros.crecimientoMensual > 5) score += 50;
    else if (datosFinancieros.crecimientoMensual > 0) score += 25;

    if (datosFinancieros.frecuenciaTransacciones > 30) score += 50;
    else if (datosFinancieros.frecuenciaTransacciones > 15) score += 25;

    // Historial de préstamos (30% del score)
    if ((cliente.prestamos_pagados || 0) > 0) score += 100;
    if ((cliente.prestamos_vencidos || 0) === 0) score += 50;
    if ((cliente.prestamos_pagados || 0) > (cliente.prestamos_vencidos || 0)) score += 75;

    // Datos del negocio (20% del score)
    if ((cliente.antiguedad_negocio || 0) > 5) score += 50;
    else if ((cliente.antiguedad_negocio || 0) > 2) score += 25;

    if ((cliente.empleados || 0) > 5) score += 25;
    else if ((cliente.empleados || 0) > 1) score += 15;

    // Verificación de identidad (10% del score)
    if (cliente.verificado) score += 50;

    return Math.min(Math.max(score, 0), 1000);
  }

  /**
   * Determina categoría de riesgo
   */
  static determinarCategoriaRiesgo(score) {
    if (score >= 750) return 'bajo';
    if (score >= 500) return 'medio';
    return 'alto';
  }

  /**
   * Calcula potencial de escalabilidad
   */
  static calcularPotencialEscalabilidad(cliente, datosFinancieros) {
    let potencial = 0;

    // Factores de escalabilidad
    if (datosFinancieros.crecimientoMensual > 15) potencial += 30;
    if ((cliente.empleados || 0) > 3) potencial += 20;
    if (datosFinancieros.frecuenciaTransacciones > 50) potencial += 25;
    if ((cliente.antiguedad_negocio || 0) > 3) potencial += 25;

    if (potencial >= 80) return 'alto';
    if (potencial >= 50) return 'medio';
    return 'bajo';
  }

  /**
   * Analiza tendencia de crecimiento
   */
  static analizarTendencia(ingresosMensuales) {
    if (ingresosMensuales.length < 3) return 'insuficiente_datos';
    
    const ultimos3 = ingresosMensuales.slice(-3);
    const crecimiento = (ultimos3[2] - ultimos3[0]) / ultimos3[0];
    
    if (crecimiento > 0.2) return 'crecimiento_acelerado';
    if (crecimiento > 0.1) return 'crecimiento_estable';
    if (crecimiento > 0) return 'crecimiento_lento';
    if (crecimiento > -0.1) return 'estable';
    return 'decrecimiento';
  }

  /**
   * Analiza estacionalidad
   */
  static analizarEstacionalidad(ingresosMensuales) {
    if (ingresosMensuales.length < 12) return 'insuficiente_datos';
    
    const desviacion = this.calcularDesviacionEstandar(ingresosMensuales);
    const promedio = ingresosMensuales.reduce((a, b) => a + b, 0) / ingresosMensuales.length;
    const coeficienteVariacion = desviacion / promedio;
    
    if (coeficienteVariacion > 0.5) return 'alta';
    if (coeficienteVariacion > 0.3) return 'media';
    return 'baja';
  }

  /**
   * Calcula volatilidad de ingresos
   */
  static calcularVolatilidad(ingresosMensuales) {
    if (ingresosMensuales.length < 2) return 0;
    return this.calcularDesviacionEstandar(ingresosMensuales);
  }

  /**
   * Calcula desviación estándar
   */
  static calcularDesviacionEstandar(valores) {
    const promedio = valores.reduce((a, b) => a + b, 0) / valores.length;
    const diferencias = valores.map(v => Math.pow(v - promedio, 2));
    const varianza = diferencias.reduce((a, b) => a + b, 0) / valores.length;
    return Math.sqrt(varianza);
  }

  /**
   * Calcula edad
   */
  static calcularEdad(fechaNacimiento) {
    const hoy = new Date();
    const nacimiento = new Date(fechaNacimiento);
    let edad = hoy.getFullYear() - nacimiento.getFullYear();
    const mes = hoy.getMonth() - nacimiento.getMonth();
    if (mes < 0 || (mes === 0 && hoy.getDate() < nacimiento.getDate())) {
      edad--;
    }
    return edad;
  }

  /**
   * Compila datos para todos los clientes verificados
   * @param {number} usuario_id - ID del usuario para filtrar los clientes
   */
  static async compilarTodosLosDatos(usuario_id = null) {
    try {
      const clientes = await Cliente.obtenerTodosVerificados(usuario_id);

      const resultados = [];
      for (const cliente of clientes) {
        try {
          const datos = await this.compilarDatosCliente(cliente.id, usuario_id);
          resultados.push({
            cliente_id: cliente.id,
            nombre: cliente.nombre,
            datos: datos,
            estado: 'exitoso'
          });
        } catch (error) {
          resultados.push({
            cliente_id: cliente.id,
            nombre: cliente.nombre,
            error: error.message,
            estado: 'error'
          });
        }
      }

      return resultados;
    } catch (error) {
      console.error('Error compilando todos los datos:', error);
      throw error;
    }
  }

  /**
   * Genera reporte para venta a bancos
   * @param {number} usuario_id - ID del usuario para filtrar los clientes
   */
  static async generarReporteVenta(usuario_id = null) {
    try {
      const clientes = await Cliente.obtenerTodosVerificados(usuario_id);

      const reporte = {
        fecha_generacion: new Date(),
        total_clientes: clientes.length,
        resumen_por_categoria: {
          bajo: clientes.filter(c => c.categoria_riesgo === 'bajo').length,
          medio: clientes.filter(c => c.categoria_riesgo === 'medio').length,
          alto: clientes.filter(c => c.categoria_riesgo === 'alto').length
        },
        resumen_financiero: {
          ingresos_promedio_total: 0,
          score_promedio: 0,
          crecimiento_promedio: 0
        },
        clientes: clientes.map(cliente => ({
          id: cliente.id,
          nombre: cliente.nombre,
          categoria_riesgo: cliente.categoria_riesgo,
          score_credito: cliente.score_credito,
          ingresos_promedio_mensual: cliente.ingresos_promedio_mensual,
          datos_completos: cliente.datos_para_venta
        }))
      };

      // Calcular promedios
      const clientesConDatos = clientes.filter(c => c.ingresos_promedio_mensual > 0);
      if (clientesConDatos.length > 0) {
        reporte.resumen_financiero.ingresos_promedio_total = 
          clientesConDatos.reduce((sum, c) => sum + parseFloat(c.ingresos_promedio_mensual), 0) / clientesConDatos.length;
        reporte.resumen_financiero.score_promedio = 
          clientesConDatos.reduce((sum, c) => sum + (c.score_credito || 0), 0) / clientesConDatos.length;
        reporte.resumen_financiero.crecimiento_promedio = 
          clientesConDatos.reduce((sum, c) => sum + parseFloat(c.crecimiento_mensual || 0), 0) / clientesConDatos.length;
      }

      return reporte;
    } catch (error) {
      console.error('Error generando reporte de venta:', error);
      throw error;
    }
  }
}

module.exports = CompiladorDatosBancarios;