import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const String _tag = 'LoginScreen';
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Pantalla de Login iniciada', tag: _tag);
  }

  @override
  void dispose() {
    AppLogger.debug('Limpiando controladores de login', tag: _tag);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    AppLogger.separator(title: 'INTENTANDO LOGIN MANUAL');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    AppLogger.info('Email ingresado: $email', tag: _tag);
    AppLogger.info('Longitud de contraseña: ${password.length} caracteres', tag: _tag);

    if (email.isEmpty || password.isEmpty) {
      AppLogger.warning('Campos vacíos detectados', tag: _tag);
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
        _isLoading = false;
      });
      return;
    }

    AppLogger.info('Campos válidos, iniciando solicitud de login...', tag: _tag);
    final result = await _authService.login(email, password);

    if (!mounted) {
      AppLogger.warning('Widget desmontado, cancelando actualización de UI', tag: _tag);
      return;
    }

    if (result['success']) {
      final userData = result['data']['usuario'];
      final userRole = userData['id_rol'].toString();

      // Reintento explícito de registro de token FCM tras login exitoso.
      await _notificationService.syncTokenWithBackend();

      AppLogger.info('Login exitoso, rol: $userRole', tag: _tag);

      // Route based on user role
      if (userRole == '1') {
        // Cliente (Conductor)
        AppLogger.success('Navegando a Conductor Home', tag: _tag);
        Navigator.of(context).pushReplacementNamed('/conductor-home');
      } else if (userRole == '3') {
        // Técnico
        AppLogger.success('Navegando a Técnico Dashboard', tag: _tag);
        Navigator.of(context).pushReplacementNamed('/tecnico-dashboard');
      } else {
        AppLogger.warning('Rol no autorizado: $userRole', tag: _tag);
        setState(() {
          _errorMessage = 'Rol no autorizado para esta aplicación';
          _isLoading = false;
        });
      }
    } else {
      AppLogger.error('Error en login: ${result['error']}', tag: _tag);
      setState(() {
        _errorMessage = result['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _mostrarRegistroCliente() async {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final telefonoController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool loading = false;
    String? error;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final nombre = nombreController.text.trim();
              final email = emailController.text.trim();
              final telefono = telefonoController.text.trim();
              final password = passwordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (nombre.length < 3) {
                setDialogState(() => error = 'El nombre debe tener al menos 3 caracteres');
                return;
              }
              if (email.isEmpty || !email.contains('@')) {
                setDialogState(() => error = 'Ingresa un correo válido');
                return;
              }
              if (password.length < 8) {
                setDialogState(() => error = 'La contraseña debe tener mínimo 8 caracteres');
                return;
              }
              if (password != confirmPassword) {
                setDialogState(() => error = 'Las contraseñas no coinciden');
                return;
              }

              setDialogState(() {
                loading = true;
                error = null;
              });

              final result = await _authService.registrarCliente(
                nombre: nombre,
                email: email,
                password: password,
                telefono: telefono.isEmpty ? null : telefono,
              );

              if (!mounted) return;

              if (result['success'] == true) {
                _emailController.text = email;
                _passwordController.text = password;
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registro exitoso. Ya puedes iniciar sesión como cliente.'),
                    backgroundColor: Colors.green,
                  ),
                );
                return;
              }

              setDialogState(() {
                loading = false;
                error = (result['error'] ?? 'No se pudo registrar el cliente').toString();
              });
            }

            return AlertDialog(
              title: const Text('Registro de Cliente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Este registro es solo para clientes. Los técnicos los crea el taller.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreController,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      enabled: !loading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: telefonoController,
                      enabled: !loading,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      enabled: !loading,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      enabled: !loading,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    emailController.dispose();
    telefonoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  // Auto-login para pruebas: Cliente (Conductor)
  Future<void> _autoLoginConductor() async {
    AppLogger.separator(title: 'AUTO-LOGIN CONDUCTOR');
    await _handleLoginWithCredentials(
      'conductor@ejemplo.com',
      'cliente123!',
    );
  }

  // Auto-login para pruebas: Técnico
  Future<void> _autoLoginTecnico() async {
    AppLogger.separator(title: 'AUTO-LOGIN TÉCNICO');
    await _handleLoginWithCredentials(
      'tecnico.juan@taller.com',
      'tecnico123!',
    );
  }

  // Método auxiliar para login con credenciales específicas
  Future<void> _handleLoginWithCredentials(String email, String password) async {
    AppLogger.info('Auto-login con: $email', tag: _tag);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailController.text = email;
      _passwordController.text = password;
    });

    final result = await _authService.login(email, password);

    if (!mounted) {
      AppLogger.warning('Widget desmontado durante auto-login', tag: _tag);
      return;
    }

    if (result['success']) {
      final userData = result['data']['usuario'];
      final userRole = userData['id_rol'].toString();

      // Reintento explícito de registro de token FCM tras login exitoso.
      await _notificationService.syncTokenWithBackend();

      AppLogger.success('Auto-login exitoso', tag: _tag);

      if (userRole == '1') {
        AppLogger.info('Navegando a Conductor Home', tag: _tag);
        Navigator.of(context).pushReplacementNamed('/conductor-home');
      } else if (userRole == '3') {
        AppLogger.info('Navegando a Técnico Dashboard', tag: _tag);
        Navigator.of(context).pushReplacementNamed('/tecnico-dashboard');
      }
    } else {
      AppLogger.error('Auto-login falló: ${result['error']}', tag: _tag);
      setState(() {
        _errorMessage = result['error'];
        _isLoading = false;
      });
    }
  }

  // Limpiar datos de prueba
  Future<void> _clearAllData() async {
    AppLogger.info('Limpiando todos los datos de sesión...', tag: _tag);
    try {
      await _authService.logout();
      AppLogger.success('Datos limpios exitosamente', tag: _tag);
      setState(() {
        _emailController.clear();
        _passwordController.clear();
        _errorMessage = 'Datos limpios ✅';
      });
    } catch (e) {
      AppLogger.error('Error al limpiar datos: $e', tag: _tag, error: e);
      setState(() {
        _errorMessage = 'Error al limpiar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icono Principal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Título
                Text(
                  'Asistencia SI2',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergencias Vehiculares',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 40),

                // Card principal con formulario
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Iniciar Sesión',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 28),

                      // Email Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          hintText: 'ejemplo@correo.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          prefixIconColor: AppTheme.primary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          prefixIconColor: AppTheme.primary,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.danger,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 16),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'INGRESAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _mostrarRegistroCliente,
                          icon: const Icon(Icons.person_add_outlined),
                          label: const Text('Registrarse como Cliente'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Demo Credentials Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credenciales de Prueba',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _credentialRow('👤 Cliente:', 'conductor@ejemplo.com', 'cliente123!'),
                      const SizedBox(height: 12),
                      _credentialRow('🔧 Técnico:', 'tecnico.juan@taller.com', 'tecnico123!'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _autoLoginConductor,
                        icon: const Icon(Icons.person),
                        label: const Text('Cliente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _autoLoginTecnico,
                        icon: const Icon(Icons.build),
                        label: const Text('Técnico'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'conductor':
              await _autoLoginConductor();
              break;
            case 'tecnico':
              await _autoLoginTecnico();
              break;
            case 'fill_conductor':
              setState(() {
                _emailController.text = 'conductor@ejemplo.com';
                _passwordController.text = 'cliente123!';
              });
              break;
            case 'fill_tecnico':
              setState(() {
                _emailController.text = 'tecnico.juan@taller.com';
                _passwordController.text = 'tecnico123!';
              });
              break;
            case 'clear':
              await _clearAllData();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'conductor',
            child: Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 12),
                Text('👤 Login: Cliente'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'tecnico',
            child: Row(
              children: [
                Icon(Icons.build),
                SizedBox(width: 12),
                Text('🔧 Login: Técnico'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'fill_conductor',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 12),
                Text('✏️ Llenar: Cliente'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'fill_tecnico',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 12),
                Text('✏️ Llenar: Técnico'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'clear',
            child: Row(
              children: [
                Icon(Icons.delete_sweep),
                SizedBox(width: 12),
                Text('🧹 Limpiar Datos'),
              ],
            ),
          ),
        ],
        tooltip: 'Opciones de Prueba',
        icon: const Icon(Icons.build),
      ),
    );
  }

      /// Helper method para mostrar credenciales
  Widget _credentialRow(String role, String email, String password) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          password,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
