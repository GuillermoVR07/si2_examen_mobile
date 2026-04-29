# 🎨 FLUTTER UI GUIDELINES - Guía de Diseño de Interfaz

## Propósito

Esta guía establece los estándares de diseño visual para la aplicación mobile en Flutter, asegurando que la interfaz sea **moderna, limpia y profesional**, con una identidad visual consistente con el panel web.

---

## 📋 Tabla de Contenidos

1. [Paleta de Colores](#paleta-de-colores)
2. [Componentes](#componentes)
3. [Tipografía](#tipografía)
4. [Espaciado y Márgenes](#espaciado-y-márgenes)
5. [Patrones de Diseño](#patrones-de-diseño)
6. [Ejemplos de Uso](#ejemplos-de-uso)

---

## 🎨 Paleta de Colores

La paleta está basada en **Tailwind CSS** para garantizar compatibilidad con el diseño web.

### Colores Base

| Color         | Valor     | Uso                    |
|---------------|-----------|------------------------|
| **Background** | #F8FAFC   | Fondo principal (gris claro) |
| **Surface**    | #FFFFFF   | Tarjetas, superficies |
| **Border**     | #E2E8F0   | Bordes sutiles         |

### Colores de Texto

| Nivel         | Valor     | Contrast | Uso                    |
|---------------|-----------|----------|------------------------|
| **Primary**    | #0F172A   | Alto     | Títulos y texto principal |
| **Secondary**  | #64748B   | Medio    | Subtítulos, fechas     |
| **Muted**      | #94A3B8   | Bajo     | Textos deshabilitados  |

### Colores de Estado

| Estado      | Valor     | Light Variant | Uso                    |
|-------------|-----------|---------------|------------------------|
| **Primary** | #4F46E5   | #EEF2FF       | Acción principal, CTA  |
| **Success** | #10B981   | #D1FAE5       | Completado, éxito      |
| **Warning** | #F97316   | #FFEDD5       | Pendiente, atención    |
| **Danger**  | #EF4444   | #FEE2E2       | Error, rechazado       |

### Importar en tu código

```dart
import 'package:app_emergencias/theme/app_theme.dart';

// Usar los colores
Container(
  color: AppTheme.background,
  child: Text(
    'Texto principal',
    style: TextStyle(color: AppTheme.textPrimary),
  ),
)
```

---

## 🧩 Componentes

### 1. StatusBadge (Píldora de Estado)

**Uso:** Mostrar el estado de una solicitud, emergencia o servicio.

**Estados disponibles:**
- `'pendiente'` → Naranja
- `'aceptada'` → Verde
- `'en_camino'` → Azul
- `'completada'` → Verde oscuro
- `'rechazada'` → Rojo

**Ejemplo:**
```dart
import 'package:app_emergencias/theme/custom_widgets.dart';

StatusBadge(
  text: 'Pendiente',
  status: 'pendiente',
),
```

**Resultado visual:**
- Fondo naranja claro (#FFEDD5)
- Texto naranja oscuro (#C2410C)
- Bordes sutiles
- Texto en mayúsculas

---

### 2. ModernCard (Tarjeta Moderna)

**Uso:** Para contenedores principales de información (listados, detalles).

**Características:**
- Fondo blanco
- Bordes sutiles en gris claro
- Sombra mínima (shadow-sm)
- Barra lateral de color opcional (indicador)
- Esquinas redondeadas (16px)

**Ejemplo:**
```dart
ModernCard(
  indicatorColor: AppTheme.warning, // Naranja para pendiente
  onTap: () => irADetalle(solicitud.id),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StatusBadge(text: 'Pendiente', status: 'pendiente'),
          Text('#${solicitud.id}', 
            style: TextStyle(
              color: AppTheme.textMuted, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
      SizedBox(height: 12),
      Text('Nombre del Cliente', 
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          color: AppTheme.textPrimary
        ),
      ),
      Text('Placa: 1234ABC', 
        style: TextStyle(
          fontSize: 12, 
          color: AppTheme.textSecondary
        ),
      ),
    ],
  ),
)
```

**Variantes de indicadores:**
- `warning` (naranja) → Para solicitudes pendientes
- `success` (verde) → Para completadas
- `primary` (azul) → Para en proceso
- `danger` (rojo) → Para rechazadas

---

### 3. PrimaryButton (Botón Principal)

**Uso:** Acciones principales y CTAs.

**Propiedades:**
- `text`: Texto del botón
- `onPressed`: Callback
- `isLoading`: Muestra spinner mientras se procesa
- `isDisabled`: Desactiva el botón

**Ejemplo:**
```dart
PrimaryButton(
  text: 'Reportar Emergencia',
  isLoading: isSubmitting,
  onPressed: () => reportarEmergencia(),
)
```

---

### 4. SectionHeader (Encabezado de Sección)

**Uso:** Títulos de secciones con acción opcional.

**Ejemplo:**
```dart
SectionHeader(
  title: 'Mis Solicitudes',
  subtitle: 'Últimas 7 días',
  actionText: 'Ver todas',
  onActionPressed: () => irAHistorial(),
)
```

---

### 5. CustomChip (Etiqueta Personalizada)

**Uso:** Filtros, categorías, estados seleccionables.

**Ejemplo:**
```dart
CustomChip(
  label: 'Mecánica',
  icon: Icons.settings,
  isSelected: selectedCategory == 'mecanica',
  onTap: () => setState(() => selectedCategory = 'mecanica'),
)
```

---

### 6. InfoField (Campo de Información)

**Uso:** Mostrar pares clave-valor de forma clara.

**Ejemplo:**
```dart
InfoField(
  label: 'Placa del Vehículo',
  value: 'ABD-1234',
  icon: Icons.directions_car,
)
```

---

## 📝 Tipografía

### Familia de Fuentes

- **Principal:** Roboto (incluida por defecto en Flutter)
- **Alternativa:** Inter (si se implementa)

### Estilos de Texto

```dart
// Título Principal (h1)
TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: AppTheme.textPrimary,
)

// Subtítulo (h2)
TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: AppTheme.textPrimary,
)

// Cuerpo (body)
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: AppTheme.textSecondary,
)

// Etiqueta pequeña (small)
TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: AppTheme.textMuted,
)
```

### Crear Estilos Reutilizables (Opcional)

```dart
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppTheme.textSecondary,
  );
}

// Usar después
Text('Mi Título', style: AppTextStyles.heading1)
```

---

## 📏 Espaciado y Márgenes

### Escala de Espaciado (en píxeles)

```
4px   → SizedBox(height: 4)
8px   → SizedBox(height: 8)
12px  → SizedBox(height: 12)
16px  → SizedBox(height: 16)  ← Predeterminado
24px  → SizedBox(height: 24)
32px  → SizedBox(height: 32)
```

### Padding en Tarjetas y Contenedores

```dart
// Padding interior estándar
padding: const EdgeInsets.all(16)

// Padding con márgenes horizontales
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)

// Márgenes de lista
margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16)
```

---

## 🎯 Patrones de Diseño

### Patrón 1: Listado con Tarjetas Modernas

```dart
ListView.builder(
  itemCount: solicitudes.length,
  itemBuilder: (context, index) {
    final solicitud = solicitudes[index];
    return ModernCard(
      indicatorColor: _getIndicatorColor(solicitud.estado),
      onTap: () => irADetalle(solicitud),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                text: solicitud.estado.toUpperCase(),
                status: solicitud.estado,
              ),
              Text('#${solicitud.id}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(solicitud.cliente,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(solicitud.placa,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  },
)
```

### Patrón 2: Encabezado + Contenido

```dart
Column(
  children: [
    SectionHeader(
      title: 'Servicios Disponibles',
      subtitle: 'Selecciona un servicio',
      actionText: 'Limpiar',
      onActionPressed: () => limpiarFiltros(),
    ),
    SizedBox(height: 12),
    // Contenido aquí
  ],
)
```

### Patrón 3: Filtros con Chips

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      CustomChip(
        label: 'Todas',
        isSelected: filtroSeleccionado == 'todas',
        onTap: () => cambiarFiltro('todas'),
      ),
      SizedBox(width: 8),
      CustomChip(
        label: 'Pendientes',
        icon: Icons.schedule,
        isSelected: filtroSeleccionado == 'pendiente',
        onTap: () => cambiarFiltro('pendiente'),
      ),
      SizedBox(width: 8),
      // Más chips...
    ],
  ),
)
```

---

## 💻 Ejemplos de Uso

### Ejemplo 1: Pantalla de Solicitudes

```dart
import 'package:flutter/material.dart';
import 'package:app_emergencias/theme/app_theme.dart';
import 'package:app_emergencias/theme/custom_widgets.dart';

class SolicitudesScreen extends StatefulWidget {
  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  String filtroSeleccionado = 'todas';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sección de filtros
            SectionHeader(
              title: 'Filtrar por Estado',
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: CustomChip(
                      label: 'Todas',
                      isSelected: filtroSeleccionado == 'todas',
                      onTap: () => setState(() => filtroSeleccionado = 'todas'),
                    ),
                  ),
                  SizedBox(width: 8),
                  CustomChip(
                    label: 'Pendientes',
                    isSelected: filtroSeleccionado == 'pendiente',
                    onTap: () => setState(() => filtroSeleccionado = 'pendiente'),
                  ),
                  SizedBox(width: 8),
                  CustomChip(
                    label: 'Completadas',
                    isSelected: filtroSeleccionado == 'completada',
                    onTap: () => setState(() => filtroSeleccionado = 'completada'),
                  ),
                  SizedBox(width: 16),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Listado de solicitudes
            SectionHeader(
              title: 'Solicitudes Recientes',
              subtitle: 'Últimas 30 días',
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ModernCard(
                  indicatorColor: AppTheme.warning,
                  onTap: () => print('Abrir solicitud $index'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(text: 'Pendiente', status: 'pendiente'),
                          Text('#SOL-1234',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Cliente XYZ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text('Placa: ABC-1234',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Hace 2 horas',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### Ejemplo 2: Pantalla de Detalles con Información Estructurada

```dart
class DetalleServicioScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Servicio')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ModernCard(
              indicatorColor: AppTheme.success,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(text: 'Completada', status: 'completada'),
                      Text('#SVC-5678'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InfoField(
                    label: 'Cliente',
                    value: 'Juan Pérez',
                    icon: Icons.person,
                  ),
                  const Divider(),
                  InfoField(
                    label: 'Vehículo',
                    value: 'Toyota Corolla - ABC-1234',
                    icon: Icons.directions_car,
                  ),
                  const Divider(),
                  InfoField(
                    label: 'Tipo de Servicio',
                    value: 'Cambio de Aceite',
                    icon: Icons.build,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Calificar Servicio',
                      onPressed: () => print('Calificar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔄 Implementación en `main.dart`

Asegúrate de que tu `MaterialApp` use el nuevo tema:

```dart
void main() async {
  // ... inicialización de Firebase, etc.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Emergencias',
      theme: AppTheme.lightTheme,  // ← Usa el nuevo tema
      home: const _InitialScreen(),
      routes: {
        // Tus rutas aquí...
      },
    );
  }
}
```

---

## 🚀 Próximos Pasos

1. ✅ Importa `AppTheme` y los componentes en tus pantallas
2. ✅ Reemplaza los `Card` antiguos con `ModernCard`
3. ✅ Usa `StatusBadge` para estados
4. ✅ Implementa `SectionHeader` en secciones de contenido
5. ✅ Aplica colores de `AppTheme` en textos y fondos
6. ✅ Prueba la aplicación y ajusta espaciados según sea necesario

---

## 📞 Soporte

Para preguntas sobre implementación o nuevos componentes, consulta los archivos:
- `lib/theme/app_theme.dart` - Configuración global
- `lib/theme/custom_widgets.dart` - Componentes reutilizables
