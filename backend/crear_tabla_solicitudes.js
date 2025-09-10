const pool = require('./config/database');

async function crearTablaSolicitudes() {
  try {
    console.log('🔄 Creando tabla de solicitudes de préstamos...');
    
    const query = `
      CREATE TABLE IF NOT EXISTS solicitudes_prestamos (
        id SERIAL PRIMARY KEY,
        cliente_id INTEGER NOT NULL REFERENCES clientes(id),
        tipo_solicitud VARCHAR(50) NOT NULL, -- 'verificacion_identidad' o 'prestamo'
        monto DECIMAL(15,2),
        proposito TEXT,
        plan_negocio TEXT,
        estado VARCHAR(20) DEFAULT 'pendiente', -- 'pendiente', 'aprobado', 'rechazado'
        datos_solicitud JSON,
        datos_analisis JSON,
        fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_revision TIMESTAMP,
        revisado_por INTEGER REFERENCES usuarios(id),
        comentarios_revision TEXT,
        activo BOOLEAN DEFAULT TRUE
      )
    `;
    
    await pool.query(query);
    console.log('✅ Tabla solicitudes_prestamos creada exitosamente');
    
    // Crear índices para optimizar consultas
    const indices = [
      'CREATE INDEX IF NOT EXISTS idx_solicitudes_cliente ON solicitudes_prestamos(cliente_id)',
      'CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON solicitudes_prestamos(estado)',
      'CREATE INDEX IF NOT EXISTS idx_solicitudes_tipo ON solicitudes_prestamos(tipo_solicitud)',
      'CREATE INDEX IF NOT EXISTS idx_solicitudes_fecha ON solicitudes_prestamos(fecha_solicitud)'
    ];
    
    for (const indice of indices) {
      await pool.query(indice);
    }
    console.log('✅ Índices creados exitosamente');
    
  } catch (error) {
    console.error('❌ Error creando tabla:', error);
  } finally {
    await pool.end();
  }
}

crearTablaSolicitudes(); 