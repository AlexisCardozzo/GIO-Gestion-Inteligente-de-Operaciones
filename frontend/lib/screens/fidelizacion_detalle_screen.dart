import 'package:flutter/material.dart';
import '../services/fidelizacion_service.dart';
import '../utils/format.dart';
import '../utils/colors.dart';

class FidelizacionDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> campania;
  const FidelizacionDetalleScreen({Key? key, required this.campania}) : super(key: key);

  @override
  State<FidelizacionDetalleScreen> createState() => _FidelizacionDetalleScreenState();
}

class _FidelizacionDetalleScreenState extends State<FidelizacionDetalleScreen> {
  late Future<List<dynamic>> _requisitosFuture;
  late Future<List<dynamic>> _beneficiosFuture;
  late Future<List<dynamic>> _participantesFuture;

  @override
  void initState() {
    super.initState();
    _requisitosFuture = FidelizacionService.obtenerRequisitos(widget.campania['id']);
    _beneficiosFuture = FidelizacionService.obtenerBeneficios(widget.campania['id']);
    _participantesFuture = FidelizacionService.obtenerParticipantesCampania(widget.campania['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GioColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: GioColors.backgroundLight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildCampaniaInfo(),
                      const SizedBox(height: 20),
                      _buildParticipantesSection(),
                      const SizedBox(height: 20),
                      _buildRequisitosSection(),
                      const SizedBox(height: 20),
                      _buildBeneficiosSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: GioColors.textWhite),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalle de Campaña',
                  style: TextStyle(
                    color: GioColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.campania['nombre'] ?? 'Sin nombre',
                  style: const TextStyle(
                    color: GioColors.textWhite,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_task, color: GioColors.textWhite),
            tooltip: 'Agregar requisito',
            onPressed: () => _mostrarDialogoAgregarRequisito(context),
          ),
          IconButton(
                icon: const Icon(Icons.card_giftcard, color: GioColors.textWhite),
            tooltip: 'Agregar beneficio',
            onPressed: () => _mostrarDialogoAgregarBeneficio(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaniaInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GioColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GioColors.primaryLightest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.campaign,
                  color: GioColors.primaryMedium,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información de la Campaña',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GioColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
          children: [
              _buildInfoItem(
                'Estado',
                widget.campania['activa'] == true ? 'Activa' : 'Inactiva',
                Icons.circle,
                color: widget.campania['activa'] == true ? GioColors.success : GioColors.error,
              ),
              _buildInfoItem(
                'Inicio',
                widget.campania['fecha_inicio'] ?? 'No definida',
                Icons.calendar_today,
              ),
              _buildInfoItem(
                'Fin',
                widget.campania['fecha_fin'] ?? 'No definida',
                Icons.calendar_today,
              ),
            ],
          ),
          if (widget.campania['descripcion'] != null && widget.campania['descripcion'].isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Descripción:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GioColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.campania['descripcion'],
              style: const TextStyle(
                fontSize: 14,
                color: GioColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? GioColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GioColors.textLight,
                  ),
                ),
            Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: GioColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequisitosSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GioColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GioColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.checklist,
                  color: GioColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Requisitos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GioColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
                    FutureBuilder<List<dynamic>>(
                      future: _requisitosFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GioColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.checklist_outlined,
                        color: GioColors.textLight,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay requisitos definidos',
                        style: TextStyle(
                          color: GioColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega requisitos para que los clientes puedan obtener beneficios',
                        style: TextStyle(
                          color: GioColors.textLight,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
                        }
                        final requisitos = snapshot.data!;
                        return Column(
                          children: requisitos.map<Widget>((req) {
                            String desc = req['tipo'] == 'compras'
                      ? 'Realizar ${req['valor']} compras'
                      : 'Gastar ${formatMiles(req['valor'])} Gs';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GioColors.primaryLightest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GioColors.primaryLighter),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          req['tipo'] == 'compras' ? Icons.shopping_cart : Icons.attach_money,
                          color: GioColors.primaryMedium,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 16,
                              color: GioColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editarRequisito(req),
                          icon: const Icon(Icons.edit, size: 16),
                          color: GioColors.primaryMedium,
                        ),
                        IconButton(
                          onPressed: () => _eliminarRequisito(req),
                          icon: const Icon(Icons.delete, size: 16),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildBeneficiosSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GioColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GioColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: GioColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Beneficios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GioColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
                    FutureBuilder<List<dynamic>>(
                      future: _beneficiosFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GioColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        color: GioColors.textLight,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay beneficios definidos',
                        style: TextStyle(
                          color: GioColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega beneficios para recompensar a tus clientes fieles',
                        style: TextStyle(
                          color: GioColors.textLight,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
                        }
                        final beneficios = snapshot.data!;
                        return Column(
                          children: beneficios.map<Widget>((ben) {
                            String desc = ben['tipo'] == 'descuento'
                      ? 'Descuento del ${ben['valor']}%'
                      : 'Producto: ${ben['valor']}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GioColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GioColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ben['tipo'] == 'descuento' ? Icons.percent : Icons.inventory,
                          color: GioColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 16,
                              color: GioColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editarBeneficio(ben),
                          icon: const Icon(Icons.edit, size: 16),
                          color: GioColors.success,
                        ),
                        IconButton(
                          onPressed: () => _eliminarBeneficio(ben),
                          icon: const Icon(Icons.delete, size: 16),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildParticipantesSection() {
    return Container(
      decoration: BoxDecoration(
        color: GioColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: GioColors.primaryMedium,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Participantes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _participantesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar participantes',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final participantes = snapshot.data ?? [];
              
              if (participantes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, color: Colors.grey, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'No hay participantes aún',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Los clientes aparecerán aquí cuando realicen compras',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: participantes.length,
                itemBuilder: (context, index) {
                  final participante = participantes[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GioColors.primaryLightest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: GioColors.primaryMedium,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                participante['nombre'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'CI/RUC: ${participante['ci_ruc']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Celular: ${participante['celular']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: GioColors.primaryLightest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${int.tryParse(participante['puntos_acumulados'].toString()) ?? 0} pts',
                                style: const TextStyle(
                                  color: GioColors.primaryMedium,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${int.tryParse(participante['total_ventas'].toString()) ?? 0} ventas',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Gs ${formatMiles(double.tryParse(participante['total_gastado'].toString()) ?? 0)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _mostrarBeneficiosDisponibles(participante),
                          icon: const Icon(Icons.card_giftcard, size: 16),
                          label: const Text('Ver Beneficios'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GioColors.primaryMedium,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _mostrarBeneficiosDisponibles(Map<String, dynamic> participante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Beneficios para ${participante['nombre']}'),
        content: FutureBuilder<Map<String, dynamic>?>(
          future: FidelizacionService.obtenerBeneficiosDisponibles(participante['id']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            
            final data = snapshot.data;
            if (data == null) {
              return const Text('No se pudieron cargar los beneficios');
            }
            
            final beneficiosDisponibles = data['beneficios_disponibles'] as List<dynamic>;
            
            if (beneficiosDisponibles.isEmpty) {
              return const Text('No hay beneficios disponibles para este cliente');
            }
            
            return SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: beneficiosDisponibles.length,
                itemBuilder: (context, index) {
                  final campania = beneficiosDisponibles[index];
                  return ExpansionTile(
                    title: Text(
                      campania['campania_nombre'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: campania['beneficios'].map<Widget>((beneficio) {
                      return ListTile(
                        leading: Icon(
                          beneficio['cumple_requisitos'] 
                            ? Icons.check_circle 
                            : Icons.circle_outlined,
                          color: beneficio['cumple_requisitos'] 
                            ? Colors.green 
                            : Colors.grey,
                        ),
                                                 title: Text('${beneficio['beneficio_tipo']} - ${beneficio['beneficio_valor']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tipo: ${beneficio['beneficio_tipo']}'),
                            Text('Valor: ${beneficio['beneficio_valor']}'),
                            Text('Requisito: ${beneficio['requisito_tipo']} - ${beneficio['requisito_valor']}'),
                          ],
                        ),
                        trailing: beneficio['cumple_requisitos']
                          ? ElevatedButton(
                              onPressed: () => _canjearBeneficio(participante['id'], beneficio['beneficio_id']),
                              child: const Text('Canjear'),
                            )
                          : const Text('No disponible'),
                      );
                    }).toList(),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _canjearBeneficio(int clienteId, int beneficioId) async {
    try {
      final success = await FidelizacionService.canjearBeneficio(clienteId, beneficioId);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Beneficio canjeado exitosamente!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al canjear el beneficio')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _mostrarDialogoAgregarRequisito(BuildContext context) {
    String tipo = 'compras';
    final valorController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Requisito'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) => Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tipo,
                    items: const [
                      DropdownMenuItem(value: 'compras', child: Text('Cantidad de compras')),
                      DropdownMenuItem(value: 'monto', child: Text('Monto gastado')),
                    ],
                    onChanged: (v) => setStateDialog(() => tipo = v ?? 'compras'),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de requisito',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                  TextFormField(
                    controller: valorController,
                    keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: tipo == 'compras' ? 'Número de compras' : 'Monto en Gs',
                    border: const OutlineInputBorder(),
                  ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'El valor es obligatorio';
                      final val = int.tryParse(v.trim());
                      if (val == null || val <= 0) return 'Debe ser un número mayor a cero';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
              
                final ok = await FidelizacionService.agregarRequisito(
                  campaniaId: widget.campania['id'],
                  tipo: tipo,
                  valor: int.parse(valorController.text.trim()),
                );
              
                if (ok) {
                  Navigator.pop(context);
                  setState(() {
                    _requisitosFuture = FidelizacionService.obtenerRequisitos(widget.campania['id']);
                  });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Requisito agregado!')),
                );
                } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al agregar requisito.')),
                );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
      ),
    );
  }

  void _mostrarDialogoAgregarBeneficio(BuildContext context) {
    String tipo = 'descuento';
    final valorController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Beneficio'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) => Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tipo,
                    items: const [
                      DropdownMenuItem(value: 'descuento', child: Text('Descuento (%)')),
                      DropdownMenuItem(value: 'producto', child: Text('Producto de regalo')),
                    ],
                    onChanged: (v) => setStateDialog(() => tipo = v ?? 'descuento'),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de beneficio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                  TextFormField(
                    controller: valorController,
                    keyboardType: tipo == 'descuento' ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: tipo == 'descuento' ? 'Porcentaje de descuento' : 'Producto de regalo',
                    border: const OutlineInputBorder(),
                  ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'El valor es obligatorio';
                      if (tipo == 'descuento') {
                        final val = int.tryParse(v.trim());
                        if (val == null || val <= 0 || val > 100) return 'Debe ser un porcentaje entre 1 y 100';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
              
                final ok = await FidelizacionService.agregarBeneficio(
                  campaniaId: widget.campania['id'],
                  tipo: tipo,
                  valor: valorController.text.trim(),
                );
              
                if (ok) {
                  Navigator.pop(context);
                  setState(() {
                    _beneficiosFuture = FidelizacionService.obtenerBeneficios(widget.campania['id']);
                  });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Beneficio agregado!')),
                );
                } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al agregar beneficio.')),
                );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
      ),
    );
  }

  void _editarRequisito(Map<String, dynamic> requisito) {
    String tipo = requisito['tipo'];
    final valorController = TextEditingController(text: requisito['valor'].toString());
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Requisito'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipo,
                  items: const [
                    DropdownMenuItem(value: 'compras', child: Text('Número de compras')),
                    DropdownMenuItem(value: 'monto', child: Text('Monto mínimo')),
                  ],
                  onChanged: (v) => setStateDialog(() => tipo = v ?? 'compras'),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de requisito',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valorController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: tipo == 'compras' ? 'Número de compras' : 'Monto mínimo',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El valor es obligatorio';
                    final val = int.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Debe ser un número mayor a 0';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final ok = await FidelizacionService.editarRequisito(
                id: requisito['id'],
                tipo: tipo,
                valor: int.parse(valorController.text.trim()),
              );
              
              if (ok) {
                Navigator.pop(context);
                setState(() {
                  _requisitosFuture = FidelizacionService.obtenerRequisitos(widget.campania['id']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Requisito actualizado!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al actualizar requisito.')),
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _eliminarRequisito(Map<String, dynamic> requisito) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Requisito'),
        content: const Text('¿Estás seguro de que quieres eliminar este requisito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final eliminado = await FidelizacionService.eliminarRequisito(requisito['id']);
              if (eliminado) {
                setState(() {
                  _requisitosFuture = FidelizacionService.obtenerRequisitos(widget.campania['id']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Requisito eliminado correctamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar requisito')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editarBeneficio(Map<String, dynamic> beneficio) {
    String tipo = beneficio['tipo'];
    final valorController = TextEditingController(text: beneficio['valor']);
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Beneficio'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipo,
                  items: const [
                    DropdownMenuItem(value: 'descuento', child: Text('Descuento (%)')),
                    DropdownMenuItem(value: 'producto', child: Text('Producto de regalo')),
                  ],
                  onChanged: (v) => setStateDialog(() => tipo = v ?? 'descuento'),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de beneficio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valorController,
                  keyboardType: tipo == 'descuento' ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: tipo == 'descuento' ? 'Porcentaje de descuento' : 'Producto de regalo',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El valor es obligatorio';
                    if (tipo == 'descuento') {
                      final val = int.tryParse(v.trim());
                      if (val == null || val <= 0 || val > 100) return 'Debe ser un porcentaje entre 1 y 100';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final ok = await FidelizacionService.editarBeneficio(
                id: beneficio['id'],
                tipo: tipo,
                valor: valorController.text.trim(),
              );
              
              if (ok) {
                Navigator.pop(context);
                setState(() {
                  _beneficiosFuture = FidelizacionService.obtenerBeneficios(widget.campania['id']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Beneficio actualizado!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al actualizar beneficio.')),
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _eliminarBeneficio(Map<String, dynamic> beneficio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Beneficio'),
        content: const Text('¿Estás seguro de que quieres eliminar este beneficio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final eliminado = await FidelizacionService.eliminarBeneficio(beneficio['id']);
              if (eliminado) {
                setState(() {
                  _beneficiosFuture = FidelizacionService.obtenerBeneficios(widget.campania['id']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Beneficio eliminado correctamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar beneficio')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 