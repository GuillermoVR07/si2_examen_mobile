import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:intl/intl.dart';

import '../models/pago_cliente_item.dart';
import '../services/pagos_service.dart';
import '../utils/app_logger.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class MisPagosScreen extends StatefulWidget {
  const MisPagosScreen({super.key});

  @override
  State<MisPagosScreen> createState() => _MisPagosScreenState();
}

class _MisPagosScreenState extends State<MisPagosScreen>
    with SingleTickerProviderStateMixin {
  final PagosService _pagosService = PagosService();
  static const String _tag = 'MIS_PAGOS';

  late TabController _tabController;
  bool _cargando = true;
  String? _error;
  List<PagoClienteItem> _pendientes = [];
  List<PagoClienteItem> _completados = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarPagos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPagos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    AppLogger.info('Cargando pagos del usuario', tag: _tag);
    final resultado = await _pagosService.listarMisPagos();

    if (!mounted) return;

    if (resultado['success'] == true) {
      setState(() {
        _pendientes = List<PagoClienteItem>.from(resultado['pendientes'] ?? []);
        _completados = List<PagoClienteItem>.from(resultado['completados'] ?? []);
      });
      AppLogger.success(
        'Pagos cargados. Pendientes: ${_pendientes.length}, Completados: ${_completados.length}',
        tag: _tag,
      );
    } else {
      setState(() {
        _error = (resultado['error'] ?? 'No se pudieron cargar los pagos').toString();
      });
      AppLogger.warning('Error al cargar pagos: $_error', tag: _tag);

      if (resultado['code'] == 'AUTH_EXPIRED') {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }

    setState(() => _cargando = false);
  }

  Future<void> _iniciarPago(PagoClienteItem item) async {
    final loadingOverlay = _showLoading('Preparando pago...');

    try {
      AppLogger.info(
        'Iniciando pago. Incidente: ${item.idIncidente}, Monto: ${item.montoTotal}',
        tag: _tag,
      );
      
      // 1. Crear PaymentIntent en el backend
      final intentResult = await _pagosService.crearPaymentIntent(
        idIncidente: item.idIncidente,
        montoTotal: item.montoTotal,
      );

      if (!mounted) return;

      if (intentResult['success'] != true) {
        loadingOverlay.remove();
        AppLogger.warning('Fallo al crear PaymentIntent: ${intentResult['error']}', tag: _tag);
        _mostrarError(intentResult['error']?.toString() ?? 'Error al crear pago');
        return;
      }

      final clientSecret = intentResult['client_secret'] as String;
      final paymentIntentId = intentResult['payment_intent_id'] as String;
      AppLogger.info('PaymentIntent creado: $paymentIntentId', tag: _tag);

      // 2. Inicializar PaymentSheet de Stripe
      AppLogger.debug('Inicializando PaymentSheet', tag: _tag);
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Yary Emergencias',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppTheme.primary, // Utilizamos el índigo principal de la app
            ),
          ),
        ),
      );

      loadingOverlay.remove();

      // 3. Presentar PaymentSheet
      AppLogger.debug('Presentando PaymentSheet', tag: _tag);
      await Stripe.instance.presentPaymentSheet();
      AppLogger.success('PaymentSheet completado', tag: _tag);

      // 4. Si llegamos aquí, el pago fue exitoso — confirmar en backend
      if (!mounted) return;
      AppLogger.info('Confirmando pago en backend', tag: _tag);
      final confirmLoading = _showLoading('Confirmando pago...');
      final confirmResult = await _pagosService.confirmarPagoApp(paymentIntentId);
      confirmLoading.remove();
      AppLogger.info('Respuesta confirmacion: ${confirmResult['success']} / ${confirmResult['estado'] ?? confirmResult['error']}', tag: _tag);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pago completado exitosamente!'),
          backgroundColor: AppTheme.success,
        ),
      );

      await _cargarPagos();
    } on StripeException catch (e) {
      loadingOverlay.remove();
      if (!mounted) return;

      // El usuario canceló — no mostrar error
      if (e.error.code == FailureCode.Canceled) {
        AppLogger.info('Pago cancelado por el usuario', tag: _tag);
        return;
      }

      AppLogger.error(
        'StripeException al procesar pago',
        tag: _tag,
        error: e,
      );
      _mostrarError('Error al procesar el pago: ${e.error.localizedMessage ?? e.error.message}');
    } catch (e) {
      loadingOverlay.remove();
      if (!mounted) return;
      AppLogger.error('Excepcion inesperada en pago', tag: _tag, error: e);
      _mostrarError('Error inesperado: $e');
    }
  }

  OverlayEntry _showLoading(String mensaje) {
    final entry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 16),
                Text(
                  mensaje,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return AppTheme.success;
      case 'procesando':
        return AppTheme.primary;
      case 'fallido':
        return AppTheme.danger;
      case 'reembolsado':
        return const Color(0xFF9333EA); // purple-600
      default:
        return AppTheme.warning;
    }
  }

  IconData _estadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return Icons.check_circle;
      case 'procesando':
        return Icons.sync;
      case 'fallido':
        return Icons.error;
      case 'reembolsado':
        return Icons.replay;
      default:
        return Icons.pending;
    }
  }

  String _monto(double monto) => NumberFormat.currency(
        locale: 'es_MX',
        symbol: '\$',
        decimalDigits: 2,
      ).format(monto);

  String _fecha(DateTime? dt) {
    if (dt == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  Widget _buildEmpty(String mensaje, IconData icono) {
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
              child: Icon(icono, size: 64, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay registros',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<PagoClienteItem> items, {required bool showPagarBtn}) {
    if (items.isEmpty) {
      return _buildEmpty(
        showPagarBtn
            ? 'No tienes pagos pendientes en este momento.'
            : 'No tienes pagos completados todavía.',
        showPagarBtn ? Icons.payments_outlined : Icons.receipt_long_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPagos,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 16, bottom: 40, left: 8, right: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final item = items[index];
          final color = _estadoColor(item.estado);

          return ModernCard(
            indicatorColor: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Incidente #${item.idIncidente}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(_estadoIcon(item.estado), color: color, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            item.estadoLabel.toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _monto(item.montoTotal),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _fecha(item.createdAt),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                if (item.referenciaExterna != null && item.referenciaExterna!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.receipt, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Ref: ${item.referenciaExterna}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
                if (showPagarBtn) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Pagar ahora',
                      icon: Icons.credit_card,
                      onPressed: () => _iniciarPago(item),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Pagos'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Pendientes (${_pendientes.length})'),
            Tab(text: 'Completados (${_completados.length})'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _error!, 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _cargarPagos,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_pendientes, showPagarBtn: true),
                    _buildList(_completados, showPagarBtn: false),
                  ],
                ),
    );
  }
}