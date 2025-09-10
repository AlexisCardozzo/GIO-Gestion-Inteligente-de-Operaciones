import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ConfiguracionTicketScreen extends StatefulWidget {
  const ConfiguracionTicketScreen({Key? key}) : super(key: key);

  @override
  _ConfiguracionTicketScreenState createState() => _ConfiguracionTicketScreenState();
}

class _ConfiguracionTicketScreenState extends State<ConfiguracionTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Campos de configuración
  final TextEditingController _nombreNegocioController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _mensajePersonalizadoController = TextEditingController();
  final TextEditingController _piePaginaController = TextEditingController();
  
  bool _mostrarLogo = false;
  bool _mostrarFecha = true;
  bool _mostrarNumeroTicket = true;
  bool _mostrarVendedor = true;
  bool _mostrarCliente = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _mensajePersonalizadoController.dispose();
    _piePaginaController.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final configuracion = await ApiService.obtenerConfiguracionTicket();
      
      if (configuracion.isNotEmpty) {
        setState(() {
          _nombreNegocioController.text = configuracion['nombre_negocio'] ?? '';
          _direccionController.text = configuracion['direccion'] ?? '';
          _telefonoController.text = configuracion['telefono'] ?? '';
          _mensajePersonalizadoController.text = configuracion['mensaje_personalizado'] ?? '';
          _piePaginaController.text = configuracion['pie_pagina'] ?? '';
          
          _mostrarLogo = configuracion['mostrar_logo'] ?? false;
          _mostrarFecha = configuracion['mostrar_fecha'] ?? true;
          _mostrarNumeroTicket = configuracion['mostrar_numero_ticket'] ?? true;
          _mostrarVendedor = configuracion['mostrar_vendedor'] ?? true;
          _mostrarCliente = configuracion['mostrar_cliente'] ?? true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar la configuración: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final config = {
        'nombre_negocio': _nombreNegocioController.text,
        'direccion': _direccionController.text,
        'telefono': _telefonoController.text,
        'mensaje_personalizado': _mensajePersonalizadoController.text,
        'pie_pagina': _piePaginaController.text,
        'mostrar_logo': _mostrarLogo,
        'mostrar_fecha': _mostrarFecha,
        'mostrar_numero_ticket': _mostrarNumeroTicket,
        'mostrar_vendedor': _mostrarVendedor,
        'mostrar_cliente': _mostrarCliente,
      };

      final success = await ApiService.guardarConfiguracionTicket(config);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada correctamente')),
        );
      } else {
        setState(() {
          _errorMessage = 'Error al guardar la configuración';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar la configuración: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Ticket'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        color: Colors.red.shade100,
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    const Text(
                      'Información del Negocio',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreNegocioController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Negocio *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre del negocio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Personalización del Ticket',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mensajePersonalizadoController,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje Personalizado',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: ¡Gracias por su compra!',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _piePaginaController,
                      decoration: const InputDecoration(
                        labelText: 'Pie de Página',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Vuelva pronto',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Elementos a Mostrar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Mostrar Logo'),
                      value: _mostrarLogo,
                      onChanged: (value) {
                        setState(() {
                          _mostrarLogo = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mostrar Fecha'),
                      value: _mostrarFecha,
                      onChanged: (value) {
                        setState(() {
                          _mostrarFecha = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mostrar Número de Ticket'),
                      value: _mostrarNumeroTicket,
                      onChanged: (value) {
                        setState(() {
                          _mostrarNumeroTicket = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mostrar Vendedor'),
                      value: _mostrarVendedor,
                      onChanged: (value) {
                        setState(() {
                          _mostrarVendedor = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mostrar Cliente'),
                      value: _mostrarCliente,
                      onChanged: (value) {
                        setState(() {
                          _mostrarCliente = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _guardarConfiguracion,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Guardar Configuración',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}