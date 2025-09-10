require('dotenv').config({ path: 'configuracion.env' });
const express = require('express');
const app = express();

// Middlewares
app.use(express.json());
// Middleware manual de CORS para desarrollo
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.header('Access-Control-Allow-Credentials', 'true');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Importar middleware de autenticación
const { authMiddleware } = require('./database/middlewares/auth');

// Rutas principales
// Aplicar middleware de autenticación a las rutas de artículos
app.use('/api/articulos', authMiddleware, require('./routes/articulos'));
app.use('/api/clientes', require('./routes/clientes'));
app.use('/api/ventas', require('./routes/venta'));
// Rutas de stock (el middleware se aplica en cada ruta individual)
app.use('/api/stock', require('./routes/stock'));
app.use('/api/roles', require('./routes/rol'));
app.use('/api/sucursales', require('./routes/sucursal'));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/sucursal-rol', require('./routes/sucursalRol'));
app.use('/api/reportes', require('./routes/reporte'));
app.use('/api/fidelizacion', require('./routes/fidelizacion'));
app.use('/api/prestamos', require('./routes/prestamos'));
app.use('/api/fondo-solidario', require('./routes/fondoSolidario'));
app.use('/api/publicaciones', require('./routes/publicaciones'));
app.use('/api/configuracion-ticket', require('./routes/configuracionTicket'));
app.use('/api/posts', authMiddleware, require('./routes/posts'));

// Ruta de prueba
app.get('/', (req, res) => {
  res.send('🚀 Backend GIO corriendo correctamente');
});

// Manejo de errores 404
app.use((req, res, next) => {
  res.status(404).json({ success: false, error: 'Ruta no encontrada' });
});

// Manejo de errores generales
app.use((err, req, res, next) => {
  console.error('Error general:', err);
  res.status(500).json({ success: false, error: 'Error interno del servidor' });
});

// Arranque del servidor
const PORT = process.env.PORT || 3001; // Cambiado a 3001 para evitar conflictos
const pool = require('./config/database');
const Reporte = require('./models/Reporte');
const Emprendedor = require('./models/Emprendedor');
const Publicacion = require('./models/Publicacion');
const ConfiguracionTicket = require('./models/ConfiguracionTicket');
const Gamificacion = require('./models/Gamificacion');

// Tablas principales a chequear (usando los nombres reales)
const tablas = [
  'usuarios',
  'articulos',
  'clientes',
  'ventas',
  'beneficios',
  'beneficios_fidelizacion',
  'clientes_beneficios',
  'puntos_cliente',
  'roles',
  'sucursales',
  'posts',
  'likes',
  'hashtags',
  'posts_hashtags',
  'notificaciones'
];

Promise.all([
  // Verificar tablas existentes
  ...tablas.map(tabla =>
    pool.query(`SELECT 1 FROM ${tabla} LIMIT 1`).then(() => {
      console.log(`✅ Conexión y acceso a la tabla '${tabla}' exitosa`);
    }).catch(err => {
      console.error(`❌ Error de conexión/acceso a la tabla '${tabla}':`, err.message);
    })
  ),
  // Crear tabla de reportes si no existe
  Reporte.createTable().then(() => {
    console.log('✅ Tabla reportes verificada/creada');
  }).catch(err => {
    console.error('❌ Error con tabla reportes:', err.message);
  }),
  // Crear tablas del sistema de emprendedores y publicaciones
  Emprendedor.createTable().then(() => {
    console.log('✅ Tabla emprendedores verificada/creada');
  }).catch(err => {
    console.error('❌ Error con tabla emprendedores:', err.message);
  }),
  Publicacion.createTable().then(() => {
    console.log('✅ Tablas del sistema de publicaciones verificadas/creadas');
  }).catch(err => {
    console.error('❌ Error con tablas del sistema de publicaciones:', err.message);
  }),
  // Crear tabla de configuración de tickets
  ConfiguracionTicket.createTable().then(() => {
    console.log('✅ Tabla configuracion_ticket verificada/creada');
  }).catch(err => {
    console.error('❌ Error con tabla configuracion_ticket:', err.message);
  }),
  // Crear tabla de gamificación
  Gamificacion.createTable().then(() => {
    console.log('✅ Tabla gamificacion_puntos verificada/creada');
  }).catch(err => {
    console.error('❌ Error con tabla gamificacion_puntos:', err.message);
  })
]).then(() => {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Servidor backend escuchando en http://localhost:${PORT}`);
  });
});
