import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/ventas_screen.dart';
import 'screens/register_screen.dart';
import 'screens/select_branch_screen.dart';
import 'screens/select_sucursal_rol_screen.dart';
import 'screens/seller_dashboard_screen.dart';

void main() {
  runApp(const GioApp());
}

class GioApp extends StatelessWidget {
  const GioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'GIO - Gestión Comercial',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }
        
        // Si está autenticado pero no tiene sucursal y rol seleccionados
        if (authProvider.needsSelection) {
          return const SelectBranchScreen();
        }
        
        // Si tiene todo seleccionado, ir al dashboard correspondiente
        if (authProvider.tipoRolActivo == 'Administrador') {
          return const AdminDashboardScreen();
        } else {
          return const SellerDashboardScreen();
        }
      },
    );
  }
}
