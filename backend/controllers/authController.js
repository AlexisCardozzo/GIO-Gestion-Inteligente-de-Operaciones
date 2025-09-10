const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Sucursal = require('../models/Sucursal');

class AuthController {
  // Registro de usuario
  static async register(req, res) {
    try {
      const { nombre, apellido, nombre_usuario, email, password, rol } = req.body;

      // Validaciones básicas
      if (!nombre || !apellido || !nombre_usuario || !email || !password) {
        return res.status(400).json({
          success: false,
          error: 'Todos los campos son requeridos'
        });
      }

      // Validación de formato de email
      const emailRegExp = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$/;
      if (!emailRegExp.test(email)) {
        return res.status(400).json({
          success: false,
          error: 'El email no tiene un formato válido'
        });
      }

      if (password.length < 6) {
        return res.status(400).json({
          success: false,
          error: 'La contraseña debe tener al menos 6 caracteres'
        });
      }

      // Verificar si el email ya existe
      const existingUserByEmail = await User.findByEmail(email);
      if (existingUserByEmail) {
        return res.status(409).json({
          success: false,
          error: 'El email ya está registrado'
        });
      }

      // Verificar si el nombre de usuario ya existe
      const existingUserByUsername = await User.findByUsername(nombre_usuario);
      if (existingUserByUsername) {
        return res.status(409).json({
          success: false,
          error: 'El nombre de usuario ya está en uso'
        });
      }

      // Crear usuario
      const user = await User.create({
        nombre,
        apellido,
        nombre_usuario,
        email,
        password,
        rol: rol || 'user'
      });
      console.log('✅ Usuario creado:', user.email, 'ID:', user.id, 'Nombre de usuario:', user.nombre_usuario);

      // Generar JWT
      const token = jwt.sign(
        { userId: user.id, email: user.email, rol: user.rol },
        process.env.JWT_SECRET || 'gio_secret_key',
        { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
      );

      res.status(201).json({
        success: true,
        message: 'Usuario registrado exitosamente',
        data: {
          user: {
            id: user.id,
            nombre: user.nombre,
            apellido: user.apellido,
            nombre_usuario: user.nombre_usuario,
            email: user.email,
            rol: user.rol
          },
          token
        }
      });

    } catch (error) {
      console.error('❌ Error en registro:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Login de usuario
  static async login(req, res) {
    try {
      const { email, password } = req.body;

      // Validaciones básicas
      if (!email || !password) {
        return res.status(400).json({
          success: false,
          error: 'Email y contraseña son requeridos'
        });
      }

      // Buscar usuario
      const user = await User.findByEmail(email);
      if (!user) {
        return res.status(401).json({
          success: false,
          error: 'Credenciales inválidas'
        });
      }

      // Validar contraseña
      const isValidPassword = await User.validatePassword(user, password);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          error: 'Credenciales inválidas'
        });
      }
      console.log('✅ Login exitoso para:', user.email, 'ID:', user.id, 'Nombre de usuario:', user.nombre_usuario);

      // Generar token inicial (solo con información básica del usuario)
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET || 'gio_secret_key',
        { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
      );

      // Verificar si el usuario tiene sucursales
      const sucursales = await Sucursal.buscarPorUsuario(user.id);
      const needsSetup = sucursales.length === 0;

      res.json({
        success: true,
        message: 'Login exitoso',
        data: {
          user: {
            id: user.id,
            nombre: user.nombre,
            apellido: user.apellido,
            nombre_usuario: user.nombre_usuario,
            email: user.email
          },
          token,
          needsSetup
        }
      });

    } catch (error) {
      console.error('❌ Error en login:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }

  // Obtener perfil del usuario autenticado
  static async getProfile(req, res) {
    try {
      const user = await User.findById(req.user.userId);
      
      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'Usuario no encontrado'
        });
      }
      console.log('✅ Perfil consultado para:', user.email);

      res.json({
        success: true,
        data: { user }
      });

    } catch (error) {
      console.error('❌ Error obteniendo perfil:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
}

module.exports = AuthController;