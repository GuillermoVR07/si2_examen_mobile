import 'package:flutter/material.dart';

import '../models/asignacion_response.dart';
import '../models/completar_servicio_form.dart';
import '../services/tecnico_asignaciones_service.dart';
import '../widgets/completar_servicio_dialog.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class AsignacionDetalleScreen extends StatefulWidget {
  final int idAsignacion;

  const AsignacionDetalleScreen({
    super.key,
    required this.idAsignacion,
  });

  @override
  State<AsignacionDetalleScreen> createState() => _AsignacionDetalleScreenState();
}

class _AsignacionDetalleScreenState extends State<AsignacionDetalleScreen> {
  final TecnicoAsignacionesService _asignacionesService = TecnicoAsignacionesService();

  AsignacionResponse? _asignacion;
  bool _iniciandoViaje = false;

  void _abrirDialogoCompletar() {
    showDialog(
      context: context,
      builder: (context) => CompletarServicioDialog(
        onConfirm: _completarServicio,
      ),
    );
  }

  Future<void> _completarServicio(CompletarServicioForm form) async {
    try {
      final resultado = await _asignacionesService.completarServicio(
        widget.idAsignacion,
        costoFinal: form.costoFinal,
        resumenTrabajo: form.resumenTrabajo,
      );

      if (!mounted) return;

      setState(() {
        _asignacion = resultado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio completado correctamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al completar servicio: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _iniciarViajeAhora() async {
    setState(() => _iniciandoViaje = true);

    try {
      final resultado = await _asignacionesService.iniciarViaje(widget.idAsignacion);

      if (!mounted) return;

      setState(() {
        _asignacion = resultado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viaje iniciado. Estado: ${resultado.estadoAsignacion.replaceAll('_', ' ')}'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _iniciandoViaje = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidente = _asignacion?.incidente;
    final estadoAsignacion = _asignacion?.estadoAsignacion ?? 'aceptada';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detalle de Asignación'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER INFORMATIVO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asignación ID',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '#${widget.idAsignacion}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  StatusBadge(
                    text: estadoAsignacion.replaceAll('_', ' '),
                    status: estadoAsignacion,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Detalles del Incidente'),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoField(
                          icon: Icons.build,
                          label: 'Categoría',
                          value: incidente?.categoria ?? 'Pendiente de cargar',
                        ),
                        const Divider(color: AppTheme.border, height: 24),
                        InfoField(
                          icon: Icons.priority_high,
                          label: 'Prioridad',
                          value: incidente?.prioridad ?? 'No disponible',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Descripción del problema',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Text(
                            incidente?.descripcionUsuario ?? 'Descripción no disponible',
                            style: const TextStyle(color: Color(0xFF312E81), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Gestión del Servicio'),
                  
                  // BOTONES DE ACCIÓN SEGÚN EL ESTADO
                  if (estadoAsignacion == 'aceptada')
                    PrimaryButton(
                      text: 'Iniciar Viaje',
                      onPressed: _iniciarViajeAhora,
                      isLoading: _iniciandoViaje,
                    ),

                  if (estadoAsignacion == 'en_camino')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _abrirDialogoCompletar,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Completar Servicio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success, // Botón verde
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  if (estadoAsignacion == 'completada')
                    ModernCard(
                      indicatorColor: AppTheme.success,
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: AppTheme.success, size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Servicio Completado',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'El cliente ya puede evaluar el servicio desde su historial.',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}