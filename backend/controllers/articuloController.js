const Articulo = require('../models/Articulo');
const pool = require('../config/database');

class ArticuloController {
  static async listar(req, res) {
    try {
      const { busqueda, incluirInactivos } = req.query;
      const incluirInactivosBool = incluirInactivos === 'true';
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const articulos = await Articulo.listar(busqueda, incluirInactivosBool, usuario_id);
      res.json({ success: true, data: articulos });
    } catch (error) {
      console.error('Error listando artículos:', error);
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
      
      const articulo = await Articulo.buscarPorId(id, null, usuario_id);
      if (!articulo) return res.status(404).json({ success: false, error: 'Artículo no encontrado' });
      res.json({ success: true, data: articulo });
    } catch (error) {
      console.error('Error buscando artículo:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async crear(req, res) {
    try {
      const { nombre, codigo, categoria_id, precio_compra, precio_venta, stock_minimo, activo, iva } = req.body;
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      // Validaciones básicas
      if (!nombre || nombre.trim() === '') {
        return res.status(400).json({ success: false, error: 'El nombre del producto es obligatorio' });
      }
      
      if (precio_compra == null || precio_compra < 0) {
        return res.status(400).json({ success: false, error: 'El precio de compra debe ser mayor o igual a 0' });
      }
      
      if (precio_venta == null || precio_venta < 0) {
        return res.status(400).json({ success: false, error: 'El precio de venta debe ser mayor o igual a 0' });
      }
      
      // Validar que el código no esté duplicado si se proporciona
      if (codigo && codigo.trim() !== '') {
        const existingProduct = await pool.query('SELECT id FROM articulos WHERE codigo = $1 AND usuario_id = $2', [codigo.trim(), usuario_id]);
        if (existingProduct.rows.length > 0) {
          return res.status(400).json({ 
            success: false, 
            error: `Ya existe un producto con el código "${codigo.trim()}". Por favor usa un código diferente.` 
          });
        }
      }
      
      const articulo = await Articulo.crear({ 
        nombre: nombre.trim(), 
        codigo: codigo ? codigo.trim() : null, 
        categoria_id, 
        precio_compra: parseFloat(precio_compra), 
        precio_venta: parseFloat(precio_venta), 
        stock_minimo: parseInt(stock_minimo) || 0, 
        activo: activo !== undefined ? activo : true, 
        iva: parseFloat(iva) || 10,
        usuario_id
      });
      
      res.status(201).json({ 
        success: true, 
        data: articulo,
        message: 'Producto creado exitosamente'
      });
    } catch (error) {
      console.error('Error creando artículo:', error);
      
      // Manejar errores específicos de la base de datos
      if (error.code === '23505') {
        if (error.constraint === 'articulos_codigo_key') {
          return res.status(400).json({ 
            success: false, 
            error: 'Ya existe un producto con este código. Por favor usa un código diferente.' 
          });
        }
      }
      
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async actualizar(req, res) {
    try {
      const id = req.params.id;
      const { nombre, codigo, categoria_id, precio_compra, precio_venta, stock_minimo, activo, iva } = req.body;
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const articulo = await Articulo.actualizar(id, { nombre, codigo, categoria_id, precio_compra, precio_venta, stock_minimo, activo, iva }, usuario_id);
      
      if (!articulo) {
        return res.status(404).json({ success: false, error: 'Artículo no encontrado o no pertenece a este usuario' });
      }
      
      res.json({ success: true, data: articulo });
    } catch (error) {
      console.error('Error actualizando artículo:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async eliminar(req, res) {
    try {
      const id = req.params.id;
      const usuario_id = req.user ? req.user.userId : null;
      
      if (!usuario_id) {
        return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
      }
      
      const articulo = await Articulo.eliminar(id, usuario_id);
      
      if (!articulo) {
        return res.status(404).json({ success: false, error: 'Artículo no encontrado o no pertenece a este usuario' });
      }
      
      res.json({ 
        success: true, 
        data: articulo,
        message: 'Artículo eliminado completamente del sistema.'
      });
    } catch (error) {
      console.error('Error eliminando artículo:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = ArticuloController;