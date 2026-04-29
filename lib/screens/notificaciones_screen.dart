import 'package:flutter/material.dart';

import '../models/incidente.dart';
import '../services/incidente_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final NotificationService _notificationService = NotificationService();
  final IncidenteService _incidenteService = IncidenteService();

  bool _loading = true;
  bool _soloNoLeidas = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final data = await _notificationService.listarMisNotificaciones(
      soloNoLeidas: _soloNoLeidas,
    );
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  Future<void> _marcarLeida(Map<String, dynamic> item) async {
    final id = item['id_notificacion'];
    if (id is! int) return;

    final ok = await _notificationService.marcarLeida(id);
    if (!mounted) return;

    if (ok) {
      setState(() {
        item['leido'] = true;
      });
    }
  }

  bool _esNotificacionCalificar(String titulo, String mensaje) {
    final t = titulo.toLowerCase();
    final m = mensaje.toLowerCase();
    return t.contains('califica') || m.contains('califica');
  }

  Future<void> _abrirCalificacionSiAplica(Map<String, dynamic> item) async {
    final titulo = (item['titulo'] ?? '').toString();
    final mensaje = (item['mensaje'] ?? '').toString();
    if (!_esNotificacionCalificar(titulo, mensaje)) return;

    final idIncidenteRaw = item['id_incidente'];
    final idIncidente = idIncidenteRaw is int
        ? idIncidenteRaw
        : int.tryParse(idIncidenteRaw?.toString() ?? '');
    if (idIncidente == null || idIncidente == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidente no disponible'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    final result = await _incidenteService.obtenerIncidencia(idIncidente);
    if (!mounted) return;

    if (result['success'] == true) {
      final inc = result['incidente'] as IncidenteDetalle;
      if (inc.evaluado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya calificaste este servicio'), backgroundColor: AppTheme.success),
        );
        return;
      }

      final updated = await Navigator.of(context).pushNamed(
        '/calificar-servicio',
        arguments: idIncidente,
      );
      if (updated == true) {
        _cargar();
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['error']?.toString() ?? 'Error al abrir'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  String _fechaBonita(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // FILTRO SUPERIOR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mostrar solo no leídas',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Switch(
                  value: _soloNoLeidas,
                  activeColor: AppTheme.primary,
                  onChanged: (value) {
                    setState(() => _soloNoLeidas = value);
                    _cargar();
                  },
                ),
              ],
            ),
          ),
          
          // LISTA DE NOTIFICACIONES
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 16, bottom: 40, left: 12, right: 12),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final titulo = (item['titulo'] ?? '').toString();
                            final mensaje = (item['mensaje'] ?? '').toString();
                            final leido = item['leido'] == true;
                            final fecha = _fechaBonita(item['created_at']);

                            return ModernCard(
                              indicatorColor: leido ? Colors.transparent : AppTheme.primary,
                              onTap: () async {
                                await _marcarLeida(item);
                                await _abrirCalificacionSiAplica(item);
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: leido ? AppTheme.background : AppTheme.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      leido ? Icons.notifications_none : Icons.notifications_active,
                                      color: leido ? AppTheme.textMuted : AppTheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                titulo,
                                                style: TextStyle(
                                                  fontWeight: leido ? FontWeight.w600 : FontWeight.bold,
                                                  fontSize: 16,
                                                  color: leido ? AppTheme.textSecondary : AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (!leido)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(top: 6, left: 8),
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          mensaje,
                                          style: TextStyle(
                                            color: leido ? AppTheme.textMuted : AppTheme.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              fecha,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textMuted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
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
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay notificaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _soloNoLeidas 
                  ? 'Estás al día. No tienes notificaciones nuevas por leer.' 
                  : 'Aún no has recibido ninguna notificación en tu cuenta.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}