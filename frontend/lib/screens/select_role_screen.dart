import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

import 'admin_dashboard_screen.dart';
import 'seller_dashboard_screen.dart';

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  int? _selectedSucursalId;
  String? _selectedRoleName;
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _sucursales = [];
  List<dynamic> _roles = [];

  @override
  void initState() {
    super.initState();
    _fetchSucursales();
  }

  Future<void> _fetchSucursales() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final response = await ApiService.listarSucursales(token);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success'] == true) {
          _sucursales = response['data'];
        }
      });
    }
  }

  Future<void> _fetchRoles(int sucursalId) async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final response = await ApiService.listarRoles(token, sucursalId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success'] == true) {
          _roles = response['data'];
        } else {
          _roles = [];
        }
      });
    }
  }

  Future<void> _autenticarRol() async {
    if (_selectedSucursalId == null || _selectedRoleName == null || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione sucursal, rol e ingrese la contraseña.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final response = await ApiService.autenticarRol(
      token,
      _selectedRoleName!,
      _passwordController.text,
      _selectedSucursalId!,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        // Guardar el rol y sucursal activos en el estado global
        final rol = response['data'];
        final sucursal = _sucursales.firstWhere((s) => s['id'] == _selectedSucursalId);
        authProvider.setSucursalActiva(sucursal['id'], sucursal['nombre']);
        authProvider.setRolActivo(rol['id'], rol['nombre'], rol['tipo']);
        if (rol['tipo'] == 'Administrador') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SellerDashboardScreen()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Error de autenticación')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Sucursal y Rol'),
        backgroundColor: const Color(0xFF223A5E),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '¡Bienvenido a GIO!\nSelecciona tu sucursal y rol para continuar.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    value: _selectedSucursalId,
                    items: _sucursales.map<DropdownMenuItem<int>>((sucursal) {
                      return DropdownMenuItem<int>(
                        value: sucursal['id'],
                        child: Text(sucursal['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSucursalId = value;
                        _selectedRoleName = null;
                        _roles = [];
                      });
                      if (value != null) {
                        _fetchRoles(value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Sucursal',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _selectedRoleName,
                    items: _roles.map<DropdownMenuItem<String>>((rol) {
                      return DropdownMenuItem<String>(
                        value: rol['nombre'],
                        child: Text(rol['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRoleName = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña del rol',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _autenticarRol,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF223A5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Acceder'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}