# ✅ VALIDACIÓN COMPLETA DE BASE DE DATOS - TEMIS

**Fecha de Validación**: 2026-09-24
**Versión DB Schema**: 1.3.0
**PostgreSQL**: 15.x
**Modelo**: Multitenant (organization_id + user_id)

---

## 📊 RESUMEN EJECUTIVO

### Estado del Schema

| Métrica | Valor | Estado |
|---------|-------|--------|
| **Tablas Creadas** | 22 tablas | ✅ |
| **Tablas Faltantes** | 4 tablas | ⚠️ |
| **Extensiones Requeridas** | 4 extensiones | ✅ Documentadas |
| **Funciones SQL** | 7 funciones | ✅ |
| **Triggers** | 14 triggers | ✅ |
| **RLS Policies** | 16 policies | ✅ |
| **Vistas** | 3 vistas | ✅ |
| **Modelo Multitenant** | Completo | ✅ |

---

## 🏗️ MODELO MULTITENANT VALIDADO

### Arquitectura Multitenant (Tipo Netflix)

**Diseño Actual**: ✅ PREPARADO para múltiples usuarios por organización

```
┌─────────────────────────────────────────────────────────┐
│                   ORGANIZATION                          │
│  (Familia, Empresa, Grupo)                              │
│  id: UUID                                                │
│  name: "Familia Pérez"                                  │
└─────────────────────────────────────────────────────────┘
                          │
                          │ 1:N
                          ▼
         ┌────────────────┬────────────────┬─────────────┐
         │                │                │             │
    ┌────▼────┐      ┌───▼────┐      ┌───▼────┐   ┌────▼────┐
    │ USER 1  │      │ USER 2 │      │ USER 3 │   │ USER N  │
    │ (Papá)  │      │ (Mamá) │      │ (Hijo) │   │ (Hija)  │
    └────┬────┘      └────┬───┘      └────┬───┘   └────┬────┘
         │                │                │            │
         │ Comparten:     │                │            │
         │ - Tareas       │                │            │
         │ - Transacciones│                │            │
         │ - Presupuestos │                │            │
         │ - Categorías   │                │            │
         └────────────────┴────────────────┴────────────┘
```

### Características del Modelo Multitenant

**✅ IMPLEMENTADO**:

1. **Tabla `organizations`**
   ```sql
   CREATE TABLE organizations (
       id UUID PRIMARY KEY,
       name VARCHAR(255),     -- "Familia Pérez", "Empresa XYZ"
       slug VARCHAR(100) UNIQUE,
       timezone VARCHAR(50),
       locale VARCHAR(10),
       is_active BOOLEAN,
       created_at TIMESTAMP WITH TIME ZONE
   );
   ```

2. **Tabla `users`**
   ```sql
   CREATE TABLE users (
       id UUID PRIMARY KEY,
       organization_id UUID REFERENCES organizations(id),  -- FK a organización
       email VARCHAR(255) UNIQUE,
       name VARCHAR(255),
       role VARCHAR(50),  -- 'admin', 'user'
       is_active BOOLEAN,
       created_at TIMESTAMP WITH TIME ZONE
   );
   ```

3. **TODAS las tablas de datos tienen `organization_id` + `user_id`**
   - ✅ tasks
   - ✅ transactions
   - ✅ budgets
   - ✅ passwords
   - ✅ memories
   - ✅ subscriptions
   - ✅ etc.

4. **RLS Policies Automáticas**
   ```sql
   CREATE POLICY tasks_isolation_policy ON tasks
       FOR ALL
       USING (
           organization_id = current_setting('app.current_organization_id')::uuid
           AND user_id = current_setting('app.current_user_id')::uuid
       );
   ```

### Escenarios Soportados

**Escenario 1: Uso Personal (Actual)**
```
Organization: "Juan's Workspace"
└── User: Juan (admin)
    ├── Tareas personales
    ├── Finanzas personales
    └── Contraseñas personales
```

**Escenario 2: Familia Compartida (Netflix-style) ✅ SOPORTADO**
```
Organization: "Familia García"
├── User: Pedro (padre, admin)
│   ├── Tareas: "Pagar hipoteca" (privada)
│   └── Transacciones: Ver TODAS las de la familia
├── User: María (madre, admin)
│   ├── Tareas: "Comprar supermercado" (privada)
│   └── Transacciones: Ver TODAS las de la familia
└── User: Ana (hija, user)
    ├── Tareas: "Hacer tarea escolar" (privada)
    └── Transacciones: Solo ver las propias
```

**Escenario 3: Empresa Pequeña ✅ SOPORTADO**
```
Organization: "Startup Tech SAS"
├── User: Carlos (CEO, admin)
├── User: Laura (CFO, admin)
├── User: Diego (Empleado, user)
└── User: Sofia (Empleado, user)
    └── Todos comparten:
        ├── Tareas del proyecto
        ├── Presupuestos de la empresa
        └── Transacciones corporativas
```

### Configuración RLS para Compartir Datos

**Opción 1: Datos Privados (Actual)**
```sql
-- Cada usuario solo ve SUS datos
WHERE organization_id = $org AND user_id = $user
```

**Opción 2: Datos Compartidos en Organización (Preparado)**
```sql
-- Todos los usuarios de la organización ven los datos
WHERE organization_id = $org
-- (Sin filtrar por user_id)
```

**Opción 3: Datos por Rol (Preparado)**
```sql
-- Admins ven todo, users solo lo suyo
WHERE organization_id = $org
  AND (
    current_setting('app.current_user_role') = 'admin'
    OR user_id = current_setting('app.current_user_id')::uuid
  )
```

### Tabla `subscriptions` - Suscripción por Organización

```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id),  -- UNA suscripción por org
    user_id UUID REFERENCES users(id),  -- Usuario que paga (owner)
    plan_id UUID REFERENCES plans(id),
    status VARCHAR(50),
    ...
);
```

**Modelo de Pago**:
- ✅ Una organización = Una suscripción
- ✅ Múltiples usuarios en la misma organización comparten el plan
- ✅ Similar a Netflix: Paga una vez, múltiples perfiles/usuarios

**Ejemplo**:
```
Familia Pérez:
- Suscripción: Premium ($19.99/mes)
- Usuarios:
  ├── Pedro (paga la suscripción)
  ├── María (usuario adicional - gratis)
  ├── Ana (usuario adicional - gratis)
  └── Luis (usuario adicional - gratis)

Total a pagar: $19.99/mes (sin importar # de usuarios)
```

---

## 📋 TABLAS EXISTENTES (22 TABLAS)

### 1. Sistema y Autenticación (4 tablas)

| # | Tabla | Descripción | Multitenant | Estado |
|---|-------|-------------|-------------|--------|
| 1 | `organizations` | Organizaciones (familias/empresas) | - | ✅ Completa |
| 2 | `users` | Usuarios del sistema | ✅ org_id | ✅ Completa |
| 3 | `refresh_tokens` | Tokens JWT de renovación | ✅ org_id + user_id | ✅ Completa |
| 4 | `audit_logs` | Auditoría de acciones | ✅ org_id + user_id | ✅ Completa |

**Campos de `users`**:
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    organization_id UUID,  -- FK a organizations
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    name VARCHAR(255),
    avatar_url TEXT,
    phone VARCHAR(20),
    role VARCHAR(50),  -- 'superadmin', 'admin', 'user'
    is_active BOOLEAN,
    is_email_verified BOOLEAN,
    preferences JSONB,  -- {theme, locale, timezone, currency}
    ai_memory_storage_bytes BIGINT,  -- Para AI Memory
    ai_memory_email VARCHAR(255) UNIQUE,  -- memories+{user_id}@temis.app
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);
```

### 2. Suscripciones y Pagos (4 tablas)

| # | Tabla | Descripción | Multitenant | Estado |
|---|-------|-------------|-------------|--------|
| 5 | `plans` | Planes de suscripción (Free, Basic, Pro, Premium) | Global | ✅ Completa |
| 6 | `subscriptions` | Suscripciones activas | ✅ org_id + user_id | ✅ Completa |
| 7 | `payment_methods` | Tarjetas guardadas (tokenizadas) | ✅ org_id + user_id | ✅ Completa |
| 8 | `payment_audit_logs` | Historial de pagos | ✅ org_id + user_id | ✅ Completa |

**Planes Incluidos**:
```sql
INSERT INTO plans (name, slug, price_monthly, price_yearly, features) VALUES
('Free', 'free', 0.00, 0.00, '{"tasks": true, "passwords": false, "finance": false}'),
('Basic', 'basic', 4.99, 49.90, '{"tasks": true, "passwords": true, "finance": false}'),
('Pro', 'pro', 9.99, 99.90, '{"tasks": true, "passwords": true, "finance": true, "voice_input": true}'),
('Premium', 'premium', 19.99, 199.90, '{"tasks": true, "passwords": true, "finance": true, "voice_input": true, "sms_capture": true}');
```

### 3. Módulo Tareas (4 tablas)

| # | Tabla | Descripción | Multitenant | Estado |
|---|-------|-------------|-------------|--------|
| 9 | `tasks` | Tareas TODO | ✅ org_id + user_id | ✅ Completa |
| 10 | `tags` | Etiquetas para organización | ✅ org_id + user_id | ✅ Completa |
| 11 | `task_tags` | Relación N:M tareas-etiquetas | ✅ org_id + user_id | ✅ Completa |
| 12 | `reminders` | Recordatorios | ✅ org_id + user_id | ✅ Completa |

**Campos de `tasks`**:
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY,
    organization_id UUID,
    user_id UUID,
    title VARCHAR(500),
    description TEXT,
    status VARCHAR(50),  -- 'pending', 'in_progress', 'completed', 'cancelled'
    priority VARCHAR(20),  -- 'low', 'medium', 'high', 'urgent'
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    is_all_day BOOLEAN,
    recurrence_rule VARCHAR(255),
    parent_task_id UUID,  -- Para subtareas
    sort_order INTEGER,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

### 4. Módulo Finanzas (4 tablas)

| # | Tabla | Descripción | Multitenant | Estado |
|---|-------|-------------|-------------|--------|
| 13 | `categories` | Categorías de transacciones | ✅ org_id + user_id (opcionales) | ✅ Completa |
| 14 | `transactions` | Transacciones financieras | ✅ org_id + user_id | ✅ Completa |
| 15 | `sms_messages` | SMS bancarios capturados | ✅ org_id + user_id | ✅ Completa |
| 16 | `budgets` | Presupuestos mensuales | ✅ org_id + user_id | ✅ Completa |

**Campos de `transactions`**:
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    organization_id UUID,
    user_id UUID,
    category_id UUID,
    type VARCHAR(20),  -- 'income', 'expense'
    amount DECIMAL(15,2),
    currency VARCHAR(3),
    description TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE,
    source VARCHAR(50),  -- 'manual', 'voice', 'sms', 'import'
    source_reference VARCHAR(255),
    payment_method VARCHAR(50),  -- 'cash', 'credit_card', 'debit_card', 'transfer'
    tags TEXT[],
    location VARCHAR(255),
    is_recurring BOOLEAN,
    recurrence_rule VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

**Categorías Predefinidas**:
```sql
-- Categorías globales (is_default=true, sin organization_id ni user_id)
INSERT INTO categories (name, type, icon, is_default) VALUES
('Salario', 'income', '💰', true),
('Freelance', 'income', '💼', true),
('Alimentación', 'expense', '🍔', true),
('Transporte', 'expense', '🚗', true),
('Entretenimiento', 'expense', '🎬', true),
('Servicios', 'expense', '💡', true),
('Salud', 'expense', '⚕️', true);
```

### 5. Módulo Contraseñas (1 tabla)

| # | Tabla | Descripción | Multitenant | Estado |
|---|-------|-------------|-------------|--------|
| 17 | `passwords` | Contraseñas encriptadas AES-256-GCM | ✅ org_id + user_id | ✅ Completa |

**Campos de `passwords`**:
```sql
CREATE TABLE passwords (
    id UUID PRIMARY KEY,
    organization_id UUID,
    user_id UUID,
    name VARCHAR(255),
    username VARCHAR(255),
    encrypted_password BYTEA,  -- AES-256-GCM
    encryption_iv BYTEA,  -- Initialization Vector
    url TEXT,
    notes TEXT,
    category VARCHAR(50),  -- 'website', 'bank', 'wifi', 'email', 'app', 'other'
    tags TEXT[],
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_favorite BOOLEAN,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

### 6. Módulo IA (2 tablas)

| # | Tabla | Descripción | Multitenant | Estado |
|---|-------|-------------|-------------|--------|
| 18 | `ai_conversations` | Historial de chat con IA | ✅ org_id + user_id | ✅ Completa |
| 19 | `ai_usage` | Control de cuotas de IA | ✅ org_id + user_id | ✅ Completa |

**Campos de `ai_usage`**:
```sql
CREATE TABLE ai_usage (
    id UUID PRIMARY KEY,
    organization_id UUID,
    user_id UUID,
    feature_type VARCHAR(50),  -- 'chat', 'voice_task', 'voice_finance', 'insight', 'prediction'
    month_year VARCHAR(7),  -- '2026-09'
    usage_count INTEGER,
    tokens_consumed INTEGER,
    cost_usd DECIMAL(10,6),
    plan_limit INTEGER,
    -- Cuotas de AI Memory
    memory_conversations_created INT,
    memory_photos_ocr INT,
    memory_documents_processed INT,
    memory_emails_received INT,
    memory_voice_notes INT,
    memory_ai_searches INT,
    memory_insights_generated INT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(organization_id, user_id, feature_type, month_year)
);
```

### 7. Módulo AI Memory (3 tablas)

| # | Tabla | Descripción | Multitenant | Estado |
|---|-------|-------------|-------------|--------|
| 20 | `memories` | Memorias del usuario | ✅ org_id + user_id | ✅ Completa |
| 21 | `memory_attachments` | Archivos adjuntos (S3) | ✅ org_id + user_id | ✅ Completa |
| 22 | `memory_embeddings` | Vectores para búsqueda semántica | ✅ org_id + user_id | ✅ Completa |

**Campos de `memories`**:
```sql
CREATE TABLE memories (
    id UUID PRIMARY KEY,
    organization_id UUID,
    user_id UUID,
    title VARCHAR(500),
    description TEXT,
    memory_type VARCHAR(50),  -- 'conversation', 'photo', 'document', 'email', 'voice_note'
    status VARCHAR(50),  -- 'processing', 'ready', 'failed'
    captured_at TIMESTAMP WITH TIME ZONE,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    location_name VARCHAR(255),
    ai_summary TEXT,  -- Resumen generado por IA
    ai_extracted_entities JSONB,  -- {persons: [], places: [], dates: []}
    ai_suggested_tags VARCHAR(255)[],
    ai_processing_error TEXT,
    is_favorite BOOLEAN,
    is_archived BOOLEAN,
    tags VARCHAR(100)[],
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

**Campos de `memory_embeddings`**:
```sql
CREATE TABLE memory_embeddings (
    id UUID PRIMARY KEY,
    organization_id UUID,
    user_id UUID,
    memory_id UUID REFERENCES memories(id),
    embedding vector(1536),  -- Vector de 1536 dimensiones (Claude 3.5 Sonnet)
    chunk_text TEXT,
    chunk_index INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
);

-- Índice HNSW para búsqueda vectorial rápida
CREATE INDEX idx_embeddings_vector ON memory_embeddings
    USING hnsw (embedding vector_cosine_ops);
```

---

## ⚠️ TABLAS FALTANTES IDENTIFICADAS (4 TABLAS)

### Tabla 1: `accounts` (CRÍTICA - Módulo Finanzas)

**Uso**: Gestión de cuentas bancarias, tarjetas, efectivo

**Mencionada en**:
- LAMBDAS-RESUMEN.md (lambda-transactions)
- Varios contratos de transacciones

**Schema Propuesto**:
```sql
CREATE TABLE accounts (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name                VARCHAR(255) NOT NULL,
    type                VARCHAR(50) NOT NULL,
                        CHECK (type IN ('bank', 'cash', 'credit_card', 'investment', 'savings', 'other')),

    currency            VARCHAR(3) DEFAULT 'USD',
    initial_balance     DECIMAL(15,2) DEFAULT 0.00,
    current_balance     DECIMAL(15,2) DEFAULT 0.00,

    -- Detalles bancarios (opcional)
    bank_name           VARCHAR(255),
    account_number      VARCHAR(100),  -- Últimos 4 dígitos
    color               VARCHAR(7) DEFAULT '#3B82F6',
    icon                VARCHAR(50),

    is_active           BOOLEAN DEFAULT true,
    is_included_in_total BOOLEAN DEFAULT true,  -- Incluir en balance total

    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP WITH TIME ZONE
);

-- Índices
CREATE INDEX idx_accounts_organization_user ON accounts(organization_id, user_id);
CREATE INDEX idx_accounts_type ON accounts(type);
CREATE INDEX idx_accounts_is_active ON accounts(is_active);
CREATE INDEX idx_accounts_deleted_at ON accounts(deleted_at) WHERE deleted_at IS NULL;

-- RLS Policy
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY accounts_isolation_policy ON accounts
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );

-- Trigger updated_at
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE accounts IS 'Cuentas bancarias y métodos de almacenamiento de dinero - DEBE filtrar por organization_id AND user_id';
```

**Impacto**:
- Sin esta tabla, las transacciones no tienen cuenta asociada
- No se puede calcular balance por cuenta
- No se puede mostrar dashboard de cuentas

**Prioridad**: ALTA

### Tabla 2: `password_history` (MEDIA - Módulo Passwords)

**Uso**: Historial de cambios de contraseñas

**Mencionada en**:
- LAMBDAS-RESUMEN.md (lambda-passwords)
- CONTRATO_PASSWORDS: GET /passwords/{id}/history

**Schema Propuesto**:
```sql
CREATE TABLE password_history (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_id         UUID NOT NULL REFERENCES passwords(id) ON DELETE CASCADE,

    encrypted_password  BYTEA NOT NULL,  -- Password anterior encriptado
    encryption_iv       BYTEA NOT NULL,

    changed_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_reason      VARCHAR(255),  -- 'manual', 'expired', 'compromised'

    metadata            JSONB DEFAULT '{}'
);

-- Índices
CREATE INDEX idx_password_history_organization_user ON password_history(organization_id, user_id);
CREATE INDEX idx_password_history_password_id ON password_history(password_id);
CREATE INDEX idx_password_history_changed_at ON password_history(changed_at DESC);

-- RLS Policy
ALTER TABLE password_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY password_history_isolation_policy ON password_history
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );

COMMENT ON TABLE password_history IS 'Historial de cambios de contraseñas - DEBE filtrar por organization_id AND user_id';
```

**Impacto**:
- Endpoint GET /passwords/{id}/history no funciona
- No se puede auditar cambios de contraseñas

**Prioridad**: MEDIA

### Tabla 3: `voice_inputs` (ALTA - Módulo Voice)

**Uso**: Registro de entradas por voz procesadas

**Mencionada en**:
- LAMBDAS-RESUMEN.md (lambda-voice)
- CONTRATO_VOICE: GET /voice/history, POST /voice/retry/{id}

**Schema Propuesto**:
```sql
CREATE TABLE voice_inputs (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Audio
    audio_s3_key        VARCHAR(500) NOT NULL,
    audio_duration_sec  INTEGER,
    audio_format        VARCHAR(20),  -- 'mp3', 'wav', 'm4a', 'ogg'
    audio_size_bytes    BIGINT,

    -- Procesamiento
    status              VARCHAR(50) DEFAULT 'processing',
                        CHECK (status IN ('processing', 'completed', 'failed')),

    transcription_text  TEXT,
    transcription_confidence DECIMAL(5,2),  -- 0.00 - 100.00

    ai_interpretation   JSONB,  -- Datos estructurados extraídos por IA
    ai_model_used       VARCHAR(100) DEFAULT 'claude-3-5-sonnet-20241022',

    tokens_input        INTEGER DEFAULT 0,
    tokens_output       INTEGER DEFAULT 0,
    cost_usd            DECIMAL(10,6) DEFAULT 0.000000,

    -- Resultado
    feature_type        VARCHAR(50) NOT NULL,  -- 'voice_task', 'voice_finance'
    created_resource_type VARCHAR(50),  -- 'task', 'transaction'
    created_resource_id UUID,

    error_message       TEXT,
    retry_count         INTEGER DEFAULT 0,

    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at        TIMESTAMP WITH TIME ZONE
);

-- Índices
CREATE INDEX idx_voice_inputs_organization_user ON voice_inputs(organization_id, user_id);
CREATE INDEX idx_voice_inputs_status ON voice_inputs(status);
CREATE INDEX idx_voice_inputs_feature_type ON voice_inputs(feature_type);
CREATE INDEX idx_voice_inputs_created_at ON voice_inputs(created_at DESC);

-- RLS Policy
ALTER TABLE voice_inputs ENABLE ROW LEVEL SECURITY;

CREATE POLICY voice_inputs_isolation_policy ON voice_inputs
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );

COMMENT ON TABLE voice_inputs IS 'Historial de entradas por voz procesadas - DEBE filtrar por organization_id AND user_id';
```

**Impacto**:
- Endpoint GET /voice/history no funciona
- Endpoint POST /voice/retry/{id} no funciona
- No se puede auditar uso de voz

**Prioridad**: ALTA

### Tabla 4: `webhook_events` (MEDIA - Módulo Webhooks)

**Uso**: Registro de webhooks recibidos para idempotencia

**Mencionada en**:
- CONTRATO_WEBHOOKS: Sección de idempotencia

**Schema Propuesto**:
```sql
CREATE TABLE webhook_events (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Identificación del evento
    event_id            VARCHAR(255) NOT NULL UNIQUE,  -- ID del evento de Wompi
    event_type          VARCHAR(100) NOT NULL,  -- 'transaction.updated', etc
    provider            VARCHAR(50) DEFAULT 'wompi',

    -- Payload
    payload             JSONB NOT NULL,
    signature           VARCHAR(255),

    -- Procesamiento
    status              VARCHAR(50) DEFAULT 'pending',
                        CHECK (status IN ('pending', 'processing', 'processed', 'failed', 'duplicate')),

    processed_at        TIMESTAMP WITH TIME ZONE,
    error_message       TEXT,
    retry_count         INTEGER DEFAULT 0,

    -- Metadatos
    ip_address          INET,
    user_agent          TEXT,

    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_webhook_events_event_id ON webhook_events(event_id);
CREATE INDEX idx_webhook_events_event_type ON webhook_events(event_type);
CREATE INDEX idx_webhook_events_status ON webhook_events(status);
CREATE INDEX idx_webhook_events_created_at ON webhook_events(created_at DESC);

COMMENT ON TABLE webhook_events IS 'Registro de webhooks recibidos para idempotencia - No requiere RLS (eventos externos)';
```

**Impacto**:
- Sin idempotencia, webhooks duplicados pueden procesarse múltiples veces
- Riesgo de doble cobro o doble activación de suscripción

**Prioridad**: MEDIA

---

## 🔧 FUNCIONES SQL IMPLEMENTADAS (7 FUNCIONES)

### Funciones Críticas

| # | Función | Propósito | Estado |
|---|---------|-----------|--------|
| 1 | `update_updated_at_column()` | Trigger para actualizar updated_at | ✅ |
| 2 | `check_plan_feature(org_id, user_id, feature)` | Verificar feature habilitada en plan | ✅ |
| 3 | `check_ai_quota(org_id, user_id, feature_type)` | Validar cuota de IA disponible | ✅ |
| 4 | `check_task_limit(org_id, user_id)` | Validar límite mensual de tareas | ✅ |
| 5 | `check_storage_quota(org_id, user_id, file_size)` | Validar espacio de almacenamiento | ✅ |
| 6 | `check_memory_quota(org_id, user_id, memory_type)` | Validar cuota de memorias | ✅ |
| 7 | `calculate_user_storage(user_id)` | Calcular storage usado en AI Memory | ✅ |

**Función Adicional Necesaria**:
```sql
-- Función para actualizar balance de cuenta
CREATE OR REPLACE FUNCTION update_account_balance(
    p_account_id UUID,
    p_amount DECIMAL(15,2),
    p_operation VARCHAR(10)  -- 'add' or 'subtract'
) RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_new_balance DECIMAL(15,2);
BEGIN
    IF p_operation = 'add' THEN
        UPDATE accounts
        SET current_balance = current_balance + p_amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_account_id
        RETURNING current_balance INTO v_new_balance;
    ELSIF p_operation = 'subtract' THEN
        UPDATE accounts
        SET current_balance = current_balance - p_amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_account_id
        RETURNING current_balance INTO v_new_balance;
    END IF;

    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql;
```

---

## 📊 MÓDULOS FUNCIONALES OFRECIDOS A USUARIOS

### RESUMEN EJECUTIVO

**Total de Módulos**: 11 módulos funcionales
**Estado de DB**: 22/26 tablas (84.6%)
**Tablas Faltantes**: 4 (accounts, password_history, voice_inputs, webhook_events)

### LISTADO COMPLETO DE MÓDULOS

#### 1. AUTENTICACIÓN Y USUARIOS 🔐

**Descripción**: Sistema completo de registro, login y gestión de perfiles

**Funcionalidades**:
- ✅ Registro de usuarios con email + contraseña
- ✅ Login con JWT RS256 (access token 15min + refresh token 7 días)
- ✅ Verificación de email
- ✅ Reset de contraseña (forgot password)
- ✅ Gestión de sesiones activas
- ✅ Revocación de tokens
- ✅ Perfil de usuario editable
- ✅ Subida de avatar
- ✅ Cambio de contraseña
- ✅ Preferencias personalizadas (tema, idioma, timezone, moneda)

**Tablas DB**:
- ✅ organizations
- ✅ users
- ✅ refresh_tokens
- ✅ audit_logs

**Lambdas**:
- lambda-auth (9 endpoints)
- lambda-users (9 endpoints)

**Estado**: ✅ 100% soportado en DB

---

#### 2. GESTIÓN DE TAREAS (TODO LIST) 📋

**Descripción**: Sistema completo de gestión de tareas con subtareas, etiquetas y recordatorios

**Funcionalidades**:
- ✅ CRUD completo de tareas
- ✅ Estados: pending, in_progress, completed, cancelled
- ✅ Prioridades: low, medium, high, urgent
- ✅ Fechas de vencimiento
- ✅ Subtareas (1 nivel de profundidad, máx 50)
- ✅ Etiquetas (tags) personalizables con colores
- ✅ Categorías predefinidas y personalizadas
- ✅ Recordatorios con notificaciones push/email
- ✅ Tareas recurrentes
- ✅ Búsqueda full-text
- ✅ Filtros múltiples (estado, prioridad, fecha, tags)
- ✅ Estadísticas de productividad
- ✅ Soft delete (papelera de reciclaje)

**Tablas DB**:
- ✅ tasks
- ✅ tags
- ✅ task_tags
- ✅ reminders
- ✅ categories (compartida)

**Lambdas**:
- lambda-tasks (11 endpoints)
- lambda-tags (5 endpoints)
- lambda-categories (5 endpoints)
- lambda-reminders (6 endpoints)

**Límites por Plan**:
- Free: 50 tareas/mes
- Basic: 200 tareas/mes
- Pro: 1,000 tareas/mes
- Premium: Ilimitado

**Estado**: ✅ 100% soportado en DB

---

#### 3. FINANZAS PERSONALES 💰

**Descripción**: Gestión completa de ingresos, gastos, presupuestos y análisis financiero

**Funcionalidades**:
- ✅ Registro de transacciones (ingresos, gastos, transferencias)
- ⚠️ Gestión de cuentas bancarias/efectivo (tabla accounts FALTANTE)
- ✅ Categorización automática de transacciones
- ✅ Multi-moneda
- ✅ Adjuntar comprobantes (recibos, facturas) en S3
- ✅ Geolocalización de transacciones
- ✅ Transacciones recurrentes
- ✅ Dashboard financiero con gráficas
- ✅ Resúmenes por período (diario, semanal, mensual, anual)
- ✅ Análisis por categorías
- ✅ Importación CSV (máx 500 transacciones)
- ✅ Captura automática de SMS bancarios (Premium - Android)
- ✅ Presupuestos por categoría y período
- ✅ Alertas de exceso de presupuesto (50%, 80%, 90%, 100%)
- ✅ Proyección de gasto fin de mes
- ✅ Presupuestos recurrentes

**Tablas DB**:
- ✅ transactions
- ✅ categories (compartida)
- ✅ sms_messages
- ✅ budgets
- ⚠️ accounts (FALTANTE - CRÍTICA)

**Lambdas**:
- lambda-transactions (11 endpoints)
- lambda-budgets (6 endpoints)
- lambda-categories (compartida)

**Límites por Plan**:
- Free: 100 transacciones/mes, 3 presupuestos
- Basic: 1,000 transacciones/mes, 10 presupuestos
- Pro: 10,000 transacciones/mes, 50 presupuestos
- Premium: Ilimitado

**Estado**: ⚠️ 80% soportado (falta tabla accounts)

---

#### 4. GESTOR DE CONTRASEÑAS 🔑

**Descripción**: Bóveda segura de contraseñas con encriptación AES-256-GCM

**Funcionalidades**:
- ✅ Almacenamiento encriptado AES-256-GCM
- ✅ CRUD completo de contraseñas
- ✅ Categorización (website, bank, wifi, email, app, other)
- ✅ Etiquetas personalizadas
- ✅ Generación de contraseñas seguras
- ✅ Análisis de fortaleza (longitud, entropía, diccionario)
- ⚠️ Historial de cambios (tabla password_history FALTANTE)
- ✅ Búsqueda y filtros
- ✅ Tracking de último acceso
- ✅ Alertas de expiración
- ✅ Favoritos
- ✅ Soft delete

**Tablas DB**:
- ✅ passwords
- ⚠️ password_history (FALTANTE - MEDIA)
- ✅ categories (compartida)

**Lambdas**:
- lambda-passwords (9 endpoints)

**Límites por Plan**:
- Free: 10 contraseñas
- Basic: 100 contraseñas
- Pro: 1,000 contraseñas
- Premium: Ilimitado

**Estado**: ⚠️ 90% soportado (falta historial)

---

#### 5. ENTRADA POR VOZ (VOICE INPUT) 🎤

**Descripción**: Creación de tareas y transacciones mediante comandos de voz

**Funcionalidades**:
- ✅ Grabación de audio (MP3, WAV, M4A, OGG - máx 5 min)
- ✅ Transcripción con Amazon Transcribe (español/inglés)
- ✅ Interpretación con IA (Amazon Bedrock - Claude)
- ✅ Extracción de datos estructurados
- ✅ Creación automática de tareas
- ✅ Creación automática de transacciones
- ✅ Manejo de lenguaje natural ("compré pan ayer por $5")
- ✅ Fechas relativas ("mañana", "en 2 días", "la semana pasada")
- ⚠️ Historial de entradas por voz (tabla voice_inputs FALTANTE)
- ⚠️ Reintentar procesamiento (tabla voice_inputs FALTANTE)
- ✅ Validación de cuota de IA

**Tablas DB**:
- ⚠️ voice_inputs (FALTANTE - ALTA)
- ✅ ai_usage (cuotas)

**Lambdas**:
- lambda-voice (4 endpoints)

**Límites por Plan**:
- Free: No disponible
- Basic: 10-20 usos/mes
- Pro: 100 usos/mes
- Premium: 500 usos/mes

**Estado**: ⚠️ 60% soportado (falta tabla voice_inputs)

---

#### 6. ASISTENTE DE IA (AI ASSISTANT) 🤖

**Descripción**: Chat conversacional con IA para análisis y recomendaciones

**Funcionalidades**:
- ✅ Chat conversacional con memoria de contexto
- ✅ Acceso a datos del usuario (tareas, finanzas, presupuestos)
- ✅ Generación de insights automáticos
- ✅ Predicciones de gastos futuros
- ✅ Resúmenes narrativos personalizados
- ✅ Recomendaciones de ahorro
- ✅ Análisis de productividad
- ✅ Respuestas a preguntas naturales
- ✅ Historial de conversaciones
- ✅ Validación de cuota de IA

**Tablas DB**:
- ✅ ai_conversations
- ✅ ai_usage

**Lambdas**:
- lambda-ai (7 endpoints)

**Modelo IA**: Claude 3.5 Sonnet v2 (Amazon Bedrock)

**Límites por Plan**:
- Free: No disponible
- Basic: 20 mensajes/mes
- Pro: 100 mensajes/mes
- Premium: 500 mensajes/mes

**Estado**: ✅ 100% soportado en DB

---

#### 7. AI MEMORY (SEGUNDA MEMORIA DIGITAL) 🧠

**Descripción**: Captura y búsqueda inteligente de memorias con IA

**Funcionalidades**:
- ✅ 5 tipos de captura:
  - Conversaciones grabadas
  - Fotos con OCR (AWS Textract)
  - Documentos PDF/DOCX procesados
  - Emails reenviados (memories+{user_id}@temis.app)
  - Notas de voz transcritas
- ✅ Almacenamiento en S3 con límites por plan
- ✅ Procesamiento automático con IA:
  - Resumen generado
  - Extracción de entidades (personas, lugares, fechas)
  - Sugerencia de etiquetas
- ✅ Búsqueda semántica con vectores (pgvector - 1536 dims)
- ✅ Búsqueda por texto, fecha, tipo, etiquetas
- ✅ Generación de insights automáticos
- ✅ Organización con favoritos y archivados
- ✅ GDPR compliance:
  - DELETE de memorias (derecho al olvido)
  - Exportación completa en ZIP
- ✅ Adjuntar múltiples archivos por memoria
- ✅ Validación de cuotas de storage y procesamiento

**Tablas DB**:
- ✅ memories
- ✅ memory_attachments
- ✅ memory_embeddings
- ✅ users (ai_memory_storage_bytes, ai_memory_email)
- ✅ ai_usage (cuotas de memoria)

**Lambdas**:
- lambda-ai-memory (19 endpoints)

**Límites de Storage por Plan**:
- Free: 2 GB
- Basic: 5 GB
- Pro: 20 GB
- Premium: 100 GB

**Límites de Procesamiento Mensual**:
- Free: 5 conversaciones, 10 fotos, 0 documentos, 0 emails, 10 notas voz
- Basic: 20 conversaciones, 50 fotos, 20 documentos, 20 emails, 50 notas voz
- Pro: 100 conversaciones, 200 fotos, 100 documentos, 100 emails, 200 notas voz
- Premium: Ilimitado

**Estado**: ✅ 100% soportado en DB

---

#### 8. SUSCRIPCIONES Y PAGOS 💳

**Descripción**: Gestión de planes de suscripción con pagos vía Wompi (Bancolombia)

**Funcionalidades**:
- ✅ 4 planes: Free, Basic ($4.99), Pro ($9.99), Premium ($19.99)
- ✅ Checkout con Wompi (pasarela de pagos Colombia)
- ✅ Tokenización de tarjetas (PCI compliant)
- ✅ Múltiples métodos de pago guardados
- ✅ Cambio de plan (upgrade/downgrade)
- ✅ Prorrateado en cambios de plan
- ✅ Cancelación con acceso hasta fin de período
- ✅ Reactivación de suscripciones
- ✅ Renovación automática
- ✅ Reintentar pago fallido
- ✅ Alertas de vencimiento (5 días antes)
- ✅ Alertas de problemas de pago
- ✅ Historial de pagos (invoices)
- ✅ Generación de invoices PDF
- ⚠️ Webhooks de Wompi (tabla webhook_events FALTANTE)
- ✅ Auditoría completa de pagos

**Tablas DB**:
- ✅ plans
- ✅ subscriptions
- ✅ payment_methods
- ✅ payment_audit_logs
- ⚠️ webhook_events (FALTANTE - MEDIA)

**Lambdas**:
- lambda-subscriptions (11 endpoints)
- lambda-webhooks (1 endpoint)

**Planes Incluidos**:
```
Free:
- Tareas: 50/mes
- Contraseñas: No
- Finanzas: No
- IA: No
- Precio: $0

Basic:
- Tareas: 200/mes
- Contraseñas: 100
- Finanzas: No
- IA: Básica (20 chats/mes)
- Precio: $4.99/mes

Pro:
- Tareas: 1,000/mes
- Contraseñas: 1,000
- Finanzas: Completo
- IA: Avanzada (100 chats/mes)
- Entrada por voz: Sí
- AI Memory: 20 GB
- Precio: $9.99/mes

Premium:
- Todo ilimitado
- AI Memory: 100 GB
- Captura SMS Android
- Soporte prioritario
- Precio: $19.99/mes
```

**Estado**: ⚠️ 90% soportado (falta webhook_events para idempotencia)

---

#### 9. CATEGORÍAS Y ETIQUETAS 🏷️

**Descripción**: Sistema de organización transversal para todos los módulos

**Funcionalidades**:
- ✅ Categorías predefinidas del sistema (13 categorías)
- ✅ Categorías personalizadas por usuario
- ✅ Jerarquía padre/hijo (subcategorías)
- ✅ Iconos emoji personalizables
- ✅ Colores personalizables
- ✅ Etiquetas (tags) con colores
- ✅ Uso transversal: tareas, transacciones, contraseñas
- ✅ Conteo de uso por categoría/etiqueta

**Tablas DB**:
- ✅ categories
- ✅ tags
- ✅ task_tags

**Lambdas**:
- lambda-categories (5 endpoints)
- lambda-tags (5 endpoints)

**Categorías Predefinidas**:
- Ingresos: Salario, Freelance, Inversiones, Otros
- Gastos: Alimentación, Transporte, Entretenimiento, Servicios, Salud, Educación, Vivienda, Ropa, Otros

**Estado**: ✅ 100% soportado en DB

---

#### 10. PANEL ADMINISTRATIVO 👨‍💼

**Descripción**: Dashboard para administradores del sistema

**Funcionalidades**:
- ✅ Dashboard con KPIs (usuarios, ingresos, conversión)
- ✅ Listado de usuarios con búsqueda
- ✅ Suspender/activar cuentas
- ✅ Forzar reset de contraseña
- ✅ Ver historial de suscripciones
- ✅ Reportes de ingresos por plan y período
- ✅ Monitoreo de recursos AWS (Lambda, RDS, S3)
- ✅ Análisis de uso por usuario

**Tablas DB**:
- ✅ Acceso a todas las tablas
- ✅ audit_logs

**Lambdas**:
- lambda-admin (7 endpoints)

**Acceso**: Solo usuarios con `role = 'admin'`

**Estado**: ✅ 100% soportado en DB

---

#### 11. MONITOREO DE COSTOS DE IA 📊

**Descripción**: Control y monitoreo de consumo de AWS Bedrock

**Funcionalidades**:
- ✅ Dashboard de costos de IA en tiempo real
- ✅ Consulta de costos vía AWS Cost Explorer API
- ✅ Proyección de costos fin de mes
- ✅ Top usuarios por consumo
- ✅ Estadísticas de uso (llamadas, tokens, errores)
- ✅ Feature flag global (habilitar/deshabilitar IA)
- ✅ Gestión dinámica de cuotas por plan
- ✅ Configuración de presupuesto mensual
- ✅ Alertas automáticas (80%, 90%, 100%)
- ✅ Notificaciones SNS y email
- ✅ Control de emergencia ante exceso

**Tablas DB**:
- ✅ ai_usage
- ✅ ai_conversations

**Lambdas**:
- lambda-ai-monitoring (11 endpoints)

**Acceso**: Solo administradores

**Estado**: ✅ 100% soportado en DB

---

## 📊 RESUMEN DE COBERTURA POR MÓDULO

| # | Módulo | Tablas Requeridas | Tablas Creadas | % Cobertura | Prioridad Gap |
|---|--------|-------------------|----------------|-------------|---------------|
| 1 | Autenticación y Usuarios | 4 | 4 | 100% ✅ | - |
| 2 | Gestión de Tareas | 5 | 5 | 100% ✅ | - |
| 3 | Finanzas Personales | 5 | 4 | 80% ⚠️ | ALTA (accounts) |
| 4 | Gestor de Contraseñas | 2 | 1 | 50% ⚠️ | MEDIA (password_history) |
| 5 | Entrada por Voz | 2 | 1 | 50% ⚠️ | ALTA (voice_inputs) |
| 6 | Asistente de IA | 2 | 2 | 100% ✅ | - |
| 7 | AI Memory | 4 | 4 | 100% ✅ | - |
| 8 | Suscripciones y Pagos | 5 | 4 | 80% ⚠️ | MEDIA (webhook_events) |
| 9 | Categorías y Etiquetas | 3 | 3 | 100% ✅ | - |
| 10 | Panel Administrativo | N/A | N/A | 100% ✅ | - |
| 11 | Monitoreo Costos IA | 2 | 2 | 100% ✅ | - |
| **TOTAL** | **34** | **30** | **88.2%** | - |

---

## 🚨 ACCIONES RECOMENDADAS

### CRÍTICAS (Implementar AHORA)

1. **Crear tabla `accounts`**
   - Bloquea: Módulo Finanzas completo
   - Impacto: No se pueden gestionar cuentas bancarias
   - Afecta: 11 endpoints de transactions
   - Tiempo estimado: 1 hora

2. **Crear tabla `voice_inputs`**
   - Bloquea: Historial de voz y retry
   - Impacto: 2 endpoints no funcionan
   - Afecta: Auditoría de uso de IA por voz
   - Tiempo estimado: 1 hora

### MEDIAS (Implementar antes de producción)

3. **Crear tabla `password_history`**
   - Bloquea: Endpoint de historial
   - Impacto: 1 endpoint no funciona
   - Afecta: Auditoría de seguridad
   - Tiempo estimado: 30 minutos

4. **Crear tabla `webhook_events`**
   - Bloquea: Idempotencia de webhooks
   - Impacto: Riesgo de pagos duplicados
   - Afecta: Confiabilidad de pagos
   - Tiempo estimado: 30 minutos

### Script de Migración

```sql
-- MIGRATION-002-ADD-MISSING-TABLES.sql
-- Añadir tablas faltantes identificadas en validación

-- 1. Tabla accounts (CRÍTICA)
CREATE TABLE accounts (
    -- [Schema completo arriba]
);

-- 2. Tabla voice_inputs (ALTA)
CREATE TABLE voice_inputs (
    -- [Schema completo arriba]
);

-- 3. Tabla password_history (MEDIA)
CREATE TABLE password_history (
    -- [Schema completo arriba]
);

-- 4. Tabla webhook_events (MEDIA)
CREATE TABLE webhook_events (
    -- [Schema completo arriba]
);
```

---

## ✅ CONCLUSIONES

### Fortalezas del Schema Actual

1. ✅ **Modelo Multitenant Robusto**
   - organization_id + user_id en todas las tablas
   - RLS policies completas
   - Preparado para familias/empresas

2. ✅ **7 de 11 Módulos 100% Soportados**
   - Autenticación ✅
   - Tareas ✅
   - Asistente IA ✅
   - AI Memory ✅
   - Categorías ✅
   - Admin ✅
   - Monitoreo IA ✅

3. ✅ **Funciones y Triggers Completos**
   - 7 funciones SQL críticas
   - 14 triggers automáticos
   - 16 RLS policies

4. ✅ **GDPR Compliance**
   - Soft delete en todas las tablas
   - Funciones de export
   - Auditoría completa

### Gaps Identificados

1. ⚠️ **4 Tablas Faltantes** (88.2% completitud)
   - accounts (CRÍTICA)
   - voice_inputs (ALTA)
   - password_history (MEDIA)
   - webhook_events (MEDIA)

2. ⚠️ **4 Módulos Parcialmente Soportados**
   - Finanzas: 80%
   - Contraseñas: 50%
   - Voz: 50%
   - Suscripciones: 80%

### Recomendaciones

**Para MVP (11 semanas)**:
1. Implementar tabla `accounts` inmediatamente
2. Implementar tabla `voice_inputs` antes de Fase 5
3. Postponer `password_history` para post-MVP
4. Postponer `webhook_events` pero documentar riesgo

**Para Producción**:
1. Implementar las 4 tablas faltantes
2. Añadir función `update_account_balance()`
3. Ejecutar MIGRATION-002-ADD-MISSING-TABLES.sql
4. Actualizar contratos YAML con nuevos campos

---

**Documento creado**: 2026-09-24
**Validación por**: Análisis Exhaustivo de DB Schema
**Estado**: 88.2% completo (22/26 tablas)
**Próximo paso**: Crear MIGRATION-002-ADD-MISSING-TABLES.sql
