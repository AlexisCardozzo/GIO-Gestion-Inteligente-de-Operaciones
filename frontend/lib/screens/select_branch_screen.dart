import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'create_branch_screen.dart';
import 'manage_roles_screen.dart';

class SelectBranchScreen extends StatefulWidget {
  const SelectBranchScreen({super.key});

  @override
  State<SelectBranchScreen> createState() => _SelectBranchScreenState();
}

class _SelectBranchScreenState extends State<SelectBranchScreen> {
  List<dynamic> _sucursales = [];
  bool _isLoading = false;

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

  void _goToCreateBranch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateBranchScreen()),
    );
    if (mounted) {
      _fetchSucursales();
    }
  }

  void _goToManageRoles(dynamic sucursal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ManageRolesScreen(sucursal: sucursal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Selecciona una Sucursal'),
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
                      '¡Bienvenido a GIO!\nSelecciona una sucursal para gestionar tus roles y operaciones.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(0,2))],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _sucursales.isEmpty
                          ? const Center(
                              child: Text(
                                'No tienes sucursales creadas. ¡Crea la primera!',
                                style: TextStyle(fontSize: 18, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _sucursales.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 18),
                              itemBuilder: (context, index) {
                                final sucursal = _sucursales[index];
                                return GestureDetector(
                                  onTap: () => _goToManageRoles(sucursal),
                                  child: Card(
                                    elevation: 10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    color: Colors.white.withOpacity(0.95),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                                      child: Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF223A5E),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            child: const Icon(Icons.store, size: 38, color: Colors.white),
                                          ),
                                          const SizedBox(width: 18),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sucursal['nombre'],
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF223A5E)),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  sucursal['direccion'],
                                                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios, color: Color(0xFF4F8EDC)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _goToCreateBranch,
                      icon: const Icon(Icons.add_business),
                      label: const Text('Nueva sucursal'),
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