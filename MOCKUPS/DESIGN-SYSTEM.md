# Sistema de Diseño - TEMIS
## Guía de Estilo Visual

---

## 🎨 Paleta de Colores

### Colores Principales

```css
/* Primary - Azul */
--primary-50:  #EFF6FF;
--primary-100: #DBEAFE;
--primary-200: #BFDBFE;
--primary-300: #93C5FD;
--primary-400: #60A5FA;
--primary-500: #3B82F6;  /* Main */
--primary-600: #2563EB;
--primary-700: #1D4ED8;
--primary-800: #1E40AF;
--primary-900: #1E3A8A;

/* Secondary - Púrpura */
--secondary-50:  #FAF5FF;
--secondary-100: #F3E8FF;
--secondary-200: #E9D5FF;
--secondary-300: #D8B4FE;
--secondary-400: #C084FC;
--secondary-500: #A855F7;
--secondary-600: #9333EA;  /* Main */
--secondary-700: #7E22CE;
--secondary-800: #6B21A8;
--secondary-900: #581C87;
```

### Colores Semánticos

```css
/* Success - Verde */
--success-50:  #ECFDF5;
--success-100: #D1FAE5;
--success-500: #10B981;  /* Main */
--success-700: #047857;

/* Warning - Naranja */
--warning-50:  #FFFBEB;
--warning-100: #FEF3C7;
--warning-500: #F59E0B;  /* Main */
--warning-700: #B45309;

/* Danger - Rojo */
--danger-50:  #FEF2F2;
--danger-100: #FEE2E2;
--danger-500: #EF4444;  /* Main */
--danger-700: #B91C1C;

/* Info - Cyan */
--info-50:  #ECFEFF;
--info-100: #CFFAFE;
--info-500: #06B6D4;  /* Main */
--info-700: #0E7490;
```

### Colores Neutrales

```css
/* Grises */
--gray-50:  #F9FAFB;
--gray-100: #F3F4F6;
--gray-200: #E5E7EB;
--gray-300: #D1D5DB;
--gray-400: #9CA3AF;
--gray-500: #6B7280;
--gray-600: #4B5563;
--gray-700: #374151;
--gray-800: #1F2937;
--gray-900: #111827;
--gray-950: #030712;
```

### Prioridades de Tareas

```css
/* Task Priorities */
--priority-low:    #10B981;  /* Verde */
--priority-medium: #F59E0B;  /* Naranja */
--priority-high:   #EF4444;  /* Rojo */
--priority-urgent: #DC2626;  /* Rojo oscuro */
```

---

## 📝 Tipografía

### Familia de Fuentes

**Principal**: Inter (Google Fonts)
- **Weights**: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)
- **Fallback**: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif

### Escala Tipográfica

```css
/* Headings */
--h1: 32px / 40px (Bold)      /* Títulos principales */
--h2: 28px / 36px (Bold)      /* Subtítulos importantes */
--h3: 24px / 32px (SemiBold)  /* Títulos de sección */
--h4: 20px / 28px (SemiBold)  /* Subtítulos */
--h5: 18px / 28px (Medium)    /* Títulos pequeños */
--h6: 16px / 24px (Medium)    /* Encabezados menores */

/* Body */
--body-large:  18px / 28px (Regular)  /* Texto destacado */
--body-normal: 16px / 24px (Regular)  /* Texto principal */
--body-small:  14px / 20px (Regular)  /* Texto secundario */

/* Captions */
--caption-large: 14px / 20px (Medium)   /* Labels */
--caption-small: 12px / 16px (Regular)  /* Metadatos */
--caption-tiny:  10px / 16px (Medium)   /* Badges */
```

### Casos de Uso

| Elemento | Tamaño | Weight | Uso |
|----------|--------|--------|-----|
| Screen Title | 28px | Bold | Título de pantalla |
| Card Title | 18px | SemiBold | Título de card |
| Button Text | 16px | Medium | Texto de botones |
| Input Label | 14px | Medium | Labels de formulario |
| Body Text | 16px | Regular | Contenido principal |
| Caption | 12px | Regular | Información secundaria |

---

## 📐 Espaciado

### Sistema de 8px Grid

```css
--spacing-0: 0px;
--spacing-1: 4px;   /* Mínimo */
--spacing-2: 8px;   /* Pequeño */
--spacing-3: 12px;
--spacing-4: 16px;  /* Base */
--spacing-5: 20px;
--spacing-6: 24px;  /* Medio */
--spacing-8: 32px;  /* Grande */
--spacing-10: 40px;
--spacing-12: 48px; /* Extra grande */
--spacing-16: 64px;
--spacing-20: 80px;
```

### Márgenes Comunes

- **Margen de pantalla**: 16px (izq/der)
- **Entre elementos**: 12px
- **Entre secciones**: 24px
- **Padding de cards**: 16px
- **Padding de botones**: 12px (vertical), 24px (horizontal)

---

## 🔲 Componentes

### Botones

#### Primary Button
```
Background: --primary-500
Text: White
Height: 48px
Border Radius: 8px
Padding: 12px 24px
Font: 16px Medium
Shadow: 0 2px 8px rgba(59, 130, 246, 0.3)

States:
- Hover: --primary-600
- Active: --primary-700
- Disabled: --gray-300 (opacity 0.5)
```

#### Secondary Button
```
Background: Transparent
Border: 2px solid --primary-500
Text: --primary-500
Height: 48px
Border Radius: 8px
Padding: 12px 24px
Font: 16px Medium

States:
- Hover: --primary-50 background
- Active: --primary-100 background
- Disabled: --gray-300 (opacity 0.5)
```

#### Text Button
```
Background: Transparent
Text: --primary-500
Height: 40px
Padding: 8px 16px
Font: 14px Medium

States:
- Hover: --primary-50 background
- Active: --primary-100 background
```

### Input Fields

```
Height: 48px
Border: 1px solid --gray-300
Border Radius: 8px
Padding: 12px 16px
Font: 16px Regular
Background: White

States:
- Focus: Border --primary-500, Shadow 0 0 0 3px rgba(59, 130, 246, 0.1)
- Error: Border --danger-500
- Disabled: Background --gray-100

With Icon:
- Padding Left: 44px (si tiene icono izquierdo)
- Padding Right: 44px (si tiene icono derecho)
```

### Cards

```
Background: White
Border Radius: 12px
Padding: 16px
Shadow: 0 1px 3px rgba(0, 0, 0, 0.1)
Border: 1px solid --gray-200

Variants:
- Elevated: Shadow 0 4px 12px rgba(0, 0, 0, 0.1)
- Outlined: Border 2px, no shadow
- Flat: No shadow, no border
```

### Badges

```
Height: 24px
Border Radius: 12px (pill)
Padding: 4px 12px
Font: 12px Medium

Colors:
- Success: Background --success-100, Text --success-700
- Warning: Background --warning-100, Text --warning-700
- Danger: Background --danger-100, Text --danger-700
- Info: Background --info-100, Text --info-700
- Default: Background --gray-100, Text --gray-700
```

### Chips (Tags)

```
Height: 32px
Border Radius: 16px
Padding: 6px 12px
Font: 14px Medium
Background: --gray-100
Text: --gray-700

With Close Icon:
- Padding Right: 8px
- Icon: 16x16px, --gray-500

Selected:
- Background: --primary-100
- Text: --primary-700
```

---

## 🎯 Iconos

### Sistema de Iconos

**Librería**: Heroicons, Feather Icons, o custom
**Formatos**: SVG (preferido), PNG @2x @3x

### Tamaños

```css
--icon-xs: 16x16px  /* Inline con texto */
--icon-sm: 20x20px  /* Botones pequeños */
--icon-md: 24x24px  /* Default */
--icon-lg: 32x32px  /* Encabezados */
--icon-xl: 48x48px  /* Ilustraciones */
```

### Colores de Iconos

- **Default**: --gray-600
- **Primary**: --primary-500
- **Success**: --success-500
- **Warning**: --warning-500
- **Danger**: --danger-500
- **On Dark**: White

---

## 🌓 Modo Oscuro

### Paleta Dark Mode

```css
/* Backgrounds */
--dark-bg-primary:   #0F1419;
--dark-bg-secondary: #1A1F29;
--dark-bg-tertiary:  #252D3A;

/* Text */
--dark-text-primary:   #FFFFFF;
--dark-text-secondary: #9CA3AF;
--dark-text-tertiary:  #6B7280;

/* Borders */
--dark-border: #374151;

/* Colores principales ajustados */
--dark-primary:   #60A5FA;  /* Más claro que light mode */
--dark-secondary: #C084FC;
--dark-success:   #34D399;
--dark-warning:   #FBBF24;
--dark-danger:    #F87171;
```

### Componentes en Dark Mode

- **Cards**: Background --dark-bg-secondary, Border --dark-border
- **Inputs**: Background --dark-bg-tertiary, Border --dark-border
- **Buttons Primary**: Mismo color, ajustar opacidad si necesario
- **Text**: Invertir jerarquía de grises

---

## 📱 Componentes Móviles Nativos

### Navigation Bar (iOS/Android)

```
iOS:
- Height: 44px + Safe Area (aprox 88px total)
- Background: Translucent white
- Title: 17px SemiBold, Centered
- Buttons: 17px Regular

Android (Material):
- Height: 56px
- Background: --primary-500
- Title: 20px Medium, Left aligned
- Icons: 24x24px
```

### Bottom Navigation

```
Height: 56px + Safe Area (aprox 80px total)
Items: 3-5 items
Active:
  - Icon: --primary-500
  - Label: 12px Medium, --primary-500
Inactive:
  - Icon: --gray-500
  - Label: 12px Regular, --gray-500
```

### Floating Action Button (FAB)

```
Size: 56x56px
Border Radius: 28px (circle)
Background: --primary-500
Icon: 24x24px, White
Shadow: 0 4px 12px rgba(59, 130, 246, 0.4)

Position:
- Bottom: 16px + Safe Area
- Right: 16px
```

### List Items

```
Height: 56px (mínimo)
Padding: 16px
Divider: 1px solid --gray-200

Structure:
- Leading: Icon/Avatar (40x40px)
- Title: 16px Medium
- Subtitle: 14px Regular, --gray-600
- Trailing: Icon/Badge/Chevron
```

---

## ✨ Efectos y Animaciones

### Sombras

```css
/* Elevaciones */
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
--shadow-md: 0 2px 8px rgba(0, 0, 0, 0.1);
--shadow-lg: 0 4px 16px rgba(0, 0, 0, 0.15);
--shadow-xl: 0 8px 24px rgba(0, 0, 0, 0.2);
```

### Border Radius

```css
--radius-sm: 4px;   /* Inputs */
--radius-md: 8px;   /* Botones, Cards */
--radius-lg: 12px;  /* Cards grandes */
--radius-xl: 16px;  /* Modals */
--radius-full: 9999px; /* Pills, círculos */
```

### Duraciones de Animación

```css
--duration-fast: 150ms;    /* Hover, pequeños cambios */
--duration-normal: 300ms;  /* Default */
--duration-slow: 500ms;    /* Transiciones grandes */

/* Easing */
--ease-in: cubic-bezier(0.4, 0, 1, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
```

---

## 📏 Breakpoints

### Responsive Breakpoints

```css
--mobile-sm: 320px;   /* iPhone SE */
--mobile: 375px;      /* iPhone 12/13 */
--mobile-lg: 414px;   /* iPhone Plus */
--tablet: 768px;      /* iPad Mini */
--tablet-lg: 1024px;  /* iPad Pro */
--desktop: 1280px;    /* Desktop */
```

---

## ♿ Accesibilidad

### Contraste Mínimo (WCAG AA)

- **Texto normal**: 4.5:1
- **Texto grande (18px+)**: 3:1
- **Componentes UI**: 3:1

### Touch Targets

- **Mínimo**: 44x44px (iOS), 48x48px (Android)
- **Recomendado**: 48x48px para ambos
- **Espaciado entre targets**: 8px mínimo

### Estados de Foco

```
Keyboard Focus:
- Outline: 2px solid --primary-500
- Offset: 2px
- Border Radius: Match element
```

---

## 📦 Exportación para Desarrollo

### Assets para iOS

```
AppIcon: 1024x1024px
LaunchScreen: 375x812pt (@1x, @2x, @3x)
TabBar Icons: 25x25pt (@1x, @2x, @3x)
Images: @1x, @2x, @3x
```

### Assets para Android

```
AppIcon: 512x512px
LaunchScreen: xxxhdpi (1080x1920px)
Icons: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
Images: drawable-mdpi hasta drawable-xxxhdpi
```

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.0.0
