# MODELO DE PLANES Y LÍMITES - TEMIS

**Fecha:** 2026-09-24
**Versión:** 2.0.0
**Autor:** Equipo Backend TEMIS

---

## 📊 RESUMEN EJECUTIVO

TEMIS utiliza un **modelo de planes por niveles** con acceso progresivo a módulos funcionales:

- **Módulo Base**: Tareas + Contraseñas (disponible en todos los planes)
- **Módulo Finanzas**: Transacciones + Presupuestos + Cuentas (Basic, Pro, Premium)
- **Módulo AI Memory**: Segunda Memoria Digital con IA (Pro, Premium)

---

## 💰 PLANES DISPONIBLES

### Free - Gratis

**Precio:** $0.00/mes

**Módulos incluidos:**
- ✅ Tareas: 50/mes
- ✅ Contraseñas: 10 almacenadas
- ❌ Módulo Finanzas: NO disponible
- ❌ Módulo AI Memory: NO disponible

**Uso recomendado:** Prueba del producto, usuarios individuales con necesidades básicas

---

### Basic - $9.99/mes

**Precio:**
- Mensual: $9.99
- Anual: $99.90 (ahorro 17%)

**Módulos incluidos:**
- ✅ Tareas: 200/mes
- ✅ Contraseñas: 100 almacenadas
- ✅ **Módulo Finanzas** con límites:
  - Transacciones: 1000/mes
  - Presupuestos: 5
  - Cuentas bancarias: 3
- ❌ Módulo AI Memory: NO disponible
- ✅ Cuota IA: 20 llamadas/mes

**Uso recomendado:** Usuarios individuales que necesitan control financiero básico

---

### Pro - $14.99/mes

**Precio:**
- Mensual: $14.99
- Anual: $149.90 (ahorro 17%)

**Módulos incluidos:**
- ✅ Tareas: **Ilimitadas**
- ✅ Contraseñas: **Ilimitadas**
- ✅ **Módulo Finanzas** ilimitado:
  - Transacciones: **Ilimitadas**
  - Presupuestos: **Ilimitados**
  - Cuentas bancarias: **Ilimitadas**
- ✅ **Módulo AI Memory**:
  - Memorias: **Ilimitadas**
  - Almacenamiento: **20 GB**
  - Búsquedas IA: 100/mes
- ✅ Cuota IA: 100 llamadas/mes

**Uso recomendado:** Profesionales, familias, usuarios power con necesidades avanzadas

---

### Premium - $19.99/mes

**Precio:**
- Mensual: $19.99
- Anual: $199.90 (ahorro 17%)

**Módulos incluidos:**
- ✅ Tareas: **Ilimitadas**
- ✅ Contraseñas: **Ilimitadas**
- ✅ **Módulo Finanzas** ilimitado:
  - Transacciones: **Ilimitadas**
  - Presupuestos: **Ilimitados**
  - Cuentas bancarias: **Ilimitadas**
- ✅ **Módulo AI Memory** mejorado:
  - Memorias: **Ilimitadas**
  - Almacenamiento: **100 GB**
  - Búsquedas IA: 500/mes
- ✅ Cuota IA: 500 llamadas/mes
- ✅ Soporte prioritario

**Uso recomendado:** Empresas pequeñas, usuarios con alto volumen de datos

---

## 📋 TABLA COMPARATIVA COMPLETA

| Característica | Free | Basic | Pro | Premium |
|----------------|------|-------|-----|---------|
| **Precio mensual** | $0 | $9.99 | $14.99 | $19.99 |
| **Precio anual** | $0 | $99.90 | $149.90 | $199.90 |
| | | | | |
| **MÓDULO BASE** | | | | |
| Tareas/mes | 50 | 200 | ∞ | ∞ |
| Contraseñas | 10 | 100 | ∞ | ∞ |
| Categorías personalizadas | ❌ | ✅ | ✅ | ✅ |
| Recordatorios | ✅ | ✅ | ✅ | ✅ |
| Subtareas | ❌ | ✅ | ✅ | ✅ |
| | | | | |
| **MÓDULO FINANZAS** | ❌ | ✅ | ✅ | ✅ |
| Transacciones/mes | 0 | 1000 | ∞ | ∞ |
| Presupuestos | 0 | 5 | ∞ | ∞ |
| Cuentas bancarias | 0 | 3 | ∞ | ∞ |
| Dashboard financiero | ❌ | ✅ | ✅ | ✅ |
| Reportes avanzados | ❌ | ❌ | ✅ | ✅ |
| Entrada por voz | ❌ | ❌ | ✅ | ✅ |
| | | | | |
| **MÓDULO AI MEMORY** | ❌ | ❌ | ✅ | ✅ |
| Memorias/mes | 0 | 0 | ∞ | ∞ |
| Almacenamiento | 0 GB | 0 GB | 20 GB | 100 GB |
| Búsquedas IA/mes | 0 | 0 | 100 | 500 |
| OCR (fotos/documentos) | ❌ | ❌ | ✅ | ✅ |
| Transcripción audio | ❌ | ❌ | ✅ | ✅ |
| Búsqueda semántica | ❌ | ❌ | ✅ | ✅ |
| Email forwarding | ❌ | ❌ | ✅ | ✅ |
| | | | | |
| **IA GENERAL** | | | | |
| Cuota IA mensual | 0 | 20 | 100 | 500 |
| Asistente inteligente | ❌ | ✅ | ✅ | ✅ |
| Insights automáticos | ❌ | ❌ | ✅ | ✅ |
| | | | | |
| **SOPORTE** | | | | |
| Email support | ✅ | ✅ | ✅ | ✅ |
| Tiempo de respuesta | 48h | 24h | 12h | 4h |
| Soporte prioritario | ❌ | ❌ | ❌ | ✅ |
| | | | | |
| **PERÍODO DE PRUEBA** | N/A | 14 días | 14 días | 14 días |

**Leyenda:** ∞ = Ilimitado, ❌ = No disponible, ✅ = Disponible

---

## 🔒 VALIDACIÓN DE ACCESO A MÓDULOS

### Funciones SQL

```sql
-- Verificar si usuario tiene acceso a módulo de Finanzas
SELECT has_finance_module(organization_id, user_id);
-- Retorna: true (Basic, Pro, Premium) | false (Free)

-- Verificar si usuario tiene acceso a módulo de AI Memory
SELECT has_ai_memory_module(organization_id, user_id);
-- Retorna: true (Pro, Premium) | false (Free, Basic)

-- Verificar feature específico (genérico)
SELECT check_plan_feature(organization_id, user_id, 'transactions');
-- Retorna: true si tiene acceso, false si no
```

### Validación en Lambdas

#### Lambda de Transacciones (Finance)

```javascript
// Middleware: Validar acceso al módulo de Finanzas
async function validateFinanceModuleAccess(event) {
  const { organizationId, userId } = event.requestContext;

  const result = await db.query(
    'SELECT has_finance_module($1, $2) AS has_access',
    [organizationId, userId]
  );

  if (!result.rows[0].has_access) {
    return {
      statusCode: 403,
      body: JSON.stringify({
        messageResponse: {
          responseCode: 'FINANCE_MODULE_NOT_ACTIVE',
          responseMessage: 'Módulo de Finanzas no activo',
          responseDetail: 'Tu plan actual no incluye el módulo de Finanzas. Actualiza a Basic, Pro o Premium para acceder.'
        },
        errors: [{
          errorCode: 'MODULE_REQUIRED',
          errorDetail: 'finance',
          upgradeUrl: '/subscriptions/plans'
        }]
      })
    };
  }

  return null; // Continuar con la lógica normal
}

// Usar en todos los endpoints de transactions
exports.handler = async (event) => {
  const accessError = await validateFinanceModuleAccess(event);
  if (accessError) return accessError;

  // Lógica del endpoint...
};
```

#### Lambda de AI Memory

```javascript
// Middleware: Validar acceso al módulo de AI Memory
async function validateAIMemoryModuleAccess(event) {
  const { organizationId, userId } = event.requestContext;

  const result = await db.query(
    'SELECT has_ai_memory_module($1, $2) AS has_access',
    [organizationId, userId]
  );

  if (!result.rows[0].has_access) {
    return {
      statusCode: 403,
      body: JSON.stringify({
        messageResponse: {
          responseCode: 'AI_MEMORY_MODULE_NOT_ACTIVE',
          responseMessage: 'Módulo de AI Memory no activo',
          responseDetail: 'Tu plan actual no incluye el módulo de AI Memory. Actualiza a Pro o Premium para acceder.'
        },
        errors: [{
          errorCode: 'MODULE_REQUIRED',
          errorDetail: 'ai_memory',
          upgradeUrl: '/subscriptions/plans'
        }]
      })
    };
  }

  return null;
}
```

### Validación en Auth (JWT)

```javascript
// Lambda Auth: Incluir información de módulos en JWT
async function generateJWT(user, organization, subscription) {
  const plan = await db.query(
    'SELECT features FROM plans WHERE id = $1',
    [subscription.plan_id]
  );

  const payload = {
    userId: user.id,
    organizationId: organization.id,
    email: user.email,
    role: user.role,
    plan: {
      slug: plan.slug,
      financeModule: plan.features.finance_module,
      aiMemoryModule: plan.features.ai_memory_module
    }
  };

  return jwt.sign(payload, privateKey, { algorithm: 'RS256', expiresIn: '15m' });
}

// El frontend puede leer el JWT y mostrar/ocultar módulos según acceso
```

---

## 🚫 RESPUESTAS DE ERROR

### 403 Forbidden - Módulo de Finanzas no activo

**Endpoint afectados:**
- `POST /transactions`
- `GET /transactions`
- `PUT /transactions/{id}`
- `DELETE /transactions/{id}`
- `POST /budgets`
- `GET /budgets`
- Todos los endpoints de `/accounts`

**Respuesta:**
```json
{
  "headers": {
    "httpStatusCode": 403,
    "httpStatusDesc": "Forbidden",
    "messageUuid": "550e8400-e29b-41d4-a716-446655440000",
    "requestDatetime": "2026-09-24T10:30:00Z",
    "requestAppId": "app-001"
  },
  "messageResponse": {
    "responseCode": "FINANCE_MODULE_NOT_ACTIVE",
    "responseMessage": "Módulo de Finanzas no activo",
    "responseDetail": "Tu plan actual no incluye el módulo de Finanzas. Actualiza a Basic, Pro o Premium para acceder."
  },
  "errors": [
    {
      "errorCode": "MODULE_REQUIRED",
      "errorDetail": "finance",
      "upgradeUrl": "/subscriptions/plans"
    }
  ]
}
```

### 403 Forbidden - Módulo de AI Memory no activo

**Endpoints afectados:**
- `POST /memories`
- `GET /memories`
- `POST /memories/search`
- Todos los endpoints de AI Memory

**Respuesta:**
```json
{
  "headers": {
    "httpStatusCode": 403,
    "httpStatusDesc": "Forbidden",
    "messageUuid": "550e8400-e29b-41d4-a716-446655440000",
    "requestDatetime": "2026-09-24T10:30:00Z",
    "requestAppId": "app-001"
  },
  "messageResponse": {
    "responseCode": "AI_MEMORY_MODULE_NOT_ACTIVE",
    "responseMessage": "Módulo de AI Memory no activo",
    "responseDetail": "Tu plan actual no incluye el módulo de AI Memory. Actualiza a Pro o Premium para acceder."
  },
  "errors": [
    {
      "errorCode": "MODULE_REQUIRED",
      "errorDetail": "ai_memory",
      "upgradeUrl": "/subscriptions/plans"
    }
  ]
}
```

### 429 Too Many Requests - Límite de plan excedido

**Ejemplo: Usuario en plan Basic intenta crear tarea #201 del mes**

```json
{
  "headers": {
    "httpStatusCode": 429,
    "httpStatusDesc": "Too Many Requests",
    "messageUuid": "550e8400-e29b-41d4-a716-446655440000",
    "requestDatetime": "2026-09-24T10:30:00Z",
    "requestAppId": "app-001"
  },
  "messageResponse": {
    "responseCode": "PLAN_LIMIT_EXCEEDED",
    "responseMessage": "Límite mensual de tareas excedido",
    "responseDetail": "Has alcanzado el límite de 200 tareas/mes de tu plan Basic. Actualiza a Pro para tareas ilimitadas."
  },
  "errors": [
    {
      "errorCode": "QUOTA_EXCEEDED",
      "errorDetail": "tasks",
      "currentUsage": 200,
      "planLimit": 200,
      "upgradeUrl": "/subscriptions/plans"
    }
  ]
}
```

---

## 📊 FEATURES EN BASE DE DATOS

### Estructura JSONB en tabla `plans`

```sql
-- Plan Free
{
  "tasks": 50,
  "passwords": 10,
  "transactions": 0,
  "budgets": 0,
  "accounts": 0,
  "memories": 0,
  "storage_gb": 0,
  "ai_quota": 0,
  "finance_module": false,
  "ai_memory_module": false
}

-- Plan Basic
{
  "tasks": 200,
  "passwords": 100,
  "transactions": 1000,
  "budgets": 5,
  "accounts": 3,
  "memories": 0,
  "storage_gb": 0,
  "ai_quota": 20,
  "finance_module": true,
  "ai_memory_module": false
}

-- Plan Pro
{
  "tasks": -1,
  "passwords": -1,
  "transactions": -1,
  "budgets": -1,
  "accounts": -1,
  "memories": -1,
  "storage_gb": 20,
  "ai_quota": 100,
  "finance_module": true,
  "ai_memory_module": true
}

-- Plan Premium
{
  "tasks": -1,
  "passwords": -1,
  "transactions": -1,
  "budgets": -1,
  "accounts": -1,
  "memories": -1,
  "storage_gb": 100,
  "ai_quota": 500,
  "finance_module": true,
  "ai_memory_module": true
}
```

**Leyenda:**
- `-1` = Ilimitado
- `0` = Sin acceso
- `N` (número positivo) = Límite específico
- `true/false` = Acceso sí/no a módulo

---

## 🎯 ESTRATEGIA DE UPGRADE

### Flujo de Upgrade en Frontend

1. **Usuario intenta usar feature bloqueada**
   - Ejemplo: Usuario Free intenta crear transacción
   - Backend retorna 403 Forbidden

2. **Frontend detecta error 403**
   - Lee `errorCode: "MODULE_REQUIRED"`
   - Lee `errorDetail: "finance"`
   - Lee `upgradeUrl: "/subscriptions/plans"`

3. **Frontend muestra modal de upgrade**
   ```
   🔒 Módulo de Finanzas no disponible

   Para acceder a transacciones, presupuestos y cuentas bancarias,
   actualiza tu plan a:

   ✅ Basic ($9.99/mes) - 1000 transacciones/mes
   ✅ Pro ($14.99/mes) - Ilimitado
   ✅ Premium ($19.99/mes) - Ilimitado

   [Ver planes] [Cancelar]
   ```

4. **Usuario selecciona plan**
   - Redirige a `/subscriptions/checkout?plan=basic`
   - Proceso de pago con Wompi

5. **Tras pago exitoso**
   - Webhook actualiza suscripción
   - Usuario puede usar módulo inmediatamente

---

## 📱 UX: Mostrar/Ocultar Módulos

### En Frontend (React Native)

```typescript
// Leer JWT del usuario
const decodedToken = jwtDecode(userToken);
const { plan } = decodedToken;

// Mostrar módulos según plan
const showFinanceModule = plan.financeModule; // true en Basic, Pro, Premium
const showAIMemoryModule = plan.aiMemoryModule; // true en Pro, Premium

// Renderizar tabs condicionales
<Tab.Navigator>
  <Tab.Screen name="Tasks" component={TasksScreen} />
  <Tab.Screen name="Passwords" component={PasswordsScreen} />

  {showFinanceModule && (
    <Tab.Screen name="Finance" component={FinanceScreen} />
  )}

  {showAIMemoryModule && (
    <Tab.Screen name="AI Memory" component={AIMemoryScreen} />
  )}
</Tab.Navigator>
```

---

## 🔄 MIGRACIÓN DE USUARIOS EXISTENTES

Si ya existen usuarios con planes antiguos, usar este script SQL:

```sql
-- Los planes ya están correctamente definidos
-- No se requiere migración de datos

-- Verificar que todos los usuarios tengan suscripción
SELECT u.id, u.email, s.id AS subscription_id, pl.slug AS plan_slug
FROM users u
LEFT JOIN subscriptions s ON s.user_id = u.id AND s.status IN ('trial', 'active')
LEFT JOIN plans pl ON s.plan_id = pl.id
WHERE u.is_active = true;

-- Usuarios sin suscripción → Asignar plan Free
INSERT INTO subscriptions (organization_id, user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
SELECT
    u.organization_id,
    u.id,
    (SELECT id FROM plans WHERE slug = 'free'),
    'active',
    'monthly',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '1 year'
FROM users u
WHERE u.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM subscriptions s
    WHERE s.user_id = u.id
    AND s.status IN ('trial', 'active')
  );
```

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Base de Datos
- [x] Tabla `plans` con features correctos
- [x] Función `check_plan_feature()`
- [x] Función `has_finance_module()`
- [x] Función `has_ai_memory_module()`
- [x] Comentarios actualizados

### Lambdas
- [x] Lambda Subscriptions: Contrato actualizado con features correctos
- [x] Lambda Transactions: Documentación de acceso restringido + error 403
- [x] Lambda Budgets: Documentación de acceso restringido
- [x] Lambda AI Memory: Documentación de acceso restringido + error 403
- [ ] Implementar middleware de validación en cada lambda
- [ ] Tests unitarios de validación de módulos

### Contratos YAML
- [x] TEMIS_CONTRATO_SUBSCRIPTIONS_V1.0.yaml: Features actualizados
- [x] TEMIS_CONTRATO_TRANSACTIONS_V1.0.yaml: Restricción documentada
- [x] TEMIS_CONTRATO_BUDGETS_V1.0.yaml: Restricción documentada
- [x] TEMIS_CONTRATO_AI_MEMORY_V1.0.yaml: Restricción documentada

### Frontend
- [ ] Leer `plan.financeModule` y `plan.aiMemoryModule` del JWT
- [ ] Mostrar/ocultar tabs según módulos activos
- [ ] Modal de upgrade cuando se intenta acceder a módulo bloqueado
- [ ] Pantalla de comparación de planes
- [ ] Flow de checkout con Wompi

---

## 📖 REFERENCIAS

- **Base de datos:** `/docs/database/DATABASE-SCHEMA-COMPLETE.sql`
- **Contratos API:** `/contratos/TEMIS_CONTRATO_*.yaml`
- **Documentación Wompi:** https://docs.wompi.co/
- **Módulo AI Memory:** `/docs/architecture/03-MODULES-FEATURES.md`

---

**Última actualización:** 2026-09-24
**Versión:** 2.0.0
**Estado:** ✅ LISTO PARA IMPLEMENTACIÓN
