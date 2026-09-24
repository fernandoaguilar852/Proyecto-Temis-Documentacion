-- ============================================================================
-- MIGRATION-002: AÑADIR TABLAS FALTANTES PARA MÓDULOS CORE
-- ============================================================================
-- Fecha: 2026-09-24
-- Versión: 1.0
-- Descripción: Añade 4 tablas identificadas como faltantes en validación:
--              1. accounts (CRÍTICA - Módulo Finanzas)
--              2. voice_inputs (ALTA - Módulo Voice)
--              3. password_history (MEDIA - Módulo Passwords)
--              4. webhook_events (MEDIA - Módulo Webhooks)
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. TABLA: accounts
-- ============================================================================
-- Propósito: Gestión de cuentas bancarias, efectivo, tarjetas de crédito
-- Módulo: Finanzas Personales
-- Prioridad: CRÍTICA
-- ============================================================================

CREATE TABLE IF NOT EXISTS accounts (
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

    -- Detalles bancarios (opcional, encriptado en app)
    bank_name               VARCHAR(255),
    account_number_last4    VARCHAR(4),  -- Últimos 4 dígitos

    -- Personalización
    color                   VARCHAR(7) DEFAULT '#3B82F6',
    icon                    VARCHAR(50) DEFAULT '💳',

    -- Estados
    is_active               BOOLEAN DEFAULT true,
    is_included_in_total    BOOLEAN DEFAULT true,  -- Incluir en balance total

    -- Metadatos
    metadata                JSONB DEFAULT '{}',
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMP WITH TIME ZONE  -- Soft delete
);

-- Índices para accounts
CREATE INDEX idx_accounts_organization_user ON accounts(organization_id, user_id);
CREATE INDEX idx_accounts_type ON accounts(type);
CREATE INDEX idx_accounts_is_active ON accounts(is_active);
CREATE INDEX idx_accounts_currency ON accounts(currency);
CREATE INDEX idx_accounts_deleted_at ON accounts(deleted_at) WHERE deleted_at IS NULL;

-- RLS Policy para accounts
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY accounts_isolation_policy ON accounts
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );

-- Trigger para updated_at
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE accounts IS 'Cuentas bancarias y métodos de almacenamiento de dinero - DEBE filtrar por organization_id AND user_id';
COMMENT ON COLUMN accounts.type IS 'Tipos: bank, cash, credit_card, investment, savings, other';
COMMENT ON COLUMN accounts.current_balance IS 'Balance actual calculado automáticamente con transacciones';
COMMENT ON COLUMN accounts.is_included_in_total IS 'Si false, no se incluye en cálculos de patrimonio total';

-- ============================================================================
-- 2. TABLA: voice_inputs
-- ============================================================================
-- Propósito: Registro de entradas por voz procesadas (auditoría y retry)
-- Módulo: Entrada por Voz
-- Prioridad: ALTA
-- ============================================================================

CREATE TABLE IF NOT EXISTS voice_inputs (
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
    ai_interpretation       JSONB,  -- Datos estructurados extraídos
    ai_model_used           VARCHAR(100) DEFAULT 'anthropic.claude-3-5-sonnet-20241022-v2:0',
    ai_prompt_tokens        INTEGER DEFAULT 0,
    ai_completion_tokens    INTEGER DEFAULT 0,
    ai_total_tokens         INTEGER GENERATED ALWAYS AS (ai_prompt_tokens + ai_completion_tokens) STORED,
    ai_cost_usd             DECIMAL(10,6) DEFAULT 0.000000,

    -- Resultado de la creación
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

-- Índices para voice_inputs
CREATE INDEX idx_voice_inputs_organization_user ON voice_inputs(organization_id, user_id);
CREATE INDEX idx_voice_inputs_status ON voice_inputs(status);
CREATE INDEX idx_voice_inputs_feature_type ON voice_inputs(feature_type);
CREATE INDEX idx_voice_inputs_created_at ON voice_inputs(created_at DESC);
CREATE INDEX idx_voice_inputs_user_created_at ON voice_inputs(user_id, created_at DESC);

-- RLS Policy para voice_inputs
ALTER TABLE voice_inputs ENABLE ROW LEVEL SECURITY;

CREATE POLICY voice_inputs_isolation_policy ON voice_inputs
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );

COMMENT ON TABLE voice_inputs IS 'Registro de entradas por voz procesadas con IA - DEBE filtrar por organization_id AND user_id';
COMMENT ON COLUMN voice_inputs.status IS 'Estados: processing (en proceso), completed (exitoso), failed (error)';
COMMENT ON COLUMN voice_inputs.feature_type IS 'Tipo de acción: voice_task (crear tarea) o voice_finance (crear transacción)';
COMMENT ON COLUMN voice_inputs.retry_count IS 'Número de reintentos realizados (máximo 3)';

-- ============================================================================
-- 3. TABLA: password_history
-- ============================================================================
-- Propósito: Historial de cambios de contraseñas para auditoría
-- Módulo: Gestor de Contraseñas
-- Prioridad: MEDIA
-- ============================================================================

CREATE TABLE IF NOT EXISTS password_history (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_id             UUID NOT NULL REFERENCES passwords(id) ON DELETE CASCADE,

    -- Contraseña anterior (encriptada)
    encrypted_password      BYTEA NOT NULL,  -- AES-256-GCM
    encryption_iv           BYTEA NOT NULL,  -- Initialization Vector
    encryption_tag          BYTEA,  -- Authentication Tag (GCM)

    -- Detalles del cambio
    changed_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_reason          VARCHAR(255),  -- 'manual', 'expired', 'compromised', 'forgot', 'policy'
    changed_by_user_id      UUID REFERENCES users(id),

    -- IP y device tracking
    ip_address              INET,
    user_agent              TEXT,

    -- Metadatos
    metadata                JSONB DEFAULT '{}'
);

-- Índices para password_history
CREATE INDEX idx_password_history_organization_user ON password_history(organization_id, user_id);
CREATE INDEX idx_password_history_password_id ON password_history(password_id);
CREATE INDEX idx_password_history_changed_at ON password_history(changed_at DESC);
CREATE INDEX idx_password_history_user_changed_at ON password_history(user_id, changed_at DESC);

-- RLS Policy para password_history
ALTER TABLE password_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY password_history_isolation_policy ON password_history
    FOR ALL
    USING (
        organization_id::TEXT = current_setting('app.current_organization_id', TRUE)
        AND user_id::TEXT = current_setting('app.current_user_id', TRUE)
    );

COMMENT ON TABLE password_history IS 'Historial de cambios de contraseñas guardadas - DEBE filtrar por organization_id AND user_id';
COMMENT ON COLUMN password_history.encrypted_password IS 'Contraseña anterior encriptada con AES-256-GCM';
COMMENT ON COLUMN password_history.changed_reason IS 'Motivo del cambio: manual, expired, compromised, forgot, policy';

-- ============================================================================
-- 4. TABLA: webhook_events
-- ============================================================================
-- Propósito: Registro de webhooks recibidos para idempotencia
-- Módulo: Webhooks (Wompi)
-- Prioridad: MEDIA
-- ============================================================================

CREATE TABLE IF NOT EXISTS webhook_events (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Identificación del evento
    event_id                VARCHAR(255) NOT NULL UNIQUE,  -- ID único del proveedor
    event_type              VARCHAR(100) NOT NULL,  -- 'transaction.updated', 'payment_source.created', etc
    provider                VARCHAR(50) NOT NULL DEFAULT 'wompi',  -- 'wompi', 'stripe', etc

    -- Payload completo
    payload                 JSONB NOT NULL,
    signature               VARCHAR(500),  -- HMAC signature del webhook
    signature_verified      BOOLEAN DEFAULT false,

    -- Procesamiento
    status                  VARCHAR(50) DEFAULT 'pending',
                            CHECK (status IN ('pending', 'processing', 'processed', 'failed', 'duplicate', 'invalid_signature')),

    processed_at            TIMESTAMP WITH TIME ZONE,
    error_message           TEXT,
    error_code              VARCHAR(100),
    retry_count             INTEGER DEFAULT 0,

    -- Relación con suscripción (si aplica)
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

-- Índices para webhook_events
CREATE UNIQUE INDEX idx_webhook_events_event_id ON webhook_events(event_id);
CREATE INDEX idx_webhook_events_provider_event_type ON webhook_events(provider, event_type);
CREATE INDEX idx_webhook_events_status ON webhook_events(status);
CREATE INDEX idx_webhook_events_created_at ON webhook_events(created_at DESC);
CREATE INDEX idx_webhook_events_subscription_id ON webhook_events(subscription_id) WHERE subscription_id IS NOT NULL;
CREATE INDEX idx_webhook_events_organization ON webhook_events(organization_id) WHERE organization_id IS NOT NULL;

COMMENT ON TABLE webhook_events IS 'Registro de webhooks recibidos para idempotencia - NO requiere RLS (eventos externos)';
COMMENT ON COLUMN webhook_events.event_id IS 'ID único del evento del proveedor (Wompi event ID)';
COMMENT ON COLUMN webhook_events.status IS 'Estados: pending, processing, processed, failed, duplicate, invalid_signature';
COMMENT ON COLUMN webhook_events.signature_verified IS 'true si la firma HMAC fue validada correctamente';

-- ============================================================================
-- 5. FUNCIÓN: Actualizar balance de cuenta
-- ============================================================================

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
    ELSE
        RAISE EXCEPTION 'Invalid operation: %. Use "add" or "subtract"', p_operation;
    END IF;

    IF v_new_balance IS NULL THEN
        RAISE EXCEPTION 'Account not found: %', p_account_id;
    END IF;

    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_account_balance IS 'Actualiza el balance de una cuenta sumando o restando un monto';

-- ============================================================================
-- 6. ACTUALIZAR transactions para incluir account_id
-- ============================================================================

-- Añadir columna account_id a transactions (si no existe)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'transactions' AND column_name = 'account_id'
    ) THEN
        ALTER TABLE transactions
        ADD COLUMN account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

        CREATE INDEX idx_transactions_account_id ON transactions(account_id);

        COMMENT ON COLUMN transactions.account_id IS 'Cuenta asociada a la transacción (bank, cash, credit_card, etc)';
    END IF;
END $$;

-- ============================================================================
-- 7. INSERTAR CUENTAS POR DEFECTO PARA USUARIOS EXISTENTES
-- ============================================================================

-- Crear cuenta "Efectivo" para todos los usuarios existentes que no tengan cuentas
INSERT INTO accounts (organization_id, user_id, name, type, currency, initial_balance, current_balance, color, icon)
SELECT
    u.organization_id,
    u.id AS user_id,
    'Efectivo' AS name,
    'cash' AS type,
    COALESCE((u.preferences->>'currency')::VARCHAR, 'COP') AS currency,
    0.00 AS initial_balance,
    0.00 AS current_balance,
    '#10B981' AS color,
    '💵' AS icon
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM accounts a
    WHERE a.user_id = u.id
)
AND u.is_active = true
AND u.deleted_at IS NULL;

-- ============================================================================
-- 8. VISTAS ÚTILES
-- ============================================================================

-- Vista: accounts_with_balance
CREATE OR REPLACE VIEW accounts_with_balance AS
SELECT
    a.*,
    COALESCE(SUM(CASE
        WHEN t.type = 'income' THEN t.amount
        WHEN t.type = 'expense' THEN -t.amount
        ELSE 0
    END), 0) + a.initial_balance AS calculated_balance,
    COUNT(t.id) AS transaction_count
FROM accounts a
LEFT JOIN transactions t ON t.account_id = a.id AND t.deleted_at IS NULL
WHERE a.deleted_at IS NULL
GROUP BY a.id;

COMMENT ON VIEW accounts_with_balance IS 'Cuentas con balance calculado desde transacciones';

-- ============================================================================
-- VALIDACIONES FINALES
-- ============================================================================

-- Verificar que todas las tablas fueron creadas
DO $$
DECLARE
    v_missing_tables TEXT[];
BEGIN
    SELECT ARRAY_AGG(table_name)
    INTO v_missing_tables
    FROM (VALUES
        ('accounts'),
        ('voice_inputs'),
        ('password_history'),
        ('webhook_events')
    ) AS required(table_name)
    WHERE NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = required.table_name
    );

    IF v_missing_tables IS NOT NULL THEN
        RAISE EXCEPTION 'Missing tables: %', array_to_string(v_missing_tables, ', ');
    ELSE
        RAISE NOTICE '✅ All 4 tables created successfully';
    END IF;
END $$;

-- Verificar índices
DO $$
DECLARE
    v_index_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND tablename IN ('accounts', 'voice_inputs', 'password_history', 'webhook_events');

    RAISE NOTICE '✅ Created % indexes for new tables', v_index_count;
END $$;

-- Verificar RLS policies
DO $$
DECLARE
    v_policy_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename IN ('accounts', 'voice_inputs', 'password_history');

    RAISE NOTICE '✅ Created % RLS policies for new tables', v_policy_count;
END $$;

COMMIT;

-- ============================================================================
-- RESUMEN DE MIGRACIÓN
-- ============================================================================
-- Tablas añadidas: 4
--   1. accounts (CRÍTICA - Módulo Finanzas)
--   2. voice_inputs (ALTA - Módulo Voice)
--   3. password_history (MEDIA - Módulo Passwords)
--   4. webhook_events (MEDIA - Módulo Webhooks)
--
-- Funciones añadidas: 1
--   - update_account_balance()
--
-- Columnas actualizadas: 1
--   - transactions.account_id
--
-- Vistas creadas: 1
--   - accounts_with_balance
--
-- Índices creados: ~20
-- RLS Policies creadas: 3
--
-- Estado final: DATABASE-SCHEMA completitud = 100% (26/26 tablas)
-- ============================================================================
