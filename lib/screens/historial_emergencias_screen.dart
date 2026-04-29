import 'package:flutter/material.dart';
import '../services/incidente_service.dart';
import '../models/incidente.dart';
import '../models/candidato_asignacion.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';
import 'subir_evidencia_screen.dart';
import 'mensajes_screen.dart';
import 'tecnico_tracking_screen.dart';

class HistorialEmergenciasScreen extends StatefulWidget {
  const HistorialEmergenciasScreen({super.key});

  @override
  State<HistorialEmergenciasScreen> createState() =>
      _HistorialEmergenciasScreenState();
}

class _HistorialEmergenciasScreenState
    extends State<HistorialEmergenciasScreen> {
  final incidenteService = IncidenteService();

  List<IncidenteDetalle> incidencias = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarIncidencias();
  }

  void _cargarIncidencias() async {
    final resultado = await incidenteService.listarMisIncidencias();

    if (!mounted) return;

    if (resultado['success']) {
      setState(() {
        incidencias = resultado['incidencias'] ?? [];
        error = null;
      });
    } else {
      setState(() => error = resultado['error']);
      if (resultado['code'] == 'AUTH_EXPIRED') {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }

    setState(() => cargando = false);
  }

  // Mapeo de colores basado en Tailwind
  Color _getColorEstado(int idEstado) {
    switch (idEstado) {
      case 1: // Pendiente
        return AppTheme.warning;
      case 2: // En proceso/Aceptada
        return AppTheme.primary;
      case 3: // Completado
        return AppTheme.success;
      case 4: // Cancelado/Rechazado
        return AppTheme.danger;
      default:
        return AppTheme.textMuted;
    }
  }

  String _mapStatusName(int idEstado) {
    switch (idEstado) {
      case 1:
        return 'pendiente';
      case 2:
        return 'en_camino';
      case 3:
        return 'completada';
      case 4:
        return 'rechazada';
      default:
        return 'pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Emergencias'),
        centerTitle: false,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState()
              : incidencias.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() => cargando = true);
                        _cargarIncidencias();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 80),
                        itemCount: incidencias.length,
                        itemBuilder: (context, index) {
                          final inc = incidencias[index];
                          return ModernCard(
                            indicatorColor: _getColorEstado(inc.idEstado),
                            onTap: () => _showDetailDialog(context, inc),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatusBadge(
                                      text: inc.getEstadoNombre(),
                                      status: _mapStatusName(inc.idEstado),
                                    ),
                                    Text(
                                      inc.getFechaFormato(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.background,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.directions_car, color: AppTheme.textSecondary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '#${inc.idIncidente} - ${inc.getMarca()} ${inc.getPlaca()}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${inc.getCategoriaNombre()} • Prioridad: ${inc.getNivelPrioridad()}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppTheme.border),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.pushNamed(
            context,
            '/reportar-emergencia',
          );
          if (resultado != null) {
            _cargarIncidencias();
          }
        },
        label: const Text('Nueva Emergencia', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_alert),
        backgroundColor: AppTheme.danger,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              child: const Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin Emergencias',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'No tienes ninguna solicitud activa o en el historial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
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
            Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Reintentar',
              onPressed: () {
                setState(() {
                  cargando = true;
                  error = null;
                });
                _cargarIncidencias();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, IncidenteDetalle inicial) {
    IncidenteDetalle inc = inicial;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> analizarIA() async {
            showDialog(
              context: ctx,
              barrierDismissible: false,
              builder: (_) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analizando evidencias con IA...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );

            final resultado = await incidenteService.analizarConIA(inc.idIncidente);

            if (!mounted) return;
            Navigator.pop(ctx);

            if (resultado['success']) {
              final actualizado = resultado['incidente'] as IncidenteDetalle;
              setDialogState(() => inc = actualizado);
              _cargarIncidencias();
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('✨ Análisis IA completado'), backgroundColor: AppTheme.success));
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(resultado['error'] ?? 'Error IA'), backgroundColor: AppTheme.danger));
              if (resultado['code'] == 'AUTH_EXPIRED') Navigator.of(ctx).pushReplacementNamed('/login');
            }
          }

          Future<void> cancelar() async {
            final confirmar = await showDialog<bool>(
              context: ctx,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('¿Cancelar incidente?', style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text('Esta acción no se puede deshacer. ¿Seguro que quieres cancelar esta solicitud?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No', style: TextStyle(color: AppTheme.textSecondary))),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                    child: const Text('Sí, cancelar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirmar != true) return;

            final resultado = await incidenteService.cancelarIncidente(inc.idIncidente);
            if (!mounted) return;

            if (resultado['success'] == true) {
              Navigator.pop(ctx);
              _cargarIncidencias();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incidente cancelado'), backgroundColor: AppTheme.warning));
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(resultado['error'] ?? 'Error al cancelar'), backgroundColor: AppTheme.danger));
              if (resultado['code'] == 'AUTH_EXPIRED') Navigator.of(ctx).pushReplacementNamed('/login');
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.all(16),
            backgroundColor: AppTheme.surface,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER DEL MODAL
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      border: Border(bottom: BorderSide(color: AppTheme.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Detalles #${inc.idIncidente}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        StatusBadge(text: inc.getEstadoNombre(), status: _mapStatusName(inc.idEstado)),
                      ],
                    ),
                  ),

                  // CONTENIDO DEL MODAL
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoField(label: 'Vehículo', value: '${inc.getMarca()} ${inc.getPlaca()}', icon: Icons.directions_car),
                        InfoField(label: 'Categoría', value: inc.getCategoriaNombre(), icon: Icons.build),
                        InfoField(label: 'Ubicación', value: inc.getUbicacion(), icon: Icons.location_on),
                        
                        if (inc.descripcionUsuario != null) ...[
                          const SizedBox(height: 16),
                          const Text('Descripción', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
                            child: Text(inc.descripcionUsuario!, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                          ),
                        ],

                        // SECCIÓN IA
                        if (inc.resumenIa != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7D2FE))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.auto_awesome, color: AppTheme.primary, size: 18),
                                        SizedBox(width: 8),
                                        Text('Análisis IA', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                      ],
                                    ),
                                    if (inc.clasificacionIaConfianza != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: _colorConfianza(inc.clasificacionIaConfianza!), borderRadius: BorderRadius.circular(12)),
                                        child: Text('${(inc.clasificacionIaConfianza! * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(inc.resumenIa!, style: const TextStyle(fontSize: 13, color: Color(0xFF312E81))),
                                if (inc.requiereRevisionManual) ...[
                                  const SizedBox(height: 8),
                                  const Text('⚠️ Baja confianza, requiere revisión manual.', style: TextStyle(fontSize: 11, color: AppTheme.warning, fontWeight: FontWeight.bold)),
                                ]
                              ],
                            ),
                          ),
                        ],

                        // ASIGNACIÓN (TALLER)
                        if (inc.asignaciones != null && inc.asignaciones!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text('Taller Asignado', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          _buildAsignacionCard(inc.asignaciones!.first),
                        ],

                        const SizedBox(height: 24),

                        // BOTONES DE ACCIÓN (Mosaico)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (inc.idCategoria == null)
                              ElevatedButton.icon(
                                onPressed: analizarIA,
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: const Text('Analizar IA'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                              ),
                            if (inc.asignaciones != null && inc.asignaciones!.isNotEmpty) ...[
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => MensajesScreen(idIncidente: inc.idIncidente)));
                                },
                                icon: const Icon(Icons.chat, size: 18),
                                label: const Text('Chat'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)), // sky-600
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => TecnicoTrackingScreen(idIncidente: inc.idIncidente, clienteLat: inc.latitud, clienteLng: inc.longitud)));
                                },
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('GPS'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                              ),
                            ],
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => SubirEvidenciaScreen(idIncidente: inc.idIncidente)));
                              },
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Fotos'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textSecondary),
                            ),
                            if (inc.idEstado == 3 && !inc.evaluado)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final updated = await Navigator.pushNamed(context, '/calificar-servicio', arguments: inc.idIncidente);
                                  if (updated == true) _cargarIncidencias();
                                },
                                icon: const Icon(Icons.star, size: 18),
                                label: const Text('Calificar'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                              ),
                            if (inc.idEstado == 1 || inc.idEstado == 2)
                              ElevatedButton.icon(
                                onPressed: cancelar,
                                icon: const Icon(Icons.cancel, size: 18),
                                label: const Text('Cancelar'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // PIE DEL MODAL (Cerrar)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar Detalles', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _colorConfianza(double c) {
    if (c >= 0.8) return AppTheme.success;
    if (c >= 0.6) return AppTheme.warning;
    return AppTheme.danger;
  }

  Widget _buildAsignacionCard(Asignacion a) {
    Color color;
    switch (a.estado.nombre.toLowerCase()) {
      case 'aceptada':
      case 'en_camino':
        color = AppTheme.success;
        break;
      case 'rechazada':
        color = AppTheme.danger;
        break;
      case 'completada':
        color = AppTheme.primary;
        break;
      default:
        color = AppTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(a.getMensajeEstado(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color))),
            ],
          ),
          if (a.notaTaller != null && a.notaTaller!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('💬 "${a.notaTaller!}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
          ],
          if (a.taller.telefono != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(a.taller.telefono!, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}