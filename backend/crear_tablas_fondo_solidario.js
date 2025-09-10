const pool = require('./config/database');

async function crearTablasFondoSolidario() {
  try {
    console.log('🔧 Creando tablas para el Fondo Solidario...\n');

    // 1. Tabla de emprendedores
    console.log('📋 Creando tabla emprendedores...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS emprendedores (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        apellido VARCHAR(100) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        telefono VARCHAR(20) NOT NULL,
        foto_perfil TEXT,
        foto_portada TEXT,
        video_url TEXT,
        historia TEXT NOT NULL,
        meta_descripcion TEXT,
        meta_recaudacion DECIMAL(15,2) DEFAULT 0,
        recaudado DECIMAL(15,2) DEFAULT 0,
        verificado BOOLEAN DEFAULT FALSE,
        estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'aprobado', 'rechazado', 'suspendido')),
        fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_verificacion TIMESTAMP,
        motivo_rechazo TEXT,
        categoria VARCHAR(100),
        ubicacion VARCHAR(255),
        usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Tabla emprendedores creada');

    // 2. Tabla de donaciones
    console.log('📋 Creando tabla donaciones...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS donaciones (
        id SERIAL PRIMARY KEY,
        emprendedor_id INTEGER NOT NULL REFERENCES emprendedores(id) ON DELETE CASCADE,
        donante_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
        nombre_donante VARCHAR(255),
        monto DECIMAL(15,2) NOT NULL,
        comision_gio DECIMAL(15,2) NOT NULL,
        monto_neto DECIMAL(15,2) NOT NULL,
        mensaje TEXT,
        anonimo BOOLEAN DEFAULT FALSE,
        estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'procesada', 'completada', 'fallida')),
        fecha_donacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_procesamiento TIMESTAMP,
        metodo_pago VARCHAR(50),
        referencia_pago VARCHAR(255),
        agradecimiento TEXT,
        fecha_agradecimiento TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Tabla donaciones creada');

    // 3. Tabla de categorías de emprendedores
    console.log('📋 Creando tabla categorias_emprendedores...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS categorias_emprendedores (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) UNIQUE NOT NULL,
        descripcion TEXT,
        activo BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Tabla categorias_emprendedores creada');

    // 4. Tabla de configuración de comisiones
    console.log('📋 Creando tabla configuracion_comisiones...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS configuracion_comisiones (
        id SERIAL PRIMARY KEY,
        porcentaje_comision DECIMAL(5,2) NOT NULL DEFAULT 5.00,
        monto_minimo_donacion DECIMAL(15,2) DEFAULT 1000.00,
        activo BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Tabla configuracion_comisiones creada');

    // 5. Insertar datos iniciales
    console.log('📋 Insertando datos iniciales...');
    
    // Configuración de comisiones
    await pool.query(`
      INSERT INTO configuracion_comisiones (porcentaje_comision, monto_minimo_donacion)
      VALUES (5.00, 1000.00)
      ON CONFLICT DO NOTHING
    `);

    // Categorías de emprendedores
    const categorias = [
      'Artesanías',
      'Gastronomía',
      'Servicios',
      'Tecnología',
      'Educación',
      'Salud',
      'Agricultura',
      'Otros'
    ];

    for (const categoria of categorias) {
      await pool.query(`
        INSERT INTO categorias_emprendedores (nombre)
        VALUES ($1)
        ON CONFLICT DO NOTHING
      `, [categoria]);
    }

    console.log('✅ Datos iniciales insertados');

    // 6. Crear índices para optimización
    console.log('📋 Creando índices...');
    
    await pool.query('CREATE INDEX IF NOT EXISTS idx_emprendedores_estado ON emprendedores(estado)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_emprendedores_verificado ON emprendedores(verificado)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_donaciones_emprendedor ON donaciones(emprendedor_id)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_donaciones_estado ON donaciones(estado)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_donaciones_fecha ON donaciones(fecha_donacion)');
    
    console.log('✅ Índices creados');

    // 7. Crear función para actualizar timestamp
    console.log('📋 Creando función de actualización de timestamp...');
    await pool.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql'
    `);

    // 8. Crear triggers para actualizar timestamps
    await pool.query(`
      DROP TRIGGER IF EXISTS update_emprendedores_updated_at ON emprendedores;
      CREATE TRIGGER update_emprendedores_updated_at
        BEFORE UPDATE ON emprendedores
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column()
    `);

    await pool.query(`
      DROP TRIGGER IF EXISTS update_donaciones_updated_at ON donaciones;
      CREATE TRIGGER update_donaciones_updated_at
        BEFORE UPDATE ON donaciones
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column()
    `);

    await pool.query(`
      DROP TRIGGER IF EXISTS update_configuracion_comisiones_updated_at ON configuracion_comisiones;
      CREATE TRIGGER update_configuracion_comisiones_updated_at
        BEFORE UPDATE ON configuracion_comisiones
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column()
    `);

    console.log('✅ Triggers creados');

    // 9. Crear función para calcular comisión automáticamente
    console.log('📋 Creando función para calcular comisión...');
    await pool.query(`
      CREATE OR REPLACE FUNCTION calcular_comision_gio(monto_donacion DECIMAL)
      RETURNS DECIMAL AS $$
      DECLARE
        porcentaje_comision DECIMAL;
      BEGIN
        SELECT porcentaje_comision INTO porcentaje_comision
        FROM configuracion_comisiones
        WHERE activo = TRUE
        LIMIT 1;
        
        IF porcentaje_comision IS NULL THEN
          porcentaje_comision := 5.00; -- Valor por defecto
        END IF;
        
        RETURN (monto_donacion * porcentaje_comision) / 100;
      END;
      $$ LANGUAGE plpgsql
    `);

    console.log('✅ Función de cálculo de comisión creada');

    // 10. Crear función para calcular comisión automáticamente
    await pool.query(`
      CREATE OR REPLACE FUNCTION calcular_comision_automatica()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.comision_gio := calcular_comision_gio(NEW.monto);
        NEW.monto_neto := NEW.monto - NEW.comision_gio;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);

    // 11. Crear trigger para calcular comisión automáticamente
    await pool.query(`
      DROP TRIGGER IF EXISTS calcular_comision_trigger ON donaciones;
      CREATE TRIGGER calcular_comision_trigger
        BEFORE INSERT ON donaciones
        FOR EACH ROW
        EXECUTE FUNCTION calcular_comision_automatica()
    `);

    console.log('✅ Trigger de cálculo automático de comisión creado');

    console.log('\n🎉 ¡Todas las tablas del Fondo Solidario han sido creadas exitosamente!');
    console.log('\n📊 Resumen de tablas creadas:');
    console.log('  - emprendedores');
    console.log('  - donaciones');
    console.log('  - categorias_emprendedores');
    console.log('  - configuracion_comisiones');
    console.log('\n🔧 Funcionalidades implementadas:');
    console.log('  - Cálculo automático de comisiones');
    console.log('  - Índices para optimización');
    console.log('  - Triggers para timestamps');
    console.log('  - Datos iniciales');

  } catch (error) {
    console.error('❌ Error creando tablas:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la creación
crearTablasFondoSolidario();
