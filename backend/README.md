# Backend GIO

**Visión:**
Backend de la plataforma GIO, orientado a la excelencia, escalabilidad y robustez para la gestión comercial de nivel mundial.

## Tecnologías base
- Node.js
- Express
- PostgreSQL

## Pasos iniciales
1. Inicializa el proyecto:
   ```sh
   npm init -y
   npm install express pg
   ```
2. Crea tu archivo `server.js` y la estructura de carpetas que necesites (`routes`, `controllers`, `models`, etc).
3. Configura la conexión a tu base de datos PostgreSQL.

---

**Construye el backend de GIO con excelencia y visión global.** 

# Quitar restricción UNIQUE de ci_ruc y celular en clientes

Si tienes problemas para registrar clientes con el mismo CI/RUC o celular, ejecuta estas consultas en tu base de datos PostgreSQL:

```
-- Busca el nombre de los constraints únicos:
SELECT conname FROM pg_constraint WHERE conrelid = 'clientes'::regclass;

-- Elimina la restricción UNIQUE de ci_ruc (ajusta el nombre si es diferente):
ALTER TABLE clientes DROP CONSTRAINT IF EXISTS clientes_ci_ruc_key;

-- Elimina la restricción UNIQUE de celular (ajusta el nombre si es diferente):
ALTER TABLE clientes DROP CONSTRAINT IF EXISTS clientes_celular_key;
```

Esto permitirá registrar clientes con CI/RUC o celular repetidos. 