class MensajesPersonalizados {
  
  // Generar mensaje personalizado basado en el perfil del cliente
  static generarMensajePersonalizado(cliente) {
    const {
      cliente_nombre,
      nivel_riesgo,
      dias_sin_comprar,
      total_compras,
      promedio_compra,
      total_gastado,
      tipo_cliente,
      valor_cliente,
      producto_favorito
    } = cliente;

    // Saludo personalizado
    const saludos = [
      `¡Hola ${cliente_nombre}! 👋`,
      `¡${cliente_nombre}, te extrañamos! 💕`,
      `¡Hola ${cliente_nombre}! ¿Cómo estás? 😊`,
      `¡${cliente_nombre}! Tenemos algo especial para ti 🎁`
    ];

    // Mensaje según tipo de cliente
    const mensajeTipoCliente = this._getMensajePorTipoCliente(tipo_cliente, valor_cliente);
    
    // Mensaje según nivel de riesgo
    const mensajeRiesgo = this._getMensajePorRiesgo(nivel_riesgo, dias_sin_comprar);
    
    // Oferta personalizada
    const oferta = this._getOfertaPersonalizada(nivel_riesgo, valor_cliente, promedio_compra);
    
    // Producto favorito
    const mensajeProducto = this._getMensajeProducto(producto_favorito);
    
    // Call to action
    const callToAction = this._getCallToAction(nivel_riesgo, tipo_cliente);

    // Construir mensaje completo
    const mensaje = `${saludos[Math.floor(Math.random() * saludos.length)]}

${mensajeTipoCliente}

${mensajeRiesgo}

${oferta}

${mensajeProducto}

${callToAction}

¡Esperamos verte pronto! 🚀`;

    return mensaje;
  }

  // Mensaje según tipo de cliente
  static _getMensajePorTipoCliente(tipoCliente, valorCliente) {
    switch (tipoCliente) {
      case 'Cliente Frecuente':
        return `Como ${tipoCliente.toLowerCase()} y cliente de ${valorCliente.toLowerCase()}, eres muy especial para nosotros.`;
      case 'Cliente Regular':
        return `Sabemos que eres un ${tipoCliente.toLowerCase()} y valoramos mucho tu confianza.`;
      case 'Cliente Ocasional':
        return `Aunque no nos visitas muy seguido, cada vez que vienes es especial.`;
      case 'Cliente Nuevo':
        return `Como cliente nuevo, queremos que te sientas como en casa.`;
      default:
        return `Eres un cliente muy importante para nosotros.`;
    }
  }

  // Mensaje según nivel de riesgo
  static _getMensajePorRiesgo(nivelRiesgo, diasSinComprar) {
    switch (nivelRiesgo) {
      case 1:
        return `Han pasado ${diasSinComprar} días desde tu última visita. ¡Te hemos extrañado un poco! 😊`;
      case 2:
        return `Ya han pasado ${diasSinComprar} días sin verte. ¡Realmente te extrañamos! 💔`;
      case 3:
        return `¡${diasSinComprar} días sin verte! Nos preocupa no saber de ti. 😢`;
      default:
        return `Han pasado algunos días desde tu última visita.`;
    }
  }

  // Oferta personalizada
  static _getOfertaPersonalizada(nivelRiesgo, valorCliente, promedioCompra) {
    let descuento, mensajeOferta;

    switch (nivelRiesgo) {
      case 1:
        descuento = 15;
        mensajeOferta = `Por eso queremos ofrecerte un ${descuento}% de descuento en tu próxima compra.`;
        break;
      case 2:
        descuento = 25;
        mensajeOferta = `Para que vuelvas, te damos un ${descuento}% de descuento especial.`;
        break;
      case 3:
        descuento = 40;
        mensajeOferta = `¡${descuento}% de descuento exclusivo solo para ti! Es nuestra mejor oferta.`;
        break;
      default:
        descuento = 10;
        mensajeOferta = `Te ofrecemos un ${descuento}% de descuento en tu próxima compra.`;
    }

    // Personalizar según valor del cliente
    if (valorCliente === 'Alto Valor') {
      mensajeOferta += ` Además, como cliente de alto valor, tendrás atención VIP. 👑`;
    } else if (valorCliente === 'Medio Valor') {
      mensajeOferta += ` También tendrás acceso a productos exclusivos. ⭐`;
    }

    return mensajeOferta;
  }

  // Mensaje sobre producto favorito
  static _getMensajeProducto(productoFavorito) {
    if (productoFavorito && productoFavorito !== 'Sin datos') {
      return `Sabemos que te encanta ${productoFavorito}. ¡Tenemos novedades que te van a fascinar! 🎯`;
    } else {
      return `Tenemos nuevos productos que creemos que te van a encantar. 🛍️`;
    }
  }

  // Call to action personalizado
  static _getCallToAction(nivelRiesgo, tipoCliente) {
    const urgencia = nivelRiesgo === 3 ? '¡APROVECHA HOY MISMO!' : '¡No te lo pierdas!';
    
    switch (tipoCliente) {
      case 'Cliente Frecuente':
        return `${urgencia} Esta oferta es exclusiva para clientes como tú.`;
      case 'Cliente Regular':
        return `${urgencia} Es el momento perfecto para visitarnos.`;
      case 'Cliente Ocasional':
        return `${urgencia} Es una oportunidad única que no puedes dejar pasar.`;
      default:
        return `${urgencia} Ven a visitarnos pronto.`;
    }
  }

  // Generar múltiples opciones de mensaje
  static generarOpcionesMensaje(cliente, cantidad = 3) {
    const opciones = [];
    
    for (let i = 0; i < cantidad; i++) {
      // Variar ligeramente el mensaje para cada opción
      const clienteVariado = {
        ...cliente,
        // Pequeñas variaciones para generar diferentes mensajes
        dias_sin_comprar: cliente.dias_sin_comprar + (i * 0.1)
      };
      
      opciones.push({
        id: i + 1,
        titulo: `Opción ${i + 1}`,
        mensaje: this.generarMensajePersonalizado(clienteVariado),
        descuento: this._getDescuentoPorRiesgo(cliente.nivel_riesgo),
        urgencia: this._getNivelUrgencia(cliente.nivel_riesgo)
      });
    }
    
    return opciones;
  }

  // Obtener descuento por nivel de riesgo
  static _getDescuentoPorRiesgo(nivelRiesgo) {
    switch (nivelRiesgo) {
      case 1: return 15;
      case 2: return 25;
      case 3: return 40;
      default: return 10;
    }
  }

  // Obtener nivel de urgencia
  static _getNivelUrgencia(nivelRiesgo) {
    switch (nivelRiesgo) {
      case 1: return 'Baja';
      case 2: return 'Media';
      case 3: return 'Alta';
      default: return 'Normal';
    }
  }
}

module.exports = MensajesPersonalizados; 