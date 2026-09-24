# PLAN DE TESTING: Validación de Planes y Módulos

**Fecha:** 2026-09-24
**Versión:** 1.0.0
**Autor:** Equipo QA TEMIS

---

## 📋 ÍNDICE

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Tests de Base de Datos](#tests-de-base-de-datos)
3. [Tests Unitarios](#tests-unitarios)
4. [Tests de Integración](#tests-de-integración)
5. [Tests End-to-End](#tests-end-to-end)
6. [Tests de Regresión](#tests-de-regresión)
7. [Casos Edge](#casos-edge)

---

## 🎯 RESUMEN EJECUTIVO

Este documento define todos los casos de prueba para validar el modelo de planes con acceso progresivo a módulos.

**Alcance:**
- ✅ Funciones SQL de validación
- ✅ Middleware de lambdas
- ✅ Endpoints de API
- ✅ Respuestas de error
- ✅ Casos edge y límites

**Cobertura esperada:** 100% en funciones SQL y utilities, 95%+ en lambdas

---

## 🗄️ TESTS DE BASE DE DATOS

### Test Suite: Funciones SQL

#### Test 1: `check_plan_feature()` con valores numéricos

```sql
-- Setup
INSERT INTO organizations (id, name, slug) VALUES (999, 'Test Org', 'test-org');
INSERT INTO users (id, organization_id, email, password_hash, name)
VALUES (1001, 999, 'test@test.com', 'hash', 'Test User');
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'basic'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

-- Test: Usuario Basic tiene acceso a tasks (200 > 0)
SELECT check_plan_feature(999, 1001, 'tasks') AS result;
-- Esperado: true

-- Test: Usuario Basic tiene acceso a transactions (1000 > 0)
SELECT check_plan_feature(999, 1001, 'transactions') AS result;
-- Esperado: true

-- Test: Usuario Basic NO tiene acceso a memories (0)
SELECT check_plan_feature(999, 1001, 'memories') AS result;
-- Esperado: false

-- Cleanup
DELETE FROM subscriptions WHERE organization_id = 999;
DELETE FROM users WHERE id = 1001;
DELETE FROM organizations WHERE id = 999;
```

**Resultado esperado:** ✅ Todos los tests pasan

---

#### Test 2: `check_plan_feature()` con valores booleanos

```sql
-- Setup (mismo que Test 1)

-- Test: Usuario Basic tiene finance_module
SELECT check_plan_feature(999, 1001, 'finance_module') AS result;
-- Esperado: true

-- Test: Usuario Basic NO tiene ai_memory_module
SELECT check_plan_feature(999, 1001, 'ai_memory_module') AS result;
-- Esperado: false

-- Cleanup
```

**Resultado esperado:** ✅ Todos los tests pasan

---

#### Test 3: `check_plan_feature()` con valores ilimitados (-1)

```sql
-- Setup: Usuario con plan Pro
INSERT INTO organizations (id, name, slug) VALUES (998, 'Pro Org', 'pro-org');
INSERT INTO users (id, organization_id, email, password_hash, name)
VALUES (1002, 998, 'pro@test.com', 'hash', 'Pro User');
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (998, 1002, (SELECT id FROM plans WHERE slug = 'pro'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

-- Test: Usuario Pro tiene tasks ilimitadas (-1)
SELECT check_plan_feature(998, 1002, 'tasks') AS result;
-- Esperado: true

-- Test: Usuario Pro tiene transactions ilimitadas (-1)
SELECT check_plan_feature(998, 1002, 'transactions') AS result;
-- Esperado: true

-- Cleanup
DELETE FROM subscriptions WHERE organization_id = 998;
DELETE FROM users WHERE id = 1002;
DELETE FROM organizations WHERE id = 998;
```

**Resultado esperado:** ✅ Todos los tests pasan

---

#### Test 4: `has_finance_module()` por plan

```sql
-- Test Free: NO tiene módulo Finance
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'free'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

SELECT has_finance_module(999, 1001) AS result;
-- Esperado: false

DELETE FROM subscriptions WHERE organization_id = 999 AND user_id = 1001;

-- Test Basic: SÍ tiene módulo Finance
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'basic'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

SELECT has_finance_module(999, 1001) AS result;
-- Esperado: true

DELETE FROM subscriptions WHERE organization_id = 999 AND user_id = 1001;

-- Test Pro: SÍ tiene módulo Finance
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'pro'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

SELECT has_finance_module(999, 1001) AS result;
-- Esperado: true

DELETE FROM subscriptions WHERE organization_id = 999 AND user_id = 1001;

-- Test Premium: SÍ tiene módulo Finance
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'premium'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

SELECT has_finance_module(999, 1001) AS result;
-- Esperado: true
```

**Resultado esperado:** ✅ Free=false, Basic/Pro/Premium=true

---

#### Test 5: `has_ai_memory_module()` por plan

```sql
-- Test Free: NO tiene módulo AI Memory
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'free'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

SELECT has_ai_memory_module(999, 1001) AS result;
-- Esperado: false

DELETE FROM subscriptions WHERE organization_id = 999 AND user_id = 1001;

-- Test Basic: NO tiene módulo AI Memory
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'basic'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

SELECT has_ai_memory_module(999, 1001) AS result;
-- Esperado: false

DELETE FROM subscriptions WHERE organization_id = 999 AND user_id = 1001;

-- Test Pro: SÍ tiene módulo AI Memory
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'pro'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

SELECT has_ai_memory_module(999, 1001) AS result;
-- Esperado: true

DELETE FROM subscriptions WHERE organization_id = 999 AND user_id = 1001;

-- Test Premium: SÍ tiene módulo AI Memory
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (999, 1001, (SELECT id FROM plans WHERE slug = 'premium'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

SELECT has_ai_memory_module(999, 1001) AS result;
-- Esperado: true
```

**Resultado esperado:** ✅ Free/Basic=false, Pro/Premium=true

---

#### Test 6: Usuario sin suscripción activa

```sql
-- Setup: Usuario sin suscripción
INSERT INTO organizations (id, name, slug) VALUES (997, 'No Sub Org', 'no-sub-org');
INSERT INTO users (id, organization_id, email, password_hash, name)
VALUES (1003, 997, 'nosub@test.com', 'hash', 'No Sub User');

-- NO insertar suscripción

-- Test: Usuario sin suscripción NO tiene acceso a nada
SELECT check_plan_feature(997, 1003, 'tasks') AS result;
-- Esperado: false

SELECT has_finance_module(997, 1003) AS result;
-- Esperado: false

SELECT has_ai_memory_module(997, 1003) AS result;
-- Esperado: false

-- Cleanup
DELETE FROM users WHERE id = 1003;
DELETE FROM organizations WHERE id = 997;
```

**Resultado esperado:** ✅ Todos retornan false

---

#### Test 7: Suscripción expirada

```sql
-- Setup: Suscripción con status='expired'
INSERT INTO organizations (id, name, slug) VALUES (996, 'Expired Org', 'expired-org');
INSERT INTO users (id, organization_id, email, password_hash, name)
VALUES (1004, 996, 'expired@test.com', 'hash', 'Expired User');
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (996, 1004, (SELECT id FROM plans WHERE slug = 'pro'), 'expired', 'monthly', NOW() - INTERVAL '2 months', NOW() - INTERVAL '1 month');

-- Test: Usuario con suscripción expirada NO tiene acceso
SELECT has_finance_module(996, 1004) AS result;
-- Esperado: false

SELECT has_ai_memory_module(996, 1004) AS result;
-- Esperado: false

-- Cleanup
DELETE FROM subscriptions WHERE organization_id = 996;
DELETE FROM users WHERE id = 1004;
DELETE FROM organizations WHERE id = 996;
```

**Resultado esperado:** ✅ Suscripción expirada no da acceso

---

## 🧪 TESTS UNITARIOS

### Test Suite: `planValidation.js`

**Archivo:** `tests/unit/planValidation.test.js`

```javascript
const { hasFinanceModule, hasAIMemoryModule, checkPlanFeature, getUserPlan } = require('../../src/utils/planValidation');

jest.mock('../../src/utils/database');
const { getDbConnection } = require('../../src/utils/database');

describe('planValidation - hasFinanceModule', () => {
  let mockDb;

  beforeEach(() => {
    mockDb = { query: jest.fn() };
    getDbConnection.mockResolvedValue(mockDb);
  });

  test('Plan Free: retorna false', async () => {
    mockDb.query.mockResolvedValue({ rows: [{ has_access: false }] });

    const result = await hasFinanceModule(1, 100);

    expect(result).toBe(false);
    expect(mockDb.query).toHaveBeenCalledWith(
      'SELECT has_finance_module($1, $2) AS has_access',
      [1, 100]
    );
  });

  test('Plan Basic: retorna true', async () => {
    mockDb.query.mockResolvedValue({ rows: [{ has_access: true }] });

    const result = await hasFinanceModule(1, 200);

    expect(result).toBe(true);
  });

  test('Plan Pro: retorna true', async () => {
    mockDb.query.mockResolvedValue({ rows: [{ has_access: true }] });

    const result = await hasFinanceModule(1, 300);

    expect(result).toBe(true);
  });

  test('Error de DB: propaga el error', async () => {
    mockDb.query.mockRejectedValue(new Error('DB error'));

    await expect(hasFinanceModule(1, 100)).rejects.toThrow('DB error');
  });
});

describe('planValidation - hasAIMemoryModule', () => {
  let mockDb;

  beforeEach(() => {
    mockDb = { query: jest.fn() };
    getDbConnection.mockResolvedValue(mockDb);
  });

  test('Plan Free: retorna false', async () => {
    mockDb.query.mockResolvedValue({ rows: [{ has_access: false }] });

    const result = await hasAIMemoryModule(1, 100);

    expect(result).toBe(false);
  });

  test('Plan Basic: retorna false', async () => {
    mockDb.query.mockResolvedValue({ rows: [{ has_access: false }] });

    const result = await hasAIMemoryModule(1, 200);

    expect(result).toBe(false);
  });

  test('Plan Pro: retorna true', async () => {
    mockDb.query.mockResolvedValue({ rows: [{ has_access: true }] });

    const result = await hasAIMemoryModule(1, 300);

    expect(result).toBe(true);
  });

  test('Plan Premium: retorna true', async () => {
    mockDb.query.mockResolvedValue({ rows: [{ has_access: true }] });

    const result = await hasAIMemoryModule(1, 400);

    expect(result).toBe(true);
  });
});

describe('planValidation - getUserPlan', () => {
  let mockDb;

  beforeEach(() => {
    mockDb = { query: jest.fn() };
    getDbConnection.mockResolvedValue(mockDb);
  });

  test('Usuario con plan activo: retorna info del plan', async () => {
    mockDb.query.mockResolvedValue({
      rows: [{
        id: 2,
        slug: 'basic',
        name: 'Basic',
        features: {
          tasks: 200,
          passwords: 100,
          finance_module: true,
          ai_memory_module: false
        },
        subscription_status: 'active',
        current_period_end: '2026-10-24T00:00:00Z'
      }]
    });

    const result = await getUserPlan(1, 200);

    expect(result.slug).toBe('basic');
    expect(result.features.finance_module).toBe(true);
    expect(result.subscription_status).toBe('active');
  });

  test('Usuario sin suscripción: retorna plan Free por defecto', async () => {
    mockDb.query.mockResolvedValue({ rows: [] });

    const result = await getUserPlan(1, 999);

    expect(result.slug).toBe('free');
    expect(result.features.finance_module).toBe(false);
    expect(result.subscription_status).toBeNull();
  });
});
```

**Comando para ejecutar:**
```bash
npm test -- tests/unit/planValidation.test.js
```

**Cobertura esperada:** 100%

---

### Test Suite: `errorResponses.js`

**Archivo:** `tests/unit/errorResponses.test.js`

```javascript
const { moduleNotActiveError, planLimitExceededError } = require('../../src/utils/errorResponses');

describe('errorResponses - moduleNotActiveError', () => {
  test('Finance module: genera respuesta 403 correcta', () => {
    const response = moduleNotActiveError('finance', 'uuid-123', 'app-001');

    expect(response.statusCode).toBe(403);

    const body = JSON.parse(response.body);
    expect(body.messageResponse.responseCode).toBe('FINANCE_MODULE_NOT_ACTIVE');
    expect(body.errors[0].errorCode).toBe('MODULE_REQUIRED');
    expect(body.errors[0].errorDetail).toBe('finance');
    expect(body.errors[0].plansWithAccess).toEqual(['Basic', 'Pro', 'Premium']);
  });

  test('AI Memory module: genera respuesta 403 correcta', () => {
    const response = moduleNotActiveError('ai_memory', 'uuid-456', 'app-001');

    expect(response.statusCode).toBe(403);

    const body = JSON.parse(response.body);
    expect(body.messageResponse.responseCode).toBe('AI_MEMORY_MODULE_NOT_ACTIVE');
    expect(body.errors[0].plansWithAccess).toEqual(['Pro', 'Premium']);
  });
});

describe('errorResponses - planLimitExceededError', () => {
  test('Tasks limit: genera respuesta 429 correcta', () => {
    const response = planLimitExceededError('tasks', 200, 200, 'uuid-789', 'app-001');

    expect(response.statusCode).toBe(429);
    expect(response.headers['Retry-After']).toBe('86400');

    const body = JSON.parse(response.body);
    expect(body.messageResponse.responseCode).toBe('PLAN_LIMIT_EXCEEDED');
    expect(body.errors[0].currentUsage).toBe(200);
    expect(body.errors[0].planLimit).toBe(200);
  });
});
```

**Comando para ejecutar:**
```bash
npm test -- tests/unit/errorResponses.test.js
```

---

## 🔗 TESTS DE INTEGRACIÓN

### Test Suite: Lambda Transactions

**Archivo:** `tests/integration/transactions.test.js`

```javascript
const { listTransactions, createTransaction } = require('../../src/lambdas/transactions/index');

// Mock de base de datos con datos reales
const setupTestDb = require('../helpers/setupTestDb');

describe('Lambda Transactions - Module Access', () => {
  beforeAll(async () => {
    await setupTestDb.init();
  });

  afterAll(async () => {
    await setupTestDb.cleanup();
  });

  describe('GET /transactions - Access Control', () => {
    test('Plan Free: retorna 403', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 1,
            userId: 100 // Usuario con plan Free
          }
        },
        headers: {
          'message-uuid': 'test-uuid-1',
          'request-app-id': 'test-app'
        },
        queryStringParameters: {}
      };

      const response = await listTransactions(event);

      expect(response.statusCode).toBe(403);
      const body = JSON.parse(response.body);
      expect(body.messageResponse.responseCode).toBe('FINANCE_MODULE_NOT_ACTIVE');
    });

    test('Plan Basic: retorna 200 con transacciones', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 2,
            userId: 200 // Usuario con plan Basic
          }
        },
        headers: {
          'message-uuid': 'test-uuid-2',
          'request-app-id': 'test-app'
        },
        queryStringParameters: {}
      };

      const response = await listTransactions(event);

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.data).toHaveProperty('transactions');
      expect(Array.isArray(body.data.transactions)).toBe(true);
    });

    test('Plan Pro: retorna 200 con transacciones', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 3,
            userId: 300 // Usuario con plan Pro
          }
        },
        headers: {
          'message-uuid': 'test-uuid-3',
          'request-app-id': 'test-app'
        },
        queryStringParameters: {}
      };

      const response = await listTransactions(event);

      expect(response.statusCode).toBe(200);
    });
  });

  describe('POST /transactions - Access Control', () => {
    test('Plan Free: no puede crear transacción', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 1,
            userId: 100
          }
        },
        headers: {
          'message-uuid': 'test-uuid-4',
          'request-app-id': 'test-app'
        },
        body: JSON.stringify({
          type: 'expense',
          amount: 50000,
          description: 'Test transaction',
          transaction_date: '2026-09-24T10:00:00Z'
        })
      };

      const response = await createTransaction(event);

      expect(response.statusCode).toBe(403);
    });

    test('Plan Basic: puede crear transacción', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 2,
            userId: 200
          }
        },
        headers: {
          'message-uuid': 'test-uuid-5',
          'request-app-id': 'test-app'
        },
        body: JSON.stringify({
          type: 'expense',
          amount: 50000,
          description: 'Test transaction',
          transaction_date: '2026-09-24T10:00:00Z',
          category_id: 1
        })
      };

      const response = await createTransaction(event);

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.data.transaction).toHaveProperty('id');
    });
  });
});
```

---

### Test Suite: Lambda AI Memory

**Archivo:** `tests/integration/aiMemory.test.js`

```javascript
const { createMemory, listMemories } = require('../../src/lambdas/ai-memory/index');
const setupTestDb = require('../helpers/setupTestDb');

describe('Lambda AI Memory - Module Access', () => {
  beforeAll(async () => {
    await setupTestDb.init();
  });

  afterAll(async () => {
    await setupTestDb.cleanup();
  });

  describe('POST /memories - Access Control', () => {
    test('Plan Free: retorna 403', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 1,
            userId: 100
          }
        },
        headers: {
          'message-uuid': 'test-uuid-10',
          'request-app-id': 'test-app'
        },
        body: JSON.stringify({
          memory_type: 'conversation',
          title: 'Test memory',
          description: 'Test description'
        })
      };

      const response = await createMemory(event);

      expect(response.statusCode).toBe(403);
      const body = JSON.parse(response.body);
      expect(body.messageResponse.responseCode).toBe('AI_MEMORY_MODULE_NOT_ACTIVE');
    });

    test('Plan Basic: retorna 403', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 2,
            userId: 200
          }
        },
        headers: {
          'message-uuid': 'test-uuid-11',
          'request-app-id': 'test-app'
        },
        body: JSON.stringify({
          memory_type: 'conversation',
          title: 'Test memory'
        })
      };

      const response = await createMemory(event);

      expect(response.statusCode).toBe(403);
    });

    test('Plan Pro: puede crear memoria', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 3,
            userId: 300
          }
        },
        headers: {
          'message-uuid': 'test-uuid-12',
          'request-app-id': 'test-app'
        },
        body: JSON.stringify({
          memory_type: 'conversation',
          title: 'Test memory Pro',
          description: 'Test'
        })
      };

      const response = await createMemory(event);

      expect(response.statusCode).toBe(201);
    });

    test('Plan Premium: puede crear memoria', async () => {
      const event = {
        requestContext: {
          authorizer: {
            organizationId: 4,
            userId: 400
          }
        },
        headers: {
          'message-uuid': 'test-uuid-13',
          'request-app-id': 'test-app'
        },
        body: JSON.stringify({
          memory_type: 'photo',
          title: 'Test photo Premium'
        })
      };

      const response = await createMemory(event);

      expect(response.statusCode).toBe(201);
    });
  });
});
```

---

## 🌐 TESTS END-TO-END

### Test E2E: Upgrade de Plan

**Escenario:** Usuario Free actualiza a Basic y obtiene acceso a Finanzas

```javascript
describe('E2E - Plan Upgrade Flow', () => {
  test('Usuario Free → Basic: obtiene acceso a finanzas', async () => {
    // 1. Usuario con plan Free intenta acceder a transacciones
    let response = await apiClient.get('/transactions', {
      headers: { Authorization: 'Bearer free-user-token' }
    });
    expect(response.status).toBe(403);

    // 2. Usuario actualiza a plan Basic
    response = await apiClient.post('/subscriptions/checkout', {
      plan_id: 'basic',
      billing_cycle: 'monthly'
    }, {
      headers: { Authorization: 'Bearer free-user-token' }
    });
    expect(response.status).toBe(201);

    // Simular webhook de Wompi confirmando pago
    await webhookSimulator.confirmPayment(response.data.transaction_reference);

    // 3. Usuario ahora puede acceder a transacciones
    response = await apiClient.get('/transactions', {
      headers: { Authorization: 'Bearer free-user-token' } // Token se refresca
    });
    expect(response.status).toBe(200);
    expect(response.data.data.transactions).toBeDefined();
  });
});
```

---

## 🔄 TESTS DE REGRESIÓN

### Matriz de Compatibilidad

| Plan | Tareas | Contraseñas | Finanzas | AI Memory | Esperado |
|------|--------|-------------|----------|-----------|----------|
| Free | ✅ GET | ✅ GET | ❌ 403 | ❌ 403 | PASS |
| Basic | ✅ GET | ✅ GET | ✅ GET | ❌ 403 | PASS |
| Pro | ✅ GET | ✅ GET | ✅ GET | ✅ GET | PASS |
| Premium | ✅ GET | ✅ GET | ✅ GET | ✅ GET | PASS |

**Script de regresión:**

```bash
#!/bin/bash
# tests/regression/plan-access-matrix.sh

# Free user
echo "Testing Free user..."
curl -H "Authorization: Bearer $FREE_TOKEN" https://api.temis.app/v1/tasks | jq '.headers.httpStatusCode' # Esperado: 200
curl -H "Authorization: Bearer $FREE_TOKEN" https://api.temis.app/v1/passwords | jq '.headers.httpStatusCode' # Esperado: 200
curl -H "Authorization: Bearer $FREE_TOKEN" https://api.temis.app/v1/transactions | jq '.headers.httpStatusCode' # Esperado: 403
curl -H "Authorization: Bearer $FREE_TOKEN" https://api.temis.app/v1/memories | jq '.headers.httpStatusCode' # Esperado: 403

# Basic user
echo "Testing Basic user..."
curl -H "Authorization: Bearer $BASIC_TOKEN" https://api.temis.app/v1/transactions | jq '.headers.httpStatusCode' # Esperado: 200
curl -H "Authorization: Bearer $BASIC_TOKEN" https://api.temis.app/v1/memories | jq '.headers.httpStatusCode' # Esperado: 403

# Pro user
echo "Testing Pro user..."
curl -H "Authorization: Bearer $PRO_TOKEN" https://api.temis.app/v1/transactions | jq '.headers.httpStatusCode' # Esperado: 200
curl -H "Authorization: Bearer $PRO_TOKEN" https://api.temis.app/v1/memories | jq '.headers.httpStatusCode' # Esperado: 200
```

---

## ⚠️ CASOS EDGE

### Edge Case 1: Múltiples suscripciones activas

**Escenario:** Usuario tiene 2 suscripciones activas por error

```sql
-- Setup
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES
  (1, 100, (SELECT id FROM plans WHERE slug = 'basic'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month'),
  (1, 100, (SELECT id FROM plans WHERE slug = 'pro'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

-- Test: Debe tomar la más reciente (Pro)
SELECT has_ai_memory_module(1, 100) AS result;
-- Esperado: true (porque Pro tiene AI Memory)
```

**Resultado esperado:** ✅ Función usa `ORDER BY created_at DESC LIMIT 1`

---

### Edge Case 2: Suscripción cancelada pero aún en período activo

**Escenario:** Usuario canceló pero subscription.current_period_end aún no pasó

```sql
-- Setup
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end, cancelled_at, cancel_at_period_end)
VALUES (1, 100, (SELECT id FROM plans WHERE slug = 'pro'), 'active', 'monthly', NOW(), NOW() + INTERVAL '15 days', NOW(), true);

-- Test: Usuario aún tiene acceso hasta current_period_end
SELECT has_ai_memory_module(1, 100) AS result;
-- Esperado: true (aún está 'active')
```

**Resultado esperado:** ✅ Usuario tiene acceso hasta que expire

---

### Edge Case 3: Cambio de plan en medio del período

**Escenario:** Usuario cambia de Basic → Pro hoy

```sql
-- Cancelar suscripción anterior
UPDATE subscriptions SET status = 'cancelled', cancelled_at = NOW()
WHERE organization_id = 1 AND user_id = 100;

-- Crear nueva suscripción
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
VALUES (1, 100, (SELECT id FROM plans WHERE slug = 'pro'), 'active', 'monthly', NOW(), NOW() + INTERVAL '1 month');

-- Test: Usuario inmediatamente tiene acceso a AI Memory
SELECT has_ai_memory_module(1, 100) AS result;
-- Esperado: true
```

**Resultado esperado:** ✅ Acceso inmediato al cambiar de plan

---

## 📊 REPORTE DE COBERTURA

### Comando para generar reporte:

```bash
npm test -- --coverage --coverageDirectory=coverage
```

### Métricas esperadas:

| Componente | Statements | Branches | Functions | Lines |
|------------|------------|----------|-----------|-------|
| `planValidation.js` | 100% | 100% | 100% | 100% |
| `errorResponses.js` | 100% | 100% | 100% | 100% |
| `transactions/index.js` | 95%+ | 90%+ | 100% | 95%+ |
| `ai-memory/index.js` | 95%+ | 90%+ | 100% | 95%+ |

---

## ✅ CHECKLIST DE TESTING

### Pre-deployment
- [ ] Ejecutar todos los tests de base de datos
- [ ] Ejecutar tests unitarios con coverage 100%
- [ ] Ejecutar tests de integración
- [ ] Verificar matriz de compatibilidad de planes
- [ ] Probar casos edge manualmente
- [ ] Ejecutar tests E2E en staging

### Post-deployment
- [ ] Smoke test en producción (1 request por endpoint)
- [ ] Monitorear logs de CloudWatch por 1 hora
- [ ] Verificar métricas de errores 403 en CloudWatch
- [ ] Confirmar que usuarios existentes mantienen acceso correcto

---

## 📚 REFERENCIAS

- **Código de lambdas:** `/docs/implementation/LAMBDA-MIDDLEWARE-VALIDATION.md`
- **Modelo de planes:** `/docs/architecture/MODELO-PLANES-Y-LIMITES.md`
- **Schema de DB:** `/docs/database/DATABASE-SCHEMA-COMPLETE.sql`

---

**Última actualización:** 2026-09-24
**Versión:** 1.0.0
**Estado:** ✅ LISTO PARA EJECUCIÓN
