const pool = require('../config/database');
const jwt = require('jsonwebtoken');

class SucursalRolController {
  // Obtener sucursales y roles disponibles para el usuario
  static async getSucursalesRoles(req, res) {
    try {
      const usuario_id = req.user.userId;

      // Obtener sucursales y roles del usuario
      const result = await pool.query(
        'SELECT DISTINCT s.id as sucursal_id, s.nombre as sucursal_nombre, ' +
        'r.id as rol_id, r.nombre as rol_nombre ' +
        'FROM usuario_sucursal_rol usr ' +
        'INNER JOIN sucursales s ON s.id = usr.sucursal_id ' +
        'INNER JOIN roles r ON r.id = usr.rol_id ' +
        'WHERE usr.usuario_id = $1 ' +
        'ORDER BY s.nombre, r.nombre',
        [usuario_id]
      );

      const sucursales = [];
      const sucursalesMap = new Map();

      // Organizar los datos por sucursal
      result.rows.forEach(row => {
        if (!sucursalesMap.has(row.sucursal_id)) {
          const sucursal = {
            id: row.sucursal_id,
            nombre: row.sucursal_nombre,
            roles: []
          };
          sucursales.push(sucursal);
          sucursalesMap.set(row.sucursal_id, sucursal);
        }
        
        sucursalesMap.get(row.sucursal_id).roles.push({
          id: row.rol_id,
          nombre: row.rol_nombre
        });
      });

      res.json({
        success: true,
        data: sucursales
      });

    } catch (error) {
      console.error('❌ Error obteniendo sucursales y roles:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Seleccionar sucursal y rol
  static async seleccionar(req, res) {
    try {
      const { sucursal_id, rol_id } = req.body;
      const usuario_id = req.user.userId;

      if (!sucursal_id || !rol_id) {
        return res.status(400).json({
          success: false,
          error: 'Sucursal y rol son requeridos'
        });
      }

      // Verificar que la combinación exista y esté activa
      const usuarioSucursalRol = await pool.query(
        'SELECT usr.*, s.nombre as sucursal_nombre, r.nombre as rol_nombre ' +
        'FROM usuario_sucursal_rol usr ' +
        'INNER JOIN sucursales s ON s.id = usr.sucursal_id ' +
        'INNER JOIN roles r ON r.id = usr.rol_id ' +
        'WHERE usr.usuario_id = $1 AND usr.sucursal_id = $2 AND usr.rol_id = $3',
        [usuario_id, sucursal_id, rol_id]
      );

      if (usuarioSucursalRol.rows.length === 0) {
        return res.status(403).json({
          success: false,
          error: 'No tiene acceso a esta combinación de sucursal y rol'
        });
      }

      const seleccion = usuarioSucursalRol.rows[0];

      // Generar nuevo token con la información completa
      const token = jwt.sign(
        {
          userId: usuario_id,
          sucursal_id: seleccion.sucursal_id,
          rol_id: seleccion.rol_id,
          sucursal_nombre: seleccion.sucursal_nombre,
          rol_nombre: seleccion.rol_nombre
        },
        process.env.JWT_SECRET || 'gio_secret_key',
        { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
      );

      res.json({
        success: true,
        data: {
          token,
          sucursal: {
            id: seleccion.sucursal_id,
            nombre: seleccion.sucursal_nombre
          },
          rol: {
            id: seleccion.rol_id,
            nombre: seleccion.rol_nombre
          }
        }
      });

    } catch (error) {
      console.error('❌ Error seleccionando sucursal y rol:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
}

module.exports = SucursalRolController;
