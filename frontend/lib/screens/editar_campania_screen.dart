import 'package:flutter/material.dart';
import '../services/fidelizacion_service.dart';
import '../utils/colors.dart';

class EditarCampaniaScreen extends StatefulWidget {
  final Map<String, dynamic> campania;
  final VoidCallback? onCampaniaEditada;

  const EditarCampaniaScreen({
    Key? key,
    required this.campania,
    this.onCampaniaEditada,
  }) : super(key: key);

  @override
  State<EditarCampaniaScreen> createState() => _EditarCampaniaScreenState();
}

class _EditarCampaniaScreenState extends State<EditarCampaniaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _activa = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosCampania();
  }

  void _cargarDatosCampania() {
    _nombreController.text = widget.campania['nombre'] ?? '';
    _descripcionController.text = widget.campania['descripcion'] ?? '';
    _fechaInicio = DateTime.tryParse(widget.campania['fecha_inicio'] ?? '');
    _fechaFin = DateTime.tryParse(widget.campania['fecha_fin'] ?? '');
    _activa = widget.campania['activa'] ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio ?? DateTime.now() : _fechaFin ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fechaSeleccionada;
          // Si la fecha de fin es anterior a la nueva fecha de inicio, ajustarla
          if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
            _fechaFin = _fechaInicio!.add(const Duration(days: 1));
          }
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona las fechas')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultado = await FidelizacionService.editarCampania(
        id: widget.campania['id'],
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        fechaInicio: _fechaInicio!.toIso8601String().split('T')[0],
        fechaFin: _fechaFin!.toIso8601String().split('T')[0],
        activa: _activa,
      );

      if (resultado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaña actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCampaniaEditada?.call();
        Navigator.pop(context, resultado);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar campaña: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCampoNombre(),
                          const SizedBox(height: 20),
                          _buildCampoDescripcion(),
                          const SizedBox(height: 20),
                          _buildCampoFechas(),
                          const SizedBox(height: 20),
                          _buildCampoEstado(),
                          const SizedBox(height: 30),
                          _buildBotones(),
                        ],
                      ),
                    ),
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
          const Expanded(
            child: Text(
              'Editar Campaña',
              style: TextStyle(
                color: GioColors.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoNombre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nombre de la Campaña',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: GioColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nombreController,
          decoration: InputDecoration(
            hintText: 'Ej: Descuento de Verano',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es obligatorio';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCampoDescripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: GioColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descripcionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe los detalles de la campaña...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCampoFechas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período de la Campaña',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: GioColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFechaField(
                'Fecha de Inicio',
                _fechaInicio,
                () => _seleccionarFecha(context, true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFechaField(
                'Fecha de Fin',
                _fechaFin,
                () => _seleccionarFecha(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFechaField(String label, DateTime? fecha, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fecha != null
                  ? '${fecha.day}/${fecha.month}/${fecha.year}'
                  : 'Seleccionar fecha',
              style: TextStyle(
                fontSize: 16,
                color: fecha != null ? GioColors.textPrimary : Colors.grey.shade500,
                fontWeight: fecha != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoEstado() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const Icon(Icons.toggle_on, color: GioColors.primaryMedium),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Campaña Activa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: GioColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: _activa,
            onChanged: (value) => setState(() => _activa = value),
            activeColor: GioColors.primaryMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: GioColors.primaryMedium,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
} 