import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final bool isAdmin = user?.rol == 'admin';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
            ),
            accountName: Text(
              user?.nombre ?? 'Usuario',
              style: const TextStyle(fontSize: 18),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user != null && user.nombre.isNotEmpty)
                    ? user.nombre[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Inicio'),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Red de Historias'),
                  subtitle: const Text('Experiencias y apoyo'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.feedSocial);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.forum),
                  title: const Text('Comunidad'),
                  subtitle: const Text('Consejos y experiencias'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.publicaciones);
                  },
                ),
                if (isAdmin) ...[                  
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Administración',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Panel Admin'),
                    onTap: () {
                      // TODO: Implementar navegación al panel admin
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt),
                    title: const Text('Personalización de Ticket'),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.configuracionTicket);
                    },
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    // TODO: Implementar navegación a configuración
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Cerrar Sesión'),
                  onTap: () async {
                    await authProvider.logout();
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}