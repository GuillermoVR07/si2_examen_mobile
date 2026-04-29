import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  final AuthService _authService = AuthService();
  String _userName = 'Conductor';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _authService.getUserName();
    if (mounted) {
      setState(() {
        _userName = name ?? 'Conductor';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER HERO (Gradiente idéntico al Taller/Admin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, Color(0xFF6366F1)], // Indigo a Violeta
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Hola, $_userName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '¿En qué podemos ayudarte hoy?',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACCIÓN PRINCIPAL: REPORTAR EMERGENCIA
                  const SectionHeader(title: 'Asistencia Inmediata'),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/reportar-emergencia'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.danger.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.white, size: 40),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reportar Emergencia',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Solicita una grúa o técnico ahora',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // GRILLA DE ACCIONES SECUNDARIAS
                  const SectionHeader(title: 'Gestión de Cuenta'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildQuickAction(
                        context,
                        'Mis Vehículos',
                        Icons.directions_car_filled,
                        AppTheme.primary,
                        '/mis-vehiculos',
                      ),
                      _buildQuickAction(
                        context,
                        'Historial',
                        Icons.history,
                        Colors.blueGrey,
                        '/historial-emergencias',
                      ),
                      _buildQuickAction(
                        context,
                        'Mis Pagos',
                        Icons.account_balance_wallet,
                        AppTheme.success,
                        '/mis-pagos',
                      ),
                      _buildQuickAction(
                        context,
                        'Notificaciones',
                        Icons.notifications,
                        AppTheme.warning,
                        '/notificaciones',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // PERFIL RÁPIDO
                  ModernCard(
                    onTap: () => Navigator.pushNamed(context, '/perfil'),
                    child: const Row(
                      children: [
                        Icon(Icons.settings, color: AppTheme.textSecondary),
                        SizedBox(width: 16),
                        Text(
                          'Configuración de Perfil',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right, color: AppTheme.border),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}