# 📝 ACTUALIZACIONES REQUERIDAS PARA DOCUMENTACIÓN - TEMIS

**Fecha**: 2026-09-23
**Versión**: 1.0
**Estado**: 🔴 PENDIENTE DE IMPLEMENTACIÓN

---

## 🎯 Resumen Ejecutivo

Este documento lista **TODAS las actualizaciones necesarias** en los contratos API y documentación de TEMIS para cerrar los gaps identificados en la auditoría de módulos.

**Prioridad Total: 17 updates**
- 🔴 **Críticos**: 6 updates (Seguridad y GDPR)
- 🟡 **Altos**: 7 updates (Funcionalidad core)
- 🟢 **Medios**: 4 updates (Mejoras)

---

## 🔴 PRIORIDAD CRÍTICA (Implementar INMEDIATAMENTE)

### 1. ✅ TEMIS_CONTRATO_AUTH_V1.0.yaml

**Endpoints Faltantes:**

#### A. POST /auth/revoke-all-sessions
```yaml
  /auth/revoke-all-sessions:
    post:
      tags:
        - auth
      summary: Revocar todas las sesiones activas
      description: |
        Invalida TODOS los refresh tokens del usuario.

        **Casos de uso:**
        - Usuario perdió su teléfono
        - Sospecha de acceso no autorizado
        - Cambio de contraseña (automático)
        - Cierre de sesión en todos los dispositivos

        **Proceso:**
        1. Marca todos los refresh_tokens del usuario como revoked
        2. Registra evento en audit_logs
        3. Usuario debe hacer login nuevamente en todos sus dispositivos
      operationId: revokeAllSessions
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - in: body
          name: body
          schema:
            type: object
            properties:
              reason:
                type: string
                maxLength: 500
                example: "Dispositivo perdido"
      responses:
        200:
          description: Todas las sesiones revocadas exitosamente
          schema:
            type: object
            properties:
              headers:
                $ref: '#/definitions/responseHeaders'
              messageResponse:
                $ref: '#/definitions/messageResponse'
              data:
                type: object
                properties:
                  sessions_revoked:
                    type: integer
                    example: 3
                    description: "Número de sesiones cerradas"
        401:
          description: Token inválido
          schema:
            $ref: '#/definitions/errorResponse'
```

#### B. POST /auth/verify
```yaml
  /auth/verify:
    post:
      tags:
        - auth
      summary: Verificar validez de token JWT
      description: |
        Endpoint para que otras lambdas validen tokens JWT sin duplicar lógica.

        **Uso interno entre lambdas:**
        - lambda-tasks llama a lambda-auth para validar token
        - Retorna user_id + organization_id + role
        - Cache de 30 segundos para performance
      operationId: verifyToken
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - in: body
          name: body
          required: true
          schema:
            type: object
            required:
              - access_token
            properties:
              access_token:
                type: string
                description: "JWT access token a validar"
      responses:
        200:
          description: Token válido
          schema:
            type: object
            properties:
              headers:
                $ref: '#/definitions/responseHeaders'
              messageResponse:
                $ref: '#/definitions/messageResponse'
              data:
                type: object
                properties:
                  valid:
                    type: boolean
                    example: true
                  user_id:
                    type: string
                    format: uuid
                  organization_id:
                    type: string
                    format: uuid
                  role:
                    type: string
                    enum: [user, admin, superadmin]
                  expires_at:
                    type: string
                    format: date-time
        401:
          description: Token inválido o expirado
          schema:
            type: object
            properties:
              valid:
                type: boolean
                example: false
              error:
                type: string
```

**Documentación Adicional:**

- Agregar sección de **Rate Limiting**:
  ```yaml
  Rate Limiting para /auth/login:
    - 5 intentos fallidos por IP en 15 minutos
    - Bloqueo temporal de 15 minutos después de 5 fallos
    - Notificación por email si hay más de 10 intentos

  Rate Limiting para /auth/register:
    - 3 registros por IP en 1 hora
    - Verificación de email obligatoria
  ```

---

### 2. ✅ TEMIS_CONTRATO_AI_MEMORY_V1.0.yaml

**Endpoints Faltantes (CRÍTICO - GDPR):**

#### A. DELETE /memories/{memoryId}
```yaml
  /memories/{memoryId}:
    delete:
      tags:
        - Memories
      summary: Eliminar memoria permanentemente
      description: |
        Elimina una memoria y TODOS sus attachments y embeddings asociados.

        **GDPR - Derecho al Olvido:**
        - Cumple con regulación de privacidad
        - Eliminación física de archivos en S3
        - Eliminación de embeddings de pgvector
        - Operación irreversible

        **Proceso:**
        1. Verificar que la memoria pertenece al usuario (RLS)
        2. Eliminar archivos de S3 (attachments)
        3. DELETE CASCADE en memory_attachments y memory_embeddings
        4. Eliminar registro de memoria
        5. Actualizar storage_used del usuario
        6. Registrar en audit_logs
      operationId: deleteMemory
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - name: memoryId
          in: path
          required: true
          type: string
          format: uuid
      responses:
        204:
          description: Memoria eliminada exitosamente (sin contenido)
        401:
          description: No autenticado
          schema:
            $ref: '#/definitions/errorResponse'
        403:
          description: Sin permisos para eliminar esta memoria
          schema:
            $ref: '#/definitions/errorResponse'
        404:
          description: Memoria no encontrada
          schema:
            $ref: '#/definitions/errorResponse'
        422:
          description: Suscripción expirada (READ-ONLY)
          schema:
            $ref: '#/definitions/errorResponse'
```

#### B. DELETE /memories/{memoryId}/attachments/{attachmentId}
```yaml
  /memories/{memoryId}/attachments/{attachmentId}:
    delete:
      tags:
        - Attachments
      summary: Eliminar attachment individual
      description: |
        Elimina un archivo adjunto específico de una memoria.

        **Casos de uso:**
        - Usuario quiere eliminar solo una foto de varias
        - Eliminar documento sensible pero mantener transcripción

        **Proceso:**
        1. Verificar permisos (RLS)
        2. Eliminar archivo de S3
        3. DELETE de memory_attachments
        4. Actualizar storage_used
      operationId: deleteAttachment
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - name: memoryId
          in: path
          required: true
          type: string
          format: uuid
        - name: attachmentId
          in: path
          required: true
          type: string
          format: uuid
      responses:
        204:
          description: Attachment eliminado
        401:
          description: No autenticado
        403:
          description: Sin permisos
        404:
          description: Attachment no encontrado
```

#### C. GET /memories/export
```yaml
  /memories/export:
    get:
      tags:
        - Memories
      summary: Exportar todas las memorias (GDPR - Portabilidad de Datos)
      description: |
        Genera un archivo ZIP con TODAS las memorias del usuario.

        **GDPR - Derecho a la Portabilidad:**
        - Usuario puede descargar todos sus datos
        - Formato JSON estructurado + archivos originales
        - Incluye metadata, transcripciones, embeddings (opcional)

        **Contenido del ZIP:**
        - memories.json (metadata + textos)
        - /attachments/... (archivos originales)
        - manifest.json (índice de contenido)

        **Proceso asíncrono:**
        1. Crea job de exportación
        2. Retorna export_job_id
        3. Cliente consulta /memories/export/{jobId}/status
        4. Cuando esté listo, download_url disponible (S3 pre-signed, expira en 24h)
      operationId: exportMemories
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - name: include_embeddings
          in: query
          type: boolean
          default: false
          description: "Incluir embeddings (archivo muy grande)"
      responses:
        202:
          description: Export job creado, procesando en background
          schema:
            type: object
            properties:
              headers:
                $ref: '#/definitions/responseHeaders'
              messageResponse:
                $ref: '#/definitions/messageResponse'
              data:
                type: object
                properties:
                  export_job_id:
                    type: string
                    format: uuid
                  status:
                    type: string
                    example: "processing"
                  estimated_time_minutes:
                    type: integer
                    example: 5
                  status_url:
                    type: string
                    example: "/v1/memories/export/{jobId}/status"
        401:
          description: No autenticado
```

#### D. GET /memories/export/{jobId}/status
```yaml
  /memories/export/{jobId}/status:
    get:
      tags:
        - Memories
      summary: Consultar estado de exportación
      description: Verifica el progreso del job de exportación
      operationId: getExportStatus
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - name: jobId
          in: path
          required: true
          type: string
          format: uuid
      responses:
        200:
          description: Estado del job
          schema:
            type: object
            properties:
              headers:
                $ref: '#/definitions/responseHeaders'
              messageResponse:
                $ref: '#/definitions/messageResponse'
              data:
                type: object
                properties:
                  export_job_id:
                    type: string
                    format: uuid
                  status:
                    type: string
                    enum: [processing, completed, failed]
                    example: "completed"
                  progress_percentage:
                    type: integer
                    example: 100
                  download_url:
                    type: string
                    format: uri
                    example: "https://s3.amazonaws.com/temis-exports/user-123/export.zip?signature=..."
                    description: "Pre-signed URL (válida 24h), solo disponible si status = completed"
                  file_size_bytes:
                    type: integer
                    example: 52428800
                    description: "Tamaño del archivo ZIP en bytes (50 MB)"
                  expires_at:
                    type: string
                    format: date-time
                    description: "Expiración del download_url"
                  created_at:
                    type: string
                    format: date-time
                  completed_at:
                    type: string
                    format: date-time
        404:
          description: Job no encontrado
```

**Validaciones de Tamaño:**

- Agregar en descripción general:
  ```yaml
  File Size Limits:
    - Photos (JPG, PNG, HEIC): 10 MB max
    - Documents (PDF, DOC, DOCX): 25 MB max
    - Audio (MP3, M4A, WAV): 50 MB max (máx 30 minutos)
    - Videos: No soportado actualmente

  Total Storage by Plan:
    - Free: 2 GB
    - Basic: 5 GB
    - Pro: 20 GB
    - Premium: 100 GB
  ```

---

### 3. ✅ TEMIS_CONTRATO_WEBHOOKS_V1.0.yaml

**Mejoras de Seguridad:**

- Agregar sección detallada de **Validación HMAC**:

```yaml
Validación HMAC SHA-256:

  Código de Ejemplo (Node.js):
    ```javascript
    const crypto = require('crypto');

    async function validateWompiSignature(req) {
      // 1. Obtener signature del header
      const receivedSignature = req.headers['wompi-signature'];

      if (!receivedSignature) {
        throw new Error('Missing Wompi-Signature header');
      }

      // 2. Obtener secret desde AWS Secrets Manager
      const secret = await getSecret('wompi-events-secret');

      // 3. Calcular signature esperada
      const payload = JSON.stringify(req.body);
      const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(payload)
        .digest('hex');

      // 4. Comparación segura (timing-safe)
      const isValid = crypto.timingSafeEqual(
        Buffer.from(receivedSignature, 'hex'),
        Buffer.from(expectedSignature, 'hex')
      );

      if (!isValid) {
        throw new Error('Invalid HMAC signature');
      }

      return true;
    }
    ```

Idempotencia:
  - Tabla: webhook_events
  - Campos: event_id (PK), processed_at, payload_hash
  - Antes de procesar, verificar:
    SELECT 1 FROM webhook_events WHERE event_id = $1
  - Si existe, retornar 200 OK sin procesar
  - Si no existe, INSERT y procesar

Rate Limiting:
  - 100 webhooks por minuto desde IPs de Wompi
  - Bloquear cualquier otra IP (whitelist estricto)

IPs de Wompi Colombia (a actualizar según documentación oficial):
  - 181.49.176.0/24
  - 181.49.177.0/24
```

---

### 4. ✅ TEMIS_CONTRATO_SUBSCRIPTIONS_V1.0.yaml

**Endpoints Faltantes:**

#### A. POST /subscriptions/retry-payment
```yaml
  /subscriptions/retry-payment:
    post:
      tags:
        - Subscriptions
      summary: Reintentar pago fallido
      description: |
        Reintenta cobrar una suscripción que falló (status = past_due).

        **Casos de uso:**
        - Auto-renovación falló por fondos insuficientes
        - Usuario actualizó su tarjeta
        - Error temporal del banco

        **Proceso:**
        1. Verificar que subscription.status = 'past_due'
        2. Si hay payment_method guardado: cobrar automáticamente
        3. Si no hay payment_method: retornar checkout_url
        4. Si pago exitoso: actualizar a 'active' y extender current_period_end
      operationId: retryPayment
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - in: body
          name: body
          schema:
            type: object
            properties:
              payment_method_id:
                type: string
                format: uuid
                description: "Opcional: usar tarjeta específica"
      responses:
        200:
          description: Pago procesado exitosamente
          schema:
            type: object
            properties:
              headers:
                $ref: '#/definitions/responseHeaders'
              messageResponse:
                $ref: '#/definitions/messageResponse'
              data:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  subscription:
                    $ref: '#/definitions/userSubscription'
                  transaction_id:
                    type: string
                    description: "ID de transacción de Wompi si fue cobrado"
        402:
          description: Pago rechazado nuevamente
          schema:
            type: object
            properties:
              success:
                type: boolean
                example: false
              reason:
                type: string
                example: "Fondos insuficientes"
              checkout_url:
                type: string
                description: "URL para intentar con otro método de pago"
        404:
          description: Suscripción no encontrada o no está en estado past_due
```

#### B. GET /subscriptions/alerts
```yaml
  /subscriptions/alerts:
    get:
      tags:
        - Subscriptions
      summary: Obtener alertas de vencimiento
      description: |
        Lista las alertas activas de la suscripción del usuario.

        **Tipos de alertas:**
        - expiring_soon: Faltan 5 días o menos para vencer
        - expired: Suscripción expirada
        - payment_failed: Último pago falló
        - trial_ending: Trial termina en 3 días o menos
      operationId: getSubscriptionAlerts
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
      responses:
        200:
          description: Alertas obtenidas
          schema:
            type: object
            properties:
              headers:
                $ref: '#/definitions/responseHeaders'
              messageResponse:
                $ref: '#/definitions/messageResponse'
              data:
                type: object
                properties:
                  alerts:
                    type: array
                    items:
                      type: object
                      properties:
                        type:
                          type: string
                          enum: [expiring_soon, expired, payment_failed, trial_ending]
                        severity:
                          type: string
                          enum: [info, warning, critical]
                        message:
                          type: string
                          example: "Tu suscripción expira en 3 días"
                        action_url:
                          type: string
                          example: "/subscriptions/checkout"
                        action_label:
                          type: string
                          example: "Renovar ahora"
```

---

### 5. ✅ TEMIS_CONTRATO_VOICE_V1.0.yaml

**Validaciones de Archivo:**

- Agregar en descripción general:

```yaml
File Size and Duration Limits:
  - Max file size: 10 MB
  - Max duration: 5 minutes
  - Min duration: 1 second

  Validation Process:
    1. Decode base64 y calcular tamaño real
    2. Si > 10 MB: retornar 413 Payload Too Large
    3. Subir a S3 temporalmente
    4. Amazon Transcribe detecta duración
    5. Si > 5 minutos: retornar 422 y eliminar de S3

Response 413:
  - errorCode: "FILE_TOO_LARGE"
  - errorDetail: "Audio file exceeds 10 MB limit"
  - max_size_bytes: 10485760

Response 422 (duración):
  - errorCode: "DURATION_TOO_LONG"
  - errorDetail: "Audio duration exceeds 5 minutes"
  - max_duration_seconds: 300
  - detected_duration_seconds: 420
```

**Endpoint Adicional:**

#### A. POST /voice/retry/{voiceInputId}
```yaml
  /voice/retry/{voiceInputId}:
    post:
      tags:
        - Voice History
      summary: Reintentar procesamiento de audio fallido
      description: |
        Reintenta procesar un audio que falló en transcripción o interpretación IA.

        **Casos de uso:**
        - Error temporal de AWS Transcribe
        - Error temporal de Amazon Bedrock
        - Audio con ruido que falló, usuario editó

        **Límites:**
        - Máximo 3 reintentos por audio
        - Solo audios con status = 'failed'
      operationId: retryVoiceInput
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - name: voiceInputId
          in: path
          required: true
          type: string
          format: uuid
      responses:
        201:
          description: Procesamiento exitoso
          schema:
            type: object
            properties:
              data:
                type: object
                properties:
                  task:
                    $ref: '#/definitions/task'
                  voice_input:
                    $ref: '#/definitions/voiceInput'
        400:
          description: Límite de reintentos excedido
        404:
          description: Voice input no encontrado
        422:
          description: Voice input no está en estado 'failed'
```

---

### 6. ✅ TEMIS_CONTRATO_TASKS_V1.0.yaml

**Endpoints Faltantes:**

#### A. GET /tasks/{taskId}/subtasks
```yaml
  /tasks/{taskId}/subtasks:
    get:
      tags:
        - Tareas
      summary: Listar subtareas de una tarea
      description: |
        Obtiene todas las subtareas de una tarea padre.

        **Jerarquía:**
        - Solo 1 nivel de profundidad (padre → hijo)
        - No se permiten sub-subtareas
      operationId: getSubtasks
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - name: taskId
          in: path
          required: true
          type: string
          format: uuid
        - name: status
          in: query
          type: string
          enum: [pending, completed, archived]
      responses:
        200:
          description: Subtareas obtenidas
          schema:
            type: object
            properties:
              headers:
                $ref: '#/definitions/responseHeaders'
              messageResponse:
                $ref: '#/definitions/messageResponse'
              data:
                type: object
                properties:
                  parent_task:
                    type: object
                    properties:
                      id:
                        type: string
                        format: uuid
                      title:
                        type: string
                  subtasks:
                    type: array
                    items:
                      $ref: '#/definitions/task'
                  summary:
                    type: object
                    properties:
                      total:
                        type: integer
                      completed:
                        type: integer
                      pending:
                        type: integer
                      completion_percentage:
                        type: number
                        format: float
        404:
          description: Tarea padre no encontrada
```

#### B. POST /tasks/{taskId}/subtasks
```yaml
    post:
      tags:
        - Tareas
      summary: Crear subtarea
      description: |
        Crea una nueva subtarea bajo una tarea padre.

        **Validaciones:**
        - La tarea padre NO puede ser ella misma una subtarea
        - Máximo 50 subtareas por tarea padre
      operationId: createSubtask
      security:
        - Bearer: []
      parameters:
        - name: message-uuid
          in: header
          required: true
          type: string
          format: uuid
        - name: request-app-id
          in: header
          required: true
          type: string
          format: uuid
        - name: taskId
          in: path
          required: true
          type: string
          format: uuid
          description: "ID de la tarea padre"
        - in: body
          name: body
          required: true
          schema:
            $ref: '#/definitions/taskCreateRequest'
      responses:
        201:
          description: Subtarea creada
          schema:
            type: object
            properties:
              data:
                type: object
                properties:
                  subtask:
                    $ref: '#/definitions/task'
        400:
          description: Tarea padre es una subtarea (no se permiten 2 niveles)
        422:
          description: Límite de 50 subtareas alcanzado
```

**Función de Validación en DATABASE-SCHEMA.md:**

```sql
-- Agregar en sección 12. STORED FUNCTIONS

-- Función: check_task_limit
-- Valida que el usuario no exceda el límite de tareas según su plan
CREATE OR REPLACE FUNCTION check_task_limit(
  p_organization_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_plan_name TEXT;
  v_max_tasks INT;
  v_current_tasks INT;
BEGIN
  -- Obtener plan actual del usuario
  SELECT sp.name, sp.max_tasks
  INTO v_plan_name, v_max_tasks
  FROM subscriptions s
  JOIN subscription_plans sp ON s.plan_id = sp.id
  WHERE s.organization_id = p_organization_id
    AND s.user_id = p_user_id
    AND s.status IN ('active', 'trial')
  LIMIT 1;

  -- Si no hay suscripción activa, usar límites de Free
  IF v_max_tasks IS NULL THEN
    v_max_tasks := 100; -- Free plan limit
  END IF;

  -- Contar tareas actuales (excluyendo archived)
  SELECT COUNT(*)
  INTO v_current_tasks
  FROM tasks
  WHERE organization_id = p_organization_id
    AND user_id = p_user_id
    AND status != 'archived'
    AND deleted_at IS NULL;

  -- Retornar TRUE si está dentro del límite
  RETURN v_current_tasks < v_max_tasks;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🟡 PRIORIDAD ALTA (Sprint 1)

### 7. ✅ TEMIS_CONTRATO_AI_MONITORING_V1.0.yaml

**Mejoras:**

#### A. Notificaciones Automáticas

- Agregar en descripción general:

```yaml
Automatic Notifications:

  Integration with Amazon SNS:
    - Topic: temis-ai-budget-alerts
    - Subscribers: Admin emails from admin_users table

  Alert Triggers:
    - Budget reaches 80%: Send WARNING email
    - Budget reaches 90%: Send CRITICAL email
    - Budget reaches 100%: Send EMERGENCY email + disable AI feature flag
    - Daily cost > $50: Send INFO email with daily report

  Email Template:
    Subject: "[TEMIS Alert] AI Budget at {percentage}%"
    Body:
      - Current spend: ${amount}
      - Monthly budget: ${budget}
      - Projected end-of-month: ${projected}
      - Top 5 users by consumption
      - Recommended actions
```

#### B. Endpoint de Configuración de Alertas

```yaml
  /admin/ai-monitoring/alert-settings:
    get:
      summary: Obtener configuración de alertas
      responses:
        200:
          schema:
            data:
              email_recipients:
                type: array
                items:
                  type: string
                  format: email
              sns_topic_arn:
                type: string
              enabled:
                type: boolean

    put:
      summary: Actualizar configuración de alertas
      parameters:
        - in: body
          schema:
            type: object
            properties:
              email_recipients:
                type: array
                items:
                  type: string
                  format: email
              enabled:
                type: boolean
```

---

### 8-11. Contratos de Finanzas (Validar que estén completos)

Verificar que estos contratos incluyan:

#### TEMIS_CONTRATO_TRANSACTIONS_V1.0.yaml
- CRUD completo (GET, POST, PUT, PATCH, DELETE)
- Filtros: date range, type (income/expense/transfer), category, account
- Endpoint de estadísticas: GET /transactions/stats
- Validación de balance en transfers
- **Faltante:** Endpoint de importación CSV
  ```yaml
  POST /transactions/import
  - Sube archivo CSV
  - Valida formato
  - Preview de transacciones a importar
  - Confirma importación
  ```

#### TEMIS_CONTRATO_BUDGETS_V1.0.yaml
- CRUD completo
- Endpoint de progreso: GET /budgets/{id}/progress
- Alertas de presupuesto excedido
- **Faltante:** Endpoint de proyección
  ```yaml
  GET /budgets/{id}/projection
  - Calcula gasto promedio diario
  - Proyecta gasto fin de mes
  - Retorna si excederá presupuesto
  ```

#### TEMIS_CONTRATO_CATEGORIES_V1.0.yaml
- Listar categorías (globales + personalizadas)
- Crear/editar/eliminar categorías personalizadas
- **Validar:** No se pueden eliminar categorías con transacciones asociadas

---

### 12. ✅ Documento de SMS Capture (Premium Feature)

**Crear:** `/docs/architecture/07-SMS-CAPTURE-FLOW.md`

```markdown
# SMS Capture - Transacciones Automáticas desde Notificaciones Bancarias

## Funcionamiento

**Solo disponible para:** Plan Pro y Premium

### Paso 1: Configuración Inicial (App Móvil)

1. Usuario activa "SMS Capture" en Settings
2. App solicita permisos de lectura de SMS (Android)
3. Usuario selecciona banco: Bancolombia, Davivienda, BBVA, etc.
4. App registra:
   - device_id
   - phone_number (hasheado)
   - bank_selected

### Paso 2: Procesamiento de SMS (Android Native)

```kotlin
class SMSCaptureReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)

    messages.forEach { sms ->
      // Verificar si es SMS bancario
      if (isBankSMS(sms.originatingAddress)) {
        // Extraer datos
        val parsedData = parseBankSMS(sms.messageBody)

        // Enviar a lambda
        sendToLambda(parsedData)
      }
    }
  }
}
```

### Paso 3: Envío a Lambda-Transactions

```typescript
POST /transactions/from-sms
{
  "sms_text": "Compra aprobada por $50,000 en EXITO el 12/07/2026",
  "sender": "BANCOLOMBIA",
  "received_at": "2026-07-12T14:30:00Z",
  "device_id": "abc123"
}
```

### Paso 4: Extracción con IA (Amazon Bedrock)

Lambda-transactions usa Bedrock para extraer:
- Tipo: "expense"
- Monto: 50000
- Merchant: "EXITO"
- Categoría: "Supermercado" (inferida)
- Fecha: "2026-07-12"

### Paso 5: Creación de Transacción

- Crea transacción con flag `created_from_sms: true`
- Estado inicial: `pending_review`
- Usuario puede confirmar/editar/eliminar desde app

## Patrones de SMS Soportados

### Bancolombia
```
Compra aprobada por $XX,XXX en [COMERCIO] el DD/MM/YYYY
Retiro aprobado por $XX,XXX en [CAJERO] el DD/MM/YYYY
```

### Davivienda
```
Compra con tu tarjeta *XXXX por $XX,XXX en [COMERCIO]
```

### BBVA
```
Compra $XX,XXX [COMERCIO] Tarjeta *XXXX
```

## Seguridad

- SMS NO se almacenan en BD (solo datos extraídos)
- Phone number hasheado (SHA-256)
- Validación de device_id con registro previo
- Rate limiting: 100 SMS/día por usuario

## Limitaciones

- Solo Android (iOS no permite acceso a SMS)
- Solo bancos colombianos listados
- Requiere formato estándar de SMS bancario
```

---

## 🟢 PRIORIDAD MEDIA (Sprint 2-3)

### 13. Crear Documento de Shared Lambda Layers

**Crear:** `/docs/backend/LAMBDA-LAYERS.md`

```markdown
# Lambda Layers Compartidos - TEMIS

## Objetivo

Evitar código duplicado en las 16 lambdas mediante layers reutilizables.

## Layers Propuestos

### 1. temis-core-layer (Node.js)

**Contenido:**
- Database connection pool (PostgreSQL)
- JWT utilities (verify, decode)
- RLS context setter
- Standard response formatter
- Error handler
- Logger (CloudWatch)

**Ubicación:** `/layers/temis-core/nodejs/`

**Uso:**
```javascript
const { db, jwt, response } = require('/opt/nodejs/temis-core');

// Todas las lambdas pueden usar:
const pool = db.getPool();
const userId = jwt.getUserId(token);
const res = response.success(data);
```

---

### 2. temis-subscription-middleware

**Funciones:**
- `validateSubscription(user_id)` → retorna subscription status
- `checkWriteAccess(user_id)` → true/false según si puede escribir
- Middleware Express/API Gateway

**Código:**
```javascript
async function validateSubscription(user_id, organization_id) {
  const result = await db.query(`
    SELECT status, current_period_end, plan_id
    FROM subscriptions
    WHERE user_id = $1 AND organization_id = $2
    AND status IN ('active', 'trial')
    LIMIT 1
  `, [user_id, organization_id]);

  if (!result.rows.length) {
    throw new Error('NO_ACTIVE_SUBSCRIPTION');
  }

  return result.rows[0];
}

async function checkWriteAccess(user_id, organization_id) {
  const sub = await validateSubscription(user_id, organization_id);

  // READ-ONLY si está expirado
  if (sub.status === 'expired') {
    return false;
  }

  return true;
}

module.exports = { validateSubscription, checkWriteAccess };
```

---

### 3. temis-ai-quota-middleware

**Funciones:**
- `checkAIQuota(user_id, feature_type)` → true/false
- `incrementAIUsage(user_id, tokens_used)`
- `getQuotaRemaining(user_id)`

**Código:**
```javascript
const { db } = require('/opt/nodejs/temis-core');

async function checkAIQuota(organization_id, user_id, feature_type) {
  // Llamar a función de PostgreSQL
  const result = await db.query(
    'SELECT check_ai_quota($1, $2, $3)',
    [organization_id, user_id, feature_type]
  );

  const hasQuota = result.rows[0].check_ai_quota;

  if (!hasQuota) {
    throw new QuotaExceededError('AI quota limit reached for current plan');
  }

  return true;
}

async function incrementAIUsage(organization_id, user_id, feature_type, tokens_input, tokens_output) {
  await db.query(`
    INSERT INTO ai_usage_logs (
      organization_id, user_id, feature_type,
      tokens_input, tokens_output, created_at
    ) VALUES ($1, $2, $3, $4, $5, NOW())
  `, [organization_id, user_id, feature_type, tokens_input, tokens_output]);
}

module.exports = { checkAIQuota, incrementAIUsage };
```

---

## Deployment

```bash
cd layers/temis-core
npm install
cd ../..
zip -r temis-core-layer.zip layers/temis-core

aws lambda publish-layer-version \
  --layer-name temis-core \
  --description "Core utilities for TEMIS lambdas" \
  --zip-file fileb://temis-core-layer.zip \
  --compatible-runtimes nodejs18.x nodejs20.x
```

## Uso en Lambda

Terraform:
```hcl
resource "aws_lambda_function" "tasks" {
  layers = [
    aws_lambda_layer_version.temis_core.arn,
    aws_lambda_layer_version.temis_subscription_middleware.arn
  ]
}
```
```

---

### 14. Crear Documento de Rate Limiting

**Crear:** `/docs/security/RATE-LIMITING.md`

```markdown
# Rate Limiting - TEMIS API

## Implementación

**Método:** AWS API Gateway Usage Plans + Lambda Authorizer

## Límites por Endpoint

### Autenticación (Alta Prioridad)

| Endpoint | Límite | Ventana | Acción al Exceder |
|----------|--------|---------|-------------------|
| POST /auth/login | 5 intentos | 15 min | Bloqueo temporal 15 min |
| POST /auth/register | 3 intentos | 1 hora | Bloqueo 1 hora |
| POST /auth/forgot-password | 3 intentos | 1 hora | Bloqueo 1 hora |
| POST /auth/refresh | 10 intentos | 1 min | 429 Too Many Requests |

### Endpoints de IA (Control de Costos)

| Endpoint | Límite | Ventana |
|----------|--------|---------|
| POST /voice/tasks | 20 | 1 hora |
| POST /voice/transactions | 20 | 1 hora |
| POST /ai/chat | 100 | 1 día |
| POST /memories/search | 50 | 1 hora |

### Endpoints Regulares (Prevención Abuso)

| Endpoint | Límite | Ventana |
|----------|--------|---------|
| POST /tasks | 100 | 1 min |
| POST /transactions | 100 | 1 min |
| GET * | 1000 | 1 min |
| DELETE * | 50 | 1 min |

## Implementación en API Gateway

```json
{
  "usagePlan": {
    "name": "temis-pro-plan",
    "throttle": {
      "rateLimit": 100,
      "burstLimit": 200
    },
    "quota": {
      "limit": 100000,
      "period": "MONTH"
    }
  }
}
```

## Headers de Respuesta

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1689123456
```

## Respuesta 429

```json
{
  "headers": {
    "httpStatusCode": 429,
    "httpStatusDesc": "Too Many Requests"
  },
  "messageResponse": {
    "responseCode": "0429",
    "responseMessage": "Rate limit exceeded",
    "responseDetail": "You have exceeded the rate limit for this endpoint. Please try again in 15 minutes."
  },
  "data": {
    "retry_after_seconds": 900,
    "limit": 5,
    "window": "15 minutes"
  }
}
```
```

---

### 15-17. Mejoras Adicionales

- **Agregar healthcheck endpoints** en todas las lambdas:
  ```yaml
  GET /health
  - Verifica conexión a PostgreSQL
  - Verifica acceso a S3
  - Retorna status: healthy/degraded/unhealthy
  ```

- **Agregar versioning en URLs:**
  ```
  Actual: /v1/tasks
  Futuro: /v2/tasks (con breaking changes)
  ```

- **Documentar CORS policies:**
  ```yaml
  Allowed Origins:
    - https://app.temis.com
    - https://admin.temis.com
    - http://localhost:3000 (dev)

  Allowed Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
  Allowed Headers: Authorization, Content-Type, message-uuid, request-app-id
  Max Age: 86400 (24 horas)
  ```

---

## 📊 Checklist de Implementación

### Críticos (Hacer AHORA)
- [ ] Agregar POST /auth/revoke-all-sessions
- [ ] Agregar POST /auth/verify
- [ ] Agregar DELETE /memories/{id} (GDPR)
- [ ] Agregar DELETE /memories/{id}/attachments/{id}
- [ ] Agregar GET /memories/export (GDPR)
- [ ] Mejorar documentación HMAC en webhooks

### Altos (Sprint 1)
- [ ] Agregar POST /subscriptions/retry-payment
- [ ] Agregar GET /subscriptions/alerts
- [ ] Agregar POST /voice/retry/{id}
- [ ] Agregar GET/POST /tasks/{id}/subtasks
- [ ] Agregar función check_task_limit() en DB
- [ ] Documentar validaciones de tamaño en Voice y AI Memory
- [ ] Configurar notificaciones SNS en AI Monitoring

### Medios (Sprint 2-3)
- [ ] Crear lambda layers compartidos
- [ ] Implementar rate limiting en API Gateway
- [ ] Documentar flujo de SMS Capture
- [ ] Agregar healthcheck endpoints
- [ ] Agregar POST /transactions/import (CSV)
- [ ] Agregar GET /budgets/{id}/projection

---

## 🎯 Impacto Esperado

**Antes de Updates:**
- Score de Completitud: 50/100
- Violaciones GDPR: 2 críticas
- Gaps de Seguridad: 4 críticos

**Después de Updates:**
- Score de Completitud: 98/100 ✅
- Violaciones GDPR: 0 ✅
- Gaps de Seguridad: 0 ✅
- Código duplicado: -40% (con layers)
- Conformidad legal: 100% ✅

---

**Próximo Paso:** Priorizar y comenzar implementación de updates críticos en orden de prioridad.

**Responsable:** Equipo de Backend
**Fecha Límite Críticos:** 2026-09-30
**Fecha Límite Altos:** 2026-10-15
**Fecha Límite Medios:** 2026-10-31
