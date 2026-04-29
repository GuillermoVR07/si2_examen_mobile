import 'package:flutter/material.dart';

import '../models/asignacion_response.dart';
import '../models/evidencia.dart';
import '../services/auth_service.dart';
import '../services/tecnico_asignaciones_service.dart';
import '../services/tecnico_auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class TecnicoDashboardScreen extends StatefulWidget {
  const TecnicoDashboardScreen({super.key});

  @override
  State<TecnicoDashboardScreen> createState() => _TecnicoDashboardScreenState();
}

class _TecnicoDashboardScreenState extends State<TecnicoDashboardScreen> {
  final TecnicoAsignacionesService _tecnicoService = TecnicoAsignacionesService();
  final AuthService _authService = AuthService();
  final TecnicoAuthService _tecnicoAuthService = TecnicoAuthService();

  AsignacionResponse? _asignacion;
  IncidenteResponse? _incidente;
  bool _isLoading = true;
  String? _errorMessage;
  List<Evidencia> _evidencias = [];
  bool _loadingEvidencias = false;

  void _log(String message) {
    debugPrint('[TEC DASH] $message');
  }

  @override
  void initState() {
    super.initState();
    _log('initState -> dashboard tecnico inicializado');
    _loadAsignacion();
  }

  @override
  void dispose() {
    _tecnicoService.detenerSeguimientoUbicacion();
    super.dispose();
  }

  Future<void> _loadAsignacion() async {
    _log('_loadAsignacion -> INICIO');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _log('_loadAsignacion -> solicitando asignacion actual');
      final asig = await _tecnicoService.getAsignacionActual();
      if (asig == null) {
        _log('_loadAsignacion -> sin asignacion activa (null)');
        setState(() {
          _asignacion = null;
          _incidente = null;
          _isLoading = false;
        });
        return;
      }

      final incidente = asig.incidente;
      setState(() {
        _asignacion = asig;
        _incidente = incidente;
        _isLoading = false;
      });

      if (asig.estadoAsignacion == 'en_camino') {
        _tecnicoService.iniciarSeguimientoUbicacion();
      } else {
        _tecnicoService.detenerSeguimientoUbicacion();
      }

      _cargarEvidencias(asig.idAsignacion);
      _log('_loadAsignacion -> FIN OK');
    } catch (e, st) {
      _log('_loadAsignacion -> ERROR: $e');
      _log('_loadAsignacion -> STACK: $st');
      setState(() {
        _errorMessage = _mapError(e);
        _isLoading = false;
      });
    }
  }

  String _mapError(dynamic error) {
    final text = error.toString();
    if (text.contains('404')) {
      return 'No hay asignacion actual. Espera a que un taller te asigne.';
    }
    if (text.contains('401')) {
      return 'Sesion expirada. Vuelve a iniciar sesion.';
    }
    if (text.contains('409')) {
      return 'Ya tienes otra asignacion activa. Completala primero.';
    }
    if (text.contains('Connection') || text.contains('SocketException')) {
      return 'Error de conexion. Verifica tu internet.';
    }
    return 'Error: $error';
  }

  Future<void> _cargarEvidencias(int idAsignacion) async {
    setState(() => _loadingEvidencias = true);
    final lista = await _tecnicoService.obtenerEvidencias(idAsignacion);
    final embebidas = _asignacion?.incidente.evidencias ?? [];
    final todas = [...embebidas];
    for (final evidencia in lista) {
      if (!todas.any((item) => item.idEvidencia == evidencia.idEvidencia)) {
        todas.add(evidencia);
      }
    }
    if (mounted) {
      setState(() {
        _evidencias = todas;
        _loadingEvidencias = false;
      });
    }
  }

  Future<void> _handleIniciarViaje() async {
    if (_asignacion == null) return;
    try {
      final updated = await _tecnicoService.iniciarViaje(_asignacion!.idAsignacion);
      setState(() => _asignacion = updated);
      _tecnicoService.iniciarSeguimientoUbicacion();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaje iniciado. Compartiendo ubicación en tiempo real.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapError(e)), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _handleCompletar() async {
    if (_asignacion == null) return;

    final resumenController = TextEditingController();
    final costoController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Completar Servicio',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cobro final (opcional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: costoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ej: 85000'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Resumen del trabajo (opcional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: resumenController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Describe el trabajo realizado'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final costo = double.tryParse(costoController.text.trim());
                  final resumen = resumenController.text.trim().isEmpty
                      ? null
                      : resumenController.text.trim();

                  final updated = await _tecnicoService.completar(
                    _asignacion!.idAsignacion,
                    costoFinal: costo,
                    resumenTrabajo: resumen,
                  );
                  setState(() => _asignacion = updated);
                  _tecnicoService.detenerSeguimientoUbicacion();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Servicio completado.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_mapError(e)), backgroundColor: AppTheme.danger),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    resumenController.dispose();
    costoController.dispose();
  }

  Future<void> _logout() async {
    await _tecnicoAuthService.logout();
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildActionButtons() {
    if (_asignacion == null) return const SizedBox.shrink();

    switch (_asignacion!.estadoAsignacion) {
      case 'pendiente':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.access_time_filled, color: AppTheme.textMuted),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Esperando que el taller acepte la asignacion...',
                  style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      case 'aceptada':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleIniciarViaje,
            icon: const Icon(Icons.directions_car),
            label: const Text('Iniciar Viaje Hacia el Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      case 'en_camino':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleCompletar,
            icon: const Icon(Icons.check_circle),
            label: const Text('Completar Servicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      case 'completada':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: AppTheme.success),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Servicio completado. El cliente puede evaluar tu trabajo.',
                  style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEvidencias() {
    if (_loadingEvidencias) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_evidencias.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.no_photography_outlined, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 8),
            Text(
              'Sin evidencias subidas',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _evidencias.map(_buildEvidenciaItem).toList(),
    );
  }

  Widget _buildEvidenciaItem(Evidencia evidencia) {
    if (evidencia.esImagen) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            evidencia.urlArchivo,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 100,
              color: AppTheme.background,
              child: const Center(
                child: Icon(Icons.broken_image, color: AppTheme.textMuted),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: evidencia.esAudio ? AppTheme.warningLight : AppTheme.primaryLight,
          child: Icon(
            evidencia.esAudio ? Icons.mic : Icons.description,
            color: evidencia.esAudio ? AppTheme.warning : AppTheme.primary,
          ),
        ),
        title: Text(
          evidencia.esAudio ? 'Audio del cliente' : 'Descripción adicional',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          (evidencia.esAudio ? evidencia.transcripcionAudio : evidencia.descripcionIa) ?? 'Cargando...',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildGpsIndicator() {
    if (_asignacion?.estadoAsignacion != 'en_camino') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_on, color: AppTheme.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Compartiendo ubicación en tiempo real con el cliente',
              style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final estado = _asignacion?.estadoAsignacion ?? 'desconocido';
    final nombreCliente = _incidente?.usuario?['nombre'] ?? _asignacion!.incidente.usuario?['nombre'] ?? 'Cliente';
    final telefonoCliente = _incidente?.usuario?['telefono'] ?? _asignacion!.incidente.usuario?['telefono'];
    final placa = _incidente?.vehiculo?['placa'] ?? _asignacion!.incidente.vehiculo?['placa'] ?? 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFF6366F1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ASIGNACIÓN #${_asignacion!.idAsignacion}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              StatusBadge(
                text: estado.replaceAll('_', ' '),
                status: estado,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Atención a Cliente',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            nombreCliente,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vehículo: $placa',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (telefonoCliente != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(telefonoCliente, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetalleServicio() {
    final vehiculo = '${_incidente?.vehiculo?['marca'] ?? _asignacion!.incidente.vehiculo?['marca'] ?? ''} ${_incidente?.vehiculo?['modelo'] ?? _asignacion!.incidente.vehiculo?['modelo'] ?? ''}'.trim();
    final colorVehiculo = _incidente?.vehiculo?['color'] ?? _asignacion!.incidente.vehiculo?['color'];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoField(
            icon: Icons.directions_car,
            label: 'Vehículo',
            value: '$vehiculo (${_incidente?.vehiculo?['placa'] ?? _asignacion!.incidente.vehiculo?['placa'] ?? 'N/A'})',
          ),
          if (colorVehiculo != null) ...[
            const Divider(color: AppTheme.border, height: 24),
            InfoField(
              icon: Icons.palette_outlined,
              label: 'Color',
              value: colorVehiculo.toString(),
            ),
          ],
          const Divider(color: AppTheme.border, height: 24),
          InfoField(
            icon: Icons.warning_amber_rounded,
            label: 'Problema Reportado',
            value: _incidente?.descripcionUsuario ?? _asignacion!.incidente.descripcionUsuario,
          ),
          if ((_incidente?.resumenIa ?? _asignacion!.incidente.resumenIa) != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.primary, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'ANÁLISIS DE IA',
                        style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (_incidente?.resumenIa ?? _asignacion!.incidente.resumenIa)!,
                    style: const TextStyle(color: Color(0xFF312E81), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          if (_asignacion?.etaMinutos != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'ETA: ${_asignacion!.etaMinutos} minutos',
                  style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadoCard() {
    final estado = _asignacion!.estadoAsignacion;
    return ModernCard(
      indicatorColor: _getIndicatorColor(estado),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estado', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                estado.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Icon(_getIconForEstado(estado), size: 42, color: _getIndicatorColor(estado)),
        ],
      ),
    );
  }

  Color _getIndicatorColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppTheme.warning;
      case 'aceptada':
        return AppTheme.success;
      case 'en_camino':
        return AppTheme.primary;
      case 'completada':
        return const Color(0xFF0F766E);
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getIconForEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.schedule;
      case 'aceptada':
        return Icons.check_circle;
      case 'en_camino':
        return Icons.directions_car;
      case 'completada':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Tarea Activa')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Tarea Activa')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(text: 'Reintentar', onPressed: _loadAsignacion),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_asignacion == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Tarea Activa'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => Navigator.pushNamed(context, '/notificaciones'),
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAsignacion),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 80, color: AppTheme.border),
                const SizedBox(height: 16),
                const Text(
                  'Sin Asignaciones',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No tienes ninguna tarea pendiente.\nEspera a que tu taller te asigne una.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadAsignacion,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar Ahora'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Técnico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.pushNamed(context, '/notificaciones'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAsignacion),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAsignacion,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEstadoCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    _buildGpsIndicator(),
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Detalles del Servicio'),
                    _buildDetalleServicio(),
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'Evidencias Adjuntas'),
                    ModernCard(child: _buildEvidencias()),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
