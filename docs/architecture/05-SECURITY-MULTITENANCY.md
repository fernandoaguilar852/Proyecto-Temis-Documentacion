# Seguridad y Multitenancy - TEMIS
## Estrategias de Aislamiento y Protección de Datos

---

## 1. Visión General de Seguridad

TEMIS implementa múltiples capas de seguridad para proteger los datos de los usuarios:

```
┌─────────────────────────────────────────────────────────────┐
│ Capa 1: Transporte (TLS 1.3)                               │
├─────────────────────────────────────────────────────────────┤
│ Capa 2: Autenticación (JWT)                                │
├─────────────────────────────────────────────────────────────┤
│ Capa 3: Autorización (RBAC + Plan Validation)              │
├─────────────────────────────────────────────────────────────┤
│ Capa 4: Aislamiento de Datos (RLS + Filtrado Obligatorio)  │
├─────────────────────────────────────────────────────────────┤
│ Capa 5: Encriptación de Datos Sensibles                    │
├─────────────────────────────────────────────────────────────┤
│ Capa 6: Auditoría y Monitoreo                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Multitenancy

### 2.1 Modelo de Multitenancy

**Estrategia**: Shared Database, Shared Schema con aislamiento por `organization_id` y `user_id`

```
Tenant Isolation:
┌──────────────────────────────────────────────┐
│ Organization A                               │
│ ├─ User 1 (data aislada)                    │
│ └─ User 2 (futuro: compartir en familia)    │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ Organization B                               │
│ └─ User 3 (data aislada)                    │
└──────────────────────────────────────────────┘

Base de Datos:
┌────────────────────────────────────────────────┐
│ tasks                                          │
├────┬──────────────┬─────────┬──────────────────┤
│ id │ org_id       │ user_id │ title            │
├────┼──────────────┼─────────┼──────────────────┤
│ 1  │ org_a        │ user_1  │ Tarea de User 1  │
│ 2  │ org_a        │ user_2  │ Tarea de User 2  │
│ 3  │ org_b        │ user_3  │ Tarea de User 3  │
└────┴──────────────┴─────────┴──────────────────┘
```

### 2.2 Estado Actual vs Futuro

**Actual (MVP)**:
- 1 Organization = 1 Usuario
- Uso personal, sin compartir

**Futuro (Post-MVP)**:
- 1 Organization = N Usuarios (familia, equipo)
- Data compartida dentro de la organización
- Permisos granulares por usuario

---

## 3. Autenticación JWT

### 3.1 Generación de Tokens

```javascript
// lambda-auth/services/jwt.service.js
const jwt = require('jsonwebtoken');
const { getParameter } = require('../../shared/utils/ssm');

async function generateTokens(user, organization) {
  const privateKey = await getParameter('/temis/prod/jwt-private-key');

  // Access Token (15 minutos)
  const accessToken = jwt.sign(
    {
      userId: user.id,
      organizationId: organization.id,
      email: user.email,
      role: user.role,
      planId: user.subscription?.planId,
      type: 'access'
    },
    privateKey,
    {
      algorithm: 'RS256',
      expiresIn: '15m',
      issuer: 'temis-api',
      audience: 'temis-app'
    }
  );

  // Refresh Token (7 días)
  const refreshToken = jwt.sign(
    {
      userId: user.id,
      type: 'refresh'
    },
    privateKey,
    {
      algorithm: 'RS256',
      expiresIn: '7d',
      issuer: 'temis-api'
    }
  );

  // Guardar refresh token en BD
  await saveRefreshToken({
    userId: user.id,
    tokenHash: hashToken(refreshToken),
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
  });

  return { accessToken, refreshToken };
}
```

### 3.2 Validación de Tokens

```javascript
// Lambda Authorizer
async function validateToken(token) {
  const publicKey = await getParameter('/temis/prod/jwt-public-key');

  try {
    const decoded = jwt.verify(token, publicKey, {
      algorithms: ['RS256'],
      issuer: 'temis-api',
      audience: 'temis-app'
    });

    // Verificar que sea access token
    if (decoded.type !== 'access') {
      throw new Error('Invalid token type');
    }

    // Verificar que el usuario siga activo
    const user = await getUserById(decoded.userId);
    if (!user || !user.isActive) {
      throw new Error('User inactive');
    }

    return decoded;
  } catch (error) {
    throw new Error('Invalid token');
  }
}
```

### 3.3 Rotación de Claves

**Frecuencia**: Cada 90 días

**Proceso**:
1. Generar nuevo par de claves RSA
2. Guardar en Parameter Store con versión nueva
3. Mantener clave vieja por 24 horas (para tokens existentes)
4. Actualizar claves en todas las lambdas
5. Eliminar clave vieja después de 24 horas

---

## 4. Filtrado Obligatorio de Datos

### 4.1 Principio Fundamental

**CRÍTICO**: Todas las queries DEBEN filtrar por `organization_id` Y `user_id`

```sql
-- ✅ CORRECTO
SELECT * FROM tasks
WHERE organization_id = $1
  AND user_id = $2
  AND status = 'pending';

-- ❌ INCORRECTO - NUNCA hacer esto
SELECT * FROM tasks
WHERE status = 'pending';
```

### 4.2 Middleware de Seguridad

```javascript
// shared/middleware/rls.middleware.js

/**
 * Middleware que establece el contexto de usuario
 * DEBE ejecutarse en TODAS las lambdas antes de cualquier query
 */
async function setUserContext(event, context, db) {
  // Extraer del contexto del authorizer
  const userId = event.requestContext.authorizer.userId;
  const organizationId = event.requestContext.authorizer.organizationId;

  if (!userId || !organizationId) {
    throw new Error('Missing user context');
  }

  // Establecer variables de sesión en PostgreSQL
  await db.query(`
    SET LOCAL app.current_organization_id = $1;
    SET LOCAL app.current_user_id = $2;
  `, [organizationId, userId]);

  // Guardar en context para uso en la lambda
  context.userId = userId;
  context.organizationId = organizationId;

  return context;
}

module.exports = { setUserContext };
```

### 4.3 Helper de Queries Seguras

```javascript
// shared/database/secure-queries.js

class SecureQuery {
  constructor(db, context) {
    this.db = db;
    this.organizationId = context.organizationId;
    this.userId = context.userId;
  }

  /**
   * SELECT seguro - SIEMPRE agrega filtros de tenant
   */
  async select(table, conditions = {}, options = {}) {
    const where = {
      organization_id: this.organizationId,
      user_id: this.userId,
      ...conditions
    };

    const whereClauses = Object.keys(where).map((key, i) =>
      `${key} = $${i + 1}`
    );

    const values = Object.values(where);

    const query = `
      SELECT * FROM ${table}
      WHERE ${whereClauses.join(' AND ')}
      ${options.orderBy ? `ORDER BY ${options.orderBy}` : ''}
      ${options.limit ? `LIMIT ${options.limit}` : ''}
      ${options.offset ? `OFFSET ${options.offset}` : ''}
    `;

    const result = await this.db.query(query, values);
    return result.rows;
  }

  /**
   * INSERT seguro - SIEMPRE agrega organization_id y user_id
   */
  async insert(table, data) {
    const fullData = {
      organization_id: this.organizationId,
      user_id: this.userId,
      ...data
    };

    const columns = Object.keys(fullData);
    const values = Object.values(fullData);
    const placeholders = values.map((_, i) => `$${i + 1}`);

    const query = `
      INSERT INTO ${table} (${columns.join(', ')})
      VALUES (${placeholders.join(', ')})
      RETURNING *
    `;

    const result = await this.db.query(query, values);
    return result.rows[0];
  }

  /**
   * UPDATE seguro - SOLO actualiza si pertenece al usuario
   */
  async update(table, id, data) {
    const setColumns = Object.keys(data).map((key, i) =>
      `${key} = $${i + 1}`
    );

    const values = [...Object.values(data), id, this.organizationId, this.userId];

    const query = `
      UPDATE ${table}
      SET ${setColumns.join(', ')}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${values.length - 2}
        AND organization_id = $${values.length - 1}
        AND user_id = $${values.length}
      RETURNING *
    `;

    const result = await this.db.query(query, values);

    if (result.rows.length === 0) {
      throw new Error('Resource not found or access denied');
    }

    return result.rows[0];
  }

  /**
   * DELETE seguro - SOLO elimina si pertenece al usuario
   */
  async delete(table, id) {
    const query = `
      UPDATE ${table}
      SET deleted_at = CURRENT_TIMESTAMP
      WHERE id = $1
        AND organization_id = $2
        AND user_id = $3
        AND deleted_at IS NULL
      RETURNING id
    `;

    const result = await this.db.query(query, [id, this.organizationId, this.userId]);

    if (result.rows.length === 0) {
      throw new Error('Resource not found or access denied');
    }

    return true;
  }
}

module.exports = SecureQuery;
```

### 4.4 Uso en Lambdas

```javascript
// lambdas/tasks/controllers/list.js
const SecureQuery = require('../../../shared/database/secure-queries');

exports.handler = async (event, context) => {
  const db = await getDBConnection();

  try {
    // 1. Establecer contexto (OBLIGATORIO)
    await setUserContext(event, context, db);

    // 2. Crear instancia de query segura
    const secureQuery = new SecureQuery(db, context);

    // 3. Query automáticamente filtrada
    const tasks = await secureQuery.select('tasks', {
      status: 'pending'
    }, {
      orderBy: 'due_date ASC',
      limit: 20
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        data: tasks
      })
    };
  } finally {
    await db.end();
  }
};
```

---

## 5. Row-Level Security (RLS)

### 5.1 Políticas de RLS

```sql
-- Habilitar RLS en todas las tablas de usuario
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE passwords ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Política: Solo ver datos propios
CREATE POLICY user_isolation_policy ON tasks
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', true)::uuid
        AND user_id = current_setting('app.current_user_id', true)::uuid
    );

-- Aplicar a todas las tablas
CREATE POLICY user_isolation_policy ON passwords FOR ALL
    USING (organization_id = current_setting('app.current_organization_id', true)::uuid
           AND user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY user_isolation_policy ON transactions FOR ALL
    USING (organization_id = current_setting('app.current_organization_id', true)::uuid
           AND user_id = current_setting('app.current_user_id', true)::uuid);

-- ... aplicar a todas las demás tablas
```

### 5.2 Beneficios de RLS

- **Doble protección**: Incluso si el código falla, RLS previene acceso no autorizado
- **Defensa en profundidad**: Capa adicional de seguridad
- **Zero Trust**: No confiamos solo en el código de aplicación

---

## 6. Encriptación de Datos Sensibles

### 6.1 Contraseñas de Usuario (bcrypt)

```javascript
// Registro de usuario
const bcrypt = require('bcrypt');

async function hashPassword(plainPassword) {
  const saltRounds = 12;
  return await bcrypt.hash(plainPassword, saltRounds);
}

async function verifyPassword(plainPassword, hashedPassword) {
  return await bcrypt.compare(plainPassword, hashedPassword);
}
```

### 6.2 Contraseñas Guardadas (AES-256-GCM)

```javascript
// lambdas/passwords/services/encryption.service.js
const crypto = require('crypto');
const { getParameter } = require('../../../shared/utils/ssm');

const ALGORITHM = 'aes-256-gcm';

async function encryptPassword(plainPassword) {
  // Obtener clave maestra de Parameter Store
  const masterKey = await getParameter('/temis/prod/encryption-master-key');

  // Generar IV único para este registro
  const iv = crypto.randomBytes(16);

  // Crear cipher
  const cipher = crypto.createCipheriv(
    ALGORITHM,
    Buffer.from(masterKey, 'hex'),
    iv
  );

  // Encriptar
  let encrypted = cipher.update(plainPassword, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  // Obtener auth tag
  const authTag = cipher.getAuthTag();

  return {
    encryptedPassword: Buffer.from(encrypted, 'hex'),
    iv: iv,
    authTag: authTag
  };
}

async function decryptPassword(encryptedData, iv, authTag) {
  const masterKey = await getParameter('/temis/prod/encryption-master-key');

  const decipher = crypto.createDecipheriv(
    ALGORITHM,
    Buffer.from(masterKey, 'hex'),
    iv
  );

  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
}
```

### 6.3 Guardado en Base de Datos

```javascript
// Crear contraseña
async function createPassword(data, context) {
  const { encryptedPassword, iv, authTag } = await encryptPassword(data.password);

  const result = await db.query(`
    INSERT INTO passwords (
      organization_id,
      user_id,
      name,
      username,
      encrypted_password,
      encryption_iv,
      auth_tag,
      url,
      category
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    RETURNING id, name, username, url, category
  `, [
    context.organizationId,
    context.userId,
    data.name,
    data.username,
    encryptedPassword,
    iv,
    authTag,
    data.url,
    data.category
  ]);

  return result.rows[0];
}

// Obtener contraseña (desencriptar)
async function getPassword(id, context) {
  const result = await db.query(`
    SELECT * FROM passwords
    WHERE id = $1
      AND organization_id = $2
      AND user_id = $3
      AND deleted_at IS NULL
  `, [id, context.organizationId, context.userId]);

  if (result.rows.length === 0) {
    throw new Error('Password not found');
  }

  const row = result.rows[0];

  // Desencriptar contraseña
  const plainPassword = await decryptPassword(
    row.encrypted_password,
    row.encryption_iv,
    row.auth_tag
  );

  // Registrar en audit log
  await auditLog({
    userId: context.userId,
    action: 'PASSWORD_ACCESSED',
    entityType: 'password',
    entityId: id
  });

  return {
    ...row,
    password: plainPassword,
    encrypted_password: undefined,
    encryption_iv: undefined,
    auth_tag: undefined
  };
}
```

---

## 7. Control de Acceso Basado en Roles (RBAC)

### 7.1 Roles Disponibles

```javascript
const ROLES = {
  SUPERADMIN: 'superadmin',  // Acceso total, panel admin
  ADMIN: 'admin',            // Gestión de organización (futuro)
  USER: 'user',              // Usuario estándar
  VIEWER: 'viewer'           // Solo lectura (futuro)
};
```

### 7.2 Middleware de Autorización

```javascript
// shared/middleware/auth.middleware.js

function requireRole(...allowedRoles) {
  return (event, context, next) => {
    const userRole = event.requestContext.authorizer.role;

    if (!allowedRoles.includes(userRole)) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          success: false,
          error: {
            code: 'FORBIDDEN',
            message: 'Insufficient permissions'
          }
        })
      };
    }

    return next();
  };
}

// Uso en lambdas
// Solo superadmins pueden acceder
exports.handler = requireRole(ROLES.SUPERADMIN)(async (event, context) => {
  // ... código de admin
});
```

---

## 8. Validación de Plan de Suscripción

### 8.1 Middleware de Feature Gate

```javascript
// shared/middleware/plan.middleware.js

async function requireFeature(featureName) {
  return async (event, context, next) => {
    const userId = context.userId;

    // Obtener plan del usuario
    const subscription = await getActiveSubscription(userId);

    if (!subscription) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          success: false,
          error: {
            code: 'NO_SUBSCRIPTION',
            message: 'No active subscription found'
          }
        })
      };
    }

    // Verificar si el plan incluye la feature
    const hasFeature = subscription.plan.features[featureName];

    if (!hasFeature) {
      return {
        statusCode: 422,
        body: JSON.stringify({
          success: false,
          error: {
            code: 'FEATURE_NOT_AVAILABLE',
            message: `Feature '${featureName}' not available in your plan`,
            upgradeRequired: true,
            currentPlan: subscription.plan.name
          }
        })
      };
    }

    return next();
  };
}

// Uso en lambdas
// Requiere plan Pro o superior
exports.handler = requireFeature('finance')(async (event, context) => {
  // ... crear transacción
});
```

### 8.2 Límites por Plan

```javascript
async function checkPlanLimit(userId, limitType) {
  const subscription = await getActiveSubscription(userId);
  const limits = PLAN_LIMITS[subscription.plan.slug];

  switch(limitType) {
    case 'reminders':
      const currentReminders = await countUserReminders(userId);
      if (currentReminders >= limits.maxReminders) {
        throw new Error(`Reminder limit reached (${limits.maxReminders})`);
      }
      break;

    case 'voice_minutes':
      const usedMinutes = await getMonthlyVoiceMinutes(userId);
      if (usedMinutes >= limits.maxVoiceMinutes) {
        throw new Error(`Voice minutes limit reached (${limits.maxVoiceMinutes})`);
      }
      break;
  }
}

const PLAN_LIMITS = {
  free: {
    maxReminders: 50,
    maxVoiceMinutes: 0
  },
  basic: {
    maxReminders: 200,
    maxVoiceMinutes: 0
  },
  pro: {
    maxReminders: Infinity,
    maxVoiceMinutes: 60
  },
  premium: {
    maxReminders: Infinity,
    maxVoiceMinutes: 300
  }
};
```

---

## 9. Seguridad de Servicios de IA

### 9.1 Privacidad de Datos con Amazon Bedrock

**Principio**: Minimizar información personal enviada a Bedrock

```javascript
// shared/services/ai-privacy.service.js

/**
 * Anonimiza datos del usuario antes de enviar a Bedrock
 */
function anonymizeUserData(userData) {
  return {
    // Enviar solo agregados, no datos personales
    totalExpenses: userData.expenses.reduce((sum, t) => sum + t.amount, 0),
    expensesByCategory: aggregateByCategory(userData.expenses),
    budgetStatus: calculateBudgetStatus(userData.budgets),
    taskStats: {
      total: userData.tasks.length,
      completed: userData.tasks.filter(t => t.status === 'completed').length,
      pending: userData.tasks.filter(t => t.status === 'pending').length
    }
    // NO enviar: nombres, emails, descripciones personales, etc.
  };
}

/**
 * Sanitiza mensajes del chat antes de enviar a Bedrock
 */
function sanitizeChatMessage(message) {
  // Remover información personal si el usuario la incluye
  const patterns = [
    { regex: /\b\d{3}-\d{2}-\d{4}\b/g, replacement: '[SSN_REDACTED]' },
    { regex: /\b\d{16}\b/g, replacement: '[CARD_REDACTED]' },
    { regex: /\b[\w\.-]+@[\w\.-]+\.\w+\b/g, replacement: '[EMAIL_REDACTED]' }
  ];

  let sanitized = message;
  patterns.forEach(({ regex, replacement }) => {
    sanitized = sanitized.replace(regex, replacement);
  });

  return sanitized;
}
```

### 9.2 Control de Cuotas de IA

```javascript
// shared/middleware/ai-quota.middleware.js

async function checkAIQuota(userId, featureType) {
  const subscription = await getActiveSubscription(userId);
  const limits = AI_LIMITS[subscription.plan.slug];

  // Obtener límite para este tipo de feature
  const limit = limits[featureType];

  // Si es ilimitado, permitir
  if (limit === Infinity) {
    return { allowed: true, remaining: Infinity };
  }

  // Obtener uso del mes actual
  const currentMonth = new Date().toISOString().substring(0, 7); // YYYY-MM
  const usage = await db.query(`
    SELECT COUNT(*) as count
    FROM ai_usage
    WHERE user_id = $1
      AND feature_type = $2
      AND month_year = $3
  `, [userId, featureType, currentMonth]);

  const currentUsage = parseInt(usage.rows[0].count);

  // Verificar si excede el límite
  if (currentUsage >= limit) {
    return {
      allowed: false,
      current: currentUsage,
      limit: limit,
      upgradeRequired: true
    };
  }

  return {
    allowed: true,
    current: currentUsage,
    limit: limit,
    remaining: limit - currentUsage
  };
}

// Límites por plan
const AI_LIMITS = {
  free: {
    voice_tasks: 0,
    voice_transactions: 0,
    chat_messages: 0,
    insights: 0,
    predictions: 0
  },
  basic: {
    voice_tasks: 10,
    voice_transactions: 10,
    chat_messages: 20,
    insights: 0,
    predictions: 0
  },
  pro: {
    voice_tasks: 100,
    voice_transactions: 100,
    chat_messages: 100,
    insights: 5,
    predictions: 0
  },
  premium: {
    voice_tasks: Infinity,
    voice_transactions: Infinity,
    chat_messages: 500,
    insights: 20,
    predictions: 20
  }
};

// Middleware para validar cuota antes de usar IA
async function requireAIQuota(featureType) {
  return async (event, context, next) => {
    const quotaCheck = await checkAIQuota(context.userId, featureType);

    if (!quotaCheck.allowed) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          success: false,
          error: {
            code: 'AI_QUOTA_EXCEEDED',
            message: `Has alcanzado tu límite mensual de ${quotaCheck.limit} para ${featureType}`,
            upgradeRequired: true,
            currentPlan: context.planName
          }
        })
      };
    }

    // Agregar información de cuota al contexto
    context.aiQuota = quotaCheck;

    return next();
  };
}

// Registrar uso de IA después de cada llamada exitosa
async function recordAIUsage(userId, organizationId, featureType) {
  const currentMonth = new Date().toISOString().substring(0, 7);

  await db.query(`
    INSERT INTO ai_usage (
      organization_id,
      user_id,
      feature_type,
      month_year,
      usage_count,
      last_used_at
    )
    VALUES ($1, $2, $3, $4, 1, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id, feature_type, month_year)
    DO UPDATE SET
      usage_count = ai_usage.usage_count + 1,
      last_used_at = CURRENT_TIMESTAMP
  `, [organizationId, userId, featureType, currentMonth]);
}
```

### 9.3 Rate Limiting de IA

```javascript
// Protección adicional contra abuso de IA
const AI_RATE_LIMITS = {
  chat_messages: {
    window: 60, // segundos
    max: 10     // máximo 10 mensajes por minuto
  },
  voice_processing: {
    window: 60,
    max: 5      // máximo 5 audios por minuto
  }
};

async function checkAIRateLimit(userId, featureType) {
  const limit = AI_RATE_LIMITS[featureType];
  const key = `ai_rate:${userId}:${featureType}`;

  // Usar Redis para rate limiting (o DynamoDB si no hay Redis)
  const currentCount = await redis.get(key);

  if (currentCount && parseInt(currentCount) >= limit.max) {
    return {
      allowed: false,
      retryAfter: limit.window
    };
  }

  // Incrementar contador
  await redis.multi()
    .incr(key)
    .expire(key, limit.window)
    .exec();

  return { allowed: true };
}
```

### 9.4 Monitoreo de Costos de IA

```javascript
// CloudWatch Alarm - Costo de Bedrock
const bedrockCostAlarm = {
  MetricName: 'EstimatedCharges',
  Namespace: 'AWS/Bedrock',
  Statistic: 'Maximum',
  Period: 86400, // 1 día
  EvaluationPeriods: 1,
  Threshold: 50, // $50 por día
  ComparisonOperator: 'GreaterThanThreshold',
  AlarmActions: [SNS_ALERT_TOPIC_ARN],
  AlarmDescription: 'Alerta si el costo de Bedrock excede $50/día'
};

// Lambda para analizar uso de IA por usuario
async function analyzeAIUsageByUser() {
  const highUsageUsers = await db.query(`
    SELECT
      u.id,
      u.email,
      s.plan_name,
      SUM(ai.usage_count) as total_usage,
      ai.feature_type
    FROM ai_usage ai
    JOIN users u ON ai.user_id = u.id
    JOIN subscriptions s ON u.id = s.user_id
    WHERE ai.month_year = $1
    GROUP BY u.id, u.email, s.plan_name, ai.feature_type
    HAVING SUM(ai.usage_count) > 1000
    ORDER BY total_usage DESC
  `, [getCurrentMonth()]);

  // Alertar si hay usuarios con uso anormal
  if (highUsageUsers.rows.length > 0) {
    await sendAlertToOps({
      type: 'HIGH_AI_USAGE',
      users: highUsageUsers.rows
    });
  }
}
```

---

## 10. Seguridad de Pagos (Wompi)

### 10.1 PCI Compliance

**Principio**: NUNCA almacenar datos completos de tarjetas de crédito

```javascript
// ✅ CORRECTO - Guardar solo payment_source_id de Wompi
await db.query(`
  INSERT INTO payment_methods (
    user_id,
    organization_id,
    wompi_payment_source_id,  -- Token de Wompi
    card_brand,                -- Visa, Mastercard, etc.
    last_four_digits,          -- Solo últimos 4 dígitos
    expiry_month,
    expiry_year,
    is_default
  ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
`, [userId, orgId, paymentSourceId, brand, lastFour, month, year, isDefault]);

// ❌ INCORRECTO - NUNCA hacer esto
// NUNCA guardar: número completo, CVV, PIN
```

### 10.2 Verificación de Webhooks de Wompi

```javascript
// lambda-webhooks/wompi.js

const crypto = require('crypto');

/**
 * Verificar firma de webhook de Wompi
 * CRÍTICO: Siempre verificar antes de procesar
 */
function verifyWompiSignature(body, signature) {
  const secret = process.env.WOMPI_WEBHOOK_SECRET;

  // Calcular hash esperado
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(body))
    .digest('hex');

  // Comparación segura (timing-attack resistant)
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

exports.handler = async (event) => {
  const body = JSON.parse(event.body);
  const signature = event.headers['x-signature'] || event.headers['X-Signature'];

  // 1. Verificar firma SIEMPRE
  if (!verifyWompiSignature(body, signature)) {
    logger.error('Invalid Wompi webhook signature', {
      receivedSignature: signature
    });

    return {
      statusCode: 401,
      body: 'Invalid signature'
    };
  }

  // 2. Validar estructura del payload
  if (!body.event || !body.data) {
    return {
      statusCode: 400,
      body: 'Invalid payload structure'
    };
  }

  // 3. Procesar evento de forma idempotente
  const eventId = body.data.id;
  const alreadyProcessed = await checkEventProcessed(eventId);

  if (alreadyProcessed) {
    // Ya procesado, retornar success para que Wompi no reintente
    return { statusCode: 200, body: 'Already processed' };
  }

  // 4. Procesar en transacción
  try {
    await db.query('BEGIN');

    await processWompiEvent(body);
    await markEventAsProcessed(eventId);

    await db.query('COMMIT');

    return { statusCode: 200, body: 'OK' };
  } catch (error) {
    await db.query('ROLLBACK');

    logger.error('Error processing Wompi webhook', {
      error: error.message,
      eventType: body.event
    });

    // Retornar 500 para que Wompi reintente
    return {
      statusCode: 500,
      body: 'Processing error'
    };
  }
};
```

### 10.3 Protección de Endpoints de Pago

```javascript
// Rate limiting estricto para endpoints de pago
const PAYMENT_RATE_LIMITS = {
  '/subscriptions/checkout': {
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 3 // Solo 3 intentos por 15 minutos
  },
  '/subscriptions/payment-method': {
    windowMs: 60 * 60 * 1000, // 1 hora
    max: 5 // Solo 5 cambios de tarjeta por hora
  }
};

// Validación adicional de monto
async function validatePaymentAmount(amount, planId) {
  const plan = await getPlanById(planId);

  // El monto DEBE coincidir exactamente con el precio del plan
  if (Math.abs(amount - plan.price) > 0.01) {
    throw new Error('Invalid payment amount');
  }

  return true;
}
```

### 10.4 Auditoría de Pagos

```javascript
// Registrar TODOS los eventos de pago
async function auditPaymentEvent(data) {
  await db.query(`
    INSERT INTO payment_audit_logs (
      organization_id,
      user_id,
      event_type,
      payment_provider,
      transaction_id,
      amount,
      currency,
      status,
      metadata,
      ip_address
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
  `, [
    data.organizationId,
    data.userId,
    data.eventType, // PAYMENT_ATTEMPTED, PAYMENT_SUCCESS, PAYMENT_FAILED, etc.
    'wompi',
    data.transactionId,
    data.amount,
    data.currency,
    data.status,
    JSON.stringify(data.metadata),
    data.ipAddress
  ]);
}

// Eventos a auditar
const PAYMENT_AUDIT_EVENTS = {
  PAYMENT_METHOD_ADDED: 'PAYMENT_METHOD_ADDED',
  PAYMENT_METHOD_REMOVED: 'PAYMENT_METHOD_REMOVED',
  PAYMENT_ATTEMPTED: 'PAYMENT_ATTEMPTED',
  PAYMENT_SUCCESS: 'PAYMENT_SUCCESS',
  PAYMENT_FAILED: 'PAYMENT_FAILED',
  SUBSCRIPTION_UPGRADED: 'SUBSCRIPTION_UPGRADED',
  SUBSCRIPTION_DOWNGRADED: 'SUBSCRIPTION_DOWNGRADED',
  SUBSCRIPTION_CANCELLED: 'SUBSCRIPTION_CANCELLED',
  REFUND_REQUESTED: 'REFUND_REQUESTED',
  REFUND_PROCESSED: 'REFUND_PROCESSED'
};
```

---

## 11. Control de Acceso con Suscripción Vencida

### 11.1 Estados de Suscripción

```javascript
const SUBSCRIPTION_STATUS = {
  ACTIVE: 'active',           // Pagada y vigente
  TRIAL: 'trial',            // Período de prueba
  EXPIRED: 'expired',        // Vencida, sin pago
  CANCELLED: 'cancelled',    // Cancelada por el usuario
  SUSPENDED: 'suspended'     // Suspendida por admin
};
```

### 11.2 Middleware de Acceso Limitado

```javascript
// shared/middleware/subscription-access.middleware.js

/**
 * Controla el acceso basado en estado de suscripción
 */
async function checkSubscriptionAccess(event, context) {
  const subscription = await getActiveSubscription(context.userId);
  const action = event.requestContext.httpMethod; // GET, POST, PUT, DELETE
  const resource = event.requestContext.resourcePath;

  // Suscripción activa - acceso completo
  if (subscription.status === 'active' || subscription.status === 'trial') {
    return {
      allowed: true,
      mode: 'full',
      subscription: subscription
    };
  }

  // Suscripción vencida - acceso limitado
  if (subscription.status === 'expired') {
    // PERMITIR: Acceso completo a módulo de pagos/suscripciones
    if (resource.startsWith('/subscriptions') ||
        resource.startsWith('/payment')) {
      return {
        allowed: true,
        mode: 'full',
        subscription: subscription
      };
    }

    // PERMITIR: Solo lectura (GET) de otros recursos
    if (action === 'GET') {
      return {
        allowed: true,
        mode: 'read-only',
        subscription: subscription,
        message: 'Tu suscripción ha vencido. Solo puedes consultar tus datos. Renueva para continuar creando y editando.'
      };
    }

    // BLOQUEAR: Crear, editar, eliminar
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(action)) {
      return {
        allowed: false,
        mode: 'blocked',
        subscription: subscription,
        error: {
          code: 'SUBSCRIPTION_EXPIRED',
          message: 'Tu suscripción ha vencido. Por favor renueva tu plan para continuar usando todas las funcionalidades.',
          upgradeUrl: '/app/subscription/renew',
          planExpiredAt: subscription.end_date
        }
      };
    }
  }

  // Suscripción cancelada o suspendida - sin acceso
  if (subscription.status === 'cancelled' || subscription.status === 'suspended') {
    // Solo permitir ver perfil y gestión de suscripción
    if (resource === '/users/me' || resource.startsWith('/subscriptions')) {
      return {
        allowed: true,
        mode: 'limited',
        subscription: subscription
      };
    }

    return {
      allowed: false,
      mode: 'blocked',
      subscription: subscription,
      error: {
        code: 'SUBSCRIPTION_INACTIVE',
        message: 'Tu cuenta está inactiva. Contacta a soporte o renueva tu suscripción.'
      }
    };
  }

  // Estado desconocido - denegar acceso
  return {
    allowed: false,
    mode: 'blocked',
    error: {
      code: 'INVALID_SUBSCRIPTION_STATUS',
      message: 'Estado de suscripción inválido'
    }
  };
}

/**
 * Aplicar middleware en cada lambda
 */
exports.handler = async (event, context) => {
  try {
    // 1. Validar JWT (hecho por authorizer)
    // 2. Establecer contexto de usuario
    await setUserContext(event, context, db);

    // 3. Verificar acceso según estado de suscripción
    const accessControl = await checkSubscriptionAccess(event, context);

    if (!accessControl.allowed) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          success: false,
          error: accessControl.error
        })
      };
    }

    // 4. Si es modo read-only, agregar mensaje informativo
    if (accessControl.mode === 'read-only') {
      context.subscriptionWarning = accessControl.message;
    }

    // 5. Continuar con la lógica de la lambda
    const result = await processRequest(event, context);

    // 6. Agregar warning en respuesta si aplica
    if (context.subscriptionWarning) {
      result.warning = context.subscriptionWarning;
    }

    return result;

  } catch (error) {
    logger.error('Error in handler', { error: error.message });

    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        error: { message: 'Internal server error' }
      })
    };
  }
};
```

### 11.3 Notificaciones de Vencimiento

```javascript
// EventBridge: Ejecutar diariamente
async function sendExpirationNotifications() {
  // Alertar 5 días antes (120 horas)
  const expiringSoon = await db.query(`
    SELECT
      s.*,
      u.email,
      u.name,
      p.name as plan_name
    FROM subscriptions s
    JOIN users u ON s.user_id = u.id
    JOIN plans p ON s.plan_id = p.id
    WHERE s.status = 'active'
      AND s.end_date BETWEEN NOW() AND NOW() + INTERVAL '5 days'
      AND s.end_date > NOW()
  `);

  for (const sub of expiringSoon.rows) {
    const daysRemaining = Math.ceil(
      (new Date(sub.end_date) - new Date()) / (1000 * 60 * 60 * 24)
    );

    await sendEmail({
      to: sub.email,
      subject: `Tu suscripción vence en ${daysRemaining} días`,
      template: 'subscription-expiring',
      data: {
        name: sub.name,
        plan: sub.plan_name,
        expiryDate: sub.end_date,
        daysRemaining: daysRemaining,
        renewUrl: `https://app.temis.com/subscription/renew`
      }
    });

    await sendPushNotification({
      userId: sub.user_id,
      title: 'Tu suscripción está por vencer',
      body: `Tu plan ${sub.plan_name} vence en ${daysRemaining} días. Renueva para seguir disfrutando de todas las funcionalidades.`,
      data: {
        type: 'subscription_expiring',
        action: 'open_renewal_page'
      }
    });
  }

  // Notificar suscripciones recién vencidas
  const justExpired = await db.query(`
    SELECT
      s.*,
      u.email,
      u.name
    FROM subscriptions s
    JOIN users u ON s.user_id = u.id
    WHERE s.status = 'active'
      AND s.end_date < NOW()
      AND s.end_date > NOW() - INTERVAL '1 day'
  `);

  for (const sub of justExpired.rows) {
    // Cambiar estado a expired
    await db.query(`
      UPDATE subscriptions
      SET status = 'expired'
      WHERE id = $1
    `, [sub.id]);

    await sendEmail({
      to: sub.email,
      subject: 'Tu suscripción ha vencido',
      template: 'subscription-expired',
      data: {
        name: sub.name,
        renewUrl: `https://app.temis.com/subscription/renew`
      }
    });
  }
}
```

---

## 12. Auditoría y Logging

### 12.1 Audit Log

```javascript
// shared/services/audit.service.js

async function auditLog(data) {
  await db.query(`
    INSERT INTO audit_logs (
      organization_id,
      user_id,
      action,
      entity_type,
      entity_id,
      old_values,
      new_values,
      ip_address,
      user_agent
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
  `, [
    data.organizationId,
    data.userId,
    data.action,
    data.entityType,
    data.entityId,
    JSON.stringify(data.oldValues),
    JSON.stringify(data.newValues),
    data.ipAddress,
    data.userAgent
  ]);
}

// Eventos importantes a auditar:
const AUDIT_EVENTS = {
  // Autenticación
  LOGIN_SUCCESS: 'LOGIN_SUCCESS',
  LOGIN_FAILED: 'LOGIN_FAILED',
  LOGOUT: 'LOGOUT',
  PASSWORD_CHANGED: 'PASSWORD_CHANGED',
  PASSWORD_RESET: 'PASSWORD_RESET',

  // IA
  AI_CHAT_MESSAGE: 'AI_CHAT_MESSAGE',
  AI_VOICE_TRANSCRIPTION: 'AI_VOICE_TRANSCRIPTION',
  AI_QUOTA_EXCEEDED: 'AI_QUOTA_EXCEEDED',

  // Pagos (Wompi)
  PAYMENT_METHOD_ADDED: 'PAYMENT_METHOD_ADDED',
  PAYMENT_SUCCESS: 'PAYMENT_SUCCESS',
  PAYMENT_FAILED: 'PAYMENT_FAILED',

  // Datos sensibles
  PASSWORD_ACCESSED: 'PASSWORD_ACCESSED',
  PASSWORD_CREATED: 'PASSWORD_CREATED',
  PASSWORD_UPDATED: 'PASSWORD_UPDATED',
  PASSWORD_DELETED: 'PASSWORD_DELETED',

  // Suscripciones
  SUBSCRIPTION_UPGRADED: 'SUBSCRIPTION_UPGRADED',
  SUBSCRIPTION_CANCELLED: 'SUBSCRIPTION_CANCELLED',

  // Admin
  USER_SUSPENDED: 'USER_SUSPENDED',
  USER_ACTIVATED: 'USER_ACTIVATED',

  // Suscripciones vencidas
  SUBSCRIPTION_EXPIRED: 'SUBSCRIPTION_EXPIRED',
  SUBSCRIPTION_EXPIRED_ACCESS_DENIED: 'SUBSCRIPTION_EXPIRED_ACCESS_DENIED'
};
```

### 12.2 Logging Estructurado

```javascript
// shared/utils/logger.js
const winston = require('winston');

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

// Uso en lambdas
logger.info('Task created', {
  userId: context.userId,
  taskId: task.id,
  priority: task.priority
});

logger.error('Database error', {
  error: error.message,
  stack: error.stack,
  query: query
});

logger.warn('Plan limit approaching', {
  userId: context.userId,
  limit: 'reminders',
  current: 45,
  max: 50
});
```

---

## 13. Protección contra Ataques Comunes

### 13.1 SQL Injection

**Prevención**: Usar queries parametrizadas SIEMPRE

```javascript
// ✅ SEGURO - Parametrizado
await db.query('SELECT * FROM users WHERE email = $1', [email]);

// ❌ INSEGURO - String concatenation
await db.query(`SELECT * FROM users WHERE email = '${email}'`);
```

### 13.2 XSS (Cross-Site Scripting)

**Prevención**: Sanitizar input del usuario

```javascript
const validator = require('validator');

function sanitizeInput(input) {
  return validator.escape(input);
}

// Validar y sanitizar
const title = sanitizeInput(req.body.title);
```

### 13.3 Rate Limiting

```javascript
// API Gateway - Configuración de throttling
{
  "defaultThrottle": {
    "rateLimit": 100,      // requests por segundo
    "burstLimit": 200
  },
  "perRouteThrottle": {
    "/auth/login": {
      "rateLimit": 5,       // 5 intentos por segundo
      "burstLimit": 10
    },
    "/passwords/{id}": {
      "rateLimit": 20,      // Limitar acceso a contraseñas
      "burstLimit": 30
    },
    "/ai/chat": {
      "rateLimit": 10,      // Limitar IA
      "burstLimit": 15
    },
    "/voice/*": {
      "rateLimit": 5,       // Limitar procesamiento de voz
      "burstLimit": 8
    }
  }
}
```

### 13.4 CSRF Protection

**Prevención**: JWT tokens + SameSite cookies

```javascript
// En respuesta de login
res.cookie('refreshToken', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict',
  maxAge: 7 * 24 * 60 * 60 * 1000
});
```

---

## 14. Checklist de Seguridad

### 14.1 Por Cada Lambda

- [ ] Establece contexto de usuario con `setUserContext()`
- [ ] Usa `SecureQuery` o filtra manualmente por `organization_id` Y `user_id`
- [ ] Valida JWT token (via Authorizer)
- [ ] Verifica permisos de rol si es necesario
- [ ] Valida features del plan si es necesario
- [ ] Valida estado de suscripción (expired = solo lectura)
- [ ] Verifica cuota de IA antes de llamar Bedrock
- [ ] Sanitiza inputs del usuario
- [ ] Usa queries parametrizadas
- [ ] Registra eventos importantes en audit log
- [ ] Maneja errores sin exponer información sensible
- [ ] Limpia datos sensibles antes de retornar

### 14.2 Por Cada Deploy

- [ ] Rotar claves JWT (cada 90 días)
- [ ] Revisar policies de RLS activas
- [ ] Auditar accesos a Parameter Store
- [ ] Revisar logs de CloudWatch
- [ ] Verificar alarmas de seguridad (incluir Bedrock cost alarm)
- [ ] Actualizar dependencias vulnerables
- [ ] Ejecutar tests de seguridad
- [ ] Revisar permisos de IAM roles
- [ ] Verificar webhook secret de Wompi

---

## 15. Respuesta a Incidentes

### 15.1 Detección de Brecha

```javascript
// Alarmas configuradas
{
  "UnauthorizedAccessAttempts": {
    "metric": "401 errors",
    "threshold": "> 100 in 5 min",
    "action": "Alert security team"
  },
  "MassiveDataAccess": {
    "metric": "Password access count",
    "threshold": "> 50 per user in 1 min",
    "action": "Block user, alert security"
  },
  "FailedLoginAttempts": {
    "metric": "Login failures",
    "threshold": "> 10 per IP in 5 min",
    "action": "Block IP temporarily"
  },
  "AIQuotaAbuse": {
    "metric": "AI usage spike",
    "threshold": "> 100 requests per user in 1 hour",
    "action": "Throttle user, alert security"
  },
  "UnauthorizedPaymentAttempt": {
    "metric": "Failed Wompi webhook signature",
    "threshold": "> 5 in 10 min",
    "action": "Block IP, alert security"
  }
}
```

### 15.2 Plan de Respuesta

1. **Detección**: Alarma de CloudWatch o Wompi webhook sospechoso
2. **Análisis**: Revisar audit logs y payment_audit_logs
3. **Contención**: Suspender usuario/IP afectado, revocar tokens
4. **Erradicación**: Cerrar brecha de seguridad, actualizar secrets
5. **Recuperación**: Restaurar servicio seguro, notificar usuarios afectados
6. **Post-mortem**: Documentar lecciones aprendidas

---

## 16. Compliance y Estándares

### 16.1 OWASP Top 10

- [x] A01:2021 - Broken Access Control
- [x] A02:2021 - Cryptographic Failures
- [x] A03:2021 - Injection
- [x] A04:2021 - Insecure Design
- [x] A05:2021 - Security Misconfiguration
- [x] A07:2021 - Identification and Authentication Failures
- [x] A08:2021 - Software and Data Integrity Failures
- [x] A09:2021 - Security Logging and Monitoring Failures

### 16.2 PCI DSS (Payment Card Industry Data Security Standard)

- [x] Nunca almacenar datos completos de tarjeta
- [x] Usar tokenización (Wompi payment_source_id)
- [x] TLS 1.3 para transmisión de datos
- [x] Verificar siempre firmas de webhooks
- [x] Auditar todos los eventos de pago
- [x] Validar montos contra precios de planes

### 16.3 Mejores Prácticas

- **Principio de Menor Privilegio**: Cada lambda tiene solo los permisos necesarios
- **Defensa en Profundidad**: Múltiples capas de seguridad
- **Zero Trust**: No confiar en nada, verificar todo
- **Segregación de Datos**: Aislamiento estricto por tenant (organization_id + user_id)
- **Encriptación**: En tránsito (TLS) y en reposo (AES-256)
- **Auditoría**: Logging de todas las operaciones sensibles (incluye IA y pagos)
- **Privacidad de IA**: Anonimizar datos antes de enviar a Bedrock
- **Control de Costos**: Cuotas estrictas de IA por plan
- **PCI Compliance**: Tokenización de tarjetas, nunca almacenar datos completos

---

## Changelog

### v1.1.0 (2026-07-12)
- ✅ Agregada sección 9: Seguridad de Servicios de IA
  - Privacidad de datos con Amazon Bedrock
  - Control de cuotas de IA por plan
  - Rate limiting de IA
  - Monitoreo de costos de IA
- ✅ Agregada sección 10: Seguridad de Pagos (Wompi)
  - PCI Compliance (nunca almacenar tarjetas completas)
  - Verificación de webhooks con firma HMAC SHA-256
  - Protección de endpoints de pago
  - Auditoría completa de eventos de pago
- ✅ Agregada sección 11: Control de Acceso con Suscripción Vencida
  - Estados de suscripción (active, expired, cancelled, suspended)
  - Middleware de acceso limitado (solo lectura cuando vence)
  - Notificaciones 5 días antes del vencimiento
  - Acceso completo a módulo de pagos cuando está vencida
- ✅ Actualizados eventos de auditoría (IA, pagos, suscripciones vencidas)
- ✅ Actualizado rate limiting (incluye endpoints de IA y voz)
- ✅ Actualizado checklist de seguridad
- ✅ Actualizadas alarmas de detección de brechas

### v1.0.0 (2026-07-12)
- Versión inicial con seguridad base y multitenancy

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.1.0
