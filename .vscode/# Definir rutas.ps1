# Definir rutas
$backendPath = "C:\GIO.OFICIAL\backend"
$modelsPath = "$backendPath\models"
$controllersPath = "$backendPath\controllers"

# Buscar y modificar Cliente.js
$clienteContent = Get-Content "$modelsPath\Cliente.js" -Raw
$clienteModified = $clienteContent -replace 'unique:\s*true', 'unique: false'
$clienteModified | Set-Content "$modelsPath\Cliente.js"

# Buscar y modificar clienteController.js
$controllerContent = Get-Content "$controllersPath\clienteController.js" -Raw
$controllerModified = $controllerContent -replace '(?s)\/\/ Validación de duplicados.*?next\(\);', '// Validación removida\r\n    next();'
$controllerModified | Set-Content "$controllersPath\clienteController.js"

# Buscar y modificar ventaController.js
$ventaContent = Get-Content "$controllersPath\ventaController.js" -Raw
$ventaModified = $ventaContent -replace '(?s)\/\/ Validación de cliente.*?next\(\);', '// Validación removida\r\n    next();'
$ventaModified | Set-Content "$controllersPath\ventaController.js"

Write-Host "Modificaciones completadas. Reinicia el servidor para aplicar los cambios."