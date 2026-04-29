import 'package:flutter/material.dart';
import '../services/vehiculo_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';
import 'registrar_vehiculo_screen.dart';
import 'editar_vehiculo_screen.dart';

class MisVehiculosScreen extends StatefulWidget {
  const MisVehiculosScreen({super.key});

  @override
  State<MisVehiculosScreen> createState() => _MisVehiculosScreenState();
}

class _MisVehiculosScreenState extends State<MisVehiculosScreen> {
  final vehiculoService = VehiculoService();
  
  List<dynamic> vehiculos = [];
  bool cargando = true;
  String? error;
  
  @override
  void initState() {
    super.initState();
    cargarVehiculos();
  }
  
  void cargarVehiculos() async {
    setState(() => cargando = true);
    
    final resultado = await vehiculoService.listarMisVehiculos();
    if (!mounted) return;
    
    if (resultado['success']) {
      setState(() {
        vehiculos = resultado['vehiculos'] ?? [];
        error = null;
      });
    } else {
      setState(() => error = resultado['error']);
      
      if (resultado['code'] == 'AUTH_EXPIRED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Debes iniciar sesión nuevamente.'),
            backgroundColor: AppTheme.warning,
            duration: Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        });
      }
    }
    
    setState(() => cargando = false);
  }
  
  void irRegistrar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  RegistrarVehiculoScreen()),
    );
    
    if (resultado != null) {
      cargarVehiculos(); 
    }
  }
  
  void irEditar(Map<String, dynamic> vehiculo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarVehiculoScreen(vehiculo: vehiculo),
      ),
    );
    
    if (resultado != null) {
      cargarVehiculos();
    }
  }
  
  void eliminarVehiculo(int idVehiculo, String placa) async {
    final confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Vehículo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas dar de baja el vehículo $placa? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmar == true) {
      setState(() => cargando = true);
      final resultado = await vehiculoService.eliminarVehiculo(idVehiculo);
      if (!mounted) return;
      
      if (resultado['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Vehículo eliminado'), backgroundColor: AppTheme.success),
        );
        cargarVehiculos();
      } else {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${resultado['error']}'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: cargarVehiculos,
          )
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState()
              : vehiculos.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 80, left: 8, right: 8),
                      itemCount: vehiculos.length,
                      itemBuilder: (context, index) {
                        final vehiculo = vehiculos[index];
                        return ModernCard(
                          onTap: () => irEditar(vehiculo),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.directions_car, color: AppTheme.primary, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehiculo['placa'], 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${vehiculo['marca'] ?? ''} ${vehiculo['modelo'] ?? ''} ${vehiculo['anio'] != null ? '(${vehiculo['anio']})' : ''}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton(
                                icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    onTap: () => Future.delayed(const Duration(milliseconds: 10), () => irEditar(vehiculo)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit, size: 20, color: AppTheme.textSecondary),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    onTap: () => Future.delayed(const Duration(milliseconds: 10), () => eliminarVehiculo(vehiculo['id_vehiculo'], vehiculo['placa'])),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: AppTheme.danger)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: irRegistrar,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Vehículo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.directions_car_filled, size: 64, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin Vehículos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'No tienes vehículos registrados en tu cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Registrar Primer Vehículo',
              onPressed: irRegistrar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text(error!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: cargarVehiculos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}