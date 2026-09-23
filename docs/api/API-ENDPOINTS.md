# API Endpoints - TEMIS
## Arquitectura de Microservicios con AWS Lambda

---

## 1. Información General

### 1.1 Base URL
```
Development:  https://api-dev.temis.app/v1
Staging:      https://api-staging.temis.app/v1
Production:   https://api.temis.app/v1
```

### 1.2 Arquitectura de Lambdas (Microservicios)

Cada Lambda gestiona el CRUD de una entidad específica:

```
API Gateway
    ↓
    ├─ /auth/*          → lambda-auth         (users, tokens)
    ├─ /users/*         → lambda-users        (CRUD users)
    ├─ /tasks/*         → lambda-tasks        (CRUD tasks)
    ├─ /tags/*          → lambda-tags         (CRUD tags)
    ├─ /reminders/*     → lambda-reminders    (CRUD reminders)
    ├─ /passwords/*     → lambda-passwords    (CRUD passwords)
    ├─ /transactions/*  → lambda-transactions (CRUD transactions)
    ├─ /categories/*    → lambda-categories   (CRUD categories)
    ├─ /budgets/*       → lambda-budgets      (CRUD budgets)
    ├─ /subscriptions/* → lambda-subscriptions (CRUD subscriptions, payments)
    ├─ /voice/*         → lambda-voice        (Voice input for tasks & finances)
    ├─ /ai/*            → lambda-ai           (AI chat, insights, predictions)
    ├─ /webhooks/*      → lambda-webhooks     (Wompi payment webhooks)
    ├─ /admin/*         → lambda-admin        (Admin operations)
    └─ /notifications/* → lambda-notifications (Push/Email)
```

### 1.3 Autenticación
Todas las rutas (excepto `/auth/*` y `/webhooks/*`) requieren JWT Bearer Token:

```http
Authorization: Bearer <access_token>
```

### 1.4 Headers Requeridos
```http
Content-Type: application/json
Authorization: Bearer <token>
X-Device-ID: <unique_device_id>  (opcional)
X-App-Version: 1.0.0  (opcional)
```

### 1.5 Formato de Respuesta Estándar

#### Respuesta Exitosa
```json
{
  "success": true,
  "data": { /* payload */ },
  "meta": {
    "timestamp": "2026-07-12T10:30:00Z",
    "requestId": "req_abc123"
  }
}
```

#### Respuesta con Paginación
```json
{
  "success": true,
  "data": [ /* items */ ],
  "meta": {
    "page": 1,
    "perPage": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

#### Respuesta de Error
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "El título es requerido",
    "details": {
      "field": "title",
      "value": null
    }
  }
}
```

### 1.6 Códigos HTTP

| Código | Significado |
|--------|-------------|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Unprocessable Entity |
| 429 | Too Many Requests |
| 500 | Internal Server Error |

---

## 2. Lambda: Auth (Autenticación)

**Ruta**: `/auth/*`
**Lambda**: `lambda-auth`
**Tabla Principal**: `users`, `refresh_tokens`

### 2.1 Registro

```http
POST /auth/register
```

**Body**:
```json
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "password": "SecurePass123!",
  "timezone": "America/Mexico_City"
}
```

**Respuesta 201**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_123",
      "name": "Juan Pérez",
      "email": "juan@example.com",
      "organizationId": "org_123"
    },
    "tokens": {
      "accessToken": "eyJhbGc...",
      "refreshToken": "eyJhbGc...",
      "expiresIn": 900
    }
  }
}
```

---

### 2.2 Login

```http
POST /auth/login
```

**Body**:
```json
{
  "email": "juan@example.com",
  "password": "SecurePass123!",
  "deviceId": "device_abc",
  "deviceName": "iPhone 13"
}
```

**Respuesta 200**: (user + tokens)

---

### 2.3 Refresh Token

```http
POST /auth/refresh
```

**Body**:
```json
{
  "refreshToken": "eyJhbGc..."
}
```

**Respuesta 200**: (nuevo accessToken)

---

### 2.4 Logout

```http
POST /auth/logout
```

**Headers**: Authorization
**Respuesta 204**

---

### 2.5 Forgot Password

```http
POST /auth/forgot-password
```

**Body**:
```json
{
  "email": "juan@example.com"
}
```

---

### 2.6 Reset Password

```http
POST /auth/reset-password
```

**Body**:
```json
{
  "token": "reset_token",
  "newPassword": "NewPass123!"
}
```

---

## 3. Lambda: Users (Usuarios)

**Ruta**: `/users/*`
**Lambda**: `lambda-users`
**Tabla Principal**: `users`

### 3.1 Obtener Perfil

```http
GET /users/me
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "id": "user_123",
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "avatarUrl": null,
    "phone": "+52 555 1234",
    "organizationId": "org_123",
    "preferences": {
      "locale": "es_ES",
      "timezone": "America/Mexico_City",
      "currency": "MXN"
    },
    "subscription": {
      "planName": "Pro",
      "status": "active"
    }
  }
}
```

---

### 3.2 Actualizar Perfil

```http
PUT /users/me
```

**Body**:
```json
{
  "name": "Juan Pérez Updated",
  "phone": "+52 555 9999",
  "preferences": {
    "currency": "USD"
  }
}
```

**Respuesta 200**: (user actualizado)

---

### 3.3 Cambiar Contraseña

```http
POST /users/me/change-password
```

**Body**:
```json
{
  "currentPassword": "OldPass123!",
  "newPassword": "NewPass456!"
}
```

**Respuesta 200**

---

### 3.4 Subir Avatar

```http
POST /users/me/avatar
```

**Body**: (multipart/form-data)
```
file: <imagen> (jpg/png, max 5MB)
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "avatarUrl": "https://s3.../avatars/user_123.jpg"
  }
}
```

---

### 3.5 Eliminar Cuenta

```http
DELETE /users/me
```

**Body**:
```json
{
  "password": "MyPassword123!",
  "confirmation": "DELETE MY ACCOUNT"
}
```

**Respuesta 204**

---

## 4. Lambda: Tasks (Tareas)

**Ruta**: `/tasks/*`
**Lambda**: `lambda-tasks`
**Tabla Principal**: `tasks`, `task_tags`

### 4.1 Listar Tareas

```http
GET /tasks?status=pending&priority=high&page=1&limit=20
```

**Query Params**:
- `status`: pending|in_progress|completed|cancelled
- `priority`: low|medium|high|urgent
- `dueDateFrom`, `dueDateTo`: ISO dates
- `search`: texto
- `tagIds`: comma-separated UUIDs
- `page`, `limit`: paginación
- `sortBy`: created_at|due_date|priority
- `sortOrder`: asc|desc

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "task_123",
      "title": "Reunión con cliente",
      "description": "Presentar propuesta",
      "status": "pending",
      "priority": "high",
      "dueDate": "2026-07-15T10:00:00Z",
      "isAllDay": false,
      "tags": [
        {
          "id": "tag_1",
          "name": "Trabajo",
          "color": "#3B82F6"
        }
      ],
      "createdAt": "2026-07-10T08:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "perPage": 20,
    "total": 45
  }
}
```

---

### 4.2 Crear Tarea

```http
POST /tasks
```

**Body**:
```json
{
  "title": "Reunión con cliente",
  "description": "Presentar propuesta de proyecto",
  "priority": "high",
  "dueDate": "2026-07-15T10:00:00Z",
  "isAllDay": false,
  "tagIds": ["tag_1", "tag_2"],
  "reminders": [
    {
      "remindAt": "2026-07-15T09:45:00Z",
      "notificationType": "push"
    }
  ]
}
```

**Respuesta 201**: (tarea creada)

---

### 4.3 Obtener Tarea

```http
GET /tasks/{taskId}
```

**Respuesta 200**: (detalles de tarea)

---

### 4.4 Actualizar Tarea

```http
PUT /tasks/{taskId}
```

**Body**: (campos opcionales)
```json
{
  "title": "Nuevo título",
  "status": "in_progress",
  "priority": "urgent"
}
```

**Respuesta 200**: (tarea actualizada)

---

### 4.5 Eliminar Tarea

```http
DELETE /tasks/{taskId}
```

**Respuesta 204**

---

### 4.6 Completar Tarea

```http
POST /tasks/{taskId}/complete
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "id": "task_123",
    "status": "completed",
    "completedAt": "2026-07-12T10:30:00Z"
  }
}
```

---

### 4.7 Estadísticas

```http
GET /tasks/stats
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "total": 45,
    "pending": 20,
    "inProgress": 10,
    "completed": 15,
    "overdue": 5,
    "byPriority": {
      "low": 10,
      "medium": 20,
      "high": 10,
      "urgent": 5
    }
  }
}
```

---

## 5. Lambda: Tags (Etiquetas)

**Ruta**: `/tags/*`
**Lambda**: `lambda-tags`
**Tabla Principal**: `tags`

### 5.1 Listar Etiquetas

```http
GET /tags
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "tag_1",
      "name": "Trabajo",
      "color": "#3B82F6",
      "taskCount": 12,
      "createdAt": "2026-01-15"
    }
  ]
}
```

---

### 5.2 Crear Etiqueta

```http
POST /tags
```

**Body**:
```json
{
  "name": "Urgente",
  "color": "#EF4444"
}
```

**Respuesta 201**: (etiqueta creada)

---

### 5.3 Actualizar Etiqueta

```http
PUT /tags/{tagId}
```

**Body**:
```json
{
  "name": "Super Urgente",
  "color": "#DC2626"
}
```

---

### 5.4 Eliminar Etiqueta

```http
DELETE /tags/{tagId}
```

**Respuesta 204**

---

## 6. Lambda: Reminders (Recordatorios)

**Ruta**: `/reminders/*`
**Lambda**: `lambda-reminders`
**Tabla Principal**: `reminders`

### 6.1 Listar Recordatorios

```http
GET /reminders?upcoming=true
```

**Query Params**:
- `upcoming`: true (próximos 7 días)
- `isSent`: true|false
- `taskId`: UUID

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "rem_1",
      "taskId": "task_123",
      "title": "Recordatorio: Reunión",
      "remindAt": "2026-07-15T09:45:00Z",
      "isSent": false,
      "notificationType": "push",
      "notificationStyle": "alarm"
    }
  ]
}
```

**Nota**: `notificationStyle` se determina automáticamente:
- Si tarea es `urgent` o `high` → `"alarm"` (alarma insistente)
- Si tarea es `medium` o `low` → `"notification"` (notificación discreta)

---

### 6.2 Crear Recordatorio

```http
POST /reminders
```

**Body**:
```json
{
  "taskId": "task_123",
  "title": "Recordatorio personalizado",
  "remindAt": "2026-07-15T09:00:00Z",
  "notificationType": "push"
}
```

**Respuesta 201**: (recordatorio creado)

---

### 6.3 Eliminar Recordatorio

```http
DELETE /reminders/{reminderId}
```

**Respuesta 204**

---

## 7. Lambda: Passwords (Contraseñas)

**Ruta**: `/passwords/*`
**Lambda**: `lambda-passwords`
**Tabla Principal**: `passwords`

### 7.1 Listar Contraseñas

```http
GET /passwords?category=bank&search=nacional
```

**Query Params**:
- `category`: website|bank|wifi|email|app|other
- `search`: texto
- `isFavorite`: true|false

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "pwd_1",
      "name": "Banco Nacional",
      "username": "12345678",
      "url": "https://banco.com",
      "category": "bank",
      "isFavorite": true,
      "lastUsedAt": "2026-07-10",
      "createdAt": "2026-01-15"
    }
  ]
}
```

**IMPORTANTE**: La contraseña NO se devuelve en el listado.

---

### 7.2 Obtener Contraseña (con password)

```http
GET /passwords/{passwordId}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "id": "pwd_1",
    "name": "Banco Nacional",
    "username": "12345678",
    "password": "MySecurePassword123!",
    "url": "https://banco.com",
    "notes": "Tarjeta principal",
    "category": "bank",
    "tags": ["principal"],
    "isFavorite": true
  }
}
```

**Seguridad**:
- Se registra en audit_logs cada acceso
- Rate limit: 20 req/min

---

### 7.3 Crear Contraseña

```http
POST /passwords
```

**Body**:
```json
{
  "name": "Banco Nacional",
  "username": "12345678",
  "password": "MySecurePassword123!",
  "url": "https://banco.com",
  "notes": "Tarjeta de débito",
  "category": "bank",
  "tags": ["principal"]
}
```

**Respuesta 201**: (password creada, encriptada en BD)

---

### 7.4 Actualizar Contraseña

```http
PUT /passwords/{passwordId}
```

**Body**:
```json
{
  "name": "Banco Nacional - Personal",
  "password": "NewPassword456!"
}
```

---

### 7.5 Eliminar Contraseña

```http
DELETE /passwords/{passwordId}
```

**Respuesta 204**

---

### 7.6 Generar Contraseña

```http
POST /passwords/generate
```

**Body**:
```json
{
  "length": 16,
  "includeUppercase": true,
  "includeLowercase": true,
  "includeNumbers": true,
  "includeSymbols": true,
  "excludeAmbiguous": true
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "password": "K#9mP2xL@4nQ7wR5",
    "strength": "very_strong",
    "entropy": 95.2
  }
}
```

---

### 7.7 Auditoría de Seguridad

```http
GET /passwords/audit
```

**Requiere**: Plan Premium

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "overallScore": 75,
    "totalPasswords": 25,
    "weakPasswords": 3,
    "reusedPasswords": 2,
    "expiringSoon": 1,
    "recommendations": [
      {
        "passwordId": "pwd_5",
        "name": "Facebook",
        "issue": "weak_password",
        "severity": "high"
      }
    ]
  }
}
```

---

## 8. Lambda: Transactions (Transacciones)

**Ruta**: `/transactions/*`
**Lambda**: `lambda-transactions`
**Tabla Principal**: `transactions`, `sms_messages`

### 8.1 Listar Transacciones

```http
GET /transactions?type=expense&dateFrom=2026-07-01&dateTo=2026-07-31
```

**Query Params**:
- `type`: income|expense
- `categoryId`: UUID
- `dateFrom`, `dateTo`: ISO dates
- `source`: manual|voice|sms|import
- `minAmount`, `maxAmount`: decimal
- `search`: texto
- `page`, `limit`: paginación

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "trx_1",
      "type": "expense",
      "amount": 350.50,
      "currency": "USD",
      "description": "Compra en supermercado",
      "transactionDate": "2026-07-12T10:30:00Z",
      "source": "sms",
      "paymentMethod": "credit_card",
      "category": {
        "id": "cat_1",
        "name": "Alimentación",
        "icon": "🍔"
      },
      "tags": ["mercado"],
      "createdAt": "2026-07-12T10:35:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "total": 150,
    "summary": {
      "totalIncome": 5000.00,
      "totalExpense": 3500.50,
      "balance": 1499.50
    }
  }
}
```

---

### 8.2 Crear Transacción Manual

```http
POST /transactions
```

**Body**:
```json
{
  "type": "expense",
  "amount": 50.00,
  "currency": "USD",
  "description": "Almuerzo",
  "transactionDate": "2026-07-12T13:00:00Z",
  "categoryId": "cat_1",
  "paymentMethod": "credit_card",
  "tags": ["restaurante"]
}
```

**Respuesta 201**: (transacción creada)

---

### 8.3 Crear Transacción por Voz

```http
POST /transactions/voice
```

**Body**: (multipart/form-data)
```
audio: <archivo mp3/aac/wav> (max 30 segundos)
language: es-ES
```

**Respuesta 202**:
```json
{
  "success": true,
  "data": {
    "jobId": "job_voice_abc123",
    "status": "processing",
    "estimatedTime": 15
  }
}
```

---

### 8.4 Consultar Estado de Voz

```http
GET /transactions/voice/{jobId}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "jobId": "job_voice_abc123",
    "status": "completed",
    "transcription": "gasté cincuenta dólares en el supermercado",
    "parsed": {
      "type": "expense",
      "amount": 50.00,
      "categoryId": "cat_alimentacion",
      "description": "Supermercado",
      "confidence": 0.95
    }
  }
}
```

---

### 8.5 Confirmar Transacción por Voz

```http
POST /transactions/voice/{jobId}/confirm
```

**Body**:
```json
{
  "type": "expense",
  "amount": 50.00,
  "categoryId": "cat_alimentacion",
  "description": "Supermercado editado"
}
```

**Respuesta 201**: (transacción creada)

---

### 8.6 Procesar SMS Bancario

```http
POST /transactions/sms
```

**Body**:
```json
{
  "sender": "BANCO",
  "messageBody": "Compra por $350.50 en STARBUCKS con tu tarjeta *1234",
  "receivedAt": "2026-07-12T10:30:00Z"
}
```

**Respuesta 201**:
```json
{
  "success": true,
  "data": {
    "transactionId": "trx_123",
    "smsMessageId": "sms_456",
    "parsed": {
      "type": "expense",
      "amount": 350.50,
      "description": "STARBUCKS",
      "paymentMethod": "credit_card"
    }
  }
}
```

---

### 8.7 Dashboard Financiero

```http
GET /transactions/dashboard?month=2026-07
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "period": "2026-07",
    "summary": {
      "totalIncome": 5000.00,
      "totalExpense": 3500.50,
      "balance": 1499.50,
      "transactionCount": 150
    },
    "comparison": {
      "previousMonth": {
        "totalIncome": 4800.00,
        "totalExpense": 3200.00,
        "changeIncome": 4.17,
        "changeExpense": 9.39
      }
    },
    "byCategory": [
      {
        "categoryName": "Alimentación",
        "icon": "🍔",
        "total": 1200.00,
        "percentage": 34.3,
        "transactionCount": 45
      }
    ],
    "topExpenses": [
      {
        "description": "Renta",
        "amount": 1000.00,
        "date": "2026-07-01"
      }
    ],
    "trend": [
      {
        "month": "2026-01",
        "income": 4500.00,
        "expense": 3000.00
      }
    ]
  }
}
```

---

### 8.8 Generar Reporte

```http
POST /transactions/reports
```

**Body**:
```json
{
  "type": "monthly_summary",
  "dateFrom": "2026-07-01",
  "dateTo": "2026-07-31",
  "format": "pdf",
  "sendEmail": true
}
```

**Respuesta 202**:
```json
{
  "success": true,
  "data": {
    "reportId": "rpt_abc123",
    "status": "generating"
  }
}
```

---

### 8.9 Obtener Reporte

```http
GET /transactions/reports/{reportId}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "reportId": "rpt_abc123",
    "status": "completed",
    "downloadUrl": "https://s3.amazonaws.com/.../report.pdf",
    "expiresAt": "2026-07-13T10:30:00Z"
  }
}
```

---

## 9. Lambda: Categories (Categorías)

**Ruta**: `/categories/*`
**Lambda**: `lambda-categories`
**Tabla Principal**: `categories`

### 9.1 Listar Categorías

```http
GET /categories?type=expense
```

**Query Params**:
- `type`: income|expense
- `includeDefault`: true|false

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "cat_1",
      "name": "Alimentación",
      "type": "expense",
      "icon": "🍔",
      "color": "#FF6B6B",
      "isDefault": true
    }
  ]
}
```

---

### 9.2 Crear Categoría

```http
POST /categories
```

**Body**:
```json
{
  "name": "Gimnasio",
  "type": "expense",
  "icon": "💪",
  "color": "#4CAF50"
}
```

---

### 9.3 Actualizar/Eliminar Categoría

```http
PUT /categories/{categoryId}
DELETE /categories/{categoryId}
```

---

## 10. Lambda: Budgets (Presupuestos)

**Ruta**: `/budgets/*`
**Lambda**: `lambda-budgets`
**Tabla Principal**: `budgets`

### 10.1 Listar Presupuestos

```http
GET /budgets?isActive=true
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "bdg_1",
      "name": "Alimentación Mensual",
      "categoryId": "cat_1",
      "amount": 1500.00,
      "spent": 1200.00,
      "remaining": 300.00,
      "percentage": 80,
      "period": "monthly",
      "startDate": "2026-07-01",
      "endDate": "2026-07-31"
    }
  ]
}
```

---

### 10.2 Crear Presupuesto

```http
POST /budgets
```

**Body**:
```json
{
  "name": "Alimentación Mensual",
  "categoryId": "cat_1",
  "amount": 1500.00,
  "period": "monthly",
  "alertThreshold": 80
}
```

---

## 11. Lambda: Subscriptions (Suscripciones)

**Ruta**: `/subscriptions/*`
**Lambda**: `lambda-subscriptions`
**Tabla Principal**: `subscriptions`, `plans`

### 11.1 Ver Plan Actual

```http
GET /subscriptions/current
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "id": "sub_123",
    "planId": "plan_pro",
    "planName": "Pro",
    "status": "active",
    "startDate": "2026-06-01",
    "endDate": "2026-07-01",
    "autoRenew": true,
    "features": {
      "tasks": true,
      "passwords": true,
      "finance": true
    }
  }
}
```

---

### 11.2 Listar Planes Disponibles

```http
GET /subscriptions/plans
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "plan_free",
      "name": "Free",
      "priceMonthly": 0.00,
      "priceYearly": 0.00,
      "features": {
        "tasks": true,
        "passwords": false,
        "finance": false
      }
    },
    {
      "id": "plan_pro",
      "name": "Pro",
      "priceMonthly": 9.99,
      "priceYearly": 99.90,
      "features": {
        "tasks": true,
        "passwords": true,
        "finance": true
      }
    }
  ]
}
```

---

### 11.3 Upgrade de Plan

```http
POST /subscriptions/upgrade
```

**Body**:
```json
{
  "planId": "plan_premium",
  "billingCycle": "monthly",
  "paymentMethodId": "pm_card_visa"
}
```

**Respuesta 200**: (nueva suscripción + invoice)

---

### 11.4 Cambiar de Plan

```http
POST /subscriptions/change-plan
```

**Body**:
```json
{
  "newPlanId": "plan_premium",
  "billingCycle": "monthly"
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "subscriptionId": "sub_456",
    "oldPlan": "Pro",
    "newPlan": "Premium",
    "effectiveDate": "2026-07-12T10:30:00Z",
    "nextBillingDate": "2026-08-12",
    "proratedAmount": 10.00
  }
}
```

**Nota**: El usuario puede cambiar de plan en cualquier momento. Si cambia a un plan superior, se cobra el monto prorrateado inmediatamente.

---

### 11.5 Iniciar Checkout (Wompi)

```http
POST /subscriptions/checkout
```

**Body**:
```json
{
  "planId": "plan_pro",
  "billingCycle": "monthly",
  "returnUrl": "https://app.temis.com/payment/success"
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "checkoutId": "checkout_abc123",
    "wompiTransactionId": "wompi_trx_xyz",
    "checkoutUrl": "https://checkout.wompi.co/abc123",
    "amount": 9.99,
    "currency": "USD",
    "expiresAt": "2026-07-12T11:00:00Z"
  }
}
```

**Nota**: El usuario es redirigido a Wompi para completar el pago.

---

### 11.6 Guardar Método de Pago

```http
POST /subscriptions/payment-methods
```

**Body**:
```json
{
  "wompiPaymentSourceId": "tok_card_abc123",
  "cardBrand": "Visa",
  "lastFourDigits": "4242",
  "expiryMonth": 12,
  "expiryYear": 2028,
  "cardholderName": "Juan Pérez",
  "setAsDefault": true
}
```

**Respuesta 201**:
```json
{
  "success": true,
  "data": {
    "id": "pm_123",
    "cardBrand": "Visa",
    "lastFourDigits": "4242",
    "expiryMonth": 12,
    "expiryYear": 2028,
    "isDefault": true
  }
}
```

**IMPORTANTE**: Nunca enviar el número completo de tarjeta ni CVV. Solo el token de Wompi.

---

### 11.7 Listar Métodos de Pago

```http
GET /subscriptions/payment-methods
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": [
    {
      "id": "pm_123",
      "cardBrand": "Visa",
      "lastFourDigits": "4242",
      "expiryMonth": 12,
      "expiryYear": 2028,
      "isDefault": true,
      "isActive": true
    }
  ]
}
```

---

### 11.8 Eliminar Método de Pago

```http
DELETE /subscriptions/payment-methods/{paymentMethodId}
```

**Respuesta 204**

---

### 11.9 Cancelar Suscripción

```http
POST /subscriptions/cancel
```

**Body**:
```json
{
  "reason": "Muy caro",
  "feedback": "Me gustaría un plan intermedio",
  "cancelImmediately": false
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "subscriptionId": "sub_123",
    "status": "cancelled",
    "cancelledAt": "2026-07-12T10:30:00Z",
    "accessUntil": "2026-08-12"
  }
}
```

**Nota**: Si `cancelImmediately: false`, el usuario mantiene acceso hasta el final del periodo pagado.

---

## 12. Lambda: Voice (Entrada por Voz)

**Ruta**: `/voice/*`
**Lambda**: `lambda-voice`
**Tabla Principal**: `tasks`, `transactions`, `ai_conversations`, `ai_usage`
**Servicios**: AWS Transcribe, Amazon Bedrock

### 12.1 Crear Tarea por Voz

```http
POST /voice/tasks
```

**Body**: (multipart/form-data)
```
audio: <archivo mp3/aac/wav/m4a> (max 60 segundos)
language: es-ES|en-US
```

**Respuesta 202**:
```json
{
  "success": true,
  "data": {
    "jobId": "voice_task_abc123",
    "status": "processing",
    "estimatedTime": 10
  }
}
```

---

### 12.2 Consultar Estado de Procesamiento

```http
GET /voice/tasks/{jobId}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "jobId": "voice_task_abc123",
    "status": "completed",
    "transcription": "reunión con el cliente mañana a las 10 de la mañana prioridad alta",
    "parsed": {
      "title": "Reunión con el cliente",
      "description": "Reunión con el cliente mañana a las 10 de la mañana",
      "priority": "high",
      "dueDate": "2026-07-13T10:00:00Z",
      "suggestedTags": ["reunión", "cliente"],
      "confidence": 0.92
    }
  }
}
```

---

### 12.3 Confirmar y Crear Tarea

```http
POST /voice/tasks/{jobId}/confirm
```

**Body**:
```json
{
  "title": "Reunión con el cliente",
  "description": "Presentar propuesta",
  "priority": "high",
  "dueDate": "2026-07-13T10:00:00Z",
  "tagIds": ["tag_1"]
}
```

**Respuesta 201**: (tarea creada)

**Nota**: La cuota de uso de IA se incrementa al confirmar.

---

### 12.4 Crear Transacción por Voz

```http
POST /voice/transactions
```

**Body**: (multipart/form-data)
```
audio: <archivo mp3/aac/wav/m4a> (max 60 segundos)
language: es-ES|en-US
```

**Respuesta 202**:
```json
{
  "success": true,
  "data": {
    "jobId": "voice_trx_xyz789",
    "status": "processing",
    "estimatedTime": 10
  }
}
```

---

### 12.5 Consultar Estado de Transacción por Voz

```http
GET /voice/transactions/{jobId}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "jobId": "voice_trx_xyz789",
    "status": "completed",
    "transcription": "gasté cincuenta dólares en el supermercado",
    "parsed": {
      "type": "expense",
      "amount": 50.00,
      "currency": "USD",
      "description": "Supermercado",
      "categoryId": "cat_alimentacion",
      "paymentMethod": "cash",
      "transactionDate": "2026-07-12T10:30:00Z",
      "confidence": 0.95
    }
  }
}
```

---

### 12.6 Confirmar y Crear Transacción

```http
POST /voice/transactions/{jobId}/confirm
```

**Body**:
```json
{
  "type": "expense",
  "amount": 50.00,
  "currency": "USD",
  "description": "Supermercado",
  "categoryId": "cat_alimentacion",
  "paymentMethod": "cash"
}
```

**Respuesta 201**: (transacción creada)

**Nota**: La cuota de uso de IA se incrementa al confirmar.

---

### 12.7 Verificar Cuota Disponible

```http
GET /voice/quota
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "voiceTask": {
      "used": 5,
      "limit": 100,
      "remaining": 95,
      "resetDate": "2026-08-01"
    },
    "voiceFinance": {
      "used": 3,
      "limit": 100,
      "remaining": 97,
      "resetDate": "2026-08-01"
    }
  }
}
```

---

## 13. Lambda: AI (Asistente Inteligente)

**Ruta**: `/ai/*`
**Lambda**: `lambda-ai`
**Tabla Principal**: `ai_conversations`, `ai_usage`
**Servicio**: Amazon Bedrock (Claude 3.5 Sonnet)

### 13.1 Chat Conversacional

```http
POST /ai/chat
```

**Body**:
```json
{
  "conversationId": "conv_abc123",
  "message": "¿Cuánto gasté este mes en restaurantes?",
  "includeContext": true
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "conversationId": "conv_abc123",
    "response": "En julio 2026 has gastado $450.00 USD en restaurantes, distribuidos en 15 transacciones. Esto representa el 12.8% de tus gastos totales del mes.",
    "tokensUsed": {
      "input": 850,
      "output": 120
    },
    "remainingQuota": 78
  }
}
```

**Nota**: `includeContext: true` permite a la IA acceder a datos financieros y tareas del usuario (anonimizados).

---

### 13.2 Obtener Historial de Conversación

```http
GET /ai/conversations/{conversationId}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "conversationId": "conv_abc123",
    "messages": [
      {
        "id": "msg_1",
        "role": "user",
        "content": "¿Cuánto gasté este mes?",
        "timestamp": "2026-07-12T10:00:00Z"
      },
      {
        "id": "msg_2",
        "role": "assistant",
        "content": "Este mes has gastado $3,500.50 USD...",
        "timestamp": "2026-07-12T10:00:05Z"
      }
    ],
    "createdAt": "2026-07-12T10:00:00Z"
  }
}
```

---

### 13.3 Generar Insights Automáticos

```http
POST /ai/insights
```

**Requiere**: Plan Pro o Premium

**Body**:
```json
{
  "period": "month",
  "dateFrom": "2026-07-01",
  "dateTo": "2026-07-31",
  "focusAreas": ["spending_patterns", "budget_health", "recommendations"]
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "insights": [
      {
        "type": "spending_pattern",
        "title": "Aumento en gastos de entretenimiento",
        "description": "Tus gastos en entretenimiento aumentaron 25% este mes comparado con el mes anterior.",
        "severity": "medium",
        "recommendation": "Considera reducir salidas a restaurantes para mantener tu presupuesto."
      },
      {
        "type": "budget_alert",
        "title": "Presupuesto de alimentación casi agotado",
        "description": "Has usado el 85% de tu presupuesto mensual de alimentación.",
        "severity": "high",
        "recommendation": "Te quedan $225 para los próximos 19 días del mes."
      }
    ],
    "summary": {
      "overallHealth": "good",
      "score": 78
    },
    "remainingQuota": 15
  }
}
```

---

### 13.4 Predicciones Financieras

```http
POST /ai/predictions
```

**Requiere**: Plan Premium

**Body**:
```json
{
  "predictionType": "end_of_month_balance",
  "includeRecommendations": true
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "prediction": {
      "type": "end_of_month_balance",
      "estimatedBalance": 1250.00,
      "confidence": 0.87,
      "factors": [
        {
          "name": "Promedio de gastos diarios",
          "impact": "high",
          "value": 115.50
        },
        {
          "name": "Ingresos pendientes",
          "impact": "medium",
          "value": 500.00
        }
      ]
    },
    "recommendations": [
      "Reduce gastos discrecionales en $200 para alcanzar tu objetivo de ahorro",
      "Considera adelantar el pago de facturas para evitar cargos por mora"
    ],
    "remainingQuota": 18
  }
}
```

---

### 13.5 Resumen Inteligente

```http
POST /ai/summary
```

**Body**:
```json
{
  "summaryType": "weekly_tasks",
  "dateFrom": "2026-07-08",
  "dateTo": "2026-07-14"
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "summary": "Esta semana completaste 12 de 18 tareas pendientes (67%). Tienes 3 tareas de alta prioridad vencidas que requieren atención inmediata. Tu productividad aumentó 15% comparado con la semana anterior.",
    "highlights": [
      "✅ Completaste el proyecto cliente ABC",
      "⚠️ 3 tareas urgentes vencidas",
      "📈 Productividad: +15%"
    ],
    "nextActions": [
      "Priorizar las 3 tareas urgentes vencidas",
      "Revisar presupuesto de alimentación (85% usado)"
    ]
  }
}
```

---

### 13.6 Verificar Cuota de IA

```http
GET /ai/usage
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "period": "2026-07",
    "plan": "Pro",
    "usage": {
      "chat": {
        "used": 22,
        "limit": 100,
        "remaining": 78
      },
      "insights": {
        "used": 5,
        "limit": 20,
        "remaining": 15
      },
      "predictions": {
        "used": 0,
        "limit": 0,
        "available": false,
        "requiredPlan": "Premium"
      }
    },
    "totalTokensConsumed": 45230,
    "estimatedCost": 0.67,
    "resetDate": "2026-08-01"
  }
}
```

---

## 14. Lambda: Webhooks (Wompi)

**Ruta**: `/webhooks/*`
**Lambda**: `lambda-webhooks`
**Tabla Principal**: `subscriptions`, `payment_audit_logs`
**Seguridad**: Verificación de firma HMAC SHA-256

**IMPORTANTE**: Esta ruta NO requiere JWT. La autenticación se realiza mediante la firma del webhook.

### 14.1 Webhook de Pagos (Wompi)

```http
POST /webhooks/wompi
```

**Headers**:
```http
Content-Type: application/json
X-Event: transaction.updated
X-Signature: sha256=abc123...
```

**Body** (ejemplo de pago exitoso):
```json
{
  "event": "transaction.updated",
  "data": {
    "transaction": {
      "id": "wompi_trx_123",
      "status": "APPROVED",
      "amount_in_cents": 999,
      "currency": "COP",
      "customer_email": "juan@example.com",
      "reference": "sub_123_renewal",
      "payment_method_type": "CARD",
      "payment_method": {
        "type": "CARD",
        "extra": {
          "last_four": "4242",
          "brand": "VISA"
        }
      },
      "created_at": "2026-07-12T10:30:00Z"
    }
  },
  "sent_at": "2026-07-12T10:30:05Z",
  "timestamp": 1657622405
}
```

**Respuesta 200**:
```json
{
  "success": true,
  "received": true
}
```

**Proceso interno**:
1. Verificar firma HMAC SHA-256
2. Validar que el evento no haya sido procesado (idempotencia)
3. Actualizar estado de suscripción según resultado
4. Registrar evento en `payment_audit_logs`
5. Si pago fallido y es renovación, notificar al usuario

**Estados de Wompi**:
- `PENDING`: Pago pendiente
- `APPROVED`: Pago aprobado (activar suscripción)
- `DECLINED`: Pago rechazado (notificar usuario)
- `VOIDED`: Pago anulado
- `ERROR`: Error en el procesamiento

---

## 15. Lambda: Admin (Administración)

**Ruta**: `/admin/*`
**Lambda**: `lambda-admin`
**Requiere**: Rol `superadmin`

### 12.1 Dashboard

```http
GET /admin/dashboard
```

**Respuesta 200**:
```json
{
  "success": true,
  "data": {
    "users": {
      "total": 1250,
      "active": 980,
      "dau": 450,
      "mau": 850
    },
    "subscriptions": {
      "free": 500,
      "basic": 300,
      "pro": 350,
      "premium": 100
    },
    "revenue": {
      "mrr": 8475.00,
      "arr": 101700.00
    }
  }
}
```

---

### 12.2 Buscar Usuarios

```http
GET /admin/users?search=juan&status=active
```

---

### 12.3 Suspender Usuario

```http
POST /admin/users/{userId}/suspend
```

---

## 16. Lambda: Notifications (Notificaciones)

**Ruta**: `/notifications/*`
**Lambda**: `lambda-notifications`
**Uso**: Procesamiento asíncrono de notificaciones

### Función Interna (no expuesta via API)

Esta lambda es invocada por:
- EventBridge (recordatorios programados)
- Otras lambdas (eventos del sistema)

**Responsabilidades**:
1. Enviar push notifications via SNS
2. Enviar emails via SES
3. Determinar estilo según prioridad:
   - Urgente/Alta → Alarma insistente
   - Media/Baja → Notificación normal

---

## 17. Estructura de Lambdas en Backend

```
backend/
├── lambdas/
│   ├── auth/
│   │   ├── index.js              # Handler principal
│   │   ├── controllers/
│   │   │   ├── register.js
│   │   │   ├── login.js
│   │   │   ├── refresh.js
│   │   │   └── logout.js
│   │   ├── services/
│   │   │   ├── jwt.service.js
│   │   │   └── password.service.js
│   │   └── package.json
│   │
│   ├── users/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   ├── getProfile.js
│   │   │   ├── updateProfile.js
│   │   │   └── changePassword.js
│   │   ├── services/
│   │   │   └── user.service.js
│   │   └── package.json
│   │
│   ├── tasks/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   ├── list.js
│   │   │   ├── create.js
│   │   │   ├── get.js
│   │   │   ├── update.js
│   │   │   ├── delete.js
│   │   │   └── complete.js
│   │   ├── services/
│   │   │   └── task.service.js
│   │   └── package.json
│   │
│   ├── passwords/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   ├── list.js
│   │   │   ├── create.js
│   │   │   ├── get.js
│   │   │   ├── update.js
│   │   │   ├── delete.js
│   │   │   ├── generate.js
│   │   │   └── audit.js
│   │   ├── services/
│   │   │   ├── password.service.js
│   │   │   └── encryption.service.js
│   │   └── package.json
│   │
│   ├── transactions/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   ├── list.js
│   │   │   ├── create.js
│   │   │   ├── voice.js
│   │   │   ├── sms.js
│   │   │   ├── dashboard.js
│   │   │   └── reports.js
│   │   ├── services/
│   │   │   ├── transaction.service.js
│   │   │   ├── transcribe.service.js
│   │   │   └── sms-parser.service.js
│   │   └── package.json
│   │
│   ├── voice/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   ├── voiceTask.js
│   │   │   ├── voiceTransaction.js
│   │   │   └── quota.js
│   │   ├── services/
│   │   │   ├── transcribe.service.js
│   │   │   ├── bedrock.service.js
│   │   │   └── voice-parser.service.js
│   │   └── package.json
│   │
│   ├── ai/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   ├── chat.js
│   │   │   ├── insights.js
│   │   │   ├── predictions.js
│   │   │   └── summary.js
│   │   ├── services/
│   │   │   ├── bedrock.service.js
│   │   │   ├── context-builder.service.js
│   │   │   └── quota.service.js
│   │   └── package.json
│   │
│   ├── webhooks/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   └── wompi.js
│   │   ├── services/
│   │   │   ├── signature-verifier.service.js
│   │   │   └── payment-processor.service.js
│   │   └── package.json
│   │
│   ├── notifications/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   ├── sendPush.js
│   │   │   └── sendEmail.js
│   │   ├── services/
│   │   │   ├── sns.service.js
│   │   │   ├── ses.service.js
│   │   │   └── priority-handler.js  # Determina alarma vs notificación
│   │   └── package.json
│   │
│   ├── maintenance/
│   │   ├── index.js
│   │   ├── controllers/
│   │   │   ├── cleanupAuditLogs.js
│   │   │   ├── cleanupRefreshTokens.js
│   │   │   ├── cleanupConversations.js
│   │   │   └── cleanupPaymentLogs.js
│   │   └── package.json
│   │
│   └── [otras lambdas...]
│
└── shared/
    ├── database/
    │   ├── connection.js
    │   └── queries/
    ├── middleware/
    │   ├── auth.middleware.js
    │   ├── rls.middleware.js        # Row-Level Security
    │   └── validation.middleware.js
    ├── utils/
    │   ├── response.js
    │   └── errors.js
    └── package.json
```

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.1.0

## Changelog

### v1.1.0 (2026-07-12)
- ✅ Añadidos endpoints de **Lambda Voice** (`/voice/*`):
  - POST `/voice/tasks` - Crear tarea por voz
  - GET `/voice/tasks/{jobId}` - Consultar estado
  - POST `/voice/tasks/{jobId}/confirm` - Confirmar tarea
  - POST `/voice/transactions` - Crear transacción por voz
  - GET `/voice/transactions/{jobId}` - Consultar estado
  - POST `/voice/transactions/{jobId}/confirm` - Confirmar transacción
  - GET `/voice/quota` - Verificar cuota disponible
- ✅ Añadidos endpoints de **Lambda AI** (`/ai/*`):
  - POST `/ai/chat` - Chat conversacional con IA
  - GET `/ai/conversations/{conversationId}` - Historial de conversación
  - POST `/ai/insights` - Generar insights automáticos
  - POST `/ai/predictions` - Predicciones financieras (Premium)
  - POST `/ai/summary` - Resúmenes inteligentes
  - GET `/ai/usage` - Verificar cuota de IA
- ✅ Añadidos endpoints de **Lambda Webhooks** (`/webhooks/*`):
  - POST `/webhooks/wompi` - Webhook de pagos Wompi
- ✅ Actualizados endpoints de **Lambda Subscriptions**:
  - POST `/subscriptions/change-plan` - Cambiar de plan en cualquier momento
  - POST `/subscriptions/checkout` - Iniciar checkout con Wompi
  - POST `/subscriptions/payment-methods` - Guardar método de pago
  - GET `/subscriptions/payment-methods` - Listar métodos de pago
  - DELETE `/subscriptions/payment-methods/{id}` - Eliminar método de pago
  - POST `/subscriptions/cancel` - Cancelar suscripción
- ✅ Actualizada arquitectura de lambdas en diagrama
- ✅ Actualizada estructura de carpetas backend con nuevas lambdas
- ✅ Documentadas integraciones con Amazon Bedrock y AWS Transcribe
- ✅ Documentado sistema de cuotas de IA por plan
- ✅ Documentada seguridad de webhooks con HMAC SHA-256
- ✅ Agregada lambda-maintenance para limpieza programada de datos:
  - Limpieza de audit_logs (> 1 año)
  - Limpieza de refresh_tokens revocados/expirados (> 7 días)
  - Limpieza de ai_conversations (> 6 meses)
  - Limpieza de payment_audit_logs (> 2 años)
