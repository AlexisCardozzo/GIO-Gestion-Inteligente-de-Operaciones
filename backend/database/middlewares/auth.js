const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  try {
    // Obtener token del header
    const authHeader = req.headers.authorization;
    console.log('Auth Header:', authHeader);
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log('Token no proporcionado o formato incorrecto');
      return res.status(401).json({
        success: false,
        error: 'Token de acceso requerido'
      });
    }

    // Extraer token
    const token = authHeader.substring(7); // Remover 'Bearer '
    console.log('Token extraído (primeros 20 caracteres):', token.substring(0, 20) + '...');

    // Verificar token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'gio_secret_key');
    console.log('Token decodificado:', decoded);
    
    // Agregar información del usuario al request
    req.user = {
      id: decoded.userId, // Asignar userId como id para mantener compatibilidad
      ...decoded
    };
    console.log('Usuario ID asignado a req.user:', req.user.id);
    
    next();
  } catch (error) {
    console.error('❌ Error en autenticación:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: 'Token inválido'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Token expirado'
      });
    }

    res.status(500).json({
      success: false,
      error: 'Error en autenticación'
    });
  }
};

// Middleware para verificar roles específicos
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Autenticación requerida'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: 'Acceso denegado'
      });
    }

    next();
  };
};

const verificarToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET || 'gio_secret_key');
  } catch (error) {
    throw new Error('Token inválido');
  }
};

module.exports = { authMiddleware, verificarToken, requireRole };