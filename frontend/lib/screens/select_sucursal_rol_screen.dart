import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'admin_dashboard_screen.dart';
import 'seller_dashboard_screen.dart';

class SelectSucursalRolScreen extends StatefulWidget {
  const SelectSucursalRolScreen({super.key});

  @override
  State<SelectSucursalRolScreen> createState() => _SelectSucursalRolScreenState();
}

class _SelectSucursalRolScreenState extends State<SelectSucursalRolScreen> {
  bool _isLoading = true;
  List<dynamic> _sucursales = [];
  List<dynamic> _roles = [];
  int? _selectedSucursalId;
  int? _selectedRolId;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Siempre cargar las sucursales y roles al iniciar la pantalla
    _cargarSucursalesRoles();
  }

  Future<void> _cargarSucursalesRoles() async {
    if (!mounted) return;
    
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.getSucursalesRoles(authProvider.token);
      
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _sucursales = response['data'];
          _error = null;
        });
      } else {
        setState(() => _error = response['error'] ?? 'Error cargando datos');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error de conexión');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarSucursalRol() async {
    if (_selectedSucursalId == null || _selectedRolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una sucursal y un rol')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.seleccionarSucursalRol(
        authProvider.token,
        _selectedSucursalId!,
        _selectedRolId!,
      );

      if (response['success'] == true) {
        final data = response['data'];
        authProvider.setToken(data['token']);
        authProvider.setSucursalActiva(
          data['sucursal']['id'],
          data['sucursal']['nombre'],
        );
        authProvider.setRolActivo(
          data['rol']['id'],
          data['rol']['nombre'],
          data['rol']['tipo'] ?? 'Vendedor',
        );

        if (!mounted) return;

        // Navegar al dashboard correspondiente
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => authProvider.tipoRolActivo == 'Administrador'
              ? const AdminDashboardScreen()
              : const SellerDashboardScreen(),
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Error de selección')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Sucursal y Rol'),
        backgroundColor: const Color(0xFF223A5E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      ElevatedButton(
                        onPressed: _cargarSucursalesRoles,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Seleccione una sucursal y rol para continuar:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _sucursales.length,
                          itemBuilder: (context, index) {
                            final sucursal = _sucursales[index];
                            final isSelected = sucursal['id'] == _selectedSucursalId;
                            
                            return Card(
                              elevation: isSelected ? 8 : 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ExpansionTile(
                                title: Text(
                                  sucursal['nombre'],
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                children: [
                                  ...sucursal['roles'].map<Widget>((rol) {
                                    final isRolSelected = rol['id'] == _selectedRolId;
                                    return ListTile(
                                      title: Text(rol['nombre']),
                                      tileColor: isRolSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : null,
                                      onTap: () => setState(() {
                                        _selectedSucursalId = sucursal['id'];
                                        _selectedRolId = rol['id'];
                                      }),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _isLoading ? null : _seleccionarSucursalRol,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF223A5E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Continuar'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
