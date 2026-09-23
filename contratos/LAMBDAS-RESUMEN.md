# Resumen de Lambdas - TEMIS
## Arquitectura de Microservicios AWS Lambda

---

## 📋 Información General

**Total de Lambdas**: 16 funciones serverless
**Arquitectura**: Microservicios independientes
**Base de Datos**: PostgreSQL RDS compartido con RLS
**Autenticación**: JWT RS256 (sin AWS Cognito)
**Runtime**: Node.js 20.x
**Infraestructura**: AWS Lambda + API Gateway + RDS + S3 + Bedrock + Transcribe

---

## 1. lambda-auth
**Contrato**: `TEMIS_CONTRATO_AUTH_V1.0.yaml`

### Propósito
Gestión completa de autenticación y autorización de usuarios sin AWS Cognito.

### Endpoints Principales
- `POST /auth/register` - Registro de nuevos usuarios
- `POST /auth/login` - Inicio de sesión
- `POST /auth/refresh` - Renovación de access token
- `POST /auth/logout` - Cierre de sesión
- `POST /auth/forgot-password` - Solicitud de reset de contraseña
- `POST /auth/reset-password` - Confirmación de reset con token
- `POST /auth/verify-email` - Verificación de email

### Responsabilidades
- Registro de usuarios con validación de email único
- Autenticación con bcrypt para passwords
- Generación de JWT access tokens (RS256, 15 min)
- Generación de refresh tokens (7 días)
- Gestión de tokens de verificación de email
- Gestión de tokens de reset de contraseña
- Creación automática de organization para nuevos usuarios
- Almacenamiento de refresh tokens en DB
- Revocación de tokens en logout

### Integraciones
- PostgreSQL: Tabla `users`, `organizations`, `refresh_tokens`
- AWS SES: Envío de emails de verificación y reset
- Parameter Store: Claves RSA pública/privada para JWT

### Consideraciones Especiales
- No exponer información sensible en errores (no indicar si email existe)
- Rate limiting estricto en login (3 intentos/5 min)
- Tokens de reset expiran en 1 hora
- Refresh tokens tienen rotación automática
- Audit logs de todos los eventos de autenticación

---

## 2. lambda-tasks
**Contrato**: `TEMIS_CONTRATO_TASKS_V1.0.yaml`

### Propósito
Gestión completa del módulo de tareas (TODO list) con funcionalidades avanzadas.

### Endpoints Principales
- `GET /tasks` - Listar tareas con filtros y paginación
- `POST /tasks` - Crear nueva tarea
- `GET /tasks/{taskId}` - Obtener tarea por ID
- `PUT /tasks/{taskId}` - Actualizar tarea completa
- `PATCH /tasks/{taskId}` - Actualizar campos específicos
- `DELETE /tasks/{taskId}` - Eliminar tarea (soft delete)
- `POST /tasks/{taskId}/complete` - Marcar como completada
- `POST /tasks/{taskId}/uncomplete` - Marcar como pendiente
- `GET /tasks/stats` - Estadísticas de tareas

### Responsabilidades
- CRUD completo de tareas con RLS
- Filtrado por estado, prioridad, categoría, etiquetas, fecha
- Búsqueda full-text en título y descripción
- Ordenamiento y paginación
- Asociación con categorías (1:1)
- Asociación con etiquetas (N:M)
- Asociación con recordatorios (1:N)
- Tracking de completed_at automático
- Generación de estadísticas y métricas
- Validación de límites según plan de suscripción

### Integraciones
- PostgreSQL: Tabla `tasks`, `task_tags`
- lambda-categories: Validación de categorías
- lambda-tags: Validación de etiquetas
- lambda-reminders: Creación/gestión de recordatorios asociados
- lambda-voice: Recibe tareas creadas por voz

### Consideraciones Especiales
- Suscripción expirada: Solo lectura (no crear/editar/eliminar)
- Límites por plan: Free (50), Basic (500), Pro (10000), Premium (ilimitado)
- Soft delete: `deleted_at IS NULL` en queries
- Campos calculados: `category_name`, `tags[]` (denormalizados para UI)

---

## 3. lambda-passwords
**Contrato**: `TEMIS_CONTRATO_PASSWORDS_V1.0.yaml`

### Propósito
Gestor de contraseñas seguro con encriptación AES-256-GCM.

### Endpoints Principales
- `GET /passwords` - Listar contraseñas con filtros
- `POST /passwords` - Crear nueva contraseña
- `GET /passwords/{passwordId}` - Obtener contraseña (desencriptada)
- `PUT /passwords/{passwordId}` - Actualizar contraseña
- `PATCH /passwords/{passwordId}` - Actualizar campos específicos
- `DELETE /passwords/{passwordId}` - Eliminar contraseña (soft delete)
- `GET /passwords/{passwordId}/history` - Historial de cambios
- `POST /passwords/generate` - Generar contraseña segura
- `POST /passwords/check-strength` - Analizar fortaleza

### Responsabilidades
- Almacenamiento seguro con AES-256-GCM
- Encriptación/desencriptación con clave maestra única por usuario
- Generación de contraseñas aleatorias criptográficamente seguras
- Análisis de fortaleza con múltiples criterios
- Historial de cambios de contraseña
- Tracking de acceso (last_accessed_at, access_count)
- Filtrado y búsqueda (encriptado server-side)
- Asociación con categorías y etiquetas

### Integraciones
- PostgreSQL: Tabla `passwords`, `password_history`
- Node.js crypto: AES-256-GCM
- Parameter Store: Claves maestras por usuario (o derivadas de user secret)

### Consideraciones Especiales
- NUNCA almacenar contraseñas en texto plano
- Siempre usar HTTPS (TLS 1.3)
- Rate limiting estricto en obtener contraseña
- Audit logs de todos los accesos
- Contraseña desencriptada solo en memoria, nunca en logs
- Análisis de fortaleza: longitud, entropía, caracteres, diccionario
- Límites por plan: Free (10), Basic (100), Pro (1000), Premium (ilimitado)

---

## 4. lambda-transactions
**Contrato**: `TEMIS_CONTRATO_TRANSACTIONS_V1.0.yaml`

### Propósito
Gestión de transacciones financieras (ingresos, gastos, transferencias) con análisis avanzado.

### Endpoints Principales
- `GET /transactions` - Listar transacciones con filtros
- `POST /transactions` - Crear transacción
- `GET /transactions/{transactionId}` - Obtener por ID
- `PUT /transactions/{transactionId}` - Actualizar
- `PATCH /transactions/{transactionId}` - Actualizar parcial
- `DELETE /transactions/{transactionId}` - Eliminar
- `GET /transactions/dashboard` - Dashboard financiero
- `GET /transactions/summary` - Resumen por período
- `GET /transactions/by-category` - Agrupación por categoría
- `POST /transactions/voice` - Crear por voz

### Responsabilidades
- CRUD de transacciones (income, expense, transfer)
- Gestión de montos y conversión de monedas
- Tracking de fechas y descripción
- Asociación con cuentas (account_id)
- Asociación con categorías y etiquetas
- Adjuntar comprobantes en S3
- Geolocalización de transacciones
- Transacciones recurrentes
- Generación de dashboards con gráficas
- Resúmenes y reportes por período
- Integración con entrada por voz
- Actualización de balances de cuentas
- Validación contra presupuestos

### Integraciones
- PostgreSQL: Tabla `transactions`, `accounts`
- lambda-voice: Recibe transacciones creadas por voz
- lambda-categories: Validación de categorías
- lambda-budgets: Validación y alertas de presupuesto
- S3: Almacenamiento de comprobantes (recibos, facturas)
- Amazon Bedrock: Análisis de texto en comprobantes (OCR futuro)

### Consideraciones Especiales
- Transferencias: Crean 2 movimientos (salida y entrada)
- Actualización de balance: Trigger o lógica en lambda
- Montos en centavos para evitar problemas de float
- Suscripción expirada: Solo lectura
- Validación de presupuesto: Alertar si se excede
- Límites por plan: Free (100), Basic (1000), Pro (10000), Premium (ilimitado)

---

## 5. lambda-subscriptions
**Contrato**: `TEMIS_CONTRATO_SUBSCRIPTIONS_V1.0.yaml`

### Propósito
Gestión de suscripciones y pagos con integración completa de Wompi (Bancolombia).

### Endpoints Principales
- `GET /subscriptions/plans` - Listar planes disponibles
- `GET /subscriptions/current` - Suscripción actual del usuario
- `POST /subscriptions/checkout` - Crear sesión de pago con Wompi
- `POST /subscriptions/change-plan` - Cambiar plan (upgrade/downgrade)
- `POST /subscriptions/cancel` - Cancelar suscripción
- `POST /subscriptions/reactivate` - Reactivar suscripción cancelada
- `GET /subscriptions/payment-methods` - Listar tarjetas guardadas
- `POST /subscriptions/payment-methods` - Agregar método de pago
- `DELETE /subscriptions/payment-methods/{id}` - Eliminar tarjeta
- `GET /subscriptions/invoices` - Historial de pagos
- `GET /subscriptions/invoices/{id}/download` - Descargar PDF de invoice

### Responsabilidades
- Consulta de planes (Free, Basic, Pro, Premium)
- Creación de checkout con Wompi
- Gestión de métodos de pago tokenizados (PCI compliant)
- Cambio de plan con prorrateado
- Cancelación con acceso hasta fin de período
- Reactivación antes/después de expiración
- Generación de invoices en PDF
- Tracking de estado de suscripción
- Alertas 5 días antes de vencimiento (EventBridge)
- Control de acceso según estado de suscripción
- Auto-renovación con tarjetas guardadas

### Integraciones
- PostgreSQL: Tabla `subscriptions`, `payment_methods`, `invoices`, `payment_audit_logs`
- Wompi API: Checkout, transacciones, tokenización
- lambda-webhooks: Recibe notificaciones de pagos
- AWS SES: Envío de alertas de vencimiento
- EventBridge: Scheduled rule para alertas (cron diario)
- S3: Almacenamiento de invoices PDF

### Consideraciones Especiales
- **NUNCA** almacenar números completos de tarjeta
- Solo almacenar `wompi_payment_source_id` (token)
- Verificar firma de Wompi en webhooks
- Suscripción expirada: READ-ONLY en otros módulos, FULL ACCESS a pagos
- Comisión Wompi: 2.9% + $0.30 por transacción
- IVA Colombia: 19% (calcular en checkout)
- Prorrateado: Upgrade cobra diferencia, Downgrade aplica crédito
- Estados: active, trial, past_due, expired, cancelled, suspended

---

## 6. lambda-tags
**Contrato**: `TEMIS_CONTRATO_TAGS_V1.0.yaml`

### Propósito
Gestión de etiquetas (tags) transversales para organización de recursos.

### Endpoints Principales
- `GET /tags` - Listar etiquetas
- `POST /tags` - Crear etiqueta
- `GET /tags/{tagId}` - Obtener por ID
- `PUT /tags/{tagId}` - Actualizar
- `DELETE /tags/{tagId}` - Eliminar

### Responsabilidades
- CRUD simple de etiquetas
- Colores personalizables (hex)
- Conteo de uso (cuántos recursos usan cada tag)
- Validación de unicidad de nombre por usuario
- Búsqueda y ordenamiento

### Integraciones
- PostgreSQL: Tabla `tags`, `task_tags`, `transaction_tags`, `password_tags`
- lambda-tasks: Asociación con tareas
- lambda-transactions: Asociación con transacciones
- lambda-passwords: Asociación con contraseñas

### Consideraciones Especiales
- No hay límite de tags
- Eliminar tag no elimina recursos asociados
- Color debe ser formato hex válido (#RRGGBB)
- Ordenamiento por nombre o uso

---

## 7. lambda-categories
**Contrato**: `TEMIS_CONTRATO_CATEGORIES_V1.0.yaml`

### Propósito
Gestión de categorías para organizar tareas, transacciones y contraseñas.

### Endpoints Principales
- `GET /categories` - Listar categorías (sistema + personalizadas)
- `POST /categories` - Crear categoría personalizada
- `GET /categories/{categoryId}` - Obtener por ID
- `PUT /categories/{categoryId}` - Actualizar
- `DELETE /categories/{categoryId}` - Eliminar

### Responsabilidades
- Proveer categorías predefinidas del sistema
- Permitir categorías personalizadas por usuario
- Iconos (emoji) y colores
- Jerarquía padre/hijo (subcategorías)
- Validación de permisos (no editar categorías del sistema)
- Conteo de uso

### Integraciones
- PostgreSQL: Tabla `categories`
- lambda-tasks: Categorización de tareas
- lambda-transactions: Categorización de transacciones
- lambda-passwords: Categorización de contraseñas
- lambda-budgets: Presupuestos por categoría

### Consideraciones Especiales
- Categorías del sistema: `is_system = true`, no editables
- Categorías personalizadas: Solo para el usuario que las creó
- Límite de categorías personalizadas según plan
- Tipos: task, transaction, password, general

---

## 8. lambda-users
**Contrato**: `TEMIS_CONTRATO_USERS_V1.0.yaml`

### Propósito
Gestión de perfiles de usuario y configuraciones personales.

### Endpoints Principales
- `GET /users/me` - Obtener perfil del usuario autenticado
- `PUT /users/me` - Actualizar perfil
- `POST /users/me/avatar` - Subir avatar
- `DELETE /users/me/avatar` - Eliminar avatar
- `PUT /users/me/password` - Cambiar contraseña
- `GET /users/me/preferences` - Obtener preferencias
- `PUT /users/me/preferences` - Actualizar preferencias
- `GET /users/me/sessions` - Listar sesiones activas
- `DELETE /users/me/sessions/{sessionId}` - Cerrar sesión específica
- `POST /users/me/sessions/revoke-all` - Cerrar todas las sesiones

### Responsabilidades
- Actualización de datos personales (nombre, teléfono, etc)
- Gestión de avatar en S3
- Cambio de contraseña con validación de actual
- Configuración de preferencias (tema, idioma, timezone, moneda)
- Configuración de notificaciones (email, push)
- Listar sesiones activas (refresh tokens)
- Revocación de sesiones

### Integraciones
- PostgreSQL: Tabla `users`, `refresh_tokens`
- S3: Almacenamiento de avatares
- AWS SES: Notificaciones de cambio de contraseña
- Lambda Sharp: Redimensionamiento de imágenes

### Consideraciones Especiales
- Avatar máximo 5 MB (JPEG, PNG, GIF)
- Generar thumbnail automáticamente
- Cambio de contraseña requiere contraseña actual
- Nueva contraseña debe cumplir políticas de seguridad
- Sesiones muestran: device, OS, browser, IP, ubicación
- No permitir revocar la sesión actual

---

## 9. lambda-budgets
**Contrato**: `TEMIS_CONTRATO_BUDGETS_V1.0.yaml`

### Propósito
Gestión de presupuestos financieros con alertas de exceso.

### Endpoints Principales
- `GET /budgets` - Listar presupuestos
- `POST /budgets` - Crear presupuesto
- `GET /budgets/{budgetId}` - Obtener por ID
- `PUT /budgets/{budgetId}` - Actualizar
- `DELETE /budgets/{budgetId}` - Eliminar

### Responsabilidades
- Crear presupuestos por categoría y período
- Calcular gasto actual vs límite
- Generar alertas cuando se excede umbral (50%, 80%, 90%, 100%)
- Presupuestos recurrentes (mensual, trimestral, anual)
- Tracking de porcentaje usado
- Estados: active, exceeded, inactive

### Integraciones
- PostgreSQL: Tabla `budgets`
- lambda-transactions: Consulta de gastos por categoría y período
- lambda-categories: Validación de categorías
- AWS SNS: Envío de alertas push
- AWS SES: Envío de alertas email

### Consideraciones Especiales
- Budget se calcula en tiempo real al consultar
- Alertas se envían cuando se crea/actualiza transacción
- Presupuestos recurrentes: Crear automáticamente el siguiente período
- Un presupuesto puede ser global (sin categoría) o por categoría
- Límites por plan: Free (3), Basic (10), Pro (50), Premium (ilimitado)

---

## 10. lambda-reminders
**Contrato**: `TEMIS_CONTRATO_REMINDERS_V1.0.yaml`

### Propósito
Gestión de recordatorios para tareas con notificaciones push y email.

### Endpoints Principales
- `GET /reminders` - Listar recordatorios
- `POST /reminders` - Crear recordatorio
- `GET /reminders/{reminderId}` - Obtener por ID
- `PUT /reminders/{reminderId}` - Actualizar
- `DELETE /reminders/{reminderId}` - Eliminar
- `POST /reminders/{reminderId}/cancel` - Cancelar recordatorio pendiente

### Responsabilidades
- Crear recordatorios asociados a tareas
- Programar fecha/hora de notificación
- Enviar notificaciones push y/o email
- Recordatorios recurrentes (diario, semanal, mensual)
- Gestión de estado (pending, sent, cancelled, failed)
- Tracking de envío (sent_at)

### Integraciones
- PostgreSQL: Tabla `reminders`
- lambda-tasks: Validación de tareas
- EventBridge: Scheduled rules para envío de recordatorios
- AWS SNS: Notificaciones push
- AWS SES: Notificaciones email
- Lambda programada: Procesa reminders pendientes cada minuto

### Consideraciones Especiales
- EventBridge Rule: Ejecuta lambda cada 1 minuto para procesar
- Query: `SELECT * FROM reminders WHERE status='pending' AND remind_at <= NOW()`
- Después de enviar: actualizar `status='sent'`, `sent_at=NOW()`
- Recurrentes: Crear siguiente recordatorio después de enviar
- Límites por plan: Free (10 activos), Basic (50), Pro (500), Premium (ilimitado)

---

## 11. lambda-voice
**Contrato**: `TEMIS_CONTRATO_VOICE_V1.0.yaml`

### Propósito
Procesamiento de entrada por voz para crear tareas y transacciones usando IA.

### Endpoints Principales
- `POST /voice/tasks` - Crear tarea por voz
- `POST /voice/transactions` - Crear transacción por voz
- `GET /voice/history` - Historial de entradas por voz
- `GET /voice/quota` - Cuota de IA disponible

### Responsabilidades
- Recibir audio en base64 (MP3, WAV, M4A, OGG)
- Subir audio a S3 temporal
- Transcribir con Amazon Transcribe (español/inglés)
- Interpretar texto con Amazon Bedrock (Claude 3.5 Sonnet)
- Extraer datos estructurados del texto
- Crear recurso correspondiente (tarea o transacción)
- Almacenar historial de entradas por voz
- Tracking de tokens y costos
- Validación de cuota de IA

### Integraciones
- Amazon Transcribe: Speech-to-text
- Amazon Bedrock: IA para interpretar texto
- S3: Almacenamiento temporal de audio
- lambda-tasks: Creación de tareas
- lambda-transactions: Creación de transacciones
- PostgreSQL: Tabla `voice_inputs`, `ai_usage`

### Consideraciones Especiales
- Audio máximo: 5 minutos
- Idiomas: es-ES, es-CO, en-US
- Prompt a IA: Extraer tipo, monto, categoría, prioridad, fecha, etc.
- IA debe manejar lenguaje natural y fechas relativas ("ayer", "mañana")
- Cuota según plan: Free (0), Basic (10-20/mes), Pro (100/mes), Premium (500/mes)
- Verificar cuota antes de procesar
- Costo: Transcribe (~$0.024/min) + Bedrock (~$0.003/1K tokens)

---

## 12. lambda-ai
**Contrato**: `TEMIS_CONTRATO_AI_V1.0.yaml`

### Propósito
Asistente de IA conversacional con análisis y predicciones financieras.

### Endpoints Principales
- `POST /ai/chat` - Enviar mensaje al asistente
- `GET /ai/conversations` - Listar conversaciones
- `GET /ai/conversations/{conversationId}` - Obtener conversación completa
- `DELETE /ai/conversations/{conversationId}` - Eliminar conversación
- `GET /ai/insights` - Obtener insights financieros automáticos
- `GET /ai/predictions` - Predicciones financieras
- `GET /ai/summary` - Resumen narrativo del estado del usuario

### Responsabilidades
- Chat conversacional con memoria de contexto
- Acceso a datos del usuario para responder preguntas
- Generación de insights automáticos (patrones, tendencias)
- Predicciones de gastos futuros
- Resúmenes narrativos personalizados
- Recomendaciones de ahorro
- Análisis de productividad
- Tracking de conversaciones
- Validación de cuota de IA

### Integraciones
- Amazon Bedrock: Claude 3.5 Sonnet v2
- PostgreSQL: Tabla `ai_conversations`, `ai_usage`
- lambda-tasks: Consulta de tareas para contexto
- lambda-transactions: Consulta de transacciones para análisis
- lambda-budgets: Consulta de presupuestos para alertas

### Consideraciones Especiales
- Modelo: anthropic.claude-3-5-sonnet-20241022-v2:0
- Contexto incluye: tareas, transacciones, presupuestos, hábitos
- Conversaciones tienen memoria (últimos 10 mensajes)
- Insights generados periódicamente (EventBridge diario)
- Cuota compartida con lambda-voice
- Ejemplos de preguntas: "¿Cuánto gasté este mes?", "¿Estoy cumpliendo presupuestos?"
- Predicciones basadas en análisis de tendencias históricas
- Límite de mensaje: 2000 caracteres

---

## 13. lambda-webhooks
**Contrato**: `TEMIS_CONTRATO_WEBHOOKS_V1.0.yaml`

### Propósito
Recibir webhooks de servicios externos, principalmente Wompi.

### Endpoints Principales
- `POST /webhooks/wompi` - Recibir notificación de Wompi

### Responsabilidades
- Recibir eventos de Wompi (transaction.updated, etc)
- Validar firma HMAC SHA-256 (header Wompi-Signature)
- Validar IP de Wompi (whitelist)
- Procesar eventos de forma asíncrona
- Actualizar estado de suscripción según resultado de pago
- Crear/actualizar payment_methods
- Generar invoices
- Enviar notificaciones al usuario
- Almacenar en payment_audit_logs

### Integraciones
- Wompi API: Verificación de firma
- PostgreSQL: Tabla `subscriptions`, `payment_methods`, `invoices`, `payment_audit_logs`
- AWS SES: Notificación de pago exitoso/fallido
- AWS SNS: Push notification

### Consideraciones Especiales
- **NO requiere autenticación JWT**
- Autenticación mediante firma HMAC con secret de Wompi
- Responder 200 OK rápidamente (<5 segundos)
- Procesar de forma asíncrona (SQS o Step Functions)
- Validar estructura del evento antes de procesar
- Idempotencia: No procesar mismo evento dos veces
- Eventos principales:
  - `transaction.updated`: Actualizar estado de suscripción
  - `payment_source.created`: Guardar método de pago
  - `payment_source.deleted`: Marcar como eliminado

---

## 14. lambda-admin
**Contrato**: `TEMIS_CONTRATO_ADMIN_V1.0.yaml`

### Propósito
Panel administrativo para gestión del sistema y usuarios.

### Endpoints Principales
- `GET /admin/dashboard` - Dashboard con métricas globales
- `GET /admin/users` - Listar todos los usuarios
- `GET /admin/users/{userId}` - Detalles de usuario
- `PATCH /admin/users/{userId}` - Actualizar estado de usuario
- `GET /admin/organizations` - Listar organizaciones
- `GET /admin/revenue` - Reporte de ingresos
- `GET /admin/monitoring` - Métricas de recursos AWS

### Responsabilidades
- Dashboard con KPIs (usuarios, ingresos, conversión, churn)
- Listar y buscar usuarios
- Suspender/activar cuentas
- Forzar reset de contraseña
- Ver historial de suscripciones
- Reportes de ingresos por período y plan
- Monitoreo de recursos AWS (Lambda, RDS, S3, Bedrock)
- Análisis de uso por usuario
- Gestión de organizaciones

### Integraciones
- PostgreSQL: Todas las tablas (acceso completo)
- CloudWatch: Métricas de Lambda, RDS, API Gateway
- AWS Cost Explorer: Costos de recursos

### Consideraciones Especiales
- **Requiere rol admin** en JWT claim
- Middleware valida `role === 'admin'`
- Solo ciertos usuarios tienen este rol
- Nunca exponer en frontend público
- Logging exhaustivo de todas las acciones
- Rate limiting menos restrictivo
- Acceso a datos sensibles (audit_logs completos)

---

## 15. lambda-maintenance
**Nota**: No tiene contrato público (solo para tareas programadas internas)

### Propósito
Tareas de mantenimiento automatizadas para limpieza de datos.

### Tareas Programadas (EventBridge)
- **Cleanup audit_logs**: Mensual, día 1 a las 3 AM
  - Elimina registros > 1 año
- **Cleanup refresh_tokens**: Diario a las 4 AM
  - Elimina tokens revocados o expirados hace > 7 días
- **Cleanup ai_conversations**: Mensual
  - Elimina conversaciones > 6 meses
- **Cleanup payment_audit_logs**: Mensual
  - Elimina registros > 2 años
- **Send subscription expiry alerts**: Diario a las 8 AM
  - Envía alertas a usuarios con suscripción expirando en 5 días
- **Process recurring budgets**: Primer día del mes a las 1 AM
  - Crea presupuestos recurrentes para el nuevo período

### Responsabilidades
- Limpieza de datos obsoletos
- Evitar crecimiento infinito de DB
- Envío de alertas programadas
- Creación automática de recursos recurrentes

### Integraciones
- PostgreSQL: Todas las tablas para limpieza
- AWS SES: Envío de alertas
- CloudWatch Logs: Logging de operaciones

### Consideraciones Especiales
- No exponer endpoints públicos
- Solo ejecuta vía EventBridge
- Valida que no haya errores antes de commit
- Logging detallado de cuántos registros se eliminaron
- Transacciones con rollback en caso de error

---

## 16. lambda-ai-monitoring
**Contrato**: `TEMIS_CONTRATO_AI_MONITORING_V1.0.yaml`

### Propósito
Monitoreo y control de consumo de AWS Bedrock para administradores.

### Endpoints Principales
- `GET /admin/ai-monitoring/dashboard` - Dashboard de monitoreo de IA
- `GET /admin/ai-monitoring/costs` - Consultar costos de Bedrock (Cost Explorer)
- `GET /admin/ai-monitoring/usage` - Estadísticas de uso de IA
- `GET /admin/ai-monitoring/users` - Uso por usuario
- `GET /admin/ai-monitoring/feature-flag` - Estado del feature flag de IA
- `PUT /admin/ai-monitoring/feature-flag` - Habilitar/deshabilitar IA globalmente
- `GET /admin/ai-monitoring/quotas` - Obtener cuotas actuales por plan
- `PUT /admin/ai-monitoring/quotas` - Actualizar cuotas de IA
- `GET /admin/ai-monitoring/budget` - Configuración de presupuesto
- `PUT /admin/ai-monitoring/budget` - Actualizar presupuesto mensual
- `GET /admin/ai-monitoring/alerts` - Historial de alertas

### Responsabilidades
- Consultar costos de Bedrock vía AWS Cost Explorer API
- Calcular costo proyectado al fin del mes
- Estadísticas de uso (llamadas, tokens, errores)
- Top usuarios por consumo
- Control de feature flag (habilitar/deshabilitar IA)
- Gestión dinámica de cuotas por plan
- Configuración de presupuesto mensual y umbrales
- Generación y gestión de alertas
- Dashboard en tiempo real para administradores

### Integraciones
- AWS Cost Explorer: Consulta de costos históricos
- PostgreSQL: Tabla `ai_usage`, `ai_budget_alerts`, `ai_feature_flag_history`
- Parameter Store: Feature flags, cuotas, presupuesto
- AWS SNS: Notificaciones de alertas
- AWS SES: Emails de alertas críticas
- lambda-ai: Validación de feature flag
- lambda-voice: Validación de feature flag

### Consideraciones Especiales
- **Solo administradores** pueden acceder (role === 'admin')
- Consulta Cost Explorer API (puede tardar varios segundos)
- Cálculo de costo proyectado basado en gasto promedio diario
- Feature flag deshabilita TODAS las funciones de IA instantáneamente
- Cuotas se pueden ajustar dinámicamente sin redespliegue
- Alertas automáticas cuando se alcanzan umbrales (80%, 90%, 100%)
- Dashboard muestra: costo actual, proyección, top usuarios, uso por feature
- Permite control de emergencia ante exceso de presupuesto

---

## 🔐 Seguridad Transversal

### Autenticación
- **JWT RS256**: Access token (15 min) + Refresh token (7 días)
- **Headers estándar**: Authorization, message-uuid, request-app-id
- **Validación en todas las lambdas** (excepto auth y webhooks)

### Autorización (RLS)
- **Todas las queries incluyen**: `WHERE organization_id = ? AND user_id = ?`
- **PostgreSQL RLS policies**: Forzadas a nivel de DB
- **Validación en código**: Doble check antes de queries

### Rate Limiting
- **API Gateway**: Throttling por endpoint
- **Lambda function**: Contador en Redis/DynamoDB
- **Por usuario**: Límites según plan

### Audit Logs
- **Todas las operaciones críticas** se registran en `audit_logs`
- **Campos**: user_id, action, resource_type, resource_id, changes, ip_address

---

## 📊 Límites por Plan de Suscripción

| Recurso | Free | Basic | Pro | Premium |
|---------|------|-------|-----|---------|
| Tareas | 50 | 500 | 10,000 | Ilimitado |
| Contraseñas | 10 | 100 | 1,000 | Ilimitado |
| Transacciones | 100 | 1,000 | 10,000 | Ilimitado |
| Presupuestos | 3 | 10 | 50 | Ilimitado |
| Recordatorios activos | 10 | 50 | 500 | Ilimitado |
| Categorías personalizadas | 5 | 20 | 100 | Ilimitado |
| Cuota IA mensual | 0 | 10-20 | 100 | 500 |
| Entrada por voz | ❌ | ✅ | ✅ | ✅ |
| Reportes avanzados | ❌ | ❌ | ✅ | ✅ |
| Soporte prioritario | ❌ | ❌ | ✅ | ✅ |

---

## 🚀 Flujos de Integración

### Flujo de Registro y Primer Uso
1. `lambda-auth` → Registro de usuario
2. `lambda-auth` → Creación de organization
3. `lambda-subscriptions` → Asigna plan Free por defecto
4. `lambda-categories` → Carga categorías del sistema
5. Usuario puede empezar a usar con límites de plan Free

### Flujo de Suscripción de Pago
1. `lambda-subscriptions` → Crea checkout en Wompi
2. Usuario paga en Wompi
3. `lambda-webhooks` → Recibe notificación de Wompi
4. `lambda-webhooks` → Actualiza suscripción a plan pagado
5. `lambda-webhooks` → Envía email de confirmación
6. Límites se actualizan automáticamente

### Flujo de Creación de Tarea por Voz
1. `lambda-voice` → Recibe audio en base64
2. `lambda-voice` → Transcribe con Amazon Transcribe
3. `lambda-voice` → Interpreta con Bedrock (Claude)
4. `lambda-voice` → Extrae datos estructurados
5. `lambda-tasks` → Crea la tarea
6. `lambda-reminders` → Crea recordatorio si aplica
7. `lambda-voice` → Retorna tarea creada + transcripción

### Flujo de Transacción con Presupuesto
1. `lambda-transactions` → Crea transacción
2. `lambda-transactions` → Actualiza balance de cuenta
3. `lambda-budgets` → Consulta presupuestos de la categoría
4. `lambda-budgets` → Calcula porcentaje usado
5. `lambda-budgets` → Envía alerta si excede umbral (>80%)
6. `lambda-transactions` → Retorna transacción + alerta de presupuesto

---

## 📈 Consideraciones de Escalabilidad

### Optimizaciones
- **Conexiones RDS**: Connection pooling (pg-pool)
- **Caching**: Redis para consultas frecuentes
- **Índices DB**: Índices compuestos en queries comunes
- **Paginación**: Todas las listas con límite default 20

### Límites de AWS
- **Lambda concurrencia**: 1000 por región (solicitar incremento)
- **RDS connections**: db.t4g.micro (85 max connections)
- **API Gateway**: 10,000 requests/second por región

### Monitoreo
- **CloudWatch Alarms**: Lambda errors, RDS CPU, API latency
- **X-Ray**: Tracing de requests end-to-end
- **CloudWatch Logs Insights**: Análisis de logs

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.0.0
**Total de Lambdas**: 16 funciones serverless
