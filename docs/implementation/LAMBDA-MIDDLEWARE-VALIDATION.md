# GUÍA DE IMPLEMENTACIÓN: Middleware de Validación de Módulos en Lambdas

**Fecha:** 2026-09-24
**Versión:** 1.0.0
**Autor:** Equipo Backend TEMIS

---

## 📋 ÍNDICE

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura del Middleware](#arquitectura-del-middleware)
3. [Utilidades Compartidas](#utilidades-compartidas)
4. [Implementación por Lambda](#implementación-por-lambda)
5. [Manejo de Errores](#manejo-de-errores)
6. [Testing](#testing)
7. [Deployment](#deployment)

---

## 🎯 RESUMEN EJECUTIVO

Este documento describe la implementación de middleware de validación de acceso a módulos en las AWS Lambdas de TEMIS.

**Módulos que requieren validación:**
- **Módulo Finanzas**: Lambdas de Transactions, Budgets, Accounts
- **Módulo AI Memory**: Lambda de AI Memory

**Planes con acceso:**
- Finanzas: Basic, Pro, Premium
- AI Memory: Pro, Premium

---

## 🏗️ ARQUITECTURA DEL MIDDLEWARE

### Flujo de Validación

```
┌─────────────────────────────────────────────────────────────┐
│  1. Request llega a Lambda                                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  2. API Gateway extrae JWT y lo pasa en event.requestContext│
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  3. Middleware lee organizationId y userId del context      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  4. Consulta DB: has_finance_module() o has_ai_memory_module()│
└─────────────────────────────────────────────────────────────┘
                           ↓
                 ┌─────────┴─────────┐
                 │ ¿Tiene acceso?    │
                 └─────────┬─────────┘
                           │
          ┌────────────────┼────────────────┐
          │ NO                               │ SÍ
          ↓                                  ↓
┌─────────────────────┐         ┌──────────────────────────┐
│ Retornar 403        │         │ Continuar con lógica     │
│ con mensaje upgrade │         │ del endpoint             │
└─────────────────────┘         └──────────────────────────┘
```

---

## 🔧 UTILIDADES COMPARTIDAS

### 1. Archivo: `src/utils/planValidation.js`

```javascript
/**
 * TEMIS - Utilidades de Validación de Planes
 *
 * Funciones compartidas para validar acceso a módulos según el plan
 * del usuario.
 */

const { getDbConnection } = require('./database');

/**
 * Verifica si el usuario tiene acceso al módulo de Finanzas
 *
 * @param {number} organizationId - ID de la organización
 * @param {number} userId - ID del usuario
 * @returns {Promise<boolean>} true si tiene acceso, false si no
 */
async function hasFinanceModule(organizationId, userId) {
  const db = await getDbConnection();

  try {
    const result = await db.query(
      'SELECT has_finance_module($1, $2) AS has_access',
      [organizationId, userId]
    );

    return result.rows[0].has_access;
  } catch (error) {
    console.error('Error checking finance module access:', error);
    throw error;
  }
}

/**
 * Verifica si el usuario tiene acceso al módulo de AI Memory
 *
 * @param {number} organizationId - ID de la organización
 * @param {number} userId - ID del usuario
 * @returns {Promise<boolean>} true si tiene acceso, false si no
 */
async function hasAIMemoryModule(organizationId, userId) {
  const db = await getDbConnection();

  try {
    const result = await db.query(
      'SELECT has_ai_memory_module($1, $2) AS has_access',
      [organizationId, userId]
    );

    return result.rows[0].has_access;
  } catch (error) {
    console.error('Error checking AI Memory module access:', error);
    throw error;
  }
}

/**
 * Verifica un feature específico del plan
 *
 * @param {number} organizationId - ID de la organización
 * @param {number} userId - ID del usuario
 * @param {string} feature - Nombre del feature (ej: 'tasks', 'passwords', 'transactions')
 * @returns {Promise<boolean>} true si tiene acceso, false si no
 */
async function checkPlanFeature(organizationId, userId, feature) {
  const db = await getDbConnection();

  try {
    const result = await db.query(
      'SELECT check_plan_feature($1, $2, $3) AS has_feature',
      [organizationId, userId, feature]
    );

    return result.rows[0].has_feature;
  } catch (error) {
    console.error(`Error checking plan feature '${feature}':`, error);
    throw error;
  }
}

/**
 * Obtiene el plan actual del usuario con sus límites
 *
 * @param {number} organizationId - ID de la organización
 * @param {number} userId - ID del usuario
 * @returns {Promise<Object>} Objeto con información del plan y features
 */
async function getUserPlan(organizationId, userId) {
  const db = await getDbConnection();

  try {
    const result = await db.query(`
      SELECT
        pl.id,
        pl.slug,
        pl.name,
        pl.features,
        s.status AS subscription_status,
        s.current_period_end
      FROM subscriptions s
      JOIN plans pl ON s.plan_id = pl.id
      WHERE s.organization_id = $1
        AND s.user_id = $2
        AND s.status IN ('trial', 'active')
      ORDER BY s.created_at DESC
      LIMIT 1
    `, [organizationId, userId]);

    if (result.rows.length === 0) {
      // Sin suscripción activa, asumir Free
      return {
        slug: 'free',
        name: 'Free',
        features: {
          tasks: 50,
          passwords: 10,
          finance_module: false,
          ai_memory_module: false
        },
        subscription_status: null
      };
    }

    return result.rows[0];
  } catch (error) {
    console.error('Error getting user plan:', error);
    throw error;
  }
}

module.exports = {
  hasFinanceModule,
  hasAIMemoryModule,
  checkPlanFeature,
  getUserPlan
};
```

---

### 2. Archivo: `src/utils/errorResponses.js`

```javascript
/**
 * TEMIS - Respuestas de Error Estandarizadas
 */

const { v4: uuidv4 } = require('uuid');

/**
 * Genera respuesta 403 para módulo no activo
 *
 * @param {string} moduleName - Nombre del módulo ('finance' o 'ai_memory')
 * @param {string} messageUuid - UUID del mensaje original
 * @param {string} requestAppId - ID de la app que hizo la request
 * @returns {Object} Respuesta HTTP 403
 */
function moduleNotActiveError(moduleName, messageUuid, requestAppId) {
  const moduleMessages = {
    finance: {
      code: 'FINANCE_MODULE_NOT_ACTIVE',
      message: 'Módulo de Finanzas no activo',
      detail: 'Tu plan actual no incluye el módulo de Finanzas. Actualiza a Basic, Pro o Premium para acceder.',
      plansWithAccess: ['Basic', 'Pro', 'Premium']
    },
    ai_memory: {
      code: 'AI_MEMORY_MODULE_NOT_ACTIVE',
      message: 'Módulo de AI Memory no activo',
      detail: 'Tu plan actual no incluye el módulo de AI Memory. Actualiza a Pro o Premium para acceder.',
      plansWithAccess: ['Pro', 'Premium']
    }
  };

  const module = moduleMessages[moduleName];

  return {
    statusCode: 403,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({
      headers: {
        httpStatusCode: 403,
        httpStatusDesc: 'Forbidden',
        messageUuid: messageUuid || uuidv4(),
        requestDatetime: new Date().toISOString(),
        requestAppId: requestAppId || 'unknown'
      },
      messageResponse: {
        responseCode: module.code,
        responseMessage: module.message,
        responseDetail: module.detail
      },
      errors: [
        {
          errorCode: 'MODULE_REQUIRED',
          errorDetail: moduleName,
          upgradeUrl: '/subscriptions/plans',
          plansWithAccess: module.plansWithAccess
        }
      ]
    })
  };
}

/**
 * Genera respuesta 429 para límite de plan excedido
 *
 * @param {string} feature - Feature que excedió el límite
 * @param {number} currentUsage - Uso actual
 * @param {number} planLimit - Límite del plan
 * @param {string} messageUuid - UUID del mensaje
 * @param {string} requestAppId - ID de la app
 * @returns {Object} Respuesta HTTP 429
 */
function planLimitExceededError(feature, currentUsage, planLimit, messageUuid, requestAppId) {
  const featureNames = {
    tasks: 'tareas',
    passwords: 'contraseñas',
    transactions: 'transacciones',
    budgets: 'presupuestos',
    accounts: 'cuentas',
    memories: 'memorias'
  };

  const featureName = featureNames[feature] || feature;

  return {
    statusCode: 429,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Retry-After': '86400' // 24 horas (reinicio mensual)
    },
    body: JSON.stringify({
      headers: {
        httpStatusCode: 429,
        httpStatusDesc: 'Too Many Requests',
        messageUuid: messageUuid || uuidv4(),
        requestDatetime: new Date().toISOString(),
        requestAppId: requestAppId || 'unknown'
      },
      messageResponse: {
        responseCode: 'PLAN_LIMIT_EXCEEDED',
        responseMessage: `Límite mensual de ${featureName} excedido`,
        responseDetail: `Has alcanzado el límite de ${planLimit} ${featureName}/mes de tu plan. Actualiza tu plan para mayor capacidad.`
      },
      errors: [
        {
          errorCode: 'QUOTA_EXCEEDED',
          errorDetail: feature,
          currentUsage,
          planLimit,
          upgradeUrl: '/subscriptions/plans'
        }
      ]
    })
  };
}

module.exports = {
  moduleNotActiveError,
  planLimitExceededError
};
```

---

## 📦 IMPLEMENTACIÓN POR LAMBDA

### Lambda: Transactions (Finanzas)

**Archivo:** `src/lambdas/transactions/index.js`

```javascript
const { hasFinanceModule } = require('../../utils/planValidation');
const { moduleNotActiveError } = require('../../utils/errorResponses');

/**
 * Middleware: Validar acceso al módulo de Finanzas
 */
async function validateFinanceModuleAccess(event) {
  const { organizationId, userId } = event.requestContext.authorizer;
  const messageUuid = event.headers['message-uuid'];
  const requestAppId = event.headers['request-app-id'];

  try {
    const hasAccess = await hasFinanceModule(organizationId, userId);

    if (!hasAccess) {
      console.log(`Access denied - Finance module not active for user ${userId}`);
      return moduleNotActiveError('finance', messageUuid, requestAppId);
    }

    return null; // Acceso permitido
  } catch (error) {
    console.error('Error validating finance module access:', error);

    // En caso de error, denegar por seguridad
    return {
      statusCode: 500,
      body: JSON.stringify({
        messageResponse: {
          responseCode: 'INTERNAL_ERROR',
          responseMessage: 'Error al validar acceso al módulo'
        }
      })
    };
  }
}

/**
 * Handler principal - GET /transactions
 */
exports.listTransactions = async (event) => {
  // 1. Validar acceso al módulo
  const accessError = await validateFinanceModuleAccess(event);
  if (accessError) return accessError;

  // 2. Lógica del endpoint
  try {
    // ... tu lógica existente aquí ...

    return {
      statusCode: 200,
      body: JSON.stringify({
        headers: { /* ... */ },
        messageResponse: { /* ... */ },
        data: {
          transactions: [/* ... */]
        }
      })
    };
  } catch (error) {
    console.error('Error listing transactions:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ /* ... */ })
    };
  }
};

/**
 * Handler - POST /transactions
 */
exports.createTransaction = async (event) => {
  // 1. Validar acceso al módulo
  const accessError = await validateFinanceModuleAccess(event);
  if (accessError) return accessError;

  // 2. Lógica del endpoint
  try {
    const body = JSON.parse(event.body);

    // ... tu lógica de creación ...

    return {
      statusCode: 201,
      body: JSON.stringify({ /* ... */ })
    };
  } catch (error) {
    console.error('Error creating transaction:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ /* ... */ })
    };
  }
};

/**
 * Handler - PUT /transactions/{id}
 */
exports.updateTransaction = async (event) => {
  // 1. Validar acceso al módulo
  const accessError = await validateFinanceModuleAccess(event);
  if (accessError) return accessError;

  // 2. Lógica del endpoint
  const transactionId = event.pathParameters.id;
  const body = JSON.parse(event.body);

  // ... tu lógica de actualización ...

  return {
    statusCode: 200,
    body: JSON.stringify({ /* ... */ })
  };
};

/**
 * Handler - DELETE /transactions/{id}
 */
exports.deleteTransaction = async (event) => {
  // 1. Validar acceso al módulo
  const accessError = await validateFinanceModuleAccess(event);
  if (accessError) return accessError;

  // 2. Lógica del endpoint
  const transactionId = event.pathParameters.id;

  // ... tu lógica de eliminación ...

  return {
    statusCode: 204
  };
};
```

---

### Lambda: Budgets (Finanzas)

**Archivo:** `src/lambdas/budgets/index.js`

```javascript
const { hasFinanceModule } = require('../../utils/planValidation');
const { moduleNotActiveError } = require('../../utils/errorResponses');

/**
 * Middleware: Validar acceso al módulo de Finanzas
 * (Mismo código que en transactions)
 */
async function validateFinanceModuleAccess(event) {
  const { organizationId, userId } = event.requestContext.authorizer;
  const messageUuid = event.headers['message-uuid'];
  const requestAppId = event.headers['request-app-id'];

  try {
    const hasAccess = await hasFinanceModule(organizationId, userId);

    if (!hasAccess) {
      console.log(`Access denied - Finance module not active for user ${userId}`);
      return moduleNotActiveError('finance', messageUuid, requestAppId);
    }

    return null;
  } catch (error) {
    console.error('Error validating finance module access:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        messageResponse: {
          responseCode: 'INTERNAL_ERROR',
          responseMessage: 'Error al validar acceso al módulo'
        }
      })
    };
  }
}

/**
 * Handlers para budgets (aplicar el mismo patrón)
 */
exports.listBudgets = async (event) => {
  const accessError = await validateFinanceModuleAccess(event);
  if (accessError) return accessError;

  // Lógica del endpoint...
};

exports.createBudget = async (event) => {
  const accessError = await validateFinanceModuleAccess(event);
  if (accessError) return accessError;

  // Lógica del endpoint...
};

exports.getBudgetProjection = async (event) => {
  const accessError = await validateFinanceModuleAccess(event);
  if (accessError) return accessError;

  // Lógica del endpoint...
};
```

---

### Lambda: AI Memory

**Archivo:** `src/lambdas/ai-memory/index.js`

```javascript
const { hasAIMemoryModule } = require('../../utils/planValidation');
const { moduleNotActiveError } = require('../../utils/errorResponses');

/**
 * Middleware: Validar acceso al módulo de AI Memory
 */
async function validateAIMemoryModuleAccess(event) {
  const { organizationId, userId } = event.requestContext.authorizer;
  const messageUuid = event.headers['message-uuid'];
  const requestAppId = event.headers['request-app-id'];

  try {
    const hasAccess = await hasAIMemoryModule(organizationId, userId);

    if (!hasAccess) {
      console.log(`Access denied - AI Memory module not active for user ${userId}`);
      return moduleNotActiveError('ai_memory', messageUuid, requestAppId);
    }

    return null;
  } catch (error) {
    console.error('Error validating AI Memory module access:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        messageResponse: {
          responseCode: 'INTERNAL_ERROR',
          responseMessage: 'Error al validar acceso al módulo'
        }
      })
    };
  }
}

/**
 * Handlers para AI Memory
 */
exports.createMemory = async (event) => {
  const accessError = await validateAIMemoryModuleAccess(event);
  if (accessError) return accessError;

  // Lógica del endpoint...
};

exports.listMemories = async (event) => {
  const accessError = await validateAIMemoryModuleAccess(event);
  if (accessError) return accessError;

  // Lógica del endpoint...
};

exports.searchMemories = async (event) => {
  const accessError = await validateAIMemoryModuleAccess(event);
  if (accessError) return accessError;

  // Lógica del endpoint...
};
```

---

## 🧪 TESTING

### Tests Unitarios

**Archivo:** `tests/unit/planValidation.test.js`

```javascript
const { hasFinanceModule, hasAIMemoryModule } = require('../../src/utils/planValidation');

// Mock del pool de base de datos
jest.mock('../../src/utils/database');
const { getDbConnection } = require('../../src/utils/database');

describe('Plan Validation Utils', () => {
  let mockDb;

  beforeEach(() => {
    mockDb = {
      query: jest.fn()
    };
    getDbConnection.mockResolvedValue(mockDb);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('hasFinanceModule', () => {
    test('debería retornar true para usuario con plan Basic', async () => {
      mockDb.query.mockResolvedValue({
        rows: [{ has_access: true }]
      });

      const result = await hasFinanceModule(1, 123);

      expect(result).toBe(true);
      expect(mockDb.query).toHaveBeenCalledWith(
        'SELECT has_finance_module($1, $2) AS has_access',
        [1, 123]
      );
    });

    test('debería retornar false para usuario con plan Free', async () => {
      mockDb.query.mockResolvedValue({
        rows: [{ has_access: false }]
      });

      const result = await hasFinanceModule(1, 456);

      expect(result).toBe(false);
    });

    test('debería propagar errores de base de datos', async () => {
      mockDb.query.mockRejectedValue(new Error('DB connection failed'));

      await expect(hasFinanceModule(1, 123)).rejects.toThrow('DB connection failed');
    });
  });

  describe('hasAIMemoryModule', () => {
    test('debería retornar true para usuario con plan Pro', async () => {
      mockDb.query.mockResolvedValue({
        rows: [{ has_access: true }]
      });

      const result = await hasAIMemoryModule(1, 789);

      expect(result).toBe(true);
      expect(mockDb.query).toHaveBeenCalledWith(
        'SELECT has_ai_memory_module($1, $2) AS has_access',
        [1, 789]
      );
    });

    test('debería retornar false para usuario con plan Basic', async () => {
      mockDb.query.mockResolvedValue({
        rows: [{ has_access: false }]
      });

      const result = await hasAIMemoryModule(1, 456);

      expect(result).toBe(false);
    });
  });
});
```

---

### Tests de Integración

**Archivo:** `tests/integration/transactionsModule.test.js`

```javascript
const { handler } = require('../../src/lambdas/transactions/index');

describe('Transactions Lambda - Module Access', () => {
  test('debería retornar 403 para usuario sin módulo Finance', async () => {
    const event = {
      requestContext: {
        authorizer: {
          organizationId: 1,
          userId: 123 // Usuario con plan Free
        }
      },
      headers: {
        'message-uuid': 'test-uuid-123',
        'request-app-id': 'test-app'
      }
    };

    const response = await handler.listTransactions(event);

    expect(response.statusCode).toBe(403);

    const body = JSON.parse(response.body);
    expect(body.messageResponse.responseCode).toBe('FINANCE_MODULE_NOT_ACTIVE');
    expect(body.errors[0].errorCode).toBe('MODULE_REQUIRED');
    expect(body.errors[0].errorDetail).toBe('finance');
  });

  test('debería permitir acceso para usuario con plan Basic', async () => {
    const event = {
      requestContext: {
        authorizer: {
          organizationId: 1,
          userId: 456 // Usuario con plan Basic
        }
      },
      headers: {
        'message-uuid': 'test-uuid-456',
        'request-app-id': 'test-app'
      },
      queryStringParameters: {}
    };

    const response = await handler.listTransactions(event);

    expect(response.statusCode).toBe(200);

    const body = JSON.parse(response.body);
    expect(body.data).toHaveProperty('transactions');
  });
});
```

---

## 🚀 DEPLOYMENT

### 1. Actualizar `serverless.yml`

```yaml
functions:
  # Lambda Transactions
  listTransactions:
    handler: src/lambdas/transactions/index.listTransactions
    events:
      - http:
          path: /transactions
          method: get
          authorizer:
            name: authorizerFunc
            type: request
    environment:
      DB_HOST: ${env:DB_HOST}
      DB_PORT: ${env:DB_PORT}
      DB_NAME: ${env:DB_NAME}
      DB_USER: ${env:DB_USER}
      DB_PASSWORD: ${env:DB_PASSWORD}

  createTransaction:
    handler: src/lambdas/transactions/index.createTransaction
    events:
      - http:
          path: /transactions
          method: post
          authorizer:
            name: authorizerFunc
            type: request
    environment:
      DB_HOST: ${env:DB_HOST}
      # ... resto de variables

  # Lambda Budgets
  listBudgets:
    handler: src/lambdas/budgets/index.listBudgets
    events:
      - http:
          path: /budgets
          method: get
          authorizer:
            name: authorizerFunc
            type: request

  # Lambda AI Memory
  createMemory:
    handler: src/lambdas/ai-memory/index.createMemory
    events:
      - http:
          path: /memories
          method: post
          authorizer:
            name: authorizerFunc
            type: request
```

### 2. Variables de Entorno

Asegurarse de que todas las lambdas tengan acceso a las variables de DB:

```bash
# .env.production
DB_HOST=temis-prod.c9k2x3y4z5.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=temis_prod
DB_USER=temis_app
DB_PASSWORD=***************
```

### 3. Deploy

```bash
# Instalar dependencias
npm install

# Ejecutar tests
npm test

# Deploy a producción
serverless deploy --stage production

# Verificar deploy
serverless info --stage production
```

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

### Código
- [ ] Crear `src/utils/planValidation.js`
- [ ] Crear `src/utils/errorResponses.js`
- [ ] Actualizar `src/lambdas/transactions/index.js` con middleware
- [ ] Actualizar `src/lambdas/budgets/index.js` con middleware
- [ ] Actualizar `src/lambdas/ai-memory/index.js` con middleware
- [ ] Actualizar `src/lambdas/accounts/index.js` con middleware (si existe)

### Testing
- [ ] Crear tests unitarios de `planValidation.js`
- [ ] Crear tests unitarios de `errorResponses.js`
- [ ] Crear tests de integración para cada lambda
- [ ] Ejecutar `npm test` y verificar 100% de coverage en utils

### Base de Datos
- [ ] Ejecutar `DATABASE-SCHEMA-COMPLETE.sql` en ambiente de desarrollo
- [ ] Verificar que funciones `has_finance_module()` y `has_ai_memory_module()` funcionan
- [ ] Crear usuarios de prueba con diferentes planes
- [ ] Probar consultas manualmente

### Deploy
- [ ] Actualizar `serverless.yml` con configuración correcta
- [ ] Configurar variables de entorno en AWS Systems Manager Parameter Store
- [ ] Deploy a ambiente de staging primero
- [ ] Pruebas manuales en staging
- [ ] Deploy a producción
- [ ] Monitorear logs de CloudWatch

### Documentación
- [ ] Actualizar README.md con instrucciones de validación de módulos
- [ ] Documentar códigos de error en wiki del equipo
- [ ] Crear runbook para troubleshooting

---

## 🔍 TROUBLESHOOTING

### Problema: Todos los usuarios reciben 403

**Causa:** Función SQL no encuentra suscripción activa

**Solución:**
```sql
-- Verificar que usuarios tengan suscripción
SELECT u.id, u.email, s.id AS sub_id, pl.slug
FROM users u
LEFT JOIN subscriptions s ON s.user_id = u.id AND s.status IN ('trial', 'active')
LEFT JOIN plans pl ON s.plan_id = pl.id;

-- Si usuarios no tienen suscripción, crearlas
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
SELECT u.organization_id, u.id,
       (SELECT id FROM plans WHERE slug = 'free'),
       'active', 'monthly', NOW(), NOW() + INTERVAL '1 year'
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM subscriptions WHERE user_id = u.id);
```

### Problema: Error "TypeError: Cannot read property 'organizationId' of undefined"

**Causa:** Authorizer no está pasando datos en `event.requestContext.authorizer`

**Solución:** Verificar lambda authorizer en API Gateway
```javascript
// Lambda Authorizer debe retornar:
{
  principalId: userId,
  policyDocument: { /* ... */ },
  context: {
    organizationId: user.organization_id,
    userId: user.id,
    email: user.email
  }
}
```

---

## 📚 REFERENCIAS

- **Base de datos:** `/docs/database/DATABASE-SCHEMA-COMPLETE.sql`
- **Modelo de planes:** `/docs/architecture/MODELO-PLANES-Y-LIMITES.md`
- **Contratos API:** `/contratos/TEMIS_CONTRATO_*.yaml`

---

**Última actualización:** 2026-09-24
**Versión:** 1.0.0
**Estado:** ✅ LISTO PARA IMPLEMENTACIÓN
