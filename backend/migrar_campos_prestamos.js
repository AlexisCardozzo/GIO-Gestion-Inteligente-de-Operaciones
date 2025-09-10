const pool = require('./config/database');

async function migrarCamposPrestamos() {
  try {
    console.log('🔄 Iniciando migración de campos para sistema de préstamos...');
    
    // Verificar si la tabla clientes existe
    const { rows } = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'clientes'
    `);
    
    const columnasExistentes = rows.map(row => row.column_name);
    console.log('📋 Columnas existentes:', columnasExistentes);
    
    // Campos a agregar para el sistema de préstamos
    const camposNuevos = [
      // Datos de Identificación
      { nombre: 'ci_numero', tipo: 'VARCHAR(20)', comentario: 'Número de cédula de identidad' },
      { nombre: 'ci_frente_url', tipo: 'TEXT', comentario: 'URL de foto CI frente' },
      { nombre: 'ci_reverso_url', tipo: 'TEXT', comentario: 'URL de foto CI reverso' },
      
      // Datos Demográficos
      { nombre: 'fecha_nacimiento', tipo: 'DATE', comentario: 'Para cálculo de edad' },
      { nombre: 'nivel_educativo', tipo: 'VARCHAR(20)', comentario: 'Nivel educativo del cliente' },
      { nombre: 'estado_civil', tipo: 'VARCHAR(20)', comentario: 'Estado civil del cliente' },
      { nombre: 'dependientes', tipo: 'INTEGER', comentario: 'Número de dependientes económicos' },
      
      // Datos del Negocio
      { nombre: 'tipo_negocio', tipo: 'VARCHAR(100)', comentario: 'Sector económico del negocio' },
      { nombre: 'antiguedad_negocio', tipo: 'INTEGER', comentario: 'Años de operación del negocio' },
      { nombre: 'empleados', tipo: 'INTEGER', comentario: 'Número de empleados' },
      { nombre: 'ubicacion_negocio', tipo: 'VARCHAR(200)', comentario: 'Zona geográfica del negocio' },
      
      // Datos Financieros Compilados
      { nombre: 'ingresos_promedio_mensual', tipo: 'DECIMAL(15,2)', comentario: 'Promedio de ingresos últimos 12 meses' },
      { nombre: 'crecimiento_mensual', tipo: 'DECIMAL(5,2)', comentario: 'Porcentaje de crecimiento mensual promedio' },
      { nombre: 'liquidez_promedio', tipo: 'DECIMAL(15,2)', comentario: 'Liquidez disponible promedio' },
      { nombre: 'frecuencia_transacciones', tipo: 'INTEGER', comentario: 'Promedio de transacciones por mes' },
      { nombre: 'monto_promedio_venta', tipo: 'DECIMAL(15,2)', comentario: 'Monto promedio por venta' },
      
      // Score Crediticio
      { nombre: 'score_credito', tipo: 'INTEGER', comentario: 'Score crediticio interno (0-1000)' },
      { nombre: 'categoria_riesgo', tipo: 'VARCHAR(10)', comentario: 'Categoría de riesgo (bajo/medio/alto)' },
      
      // Historial de Préstamos
      { nombre: 'prestamos_solicitados', tipo: 'INTEGER DEFAULT 0', comentario: 'Número de préstamos solicitados' },
      { nombre: 'prestamos_aprobados', tipo: 'INTEGER DEFAULT 0', comentario: 'Número de préstamos aprobados' },
      { nombre: 'prestamos_pagados', tipo: 'INTEGER DEFAULT 0', comentario: 'Número de préstamos pagados' },
      { nombre: 'prestamos_vencidos', tipo: 'INTEGER DEFAULT 0', comentario: 'Número de préstamos vencidos' },
      
      // Estado de Verificación
      { nombre: 'verificado', tipo: 'BOOLEAN DEFAULT FALSE', comentario: 'Estado de verificación de identidad' },
      { nombre: 'fecha_verificacion', tipo: 'TIMESTAMP', comentario: 'Fecha de verificación' },
      
      // Datos de Venta
      { nombre: 'datos_para_venta', tipo: 'JSON', comentario: 'Datos estructurados para venta a bancos' },
      { nombre: 'fecha_ultima_actualizacion_datos', tipo: 'TIMESTAMP', comentario: 'Fecha de última actualización de datos' }
    ];
    
    // Agregar campos que no existen
    for (const campo of camposNuevos) {
      if (!columnasExistentes.includes(campo.nombre)) {
        try {
          await pool.query(`ALTER TABLE clientes ADD COLUMN ${campo.nombre} ${campo.tipo}`);
          console.log(`✅ Campo agregado: ${campo.nombre} - ${campo.comentario}`);
        } catch (error) {
          console.error(`❌ Error agregando campo ${campo.nombre}:`, error.message);
        }
      } else {
        console.log(`⏭️ Campo ya existe: ${campo.nombre}`);
      }
    }
    
    // Crear índices para optimizar consultas
    const indices = [
      'CREATE INDEX IF NOT EXISTS idx_clientes_verificado ON clientes(verificado)',
      'CREATE INDEX IF NOT EXISTS idx_clientes_score_credito ON clientes(score_credito)',
      'CREATE INDEX IF NOT EXISTS idx_clientes_categoria_riesgo ON clientes(categoria_riesgo)',
      'CREATE INDEX IF NOT EXISTS idx_clientes_ingresos ON clientes(ingresos_promedio_mensual)'
    ];
    
    for (const indice of indices) {
      try {
        await pool.query(indice);
        console.log('✅ Índice creado/verificado');
      } catch (error) {
        console.error('❌ Error creando índice:', error.message);
      }
    }
    
    console.log('🎉 Migración completada exitosamente!');
    
  } catch (error) {
    console.error('❌ Error en migración:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar migración
migrarCamposPrestamos(); 