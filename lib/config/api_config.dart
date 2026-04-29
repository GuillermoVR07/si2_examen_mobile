class ApiConfig {
  // 🔧 Cambia a `false` cuando pruebes en dispositivo físico.
  static const bool isEmulator = false;

  // Emulador Android: 10.0.2.2 → apunta al localhost del host.
  static const String _emulatorUrl = 'https://examen-si2.onrender.com';

  // Dispositivo físico: backend desplegado.
  static const String _deviceUrl = 'https://examen-si2.onrender.com';

  static const String baseUrl = isEmulator ? _emulatorUrl : _deviceUrl;
}
