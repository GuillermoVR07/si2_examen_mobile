import 'package:flutter/material.dart';
import '../services/usuario_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_widgets.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> usuarioInicial;
  
  const EditarPerfilScreen({super.key, required this.usuarioInicial});
  
  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final usuarioService = UsuarioService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  
  bool guardando = false;
  String? errorGeneral;
  
  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuarioInicial['nombre'] ?? '');
    _emailController = TextEditingController(text: widget.usuarioInicial['email'] ?? '');
    _telefonoController = TextEditingController(text: widget.usuarioInicial['telefono'] ?? '');
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
  
  void guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      guardando = true;
      errorGeneral = null;
    });
    
    final resultado = await usuarioService.actualizarPerfil(
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _telefonoController.text.trim(),
    );
    
    if (!mounted) return;
    
    setState(() => guardando = false);
    
    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: AppTheme.success,
        )
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        errorGeneral = resultado['error'] ?? 'Error al actualizar el perfil';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorGeneral!),
          backgroundColor: AppTheme.danger,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabecera Informativa
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryLight,
                    child: Icon(Icons.person, size: 32, color: AppTheme.primary),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus Datos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Mantén tu información de contacto al día.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    if (errorGeneral != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                        ),
                        child: Text(
                          errorGeneral!,
                          style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                    // Tarjeta del Formulario
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Nombre Completo',
                            controller: _nombreController,
                            icon: Icons.person_outline,
                            hint: 'Ej: Juan Pérez',
                            validator: (val) => val == null || val.isEmpty ? 'El nombre es obligatorio' : null,
                          ),
                          _buildTextField(
                            label: 'Correo Electrónico',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: 'Ej: juan@email.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => val == null || !val.contains('@') ? 'Ingresa un correo válido' : null,
                          ),
                          _buildTextField(
                            label: 'Teléfono',
                            controller: _telefonoController,
                            icon: Icons.phone_outlined,
                            hint: 'Ej: 71234567',
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botones de Acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: guardando ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            text: 'Guardar Cambios',
                            onPressed: guardarCambios,
                            isLoading: guardando,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para estandarizar los inputs
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.normal),
              prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
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
              focusedBorder:  OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}