import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_page.dart';
import 'screens/fondo_solidario_usuario_screen.dart';
import 'screens/publicaciones_screen.dart';
import 'screens/configuracion_ticket_screen.dart';
import 'screens/select_sucursal_rol_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/feed_social_screen.dart';
import 'screens/fondo_solidario_admin_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String home = '/home';
  static const String fondoSolidario = '/fondo-solidario';
  static const String publicaciones = '/publicaciones';
  static const String configuracionTicket = '/configuracion-ticket';
  static const String selectSucursalRol = '/select-sucursal-rol';
  static const String adminDashboard = '/admin-dashboard';
  static const String sellerDashboard = '/seller-dashboard';
  static const String feedSocial = '/feed-social';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      home: (context) => const HomePage(),
      fondoSolidario: (context) => Provider.of<AuthProvider>(context, listen: false).user?.rol == 'admin'
          ? const FondoSolidarioAdminScreen()
          : const FondoSolidarioUsuarioScreen(),
      feedSocial: (context) => const FeedSocialScreen(),
      publicaciones: (context) => const PublicacionesScreen(),
      configuracionTicket: (context) => const ConfiguracionTicketScreen(),
      selectSucursalRol: (context) => const SelectSucursalRolScreen(),
      adminDashboard: (context) => const AdminDashboardScreen(),
      sellerDashboard: (context) => const SellerDashboardScreen(),
    };
  }
}
