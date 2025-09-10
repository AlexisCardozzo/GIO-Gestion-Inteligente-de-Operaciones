import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'select_role_screen.dart';
import 'admin_dashboard_screen.dart';
import 'seller_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Si no hay sucursal y rol activos, redirigir a la selección
        if (!authProvider.hasActiveSucursalAndRol) {
          return const SelectRoleScreen();
        }

        // Si ya tiene sucursal y rol, mostrar el dashboard correspondiente
        if (authProvider.tipoRolActivo == 'Administrador') {
          return const AdminDashboardScreen();
        } else {
          return const SellerDashboardScreen();
        }
      },
    );
  }
}
