import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/mensajes_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class MensajesScreen extends StatefulWidget {
  final int idIncidente;
  const MensajesScreen({super.key, required this.idIncidente});

  @override
  State<MensajesScreen> createState() => _MensajesScreenState();
}

class _MensajesScreenState extends State<MensajesScreen> {
  final MensajesService _service = MensajesService();
  final AuthService _authService = AuthService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<MensajeModel> _mensajes = [];
  int? _miId;
  bool _cargando = true;
  bool _enviando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarUserId();
    _cargar();
    // Refresco automático cada 10 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _cargar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _cargarUserId() async {
    final id = await _authService.getUserId();
    if (mounted) {
      setState(() => _miId = id != null ? int.tryParse(id) : null);
    }
  }

  Future<void> _cargar() async {
    final lista = await _service.listar(widget.idIncidente);
    if (!mounted) return;

    setState(() {
      _mensajes = lista;
      _cargando = false;
    });

    // Bajar al último mensaje si no estamos enviando nada
    if (!_enviando && _scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);

    final msgEnviado = await _service.enviar(widget.idIncidente, texto);

    if (!mounted) return;

    if (msgEnviado != null) {
      _ctrl.clear();
      await _cargar();
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar el mensaje'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }

    setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryLight,
              child: Icon(Icons.support_agent, color: AppTheme.primary, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat de Asistencia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('En línea', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        centerTitle: false,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: Column(
        children: [
          // ZONA DE MENSAJES
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) {
                          final msg = _mensajes[index];
                            final soyYo = msg.idUsuario == _miId;

                            final horaTxt = DateFormat('HH:mm').format(msg.createdAt.toLocal());

                          return _buildMessageBubble(msg, soyYo, horaTxt);
                        },
                      ),
          ),
          
          // ZONA DE INPUT (Teclado)
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Inicia la conversación',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escribe un mensaje para coordinar\nlos detalles del servicio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MensajeModel msg, bool soyYo, String horaTxt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: soyYo ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!soyYo) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.person, size: 16, color: AppTheme.textMuted),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: soyYo ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(soyYo ? 20 : 4),
                  bottomRight: Radius.circular(soyYo ? 4 : 20),
                ),
                border: soyYo ? null : Border.all(color: AppTheme.border),
                boxShadow: [
                  if (!soyYo)
                    const BoxShadow(color: Color(0x05000000), blurRadius: 5, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: soyYo ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.contenido,
                    style: TextStyle(
                      fontSize: 15,
                      color: soyYo ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    horaTxt,
                    style: TextStyle(
                      fontSize: 10,
                      color: soyYo ? Colors.white70 : AppTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (soyYo) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, size: 14, color: AppTheme.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1),
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) {
                  if (!_enviando) _enviar();
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _enviando ? null : _enviar,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _ctrl.text.isEmpty && !_enviando ? AppTheme.primary.withOpacity(0.5) : AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}