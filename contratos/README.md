# Contratos API - TEMIS
## Especificaciones Swagger/OpenAPI 2.0

---

## 📋 Información General

**Formato**: Swagger 2.0 / OpenAPI 2.0
**Propósito**: Definir contratos de API para cada Lambda/Microservicio
**Versión Base**: 1.0.0

---

## 📂 Estructura de Contratos

```
contratos/
├── README.md
├── common-definitions.yaml          # Definiciones comunes reutilizables
│
├── TEMIS_CONTRATO_AUTH_V1.0.yaml    # Autenticación
├── TEMIS_CONTRATO_TASKS_V1.0.yaml   # Gestión de Tareas
├── TEMIS_CONTRATO_PASSWORDS_V1.0.yaml  # Gestor de Contraseñas
├── TEMIS_CONTRATO_TRANSACTIONS_V1.0.yaml  # Finanzas
├── TEMIS_CONTRATO_SUBSCRIPTIONS_V1.0.yaml  # Suscripciones y Pagos
├── TEMIS_CONTRATO_VOICE_V1.0.yaml   # Entrada por Voz
├── TEMIS_CONTRATO_AI_V1.0.yaml      # Asistente IA
├── TEMIS_CONTRATO_USERS_V1.0.yaml   # Usuarios
├── TEMIS_CONTRATO_TAGS_V1.0.yaml    # Etiquetas
├── TEMIS_CONTRATO_CATEGORIES_V1.0.yaml  # Categorías
├── TEMIS_CONTRATO_BUDGETS_V1.0.yaml # Presupuestos
├── TEMIS_CONTRATO_REMINDERS_V1.0.yaml   # Recordatorios
├── TEMIS_CONTRATO_WEBHOOKS_V1.0.yaml    # Webhooks Wompi
└── TEMIS_CONTRATO_ADMIN_V1.0.yaml   # Administración
```

---

## 🎯 Lambdas y sus Contratos

| Lambda | Contrato | Endpoints Principales |
|--------|----------|----------------------|
| lambda-auth | TEMIS_CONTRATO_AUTH_V1.0.yaml | /auth/register, /auth/login, /auth/refresh |
| lambda-tasks | TEMIS_CONTRATO_TASKS_V1.0.yaml | /tasks, /tasks/{id}, /tasks/stats |
| lambda-passwords | TEMIS_CONTRATO_PASSWORDS_V1.0.yaml | /passwords, /passwords/{id}, /passwords/generate |
| lambda-transactions | TEMIS_CONTRATO_TRANSACTIONS_V1.0.yaml | /transactions, /transactions/voice, /transactions/dashboard |
| lambda-subscriptions | TEMIS_CONTRATO_SUBSCRIPTIONS_V1.0.yaml | /subscriptions/plans, /subscriptions/checkout |
| lambda-voice | TEMIS_CONTRATO_VOICE_V1.0.yaml | /voice/tasks, /voice/transactions |
| lambda-ai | TEMIS_CONTRATO_AI_V1.0.yaml | /ai/chat, /ai/insights, /ai/predictions |
| lambda-users | TEMIS_CONTRATO_USERS_V1.0.yaml | /users/me, /users/me/avatar |
| lambda-tags | TEMIS_CONTRATO_TAGS_V1.0.yaml | /tags, /tags/{id} |
| lambda-categories | TEMIS_CONTRATO_CATEGORIES_V1.0.yaml | /categories, /categories/{id} |
| lambda-budgets | TEMIS_CONTRATO_BUDGETS_V1.0.yaml | /budgets, /budgets/{id} |
| lambda-reminders | TEMIS_CONTRATO_REMINDERS_V1.0.yaml | /reminders, /reminders/{id} |
| lambda-webhooks | TEMIS_CONTRATO_WEBHOOKS_V1.0.yaml | /webhooks/wompi |
| lambda-admin | TEMIS_CONTRATO_ADMIN_V1.0.yaml | /admin/dashboard, /admin/users |

---

## 🔧 Headers Estándar

Todos los endpoints (excepto webhooks) requieren:

```yaml
headers:
  - name: Authorization
    in: header
    required: true
    type: string
    description: Bearer JWT Token

  - name: message-uuid
    in: header
    required: true
    type: string
    format: uuid
    description: Identificador de trazabilidad

  - name: request-app-id
    in: header
    required: true
    type: string
    format: uuid
    description: Identificador de la aplicación consumidora

  - name: X-Device-ID
    in: header
    required: false
    type: string
    description: Identificador único del dispositivo
```

---

## 📦 Estructura Estándar de Respuesta

### Respuesta Exitosa

```json
{
  "headers": {
    "httpStatusCode": 200,
    "httpStatusDesc": "OK",
    "messageUuid": "c4e6bd04-5149-11e7-b114-a2f933d5fe66",
    "requestDatetime": "2026-07-12T10:30:00Z",
    "requestAppId": "acxff62e-6f12-42de-9012-1e7304418abd"
  },
  "messageResponse": {
    "responseCode": "0000",
    "responseMessage": "Success",
    "responseDetails": "Operation completed successfully"
  },
  "data": {
    // Payload específico del endpoint
  }
}
```

### Respuesta con Paginación

```json
{
  "headers": { /* ... */ },
  "messageResponse": { /* ... */ },
  "data": {
    "items": [ /* ... */ ]
  },
  "pagination": {
    "totalElement": 150,
    "pageSize": 20,
    "pageNumber": 1,
    "hasMoreElements": true
  }
}
```

### Respuesta de Error

```json
{
  "headers": {
    "httpStatusCode": 400,
    "httpStatusDesc": "BAD_REQUEST",
    "messageUuid": "c4e6bd04-5149-11e7-b114-a2f933d5fe66",
    "requestDatetime": "2026-07-12T10:30:00Z",
    "requestAppId": "acxff62e-6f12-42de-9012-1e7304418abd"
  },
  "messageResponse": {
    "responseCode": "0400",
    "responseMessage": "Bad Request",
    "responseDetail": "Validation error"
  },
  "errors": [
    {
      "errorCode": "FIELD_REQUIRED",
      "errorDetail": "El campo 'title' es requerido"
    }
  ]
}
```

---

## 🔐 Seguridad y Autenticación

### JWT Token

Todos los endpoints (excepto `/auth/*` y `/webhooks/*`) requieren autenticación JWT:

```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Validaciones

- **JWT**: RS256 con clave pública en Parameter Store
- **RLS**: Todas las queries filtran por `organization_id` AND `user_id`
- **Rate Limiting**: Por endpoint y usuario
- **CORS**: Configurado en API Gateway

---

## 📊 Códigos de Respuesta HTTP

| Código | Descripción | Uso |
|--------|-------------|-----|
| 200 | OK | Operación exitosa (GET, PUT, PATCH) |
| 201 | Created | Recurso creado (POST) |
| 204 | No Content | Eliminación exitosa (DELETE) |
| 400 | Bad Request | Datos mal formateados o validación fallida |
| 401 | Unauthorized | Token JWT inválido o expirado |
| 403 | Forbidden | Sin permisos para acceder al recurso |
| 404 | Not Found | Recurso no encontrado |
| 409 | Conflict | Conflicto (ej: recurso ya existe) |
| 415 | Unsupported Media Type | Content-Type incorrecto |
| 422 | Unprocessable Entity | Lógica de negocio no permite la operación |
| 429 | Too Many Requests | Rate limit excedido |
| 500 | Internal Server Error | Error interno del servidor |
| 502 | Bad Gateway | Error en servicio downstream |
| 503 | Service Unavailable | Servicio temporalmente no disponible |

---

## 🛠️ Herramientas Recomendadas

### Validación de Contratos
- **Swagger Editor**: https://editor.swagger.io/
- **Swagger UI**: Para visualización interactiva
- **Postman**: Importar colecciones desde Swagger

### Generación de Código
- **swagger-codegen**: Genera clientes y servers
- **openapi-generator**: Alternativa moderna

```bash
# Instalar
npm install -g swagger-node

# Validar contrato
swagger validate TEMIS_CONTRATO_TASKS_V1.0.yaml

# Generar documentación HTML
swagger-codegen generate -i TEMIS_CONTRATO_TASKS_V1.0.yaml -l html
```

---

## 📝 Convenciones de Nomenclatura

### Endpoints
- **Recursos en plural**: `/tasks`, `/passwords`, `/transactions`
- **Kebab-case**: `/api/v1/tipos-producto` (si incluye separador)
- **Verbos HTTP estándar**: GET, POST, PUT, PATCH, DELETE

### Parámetros
- **camelCase**: `pageSize`, `pageNumber`, `userId`
- **Query params para filtros**: `?status=pending&priority=high`
- **Path params para IDs**: `/tasks/{taskId}`

### Modelos
- **PascalCase** (en definiciones): `Task`, `Password`, `Transaction`
- **camelCase** (en properties): `taskId`, `createdAt`, `isActive`

---

## 🔄 Versionado

- **Versión en URL**: `/v1/tasks`
- **Versión en archivo**: `_V1.0.yaml`
- **Breaking changes**: Incrementar versión mayor (v2)
- **Non-breaking changes**: Incrementar versión menor (v1.1)

---

## ✅ Checklist de Contrato Completo

Para cada contrato, verificar:

- [ ] Información general (title, version, host)
- [ ] Tags definidos
- [ ] Todos los endpoints documentados
- [ ] Headers estándar en cada endpoint
- [ ] Parámetros con tipos y validaciones
- [ ] Responses para todos los códigos HTTP
- [ ] Modelos de dominio definidos
- [ ] Requests bodies con ejemplos
- [ ] Errores estándar definidos
- [ ] Paginación (si aplica)
- [ ] Autenticación especificada
- [ ] Ejemplos completos y válidos

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.0.0
