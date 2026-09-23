# Especificaciones de Exportación de Mockups

---

## 📐 Dimensiones de Pantalla

### iOS

| Device | Points | Pixels @2x | Pixels @3x |
|--------|--------|------------|------------|
| iPhone SE (2020) | 375 x 667 | 750 x 1334 | - |
| iPhone 12/13/14 Mini | 375 x 812 | 750 x 1624 | 1125 x 2436 |
| iPhone 12/13/14/15 | 390 x 844 | 780 x 1688 | 1170 x 2532 |
| iPhone 12/13/14/15 Pro Max | 428 x 926 | 856 x 1852 | 1284 x 2778 |
| iPhone 15 Pro Max | 430 x 932 | 860 x 1864 | 1290 x 2796 |
| iPad Mini | 744 x 1133 | 1488 x 2266 | 2232 x 3398 |
| iPad Pro 11" | 834 x 1194 | 1668 x 2388 | - |

### Android

| Device | Points | Pixels |
|--------|--------|--------|
| Small (Nexus 5) | 360 x 640 | 1080 x 1920 |
| Medium (Pixel 5) | 393 x 851 | 1080 x 2340 |
| Large (Pixel 6 Pro) | 412 x 915 | 1440 x 3120 |
| Tablet (Nexus 9) | 768 x 1024 | 1536 x 2048 |

### **Resolución Base Recomendada**
📱 **375 x 812 pts** (iPhone X/11/12/13 - más común)

---

## 🎨 Formato de Exportación

### Para Desarrollo
```
Formato: PNG
Compresión: Sin pérdida
Fondo: Transparente (cuando sea posible)
Color Space: sRGB
```

### Múltiples Resoluciones
Exportar en las siguientes escalas:
- **@1x**: 375 x 812 px (base)
- **@2x**: 750 x 1624 px (Retina)
- **@3x**: 1125 x 2436 px (Super Retina)

### Nomenclatura de Archivos
```
# Formato
{numero}-{nombre-descriptivo}@{scale}.png

# Ejemplos
01-splash-screen@1x.png
01-splash-screen@2x.png
01-splash-screen@3x.png

02-login@1x.png
02-login@2x.png
02-login@3x.png
```

---

## 📦 Estructura de Exportación

```
MOCKUPS/
├── 01-AUTH/
│   ├── 01-splash-screen@1x.png
│   ├── 01-splash-screen@2x.png
│   ├── 01-splash-screen@3x.png
│   ├── 02-login@1x.png
│   ├── 02-login@2x.png
│   ├── 02-login@3x.png
│   └── ...
├── 02-ONBOARDING/
│   └── ...
└── ...
```

---

## 🎯 Assets a Exportar

### Mockups de Pantallas Completas
- **Formato**: PNG
- **Escalas**: @1x, @2x, @3x
- **Uso**: Presentaciones, documentación, testing

### Componentes Individuales
- **Formato**: SVG (preferido) o PNG
- **Escalas**: @1x, @2x, @3x (si es PNG)
- **Uso**: Desarrollo, librería de componentes

### Iconos
- **Formato**: SVG (preferido) o PNG
- **Tamaños**: 24x24, 32x32, 48x48, 64x64 pts
- **Escalas**: @1x, @2x, @3x (si es PNG)

### Ilustraciones
- **Formato**: SVG (preferido) o PNG
- **Escalas**: @2x, @3x
- **Optimización**: Comprimir con TinyPNG o similar

---

## 🛠️ Herramientas de Exportación

### Figma
```javascript
// Plugin: "Figma to Code"
// Export settings:
Format: PNG
Scale: 1x, 2x, 3x
Suffix: @1x, @2x, @3x
```

### Adobe XD
```
File → Export → Batch Export
Format: PNG
Design: iOS
Asset: Multiple
Scales: 1x, 2x, 3x
```

### Sketch
```
Export → iOS App Icon
Format: PNG
Scales: @1x, @2x, @3x
Naming: Include suffix
```

---

## ✅ Checklist Pre-Exportación

### Verificación de Diseño
- [ ] Todos los textos son legibles (min 14px en @1x)
- [ ] Contraste cumple WCAG AA (4.5:1)
- [ ] Elementos interactivos mínimo 44x44 pts
- [ ] Safe areas respetadas (especialmente top/bottom)
- [ ] Consistencia de colores según guía de diseño
- [ ] Tipografía correcta (Inter)
- [ ] Iconos bien alineados

### Verificación Técnica
- [ ] Artboards con nombres descriptivos
- [ ] Capas organizadas y nombradas
- [ ] Elementos innecesarios eliminados
- [ ] Textos convertidos a outlines (si es necesario)
- [ ] Colores en formato sRGB
- [ ] Sin elementos fuera del artboard

### Exportación
- [ ] Mockups exportados en @1x, @2x, @3x
- [ ] Nomenclatura correcta de archivos
- [ ] Archivos en carpetas correctas
- [ ] Tamaño de archivos optimizado (<500KB por mockup)
- [ ] Versión de diseño guardada en archivo fuente

---

## 📊 Tamaños de Archivo Recomendados

| Tipo | @1x | @2x | @3x |
|------|-----|-----|-----|
| Mockup Simple | <200 KB | <400 KB | <600 KB |
| Mockup Complejo | <300 KB | <600 KB | <900 KB |
| Con Ilustraciones | <400 KB | <800 KB | <1.2 MB |

**Optimización**: Usar TinyPNG, ImageOptim o similar para reducir tamaño sin pérdida visible.

---

## 🎨 Color Profiles

### Para Web/App
- **Color Space**: sRGB
- **Color Profile**: sRGB IEC61966-2.1

### Para Impresión (si aplica)
- **Color Space**: CMYK
- **Color Profile**: Coated FOGRA39

---

## 📝 Metadatos de Archivo

Incluir en el nombre del archivo o en un archivo acompañante:
- Versión del diseño
- Fecha de última modificación
- Plataforma target (iOS/Android/Both)
- Estado (WIP, Review, Approved)

Ejemplo:
```
01-login@2x-v1.2-iOS-APPROVED.png
```

---

## 🔄 Versionado

### Sistema de Versiones
```
v1.0 - Versión inicial
v1.1 - Cambios menores (colores, textos)
v2.0 - Cambios mayores (layout, componentes)
```

### Control de Versiones
Mantener historial en:
- Figma: Auto-versioning
- Archivo: `CHANGELOG-MOCKUPS.md`
- Git: Commits descriptivos

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.0.0
