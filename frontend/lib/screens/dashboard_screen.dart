import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'select_role_screen.dart';
import 'select_branch_screen.dart';
import 'fondo_solidario_usuario_screen.dart';
import '../utils/owl_logo.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Obtener el tipo de rol activo
    final tipoRolActivo = authProvider.tipoRolActivo ?? 'Vendedor';
    // Definir los módulos según el tipo de rol
    final List<Map<String, dynamic>> modulos = tipoRolActivo == 'Administrador'
        ? [
            {'nombre': 'Gestión de Usuarios', 'icono': Icons.people, 'color': const Color(0xFF223A5E)},
            {'nombre': 'Gestión de Productos', 'icono': Icons.inventory, 'color': const Color(0xFF4F8EDC)},
            {'nombre': 'Ventas', 'icono': Icons.shopping_cart, 'color': const Color(0xFF223A5E)},
            {'nombre': 'Stock', 'icono': Icons.warehouse, 'color': const Color(0xFF4F8EDC)},
            {'nombre': 'Reportes', 'icono': Icons.analytics, 'color': const Color(0xFF223A5E)},
            {'nombre': 'Configuración', 'icono': Icons.settings, 'color': Colors.grey},
          ]
        : [
            {'nombre': 'Ventas', 'icono': Icons.shopping_cart, 'color': const Color(0xFF223A5E)},
            {'nombre': 'Stock', 'icono': Icons.warehouse, 'color': const Color(0xFF4F8EDC)},
            {'nombre': 'Reportes', 'icono': Icons.analytics, 'color': const Color(0xFF223A5E)},
            {'nombre': 'Fondo Solidario', 'icono': Icons.favorite, 'color': const Color(0xFF1E3A8A)},
          ];
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF223A5E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GIO - Plataforma de Gestión Comercial', style: TextStyle(fontSize: 18)),
            if (authProvider.nombreSucursalActivo != null && authProvider.nombreRolActivo != null)
              Text(
                '${authProvider.nombreSucursalActivo}  |  ${authProvider.nombreRolActivo}',
                style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar sucursal/rol',
            onPressed: () {
              authProvider.limpiarSucursalYRol();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SelectBranchScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con imagen principal y degradado azul profesional
          Opacity(
            opacity: 0.25,
            child: Image.asset(
              'assets/fondoprincipal.png',
              fit: BoxFit.cover,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF223A5E), // Azul profundo
                  Color(0xFF4F8EDC), // Azul claro
                ],
              ),
            ),
          ),
          Center(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                if (user == null) {
                  return const CircularProgressIndicator();
                }
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 16,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        color: Colors.white.withAlpha((255 * 0.97).round()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar circular con inicial
                              CircleAvatar(
                                radius: 38,
                                backgroundColor: const Color(0xFF223A5E),
                                child: Text(
                                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Bienvenida personalizada
                              Text(
                                '¡Bienvenido, ${user.fullName}!',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF223A5E),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user.email,
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rol: ${user.role}',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Miembro desde: ${user.createdAt.day.toString().padLeft(2, '0')}/${user.createdAt.month.toString().padLeft(2, '0')}/${user.createdAt.year}',
                                style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: () {
                                  authProvider.logout();
                                  Navigator.of(context).pushReplacementNamed('/login');
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text('Cerrar sesión'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF223A5E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Accesos rápidos a módulos
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.1,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final modulo in modulos)
                              _buildModuleCard(context, modulo['nombre'], modulo['icono'], modulo['color']),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (title == 'Fondo Solidario') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FondoSolidarioUsuarioScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡$title: Próximamente!'),
                backgroundColor: color,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}