const Producto = require('../models/Producto');
const pool = require('../config/database');

class StockController {
  static async registrarMovimiento(req, res) {
    try {
      const { producto_id, tipo, cantidad, motivo } = req.body;
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      if (!producto_id || !tipo || !cantidad) {
        return res.status(400).json({ success: false, error: 'Datos incompletos' });
      }
      
      // Verificar que el producto pertenezca al usuario
      const productoResult = await pool.query('SELECT * FROM articulos WHERE id = $1 AND usuario_id = $2', [producto_id, usuario_id]);
      if (productoResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Producto no encontrado o no pertenece a este usuario' });
      }
      
      if (tipo === 'salida') {
        // Verificar stock disponible
        const stockResult = await Producto.obtenerStock(false, usuario_id);
        const producto = stockResult.find(p => p.id == producto_id);
        if (!producto || producto.cantidad < cantidad) {
          return res.status(400).json({ success: false, error: 'Stock insuficiente para realizar la salida' });
        }
      }
      
      const movimiento = await Producto.registrarMovimiento({ producto_id, tipo, cantidad, motivo });
      res.status(201).json({ success: true, data: movimiento });
    } catch (error) {
      console.error('Error al registrar movimiento:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async obtenerMovimientos(req, res) {
    try {
      const { producto_id } = req.query;
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      if (!producto_id) {
        return res.status(400).json({ success: false, error: 'producto_id requerido' });
      }
      
      // Verificar que el producto pertenezca al usuario
      const productoResult = await pool.query('SELECT * FROM articulos WHERE id = $1 AND usuario_id = $2', [producto_id, usuario_id]);
      if (productoResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Producto no encontrado o no pertenece a este usuario' });
      }
      
      const movimientos = await Producto.obtenerMovimientos(producto_id);
      res.json({ success: true, data: movimientos });
    } catch (error) {
      console.error('Error al obtener movimientos:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async obtenerStock(req, res) {
    try {
      const { incluirInactivos } = req.query;
      const incluirInactivosBool = incluirInactivos === 'true';
      // Obtener el ID del usuario autenticado desde el token
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const productos = await Producto.obtenerStock(incluirInactivosBool, usuario_id);
      res.json({ success: true, data: productos });
    } catch (error) {
      console.error('Error al obtener stock:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async obtenerMovimientosGlobales(req, res) {
    try {
      // Obtener el ID del usuario autenticado desde el token
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      // Filtrar movimientos por usuario_id
      const result = await pool.query(
        'SELECT ms.* FROM movimientos_stock ms ' +
        'JOIN articulos a ON ms.articulo_id = a.id ' +
        'WHERE a.usuario_id = $1 ' +
        'ORDER BY ms.fecha_hora DESC', 
        [usuario_id]
      );
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('Error al obtener movimientos globales:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async eliminarHistorialVentas(req, res) {
    try {
      // Eliminar movimientos de salida que contengan 'venta_id=' en la referencia
      await pool.query("DELETE FROM movimientos_stock WHERE tipo_movimiento = 'salida' AND referencia LIKE '%venta_id=%'");
      res.json({ success: true, message: 'Historial de ventas eliminado correctamente.' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = StockController;