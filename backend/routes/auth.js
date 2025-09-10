const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const { authMiddleware } = require('../database/middlewares/auth');

// Ruta de registro
router.post('/register', AuthController.register);

// Ruta de login
router.post('/login', AuthController.login);

// Ruta para obtener perfil (requiere autenticación)
router.get('/profile', authMiddleware, AuthController.getProfile);

module.exports = router;