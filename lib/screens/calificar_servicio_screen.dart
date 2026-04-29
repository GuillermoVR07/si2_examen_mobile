import 'package:flutter/material.dart';

import '../models/incidente.dart';
import '../services/incidente_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class CalificarServicioScreen extends StatefulWidget {
  final int idIncidente;

  const CalificarServicioScreen({super.key, required this.idIncidente});

  @override
  State<CalificarServicioScreen> createState() => _CalificarServicioScreenState();
}

class _CalificarServicioScreenState extends State<CalificarServicioScreen> {
  final IncidenteService _incidenteService = IncidenteService();
  final TextEditingController _comentarioController = TextEditingController();

  bool _loading = true;
  bool _enviando = false;
  bool _yaEvaluado = false;
  String? _error;
  int _estrellas = 0;
  IncidenteDetalle? _incidente;

  @override
  void initState() {
    super.initState();
    _cargarIncidente();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _cargarIncidente() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _incidenteService.obtenerIncidencia(widget.idIncidente);
    if (!mounted) return;

    if (result['success']) {
      final inc = result['incidente'] as IncidenteDetalle;
      setState(() {
        _incidente = inc;
        _yaEvaluado = inc.evaluado;
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? 'Error al cargar datos';
        _loading = false;
      });
      if (result['code'] == 'AUTH_EXPIRED') {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _enviarCalificacion() async {
    if (_estrellas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos 1 estrella'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final result = await _incidenteService.evaluarServicio(
      idIncidente: widget.idIncidente,
      estrellas: _estrellas,
      comentario: _comentarioController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu evaluación!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true); // Devuelve true para recargar lista en el historial
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Error al enviar'),
          backgroundColor: AppTheme.danger,
        ),
      );
      if (result['code'] == 'AUTH_EXPIRED') {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Calificar Servicio'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _yaEvaluado
                  ? _buildEvaluadoState()
                  : _buildForm(),
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
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Reintentar',
              onPressed: _cargarIncidente,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluadoState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, size: 64, color: AppTheme.success),
            ),
            const SizedBox(height: 24),
            const Text(
              'Servicio ya evaluado',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ya has enviado una calificación para este servicio. ¡Gracias por ayudarnos a mejorar!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Volver al historial', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // CABECERA INFORMATIVA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.rate_review_outlined, size: 48, color: AppTheme.primary),
                const SizedBox(height: 16),
                const Text(
                  '¿Cómo estuvo el servicio?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Incidente #${_incidente?.idIncidente}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FORMULARIO Y ESTRELLAS
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Toca una estrella para calificar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _estrellas = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          index < _estrellas ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 48,
                          color: index < _estrellas ? Colors.amber : AppTheme.border,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Tus comentarios (opcional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _comentarioController,
                  maxLines: 4,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cuéntanos qué te pareció la atención y resolución...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

        // BOTÓN PRINCIPAL
        // BOTÓN PRINCIPAL
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Enviar Calificación',
              // Quitamos el "? null :" y ponemos la condición adentro
              onPressed: () { 
                if (!_enviando) {
                  _enviarCalificacion(); 
                }
              },
              isLoading: _enviando,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}