import 'package:flutter/material.dart';
import 'app_theme.dart';

// ==========================================
// 1. BADGE DE ESTADO (Para Pendiente, Completada, etc.)
// ==========================================
class StatusBadge extends StatelessWidget {
  final String text;
  final String status; // 'pendiente', 'aceptada', 'en_camino', 'completada', 'rechazada'

  const StatusBadge({Key? key, required this.text, required this.status})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'pendiente':
        bgColor = AppTheme.warningLight;
        textColor = const Color(0xFFC2410C); // orange-700
        borderColor = const Color(0xFFFED7AA); // orange-200
        break;
      case 'aceptada':
      case 'completada':
        bgColor = AppTheme.successLight;
        textColor = const Color(0xFF047857); // emerald-700
        borderColor = const Color(0xFFA7F3D0); // emerald-200
        break;
      case 'en_camino':
        bgColor = AppTheme.primaryLight;
        textColor = const Color(0xFF4338CA); // indigo-700
        borderColor = const Color(0xFFC7D2FE); // indigo-200
        break;
      case 'rechazada':
      default:
        bgColor = AppTheme.dangerLight;
        textColor = const Color(0xFFB91C1C); // red-700
        borderColor = const Color(0xFFFECACA); // red-200
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ==========================================
// 2. TARJETA MODERNA PARA LISTADOS
// ==========================================
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? indicatorColor; // Para la barra lateral de color

  const ModernCard({
    Key? key,
    required this.child,
    this.onTap,
    this.indicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000), // shadow-sm
              blurRadius: 4,
              offset: Offset(0, 1),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias, // Importante para que el borde lateral no se salga
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra indicadora lateral
              if (indicatorColor != null)
                Container(
                  width: 4,
                  color: indicatorColor,
                ),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. BOTÓN PRIMARIO PERSONALIZADO
// ==========================================
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: isLoading
          ? ElevatedButton(
              onPressed: null,
              child: const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : icon != null
              ? ElevatedButton.icon(
                  onPressed: isDisabled ? null : onPressed,
                  icon: Icon(icon),
                  label: Text(text),
                )
              : ElevatedButton(
                  onPressed: isDisabled ? null : onPressed,
                  child: Text(text),
                ),
    );
  }
}

// ==========================================
// 4. SECCIÓN CON TÍTULO Y DESCRIPCIÓN
// ==========================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onActionPressed;
  final String? actionText;

  const SectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onActionPressed,
    this.actionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          if (actionText != null && onActionPressed != null)
            TextButton(
              onPressed: onActionPressed,
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. CHIP / ETIQUETA PERSONALIZADA
// ==========================================
class CustomChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSelected;

  const CustomChip({
    Key? key,
    required this.label,
    this.icon,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. CAMPO DE INFORMACIÓN (DATO CLAVE-VALOR)
// ==========================================
class InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const InfoField({
    Key? key,
    required this.label,
    required this.value,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
