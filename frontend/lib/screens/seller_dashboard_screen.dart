import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'select_branch_screen.dart';
import 'ventas_screen.dart';
import 'stock_screen.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.tipoRolActivo != 'Vendedor') {
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SelectBranchScreen()),
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 24, 
            letterSpacing: 1.2,
            color: Colors.white
          )),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            tooltip: 'Cerrar rol / Cambiar sucursal o rol',
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
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text('Bienvenido, Vendedor', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 26, 
                    color: Color(0xFF1A237E),
                    letterSpacing: 1.2
                  )),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    children: [
                      _buildModuleCard('Ventas', Icons.point_of_sale, Colors.deepPurple, Colors.white, context: context),
                      _buildModuleCard('Stock', Icons.store, Colors.green, Colors.white, context: context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(String title, IconData icon, Color iconColor, Color bgColor, {required BuildContext context}) {
    return Card(
      elevation: 15, // Increased elevation for more depth
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Slightly less rounded corners
      color: bgColor.withAlpha((255 * 0.95).round()), // Slightly more opaque background
      shadowColor: Colors.black.withAlpha((255 * 0.3).round()), // More prominent shadow
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (title == 'Ventas') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VentasScreen()),
            );
          } else if (title == 'Stock') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StockScreen()),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15), // Adjusted padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16), // Increased padding for icon container
                decoration: BoxDecoration(
                  color: iconColor.withAlpha((255 * 0.15).round()), // Slightly more vibrant icon background
                  borderRadius: BorderRadius.circular(25), // More rounded icon container
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withAlpha((255 * 0.2).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 50, color: iconColor), // Larger icon
              ),
              const SizedBox(height: 25), // Increased spacing
              Text(
                title,
                style: TextStyle(
                  fontSize: 22, // Larger font size
                  fontWeight: FontWeight.bold, 
                  color: Colors.indigo.shade900, // Darker text color
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black.withAlpha((255 * 0.2).round()),
                      offset: const Offset(1, 2),
                    )
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}