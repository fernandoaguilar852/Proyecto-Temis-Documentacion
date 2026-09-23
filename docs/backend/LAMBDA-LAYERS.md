# 🔧 Lambda Layers Compartidos - TEMIS

**Fecha**: 2026-09-23
**Versión**: 1.0
**Objetivo**: Reducir código duplicado en las 16 lambdas mediante layers reutilizables

---

## 🎯 Problema

Actualmente, cada una de las 16 lambdas tiene código duplicado para:
- Conectarse a PostgreSQL
- Validar JWT tokens
- Establecer contexto RLS (organization_id, user_id)
- Format ear respuestas estándar
- Validar suscripciones
- Validar cuotas de IA
- Manejar errores

**Impacto:**
- 📦 Tamaño de deployment mayor
- 🐛 Bugs duplicados
- 🔧 Mantenimiento complejo
- ⏱️ Tiempo de desarrollo mayor

**Solución:** Crear **3 Lambda Layers** compartidos

---

## 📦 Layers Propuestos

### 1. temis-core-layer (Utilidades Base)
### 2. temis-subscription-middleware (Validación de Suscripciones)
### 3. temis-ai-quota-middleware (Validación de Cuota IA)

---

## 1️⃣ temis-core-layer

**Contenido:**
- Database connection pool (PostgreSQL)
- JWT utilities (verify, decode, sign)
- RLS context setter
- Standard response formatter
- Error handler centralizado
- Logger para CloudWatch

### Estructura de Archivos

```
/layers/temis-core/
├── nodejs/
│   ├── package.json
│   ├── index.js
│   ├── database.js
│   ├── jwt.js
│   ├── response.js
│   ├── logger.js
│   └── errors.js
└── README.md
```

### database.js

```javascript
const { Pool } = require('pg');

let pool;

function getPool() {
  if (!pool) {
    pool = new Pool({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
      ssl: {
        rejectUnauthorized: false
      }
    });

    pool.on('error', (err) => {
      console.error('Unexpected error on idle client', err);
      process.exit(-1);
    });
  }

  return pool;
}

async function query(text, params) {
  const start = Date.now();
  const result = await getPool().query(text, params);
  const duration = Date.now() - start;

  console.log('Executed query', { text, duration, rows: result.rowCount });
  return result;
}

async function setRLSContext(organizationId, userId, userRole = 'user') {
  await query(`
    SELECT
      set_config('app.current_organization_id', $1, false),
      set_config('app.current_user_id', $2, false),
      set_config('app.current_user_role', $3, false)
  `, [organizationId, userId, userRole]);
}

async function transaction(callback) {
  const client = await getPool().connect();

  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  getPool,
  query,
  setRLSContext,
  transaction
};
```

### jwt.js

```javascript
const jwt = require('jsonwebtoken');
const { SecretsManager } = require('@aws-sdk/client-secrets-manager');

const secretsManager = new SecretsManager({ region: process.env.AWS_REGION });

let publicKey;
let privateKey;

async function getKeys() {
  if (!publicKey || !privateKey) {
    const secretData = await secretsManager.getSecretValue({
      SecretId: 'temis-jwt-keys'
    });

    const secrets = JSON.parse(secretData.SecretString);
    publicKey = secrets.JWT_PUBLIC_KEY;
    privateKey = secrets.JWT_PRIVATE_KEY;
  }

  return { publicKey, privateKey };
}

async function verifyToken(token) {
  const { publicKey } = await getKeys();

  try {
    const decoded = jwt.verify(token, publicKey, {
      algorithms: ['RS256']
    });

    return {
      valid: true,
      decoded
    };
  } catch (error) {
    return {
      valid: false,
      error: error.message
    };
  }
}

function decodeToken(token) {
  return jwt.decode(token);
}

async function signToken(payload, expiresIn = '15m') {
  const { privateKey } = await getKeys();

  return jwt.sign(payload, privateKey, {
    algorithm: 'RS256',
    expiresIn
  });
}

function extractTokenFromHeader(authHeader) {
  if (!authHeader) {
    throw new Error('Missing Authorization header');
  }

  if (!authHeader.startsWith('Bearer ')) {
    throw new Error('Invalid Authorization header format');
  }

  return authHeader.substring(7); // Remove 'Bearer '
}

module.exports = {
  verifyToken,
  decodeToken,
  signToken,
  extractTokenFromHeader
};
```

### response.js

```javascript
function formatResponse(statusCode, data = null, messageResponse = null) {
  const messageUuid = process.env.MESSAGE_UUID || 'unknown';
  const requestAppId = process.env.REQUEST_APP_ID || 'unknown';

  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'X-Request-ID': messageUuid
    },
    body: JSON.stringify({
      headers: {
        httpStatusCode: statusCode,
        httpStatusDesc: getStatusDescription(statusCode),
        messageUuid,
        requestDatetime: new Date().toISOString(),
        requestAppId
      },
      messageResponse: messageResponse || getDefaultMessageResponse(statusCode),
      data
    })
  };
}

function success(data, statusCode = 200) {
  return formatResponse(statusCode, data);
}

function created(data) {
  return formatResponse(201, data);
}

function noContent() {
  return {
    statusCode: 204,
    body: ''
  };
}

function error(statusCode, errorCode, errorMessage, errorDetail = null) {
  return formatResponse(statusCode, null, {
    responseCode: `0${statusCode}`,
    responseMessage: errorMessage,
    responseDetail: errorDetail || errorMessage,
    errors: [{
      errorCode,
      errorDetail: errorDetail || errorMessage
    }]
  });
}

function badRequest(message = 'Bad Request', errorCode = 'BAD_REQUEST') {
  return error(400, errorCode, message);
}

function unauthorized(message = 'Unauthorized', errorCode = 'UNAUTHORIZED') {
  return error(401, errorCode, message);
}

function forbidden(message = 'Forbidden', errorCode = 'FORBIDDEN') {
  return error(403, errorCode, message);
}

function notFound(message = 'Not Found', errorCode = 'NOT_FOUND') {
  return error(404, errorCode, message);
}

function unprocessable(message, errorCode = 'UNPROCESSABLE_ENTITY') {
  return error(422, errorCode, message);
}

function internalError(message = 'Internal Server Error', errorCode = 'INTERNAL_ERROR') {
  return error(500, errorCode, message);
}

function getStatusDescription(statusCode) {
  const descriptions = {
    200: 'OK',
    201: 'CREATED',
    204: 'NO_CONTENT',
    400: 'BAD_REQUEST',
    401: 'UNAUTHORIZED',
    403: 'FORBIDDEN',
    404: 'NOT_FOUND',
    422: 'UNPROCESSABLE_ENTITY',
    500: 'INTERNAL_SERVER_ERROR'
  };

  return descriptions[statusCode] || 'UNKNOWN';
}

function getDefaultMessageResponse(statusCode) {
  if (statusCode >= 200 && statusCode < 300) {
    return {
      responseCode: '0000',
      responseMessage: 'Success',
      responseDetail: 'Operation completed successfully'
    };
  }

  return {
    responseCode: `0${statusCode}`,
    responseMessage: getStatusDescription(statusCode),
    responseDetail: getStatusDescription(statusCode)
  };
}

module.exports = {
  success,
  created,
  noContent,
  error,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  unprocessable,
  internalError
};
```

### index.js (entry point)

```javascript
module.exports = {
  db: require('./database'),
  jwt: require('./jwt'),
  response: require('./response'),
  logger: require('./logger'),
  errors: require('./errors')
};
```

### package.json

```json
{
  "name": "temis-core-layer",
  "version": "1.0.0",
  "description": "Core utilities for TEMIS Lambda functions",
  "dependencies": {
    "pg": "^8.11.0",
    "jsonwebtoken": "^9.0.2",
    "@aws-sdk/client-secrets-manager": "^3.400.0"
  }
}
```

---

## 2️⃣ temis-subscription-middleware

**Contenido:**
- Validación de suscripción activa
- Verificación de permisos de escritura
- Check de cuota de tareas/transacciones

### subscription.js

```javascript
const { db } = require('/opt/nodejs/temis-core');

async function validateSubscription(organizationId, userId) {
  const result = await db.query(`
    SELECT
      s.id,
      s.status,
      s.current_period_end,
      sp.name as plan_name,
      sp.max_tasks,
      sp.max_transactions
    FROM subscriptions s
    JOIN subscription_plans sp ON s.plan_id = sp.id
    WHERE s.organization_id = $1
      AND s.user_id = $2
      AND s.status IN ('active', 'trial')
    LIMIT 1
  `, [organizationId, userId]);

  if (!result.rows.length) {
    throw new Error('NO_ACTIVE_SUBSCRIPTION');
  }

  return result.rows[0];
}

async function checkWriteAccess(organizationId, userId) {
  try {
    const subscription = await validateSubscription(organizationId, userId);

    // Si status es 'expired', solo lectura
    if (subscription.status === 'expired') {
      return false;
    }

    return true;

  } catch (error) {
    if (error.message === 'NO_ACTIVE_SUBSCRIPTION') {
      // No hay suscripción → solo lectura
      return false;
    }
    throw error;
  }
}

async function enforceWriteAccess(organizationId, userId) {
  const hasAccess = await checkWriteAccess(organizationId, userId);

  if (!hasAccess) {
    const error = new Error('Subscription expired. Read-only access.');
    error.code = 'SUBSCRIPTION_EXPIRED';
    error.statusCode = 422;
    throw error;
  }
}

module.exports = {
  validateSubscription,
  checkWriteAccess,
  enforceWriteAccess
};
```

---

## 3️⃣ temis-ai-quota-middleware

**Contenido:**
- Validación de cuota de IA
- Incremento de uso de IA
- Obtención de cuota restante

### ai-quota.js

```javascript
const { db } = require('/opt/nodejs/temis-core');

async function checkAIQuota(organizationId, userId, featureType) {
  // Llamar a función de PostgreSQL
  const result = await db.query(
    'SELECT check_ai_quota($1, $2, $3) as has_quota',
    [organizationId, userId, featureType]
  );

  const hasQuota = result.rows[0].has_quota;

  if (!hasQuota) {
    const error = new Error('AI quota limit reached for current plan');
    error.code = 'AI_QUOTA_EXCEEDED';
    error.statusCode = 422;
    throw error;
  }

  return true;
}

async function incrementAIUsage(organizationId, userId, featureType, tokensInput, tokensOutput) {
  await db.query(`
    INSERT INTO ai_usage_logs (
      organization_id, user_id, feature_type,
      tokens_input, tokens_output, created_at
    ) VALUES ($1, $2, $3, $4, $5, NOW())
  `, [organizationId, userId, featureType, tokensInput, tokensOutput]);
}

async function getQuotaRemaining(organizationId, userId) {
  const result = await db.query(`
    SELECT
      sp.ai_quota_monthly as monthly_limit,
      COALESCE(SUM(CASE
        WHEN DATE_TRUNC('month', aul.created_at) = DATE_TRUNC('month', NOW())
        THEN 1 ELSE 0
      END), 0) as used_this_month
    FROM subscriptions s
    JOIN subscription_plans sp ON s.plan_id = sp.id
    LEFT JOIN ai_usage_logs aul ON aul.organization_id = s.organization_id AND aul.user_id = s.user_id
    WHERE s.organization_id = $1
      AND s.user_id = $2
      AND s.status IN ('active', 'trial')
    GROUP BY sp.ai_quota_monthly
  `, [organizationId, userId]);

  if (!result.rows.length) {
    return { monthlyLimit: 0, usedThisMonth: 0, remaining: 0 };
  }

  const { monthly_limit, used_this_month } = result.rows[0];

  return {
    monthlyLimit: monthly_limit,
    usedThisMonth: used_this_month,
    remaining: Math.max(0, monthly_limit - used_this_month)
  };
}

module.exports = {
  checkAIQuota,
  incrementAIUsage,
  getQuotaRemaining
};
```

---

## 🚀 Deployment de Layers

### Crear ZIP del Layer

```bash
cd /layers/temis-core
npm install --production
cd ..
zip -r temis-core-layer.zip temis-core

aws lambda publish-layer-version \
  --layer-name temis-core \
  --description "Core utilities for TEMIS lambdas" \
  --zip-file fileb://temis-core-layer.zip \
  --compatible-runtimes nodejs18.x nodejs20.x
```

### Terraform

```hcl
resource "aws_lambda_layer_version" "temis_core" {
  filename   = "temis-core-layer.zip"
  layer_name = "temis-core"
  description = "Core utilities for TEMIS lambdas"

  compatible_runtimes = ["nodejs18.x", "nodejs20.x"]
}

resource "aws_lambda_function" "lambda_tasks" {
  layers = [
    aws_lambda_layer_version.temis_core.arn,
    aws_lambda_layer_version.temis_subscription_middleware.arn
  ]

  # ... other config
}
```

---

## 💡 Uso en Lambda Functions

### Antes (Sin Layers)

```javascript
// lambda-tasks/index.js - 500 líneas con código duplicado
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');

const pool = new Pool({ /* config duplicada */ });

async function verifyJWT(token) {
  // Código duplicado en 16 lambdas...
}

async function formatResponse(data) {
  // Código duplicado...
}

exports.handler = async (event) => {
  // 100 líneas de setup duplicado...
};
```

### Después (Con Layers)

```javascript
// lambda-tasks/index.js - 150 líneas, código limpio
const { db, jwt, response } = require('/opt/nodejs/temis-core');
const { enforceWriteAccess } = require('/opt/nodejs/temis-subscription-middleware');

exports.handler = async (event) => {
  try {
    // 1. Validar JWT (1 línea!)
    const token = jwt.extractTokenFromHeader(event.headers.Authorization);
    const { decoded } = await jwt.verifyToken(token);

    const { userId, organizationId } = decoded;

    // 2. Establecer contexto RLS (1 línea!)
    await db.setRLSContext(organizationId, userId);

    // 3. Validar suscripción (1 línea!)
    await enforceWriteAccess(organizationId, userId);

    // 4. Lógica de negocio
    const tasks = await db.query('SELECT * FROM tasks');

    // 5. Retornar respuesta (1 línea!)
    return response.success({ tasks: tasks.rows });

  } catch (error) {
    return response.internalError(error.message);
  }
};
```

---

## 📊 Beneficios

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| **Líneas de código por lambda** | ~500 | ~150 | -70% |
| **Tamaño de deployment** | 2 MB | 500 KB | -75% |
| **Tiempo de desarrollo** | 2 días | 4 horas | -75% |
| **Bugs duplicados** | 16x | 1x | -94% |
| **Mantenibilidad** | Baja | Alta | ⬆️ |

---

## ✅ Checklist de Implementación

- [ ] Crear estructura de carpetas `/layers/`
- [ ] Implementar temis-core-layer
- [ ] Implementar temis-subscription-middleware
- [ ] Implementar temis-ai-quota-middleware
- [ ] Escribir tests unitarios para cada layer
- [ ] Deployar layers a AWS Lambda
- [ ] Actualizar las 16 lambdas para usar layers
- [ ] Testing de integración
- [ ] Documentar en README de cada lambda
- [ ] Monitorear performance en producción

---

**Autor**: Equipo Backend TEMIS
**Última actualización**: 2026-09-23
