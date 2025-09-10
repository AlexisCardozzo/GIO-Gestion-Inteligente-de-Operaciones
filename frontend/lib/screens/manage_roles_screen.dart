import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'admin_dashboard_screen.dart';
import 'seller_dashboard_screen.dart';

class ManageRolesScreen extends StatefulWidget {
  final dynamic sucursal;
  const ManageRolesScreen({super.key, required this.sucursal});

  @override
  State<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends State<ManageRolesScreen> {
  List<dynamic> _roles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final response = await ApiService.listarRoles(token, widget.sucursal['id']);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success'] == true) {
          _roles = response['data'];
        }
      });
    }
  }

  void _showCreateRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateRoleDialog(
        sucursalId: widget.sucursal['id'],
        onRoleCreated: _fetchRoles,
      ),
    );
  }

  void _showAuthRoleDialog(dynamic rol) {
    showDialog(
      context: context,
      builder: (context) => _AuthRoleDialog(
        sucursal: widget.sucursal,
        rol: rol,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Roles de ${widget.sucursal['nombre']}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF223A5E), Color(0xFF4F8EDC)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Gestiona los roles de tu sucursal.\nPuedes crear roles de Administrador o Vendedor.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(0,2))],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _roles.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'No hay roles creados.',
                                  style: TextStyle(fontSize: 18, color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: _showCreateRoleDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Crear primer rol'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF223A5E),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: _roles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 18),
                              itemBuilder: (context, index) {
                                final rol = _roles[index];
                                return GestureDetector(
                                  onTap: () => _showAuthRoleDialog(rol),
                                  child: Card(
                                    elevation: 10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    color: Colors.white.withOpacity(0.95),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                                      child: Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: rol['tipo'] == 'Administrador' ? const Color(0xFF223A5E) : const Color(0xFF4F8EDC),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            child: Icon(
                                              rol['tipo'] == 'Administrador' ? Icons.security : Icons.person,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 18),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rol['nombre'],
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF223A5E)),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  rol['tipo'],
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: rol['tipo'] == 'Administrador' ? const Color(0xFF223A5E) : const Color(0xFF4F8EDC),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.login, color: Color(0xFF4F8EDC)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    if (_roles.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _showCreateRoleDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear nuevo rol'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF223A5E),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CreateRoleDialog extends StatefulWidget {
  final int sucursalId;
  final VoidCallback onRoleCreated;
  const _CreateRoleDialog({required this.sucursalId, required this.onRoleCreated});

  @override
  State<_CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<_CreateRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _tipo = 'Vendedor';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _crearRol() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final nombre = _nombreController.text.trim();
    final password = _passwordController.text;
    final tipo = _tipo;
    final response = await ApiService.crearRol(token, nombre, password, widget.sucursalId, tipo);
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        Navigator.of(context).pop();
        widget.onRoleCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Rol creado exitosamente!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Error al crear rol')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear nuevo rol'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _tipo,
              items: const [
                DropdownMenuItem(value: 'Administrador', child: Text('Administrador')),
                DropdownMenuItem(value: 'Vendedor', child: Text('Vendedor')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _tipo = value);
              },
              decoration: const InputDecoration(
                labelText: 'Tipo de rol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del rol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Ingrese el nombre del rol' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña del rol',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) => value == null || value.length < 4 ? 'Mínimo 4 caracteres' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _crearRol,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF223A5E),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Crear'),
        ),
      ],
    );
  }
}

class _AuthRoleDialog extends StatefulWidget {
  final dynamic sucursal;
  final dynamic rol;
  const _AuthRoleDialog({required this.sucursal, required this.rol});

  @override
  State<_AuthRoleDialog> createState() => _AuthRoleDialogState();
}

class _AuthRoleDialogState extends State<_AuthRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreUsuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _autenticarRol() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final nombre = widget.rol['nombre'];
    final password = _passwordController.text;
    final sucursalId = widget.sucursal['id'];
    final response = await ApiService.autenticarRol(token, nombre, password, sucursalId);
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        // Guardar el rol y sucursal activos en el estado global
        final rol = response['data'];
        authProvider.setSucursalActiva(widget.sucursal['id'], widget.sucursal['nombre']);
        authProvider.setRolActivo(rol['id'], rol['nombre'], rol['tipo']);
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        // Ahora el usuario puede acceder al panel correspondiente
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF223A5E), Color(0xFF4F8EDC)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: widget.rol['tipo'] == 'Administrador' ? const Color(0xFF223A5E) : const Color(0xFF4F8EDC),
                    child: Icon(
                      widget.rol['tipo'] == 'Administrador' ? Icons.security : Icons.person,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Acceder como ${widget.rol['nombre']}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese la contraseña' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _autenticarRol,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: widget.rol['tipo'] == 'Administrador' ? const Color(0xFF223A5E) : const Color(0xFF4F8EDC),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                            : const Text('Acceder'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 