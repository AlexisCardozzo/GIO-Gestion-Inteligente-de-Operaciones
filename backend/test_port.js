require('dotenv').config({ path: 'configuracion.env' });
 
console.log('Puerto configurado:', process.env.PORT);
console.log('Puerto por defecto:', process.env.PORT || 3000); 