# 🔍 ANÁLISIS DETALLADO DE GAPS - DATABASE SCHEMA

**Fecha**: 2026-09-24
**Archivo Analizado**: `docs/database/DATABASE-SCHEMA.md` (2047 líneas)
**Objetivo**: Identificar TODOS los gaps uno por uno para completar el schema al 100%

---

## 📊 RESUMEN EJECUTIVO

### Estado Actual

| Aspecto | Cantidad | Estado |
|---------|----------|--------|
| **Tablas Existentes** | 22 | ✅ Documentadas |
| **Tablas Faltantes** | 4 | ⚠️ Identificadas |
| **Extensiones** | 4/4 | ✅ Completas |
| **Funciones SQL** | 7 | ✅ Completas |
| **RLS Policies** | 22/22 | ✅ Completas |
| **Triggers** | 14 | ✅ Completos |
| **Vistas** | 3 | ✅ Completas |

### Completitud Total

```
Tablas:       22/26 = 84.6%
Schema Total: ~95%
```

---

## ❌ GAPS IDENTIFICADOS (4 TABLAS FALTANTES)

### GAP #1: Tabla `accounts` - CRÍTICO 🔴

**Prioridad**: CRÍTICA
**Módulo Afectado**: Finanzas Personales
**Impacto**: Sin esta tabla el módulo de finanzas está INCOMPLETO

#### ¿Qué es?
Tabla para gestionar cuentas bancarias, tarjetas de crédito, efectivo y otros métodos de almacenamiento de dinero.

#### ¿Por qué falta?
La tabla `transactions` actualmente **NO tiene** el campo `account_id`, por lo que no se puede asociar una transacción con una cuenta específica.

#### ¿Dónde debería estar?
- **Ubicación en schema**: Después de la sección "8. Módulo: Finanzas Personales"
- **Orden recomendado**: Antes de la tabla `transactions`

#### ¿Qué endpoints están bloqueados?

| Endpoint | Método | Afectado |
|----------|--------|----------|
| GET /accounts | GET | ❌ No funciona |
| POST /accounts | POST | ❌ No funciona |
| GET /accounts/{id} | GET | ❌ No funciona |
| PUT /accounts/{id} | PUT | ❌ No funciona |
| DELETE /accounts/{id} | DELETE | ❌ No funciona |
| GET /accounts/{id}/balance | GET | ❌ No funciona |
| GET /accounts/dashboard | GET | ❌ No funciona |

**Total**: 7+ endpoints bloqueados

#### ¿Qué funcionalidades no se pueden hacer?

1. ❌ Crear cuentas bancarias (ej: "Cuenta Bancolombia", "Efectivo")
2. ❌ Ver balance por cuenta
3. ❌ Asociar transacciones a cuentas específicas
4. ❌ Dashboard de patrimonio total
5. ❌ Transferencias entre cuentas
6. ❌ Filtrar transacciones por cuenta
7. ❌ Tracking de balances en tiempo real

#### Schema Requerido

```sql
CREATE TABLE accounts (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Información básica
    name                    VARCHAR(255) NOT NULL,
    type                    VARCHAR(50) NOT NULL,
                            CHECK (type IN ('bank', 'cash', 'credit_card', 'investment', 'savings', 'other')),

    -- Moneda y balances
    currency                VARCHAR(3) DEFAULT 'USD',
    initial_balance         DECIMAL(15,2) DEFAULT 0.00,
    current_balance         DECIMAL(15,2) DEFAULT 0.00,

    -- Detalles bancarios (opcional)
    bank_name               VARCHAR(255),
    account_number_last4    VARCHAR(4),

    -- Personalización
    color                   VARCHAR(7) DEFAULT '#3B82F6',
    icon                    VARCHAR(50) DEFAULT '💳',

    -- Estados
    is_active               BOOLEAN DEFAULT true,
    is_included_in_total    BOOLEAN DEFAULT true,

    -- Auditoría
    metadata                JSONB DEFAULT '{}',
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMP WITH TIME ZONE
);

-- Índices necesarios
CREATE INDEX idx_accounts_organization_user ON accounts(organization_id, user_id);
CREATE INDEX idx_accounts_type ON accounts(type);
CREATE INDEX idx_accounts_is_active ON accounts(is_active);
CREATE INDEX idx_accounts_currency ON accounts(currency);
CREATE INDEX idx_accounts_deleted_at ON accounts(deleted_at) WHERE deleted_at IS NULL;

-- RLS Policy
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY accounts_isolation_policy ON accounts
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );

-- Trigger
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### Cambios Adicionales Requeridos

**1. Añadir campo a `transactions`:**
```sql
ALTER TABLE transactions
ADD COLUMN account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

CREATE INDEX idx_transactions_account_id ON transactions(account_id);
```

**2. Función para actualizar balance:**
```sql
CREATE OR REPLACE FUNCTION update_account_balance(
    p_account_id UUID,
    p_amount DECIMAL(15,2),
    p_operation VARCHAR(10)  -- 'add' or 'subtract'
) RETURNS DECIMAL(15,2) AS $$
-- [Ver MIGRATION-002 para código completo]
$$ LANGUAGE plpgsql;
```

#### Datos Iniciales

```sql
-- Crear cuenta "Efectivo" para usuarios existentes
INSERT INTO accounts (organization_id, user_id, name, type, currency, color, icon)
SELECT
    u.organization_id,
    u.id,
    'Efectivo',
    'cash',
    'COP',
    '#10B981',
    '💵'
FROM users u
WHERE u.is_active = true AND u.deleted_at IS NULL;
```

---

### GAP #2: Tabla `voice_inputs` - ALTA PRIORIDAD 🟡

**Prioridad**: ALTA
**Módulo Afectado**: Entrada por Voz
**Impacto**: Sin esta tabla el historial de voz y retry no funcionan

#### ¿Qué es?
Tabla para almacenar el registro de todas las entradas por voz procesadas (audios transcriptos e interpretados por IA).

#### ¿Por qué falta?
No se puede hacer tracking de:
- Audios procesados
- Transcripciones realizadas
- Uso de cuota de IA por voz
- Reintentos de procesamiento fallido
- Auditoría de costos

#### ¿Dónde debería estar?
- **Ubicación en schema**: En sección "9. Módulo: Asistente IA" o crear nueva sección "Módulo: Voice Input"
- **Orden recomendado**: Después de `ai_usage`

#### ¿Qué endpoints están bloqueados?

| Endpoint | Método | Afectado |
|----------|--------|----------|
| GET /voice/history | GET | ❌ No funciona |
| POST /voice/retry/{voiceInputId} | POST | ❌ No funciona |
| GET /voice/quota | GET | ⚠️ Parcialmente (falta detalle) |

**Total**: 2 endpoints completamente bloqueados

#### ¿Qué funcionalidades no se pueden hacer?

1. ❌ Ver historial de audios procesados
2. ❌ Reintentar procesamiento de audio fallido
3. ❌ Auditoría de cuántos audios procesó cada usuario
4. ❌ Ver transcripción original de un audio
5. ❌ Ver interpretación de IA de un audio
6. ❌ Tracking de costos de IA por voz
7. ❌ Debugging de errores de procesamiento

#### Schema Requerido

```sql
CREATE TABLE voice_inputs (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Audio original
    audio_s3_key            VARCHAR(500) NOT NULL,
    audio_s3_bucket         VARCHAR(255),
    audio_duration_sec      INTEGER,
    audio_format            VARCHAR(20),  -- 'mp3', 'wav', 'm4a', 'ogg'
    audio_size_bytes        BIGINT,

    -- Procesamiento
    status                  VARCHAR(50) DEFAULT 'processing',
                            CHECK (status IN ('processing', 'completed', 'failed')),

    -- Transcripción (Amazon Transcribe)
    transcription_text      TEXT,
    transcription_language  VARCHAR(10),  -- 'es-ES', 'en-US'
    transcription_confidence DECIMAL(5,2),  -- 0.00 - 100.00

    -- Interpretación de IA (Amazon Bedrock)
    ai_interpretation       JSONB,
    ai_model_used           VARCHAR(100) DEFAULT 'anthropic.claude-3-5-sonnet-20241022-v2:0',
    ai_prompt_tokens        INTEGER DEFAULT 0,
    ai_completion_tokens    INTEGER DEFAULT 0,
    ai_total_tokens         INTEGER GENERATED ALWAYS AS (ai_prompt_tokens + ai_completion_tokens) STORED,
    ai_cost_usd             DECIMAL(10,6) DEFAULT 0.000000,

    -- Resultado
    feature_type            VARCHAR(50) NOT NULL,  -- 'voice_task', 'voice_finance'
    created_resource_type   VARCHAR(50),  -- 'task', 'transaction'
    created_resource_id     UUID,

    -- Errores y reintentos
    error_message           TEXT,
    error_code              VARCHAR(100),
    retry_count             INTEGER DEFAULT 0,
    max_retries             INTEGER DEFAULT 3,

    -- Timestamps
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at            TIMESTAMP WITH TIME ZONE,
    failed_at               TIMESTAMP WITH TIME ZONE
);

-- Índices
CREATE INDEX idx_voice_inputs_organization_user ON voice_inputs(organization_id, user_id);
CREATE INDEX idx_voice_inputs_status ON voice_inputs(status);
CREATE INDEX idx_voice_inputs_feature_type ON voice_inputs(feature_type);
CREATE INDEX idx_voice_inputs_created_at ON voice_inputs(created_at DESC);
CREATE INDEX idx_voice_inputs_user_created_at ON voice_inputs(user_id, created_at DESC);

-- RLS
ALTER TABLE voice_inputs ENABLE ROW LEVEL SECURITY;

CREATE POLICY voice_inputs_isolation_policy ON voice_inputs
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );
```

---

### GAP #3: Tabla `password_history` - MEDIA PRIORIDAD 🟢

**Prioridad**: MEDIA
**Módulo Afectado**: Gestor de Contraseñas
**Impacto**: Sin esta tabla no hay auditoría de cambios de contraseñas

#### ¿Qué es?
Tabla para almacenar el historial de cambios de cada contraseña guardada.

#### ¿Por qué falta?
No se puede:
- Ver cuándo se cambió una contraseña
- Auditar quién cambió una contraseña
- Revertir a versión anterior
- Cumplir con compliance de seguridad

#### ¿Dónde debería estar?
- **Ubicación en schema**: En sección "7. Módulo: Gestor de Contraseñas"
- **Orden recomendado**: Después de la tabla `passwords`

#### ¿Qué endpoints están bloqueados?

| Endpoint | Método | Afectado |
|----------|--------|----------|
| GET /passwords/{passwordId}/history | GET | ❌ No funciona |

**Total**: 1 endpoint bloqueado

#### ¿Qué funcionalidades no se pueden hacer?

1. ❌ Ver historial de cambios de una contraseña
2. ❌ Auditar cuándo fue la última vez que se cambió
3. ❌ Cumplir con políticas de rotación de contraseñas
4. ❌ Detectar cambios no autorizados
5. ❌ Revertir a versión anterior en caso de error

#### Schema Requerido

```sql
CREATE TABLE password_history (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_id             UUID NOT NULL REFERENCES passwords(id) ON DELETE CASCADE,

    -- Contraseña anterior (encriptada)
    encrypted_password      BYTEA NOT NULL,  -- AES-256-GCM
    encryption_iv           BYTEA NOT NULL,
    encryption_tag          BYTEA,

    -- Detalles del cambio
    changed_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_reason          VARCHAR(255),  -- 'manual', 'expired', 'compromised', 'policy'
    changed_by_user_id      UUID REFERENCES users(id),

    -- Tracking
    ip_address              INET,
    user_agent              TEXT,
    metadata                JSONB DEFAULT '{}'
);

-- Índices
CREATE INDEX idx_password_history_organization_user ON password_history(organization_id, user_id);
CREATE INDEX idx_password_history_password_id ON password_history(password_id);
CREATE INDEX idx_password_history_changed_at ON password_history(changed_at DESC);

-- RLS
ALTER TABLE password_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY password_history_isolation_policy ON password_history
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );
```

---

### GAP #4: Tabla `webhook_events` - MEDIA PRIORIDAD 🟢

**Prioridad**: MEDIA (pero CRÍTICA para producción)
**Módulo Afectado**: Suscripciones y Pagos (Webhooks de Wompi)
**Impacto**: Sin esta tabla hay riesgo de procesar webhooks duplicados

#### ¿Qué es?
Tabla para registrar todos los webhooks recibidos de proveedores externos (principalmente Wompi) y garantizar idempotencia.

#### ¿Por qué falta?
Sin esta tabla:
- Un webhook puede procesarse múltiples veces
- Riesgo de doble cobro
- Riesgo de activar suscripción dos veces
- No hay auditoría de eventos recibidos

#### ¿Dónde debería estar?
- **Ubicación en schema**: En sección "5. Módulo: Suscripciones"
- **Orden recomendado**: Después de `payment_audit_logs`

#### ¿Qué endpoints están afectados?

| Endpoint | Método | Riesgo |
|----------|--------|--------|
| POST /webhooks/wompi | POST | ⚠️ Puede procesar duplicados |

**Riesgo**: Si Wompi reenvía el mismo evento 2 veces, se procesaría 2 veces.

#### ¿Qué funcionalidades no se pueden hacer?

1. ❌ Prevenir procesamiento duplicado de webhooks
2. ❌ Auditoría de todos los eventos recibidos de Wompi
3. ❌ Debugging de webhooks fallidos
4. ❌ Reintentar procesamiento de webhook fallido
5. ❌ Ver payload original del webhook
6. ❌ Verificar firma HMAC recibida

#### Schema Requerido

```sql
CREATE TABLE webhook_events (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Identificación del evento
    event_id                VARCHAR(255) NOT NULL UNIQUE,  -- ID único de Wompi
    event_type              VARCHAR(100) NOT NULL,  -- 'transaction.updated', etc
    provider                VARCHAR(50) NOT NULL DEFAULT 'wompi',

    -- Payload
    payload                 JSONB NOT NULL,
    signature               VARCHAR(500),
    signature_verified      BOOLEAN DEFAULT false,

    -- Procesamiento
    status                  VARCHAR(50) DEFAULT 'pending',
                            CHECK (status IN ('pending', 'processing', 'processed', 'failed', 'duplicate', 'invalid_signature')),

    processed_at            TIMESTAMP WITH TIME ZONE,
    error_message           TEXT,
    error_code              VARCHAR(100),
    retry_count             INTEGER DEFAULT 0,

    -- Relación (opcional)
    organization_id         UUID REFERENCES organizations(id),
    user_id                 UUID REFERENCES users(id),
    subscription_id         UUID REFERENCES subscriptions(id),

    -- Tracking HTTP
    ip_address              INET,
    user_agent              TEXT,
    http_headers            JSONB,

    -- Timestamps
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    received_at             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE UNIQUE INDEX idx_webhook_events_event_id ON webhook_events(event_id);
CREATE INDEX idx_webhook_events_provider_event_type ON webhook_events(provider, event_type);
CREATE INDEX idx_webhook_events_status ON webhook_events(status);
CREATE INDEX idx_webhook_events_created_at ON webhook_events(created_at DESC);
CREATE INDEX idx_webhook_events_subscription_id ON webhook_events(subscription_id) WHERE subscription_id IS NOT NULL;
```

**Nota**: Esta tabla NO requiere RLS porque los webhooks son eventos externos sin contexto de usuario.

---

## ✅ ELEMENTOS QUE SÍ ESTÁN COMPLETOS

### Extensiones PostgreSQL ✅

```sql
✅ uuid-ossp      -- Generación de UUIDs
✅ pgcrypto       -- Encriptación
✅ pg_trgm        -- Búsquedas fuzzy
✅ vector         -- pgvector para AI Memory (búsqueda semántica)
```

**Ubicación**: Líneas 16-18 y 1430

### Tablas Existentes (22 tablas) ✅

#### Sistema (4 tablas)
1. ✅ `organizations` - Organizaciones
2. ✅ `users` - Usuarios
3. ✅ `refresh_tokens` - Tokens JWT
4. ✅ `audit_logs` - Auditoría

#### Suscripciones (4 tablas)
5. ✅ `plans` - Planes de suscripción
6. ✅ `subscriptions` - Suscripciones activas
7. ✅ `payment_methods` - Tarjetas guardadas
8. ✅ `payment_audit_logs` - Historial de pagos

#### Tareas (4 tablas)
9. ✅ `tasks` - Tareas TODO
10. ✅ `tags` - Etiquetas
11. ✅ `task_tags` - Relación N:M tareas-tags
12. ✅ `reminders` - Recordatorios

#### Finanzas (3 tablas + 1 faltante)
13. ✅ `categories` - Categorías
14. ✅ `transactions` - Transacciones
15. ✅ `sms_messages` - SMS bancarios capturados
16. ✅ `budgets` - Presupuestos
17. ❌ `accounts` - FALTANTE

#### Contraseñas (1 tabla + 1 faltante)
18. ✅ `passwords` - Contraseñas encriptadas
19. ❌ `password_history` - FALTANTE

#### IA (2 tablas + 1 faltante)
20. ✅ `ai_conversations` - Chat con IA
21. ✅ `ai_usage` - Cuotas de IA
22. ❌ `voice_inputs` - FALTANTE

#### AI Memory (3 tablas)
23. ✅ `memories` - Memorias del usuario
24. ✅ `memory_attachments` - Archivos adjuntos
25. ✅ `memory_embeddings` - Vectores para búsqueda semántica

#### Webhooks (0 tablas + 1 faltante)
26. ❌ `webhook_events` - FALTANTE

### Funciones SQL (7 funciones) ✅

1. ✅ `update_updated_at_column()` - Trigger para updated_at
2. ✅ `check_plan_feature()` - Verificar feature en plan
3. ✅ `check_ai_quota()` - Validar cuota de IA
4. ✅ `check_task_limit()` - Validar límite de tareas
5. ✅ `check_storage_quota()` - Validar espacio de storage
6. ✅ `check_memory_quota()` - Validar cuota de memorias
7. ✅ `calculate_user_storage()` - Calcular storage usado

**Faltante**:
8. ❌ `update_account_balance()` - Actualizar balance de cuenta (necesita tabla accounts)

### RLS Policies ✅

✅ **22/22 tablas con RLS habilitado**

Todas las tablas de datos de usuario tienen:
- `ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;`
- Policy de aislamiento por `organization_id` + `user_id`

### Triggers ✅

✅ **14 triggers automáticos**

- updated_at triggers en todas las tablas
- Auto-población de organization_id/user_id en tablas junction

### Vistas ✅

1. ✅ `user_subscription_info` - Info de suscripción del usuario
2. ✅ `task_statistics` - Estadísticas de tareas
3. ✅ `transaction_summary` - Resumen de transacciones

---

## 📝 CHECKLIST DE IMPLEMENTACIÓN

### Paso 1: Añadir las 4 tablas faltantes

- [ ] Crear tabla `accounts` (CRÍTICA)
  - [ ] Añadir índices
  - [ ] Añadir RLS policy
  - [ ] Añadir trigger updated_at
  - [ ] Añadir campo `account_id` a `transactions`
  - [ ] Crear función `update_account_balance()`

- [ ] Crear tabla `voice_inputs` (ALTA)
  - [ ] Añadir índices
  - [ ] Añadir RLS policy

- [ ] Crear tabla `password_history` (MEDIA)
  - [ ] Añadir índices
  - [ ] Añadir RLS policy

- [ ] Crear tabla `webhook_events` (MEDIA)
  - [ ] Añadir índices
  - [ ] NO añadir RLS (tabla de eventos externos)

### Paso 2: Ejecutar MIGRATION-002

```bash
psql -h <rds-host> -U postgres -d temis < MIGRATION-002-ADD-MISSING-TABLES.sql
```

### Paso 3: Validar resultados

```sql
-- Verificar que las 26 tablas existan
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';
-- Resultado esperado: 26

-- Verificar que accounts tenga datos iniciales
SELECT COUNT(*) FROM accounts;
-- Resultado esperado: 1 cuenta "Efectivo" por cada usuario activo
```

### Paso 4: Actualizar DATABASE-SCHEMA.md

- [ ] Añadir sección de tabla `accounts`
- [ ] Añadir sección de tabla `voice_inputs`
- [ ] Añadir sección de tabla `password_history`
- [ ] Añadir sección de tabla `webhook_events`
- [ ] Actualizar changelog con versión 1.4.0

---

## 🎯 IMPACTO DE COMPLETAR GAPS

### Antes (Estado Actual)

- Tablas: 22/26 (84.6%)
- Módulos 100%: 7/11
- Módulos parciales: 4/11
- Endpoints funcionales: ~80%

### Después (Con 4 tablas añadidas)

- Tablas: 26/26 (100%) ✅
- Módulos 100%: 11/11 ✅
- Módulos parciales: 0/11 ✅
- Endpoints funcionales: 100% ✅

### Beneficios

1. ✅ Módulo Finanzas 100% funcional
2. ✅ Tracking de cuentas bancarias
3. ✅ Historial completo de voz
4. ✅ Auditoría de contraseñas
5. ✅ Idempotencia de webhooks (sin riesgo de doble cobro)
6. ✅ Base de datos production-ready

---

## 📄 ARCHIVOS RELACIONADOS

1. `DATABASE-SCHEMA.md` (2047 líneas) - Schema actual con 22 tablas
2. `MIGRATION-002-ADD-MISSING-TABLES.sql` (400 líneas) - Script para añadir 4 tablas
3. `DATABASE-VALIDATION.md` (775 líneas) - Validación completa de módulos

---

## 🚀 PRÓXIMOS PASOS

### Inmediato
1. Ejecutar MIGRATION-002-ADD-MISSING-TABLES.sql
2. Validar que las 26 tablas existan
3. Poblar datos iniciales (cuenta "Efectivo")

### Corto Plazo
4. Actualizar DATABASE-SCHEMA.md con las 4 nuevas tablas
5. Actualizar contratos YAML que usen `accounts`
6. Implementar lambdas que usen las nuevas tablas

### Medio Plazo
7. Testing de integridad referencial
8. Testing de RLS policies
9. Optimización de índices según uso real

---

**Documento creado**: 2026-09-24
**Autor**: Análisis exhaustivo de gaps
**Estado**: 4 gaps identificados y documentados
**Próxima acción**: Ejecutar MIGRATION-002
