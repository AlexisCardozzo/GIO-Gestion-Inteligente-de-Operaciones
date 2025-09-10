const pool = require('../config/database');

const checkSucursalRol = async (req, res, next) => {
  // Rutas que no requieren verificación de sucursal y rol
  const publicRoutes = [
    '/api/auth/login',
    '/api/auth/register',
    '/api/sucursales',
    '/api/roles',
    '/api/roles/login'
  ];

  if (publicRoutes.some(route => req.path.includes(route))) {
    return next();
  }

  try {
    const usuarioSucursalRol = await pool.query(
      'SELECT usr.*, s.nombre as sucursal_nombre, r.nombre as rol_nombre ' +
      'FROM usuario_sucursal_rol usr ' +
      'INNER JOIN sucursales s ON s.id = usr.sucursal_id ' +
      'INNER JOIN roles r ON r.id = usr.rol_id ' +
      'WHERE usr.usuario_id = $1 ' +
      'ORDER BY usr.id DESC LIMIT 1',
      [req.user.userId]
    );

    if (usuarioSucursalRol.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'Debe seleccionar una sucursal y rol',
        requiresSelection: true
      });
    }

    // Agregar información de sucursal y rol al request
    req.sucursalRol = usuarioSucursalRol.rows[0];
    next();
  } catch (error) {
    console.error('❌ Error verificando sucursal y rol:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
};

module.exports = checkSucursalRol;
