# MOCKUPS - TEMIS App Móvil
## Diseños de Interfaz de Usuario

---

## 📱 Información General

**Plataforma**: iOS y Android
**Resolución Base**: 375x812 (iPhone X/11/12/13)
**Formato**: PNG (2x y 3x para Retina)
**Herramientas Sugeridas**: Figma, Adobe XD, Sketch

---

## 🎨 Guía de Diseño

### Colores Principales
```
Primary:     #3B82F6 (Azul)
Secondary:   #8B5CF6 (Púrpura)
Success:     #10B981 (Verde)
Warning:     #F59E0B (Naranja)
Danger:      #EF4444 (Rojo)
Dark:        #1F2937 (Gris Oscuro)
Light:       #F9FAFB (Gris Claro)
```

### Tipografía
- **Encabezados**: Inter Bold, 24-32px
- **Subtítulos**: Inter SemiBold, 16-20px
- **Cuerpo**: Inter Regular, 14-16px
- **Pequeño**: Inter Regular, 12-14px

---

## 📂 Estructura de Carpetas

### 01-AUTH (Autenticación)
Pantallas de inicio de sesión y registro.

**Mockups Requeridos**:
- [ ] `01-splash-screen.png` - Pantalla de inicio con logo
- [ ] `02-login.png` - Inicio de sesión
- [ ] `03-register.png` - Registro de usuario
- [ ] `04-forgot-password.png` - Recuperar contraseña
- [ ] `05-reset-password.png` - Nueva contraseña
- [ ] `06-email-verification.png` - Verificar email

**Componentes**:
- Logo TEMIS
- Campos de formulario (email, password)
- Botones primarios y secundarios
- Links de navegación
- Mensajes de error/éxito

---

### 02-ONBOARDING (Introducción)
Pantallas de bienvenida y tutorial inicial.

**Mockups Requeridos**:
- [ ] `01-welcome.png` - Bienvenida con ilustración
- [ ] `02-feature-tasks.png` - Explicación: Gestión de Tareas
- [ ] `03-feature-passwords.png` - Explicación: Gestor de Contraseñas
- [ ] `04-feature-finance.png` - Explicación: Finanzas Personales
- [ ] `05-feature-ai.png` - Explicación: Asistente IA
- [ ] `06-select-plan.png` - Selección de plan de suscripción
- [ ] `07-permissions.png` - Solicitud de permisos (notificaciones, micrófono)

**Componentes**:
- Ilustraciones SVG
- Indicadores de progreso (dots)
- Botones "Siguiente" y "Omitir"
- Cards de planes

---

### 03-TAREAS (Gestión de Tareas)
Pantallas del módulo de tareas y calendario.

**Mockups Requeridos**:
- [ ] `01-dashboard-tasks.png` - Dashboard principal de tareas
- [ ] `02-task-list.png` - Lista de tareas con filtros
- [ ] `03-task-detail.png` - Detalle de tarea
- [ ] `04-create-task.png` - Crear nueva tarea
- [ ] `05-edit-task.png` - Editar tarea
- [ ] `06-voice-task-recording.png` - Grabar tarea por voz
- [ ] `07-voice-task-preview.png` - Vista previa de tarea por voz
- [ ] `08-calendar-view.png` - Vista de calendario
- [ ] `09-task-filters.png` - Filtros y búsqueda
- [ ] `10-tags-management.png` - Gestión de etiquetas
- [ ] `11-task-completed.png` - Confirmación de completado

**Componentes**:
- Cards de tareas con prioridad (colores)
- Checkboxes
- Tags/chips
- FAB (Floating Action Button) para crear
- Modal de filtros
- Calendario
- Badge de prioridad (urgent, high, medium, low)
- Botón de micrófono para voz

---

### 04-PASSWORDS (Gestor de Contraseñas)
Pantallas del módulo de contraseñas seguras.

**Mockups Requeridos**:
- [ ] `01-passwords-list.png` - Lista de contraseñas guardadas
- [ ] `02-password-detail.png` - Detalle de contraseña (oculta)
- [ ] `03-password-revealed.png` - Contraseña visible
- [ ] `04-add-password.png` - Añadir nueva contraseña
- [ ] `05-edit-password.png` - Editar contraseña
- [ ] `06-password-generator.png` - Generador de contraseñas
- [ ] `07-password-categories.png` - Categorías (banco, wifi, etc.)
- [ ] `08-password-security-audit.png` - Auditoría de seguridad (Premium)
- [ ] `09-password-search.png` - Búsqueda de contraseñas
- [ ] `10-biometric-unlock.png` - Desbloqueo biométrico

**Componentes**:
- Cards de contraseñas con iconos
- Categorías con chips
- Botón "Mostrar/Ocultar"
- Generador con opciones (longitud, caracteres)
- Indicador de fortaleza
- Lista de recomendaciones de seguridad
- Shield icon para seguridad

---

### 05-FINANZAS (Finanzas Personales)
Pantallas del módulo de gestión financiera.

**Mockups Requeridos**:
- [ ] `01-finance-dashboard.png` - Dashboard financiero
- [ ] `02-transactions-list.png` - Lista de transacciones
- [ ] `03-add-transaction.png` - Añadir transacción manual
- [ ] `04-voice-transaction-recording.png` - Grabar transacción por voz
- [ ] `05-voice-transaction-preview.png` - Vista previa de transacción por voz
- [ ] `06-transaction-detail.png` - Detalle de transacción
- [ ] `07-categories-management.png` - Gestión de categorías
- [ ] `08-budgets-list.png` - Lista de presupuestos
- [ ] `09-budget-detail.png` - Detalle de presupuesto con progreso
- [ ] `10-create-budget.png` - Crear presupuesto
- [ ] `11-reports-monthly.png` - Reporte mensual
- [ ] `12-charts-expenses.png` - Gráficos de gastos por categoría
- [ ] `13-sms-capture-setup.png` - Configurar captura SMS (Premium)

**Componentes**:
- Cards de balance (ingresos, gastos, saldo)
- Lista de transacciones con iconos
- Gráficos (pie chart, bar chart, line chart)
- Progress bars para presupuestos
- Categorías con emojis
- FAB para añadir transacción
- Filtros por fecha y categoría
- Badge de tipo (ingreso/gasto)
- Botón de micrófono para voz

---

### 06-IA-ASISTENTE (Asistente Inteligente)
Pantallas del módulo de IA con Bedrock.

**Mockups Requeridos**:
- [ ] `01-ai-chat-empty.png` - Chat vacío con sugerencias
- [ ] `02-ai-chat-conversation.png` - Conversación activa
- [ ] `03-ai-insights-dashboard.png` - Dashboard de insights
- [ ] `04-ai-insight-detail.png` - Detalle de insight
- [ ] `05-ai-predictions.png` - Predicciones financieras (Premium)
- [ ] `06-ai-weekly-summary.png` - Resumen semanal inteligente
- [ ] `07-ai-quota-usage.png` - Uso de cuota de IA
- [ ] `08-ai-upgrade-prompt.png` - Prompt para upgrade (cuota agotada)

**Componentes**:
- Chat bubbles (usuario vs asistente)
- Avatar del asistente IA
- Input de chat con botón enviar
- Sugerencias de preguntas
- Cards de insights con severidad (colores)
- Gráficos de predicciones
- Progress bar de cuota
- Botón "Upgrade to Premium"
- Loading states con animación

---

### 07-AI-MEMORY (Tu Segunda Memoria)
Pantallas del módulo AI Memory - captura y búsqueda inteligente de memorias.

**Mockups Requeridos**:
- [ ] `01-memory-home.png` - Home con lista de memorias recientes
- [ ] `02-memory-create-menu.png` - Menú de opciones de captura
- [ ] `03-record-conversation.png` - Grabar conversación (audio)
- [ ] `04-record-conversation-playing.png` - Reproduciendo grabación antes de guardar
- [ ] `05-capture-photo.png` - Capturar foto con cámara
- [ ] `06-photo-preview.png` - Vista previa de foto con OCR
- [ ] `07-upload-document.png` - Subir documento
- [ ] `08-document-processing.png` - Procesando documento (loading)
- [ ] `09-email-instructions.png` - Instrucciones para reenviar emails
- [ ] `10-record-voice-note.png` - Grabar nota de voz rápida
- [ ] `11-memory-detail.png` - Detalle de memoria con transcripción/OCR
- [ ] `12-memory-edit.png` - Editar memoria (título, etiquetas)
- [ ] `13-search-ai-empty.png` - Búsqueda IA vacía con ejemplos
- [ ] `14-search-ai-results.png` - Resultados de búsqueda semántica
- [ ] `15-search-text.png` - Búsqueda por texto tradicional
- [ ] `16-storage-dashboard.png` - Dashboard de almacenamiento usado
- [ ] `17-weekly-insight.png` - Resumen semanal de memorias
- [ ] `18-memory-tags.png` - Gestión de etiquetas
- [ ] `19-favorites-list.png` - Lista de memorias favoritas
- [ ] `20-archived-memories.png` - Memorias archivadas
- [ ] `21-memory-share.png` - Compartir memoria (exportar)
- [ ] `22-quota-exceeded.png` - Alerta de cuota excedida
- [ ] `23-storage-full.png` - Alerta de almacenamiento lleno

**Componentes**:
- Cards de memoria con tipo (icono: 🎙️ audio, 📷 foto, 📄 documento, ✉️ email, 🎤 voz)
- FAB con menú de acciones (grabar, foto, documento, voz)
- Player de audio con waveform
- Visor de imágenes con zoom
- Visor de PDFs
- Chips de etiquetas con colores
- Badge de estado (processing, ready, failed)
- Búsqueda con sugerencias de IA
- Cards de resultados con relevancia score
- Progress bar de storage
- Desglose por tipo de memoria (gráfico)
- Timeline de memorias
- Botón de favorito (estrella)
- Botón de archivar
- Botón de compartir
- Entidades extraídas (personas, lugares, fechas) como pills
- Resumen generado por IA
- Loading states con animación de procesamiento
- Empty states por tipo (sin conversaciones, sin fotos, etc.)

---

### 08-CONFIGURACION (Configuración)
Pantallas de ajustes y perfil del usuario.

**Mockups Requeridos**:
- [ ] `01-profile.png` - Perfil de usuario
- [ ] `02-edit-profile.png` - Editar perfil
- [ ] `03-change-password.png` - Cambiar contraseña
- [ ] `04-settings-general.png` - Configuración general
- [ ] `05-settings-notifications.png` - Configuración de notificaciones
- [ ] `06-settings-security.png` - Seguridad y privacidad
- [ ] `07-settings-appearance.png` - Apariencia (tema, idioma)
- [ ] `08-about.png` - Acerca de TEMIS
- [ ] `09-help-support.png` - Ayuda y soporte

**Componentes**:
- Avatar editable
- Lista de opciones con iconos
- Switches (toggles)
- Dropdowns
- Botón "Cerrar sesión"
- Version number
- Links de contacto

---

### 08-SUSCRIPCIONES (Planes y Pagos)
Pantallas de gestión de suscripción y pagos con Wompi.

**Mockups Requeridos**:
- [ ] `01-subscription-current.png` - Plan actual con detalles
- [ ] `02-plans-comparison.png` - Comparación de planes
- [ ] `03-plan-features.png` - Detalle de características por plan
- [ ] `04-change-plan.png` - Cambiar de plan
- [ ] `05-checkout-wompi.png` - Pantalla de pago con Wompi
- [ ] `06-payment-methods.png` - Métodos de pago guardados
- [ ] `07-add-payment-method.png` - Añadir tarjeta
- [ ] `08-payment-history.png` - Historial de pagos
- [ ] `09-invoice-detail.png` - Detalle de factura
- [ ] `10-subscription-expired.png` - Notificación de suscripción vencida
- [ ] `11-subscription-expiring-soon.png` - Alerta 5 días antes
- [ ] `12-upgrade-success.png` - Confirmación de upgrade
- [ ] `13-cancel-subscription.png` - Cancelar suscripción

**Componentes**:
- Cards de planes con precios
- Tabla de comparación
- Lista de features con checkmarks
- Badges de plan actual
- Cards de tarjetas guardadas
- Input de tarjeta (enmascarado)
- Selector de ciclo (mensual/anual)
- Botones de acción (Upgrade, Cancelar)
- Alert banner (vencimiento)
- Lista de facturas con descarga

---

## 🎯 Estados y Componentes Comunes

### Estados de la Aplicación
- [ ] `loading-spinner.png` - Indicador de carga
- [ ] `empty-state-tasks.png` - Estado vacío: tareas
- [ ] `empty-state-passwords.png` - Estado vacío: contraseñas
- [ ] `empty-state-transactions.png` - Estado vacío: transacciones
- [ ] `empty-state-memories.png` - Estado vacío: memorias
- [ ] `error-screen.png` - Pantalla de error
- [ ] `no-internet.png` - Sin conexión
- [ ] `maintenance.png` - Mantenimiento

### Componentes Reutilizables
- [ ] `navigation-bar.png` - Barra de navegación inferior
- [ ] `header-bar.png` - Barra superior
- [ ] `search-bar.png` - Barra de búsqueda
- [ ] `filter-modal.png` - Modal de filtros
- [ ] `date-picker.png` - Selector de fecha
- [ ] `confirmation-dialog.png` - Diálogo de confirmación
- [ ] `success-toast.png` - Toast de éxito
- [ ] `error-toast.png` - Toast de error
- [ ] `bottom-sheet.png` - Bottom sheet
- [ ] `pull-to-refresh.png` - Pull to refresh

---

## 📋 Checklist de Progreso

### Módulos Completados
- [ ] 01-AUTH (0/6)
- [ ] 02-ONBOARDING (0/7)
- [ ] 03-TAREAS (0/11)
- [ ] 04-PASSWORDS (0/10)
- [ ] 05-FINANZAS (0/13)
- [ ] 06-IA-ASISTENTE (0/8)
- [ ] 07-AI-MEMORY (0/23)
- [ ] 08-CONFIGURACION (0/9)
- [ ] 09-SUSCRIPCIONES (0/13)

**Total**: 0/100 pantallas

---

## 🚀 Próximos Pasos

1. **Fase 1**: Crear mockups de flujo principal (AUTH + ONBOARDING + TAREAS)
2. **Fase 2**: Mockups de módulos secundarios (PASSWORDS + FINANZAS)
3. **Fase 3**: Mockups de IA y suscripciones
4. **Fase 4**: Estados y componentes reutilizables
5. **Fase 5**: Variaciones (tema oscuro, diferentes estados)

---

## 📝 Notas de Diseño

### Accesibilidad
- Contraste mínimo WCAG AA (4.5:1)
- Tamaño mínimo de touch targets: 44x44px
- Soporte para tamaños de texto grandes

### Responsive
- Diseñar para múltiples tamaños de pantalla
- Considerar orientación landscape
- Safe areas para iPhone (notch)

### Dark Mode
- Crear versión oscura de cada pantalla
- Usar colores apropiados para ambos temas

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-08-14
**Versión**: 1.1.0

## Changelog

### v1.1.0 (2026-08-14)
- ✅ Añadido módulo 07-AI-MEMORY con 23 pantallas
- ✅ Actualizado total de pantallas: 100 (antes 77)
- ✅ Añadido empty state para memorias
- ✅ Renumeración de módulos (CONFIGURACION pasa a 08, SUSCRIPCIONES a 09)

### v1.0.0 (2026-07-12)
- Versión inicial con 77 pantallas en 8 módulos
