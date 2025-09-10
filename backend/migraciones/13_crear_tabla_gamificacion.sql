ALTER TABLE gamificacion_puntos OWNER TO postgres;
-- Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_gamificacion_puntos_usuario_id ON gamificacion_puntos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_gamificacion_puntos_nivel ON gamificacion_puntos(nivel);
