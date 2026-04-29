import 'package:flutter/material.dart';
import '../services/vehiculo_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class EditarVehiculoScreen extends StatefulWidget {
  final Map<String, dynamic> vehiculo;
  
  const EditarVehiculoScreen({super.key, required this.vehiculo});
  
  @override
  State<EditarVehiculoScreen> createState() => _EditarVehiculoScreenState();
}

class _EditarVehiculoScreenState extends State<EditarVehiculoScreen> {
  final vehiculoService = VehiculoService();
  
  late TextEditingController placaController;
  late TextEditingController marcaController;
  late TextEditingController modeloController;
  late TextEditingController anioController;
  late TextEditingController colorController;
  
  bool cargando = false;
  String? error;
  
  @override
  void initState() {
    super.initState();
    placaController = TextEditingController(text: widget.vehiculo['placa']);
    marcaController = TextEditingController(text: widget.vehiculo['marca'] ?? '');
    modeloController = TextEditingController(text: widget.vehiculo['modelo'] ?? '');
    anioController = TextEditingController(text: widget.vehiculo['anio']?.toString() ?? '');
    colorController = TextEditingController(text: widget.vehiculo['color'] ?? '');
  }
  
  void guardarCambios() async {
    setState(() => cargando = true);
    
    final resultado = await vehiculoService.editarVehiculo(
      widget.vehiculo['id_vehiculo'],
      placa: placaController.text.trim(), // Agregamos "placa:"
      marca: marcaController.text.trim(), // Agregamos "marca:"
      modelo: modeloController.text.trim(), // Agregamos "modelo:"
      anio: int.tryParse(anioController.text.trim()) ?? 0, // Agregamos "anio:"
      color: colorController.text.trim(), // Agregamos "color:"
    );
    
    if (!mounted) return;
    
    setState(() => cargando = false);
    
    if (resultado['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehículo actualizado correctamente'),
          backgroundColor: AppTheme.success,
        )
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['error'] ?? 'Error al actualizar el vehículo'),
          backgroundColor: AppTheme.danger,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Editar Vehículo'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            ModernCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_car, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'Datos del Vehículo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 32),
                    
                    _buildTextField(
                      label: 'Placa',
                      controller: placaController,
                      icon: Icons.pin,
                      hint: 'Ej: 1234ABC',
                    ),
                    _buildTextField(
                      label: 'Marca',
                      controller: marcaController,
                      icon: Icons.branding_watermark,
                      hint: 'Ej: Toyota',
                    ),
                    _buildTextField(
                      label: 'Modelo',
                      controller: modeloController,
                      icon: Icons.directions_car_filled,
                      hint: 'Ej: Corolla',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Año',
                            controller: anioController,
                            icon: Icons.calendar_today,
                            hint: 'Ej: 2020',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Color',
                            controller: colorController,
                            icon: Icons.palette,
                            hint: 'Ej: Blanco',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: PrimaryButton(
                text: 'Guardar Cambios',
                onPressed: guardarCambios,
                isLoading: cargando,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    placaController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    anioController.dispose();
    colorController.dispose();
    super.dispose();
  }
}