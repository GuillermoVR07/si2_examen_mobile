import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/pago_cliente_item.dart';

class PagosService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>> listarMisPagos() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/pagos/mis-pagos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final items = data
            .map((j) => PagoClienteItem.fromJson(j as Map<String, dynamic>))
            .toList();

        final pendientes = items.where((e) => e.estaPendiente).toList();
        final completados = items.where((e) => e.estaCompletado).toList();

        return {
          'success': true,
          'items': items,
          'pendientes': pendientes,
          'completados': completados,
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sesion expirada',
          'code': 'AUTH_EXPIRED',
        };
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'No tienes permisos para consultar pagos',
        };
      }

      return {'success': false, 'error': 'Error al cargar pagos'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  /// Crea un PaymentIntent en Stripe a través del backend.
  /// Retorna {'success': true, 'client_secret': '...', 'payment_intent_id': '...'} o {'success': false, 'error': '...'}.
  Future<Map<String, dynamic>> crearPaymentIntent({
    required int idIncidente,
    required double montoTotal,
    int idMetodoPago = 1,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/pagos/crear-intent'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_incidente': idIncidente,
          'monto_total': montoTotal,
          'id_metodo_pago': idMetodoPago,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'client_secret': data['client_secret'] as String,
          'payment_intent_id': data['payment_intent_id'] as String,
          'monto_centavos': data['monto_centavos'] as int,
        };
      }

      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Sesion expirada', 'code': 'AUTH_EXPIRED'};
      }

      final errorBody = _parseError(response.body);
      return {'success': false, 'error': errorBody};
    } catch (e) {
      return {'success': false, 'error': 'Error de red: $e'};
    }
  }

  /// Notifica al backend que el pago fue completado desde la app.
  /// El backend consulta Stripe y actualiza el estado del pago en la BD.
  Future<Map<String, dynamic>> confirmarPagoApp(String paymentIntentId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/pagos/confirmar-app'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'payment_intent_id': paymentIntentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'estado': data['estado']};
      }

      final errorBody = _parseError(response.body);
      return {'success': false, 'error': errorBody};
    } catch (e) {
      return {'success': false, 'error': 'Error de red: $e'};
    }
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail']?.toString() ?? 'Error desconocido';
    } catch (_) {
      return body.isNotEmpty ? body : 'Error desconocido';
    }
  }
}
