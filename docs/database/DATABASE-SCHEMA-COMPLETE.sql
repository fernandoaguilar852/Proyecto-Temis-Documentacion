-- ============================================================================
-- TEMIS - SCHEMA COMPLETO DE BASE DE DATOS POSTGRESQL 15.x
-- ============================================================================
-- Versión: 2.0.0
-- Fecha: 2026-09-24
-- Autor: Equipo Backend TEMIS
--
-- CAMBIOS IMPORTANTES:
-- - Primary Keys: INTEGER AUTOINCREMENT (en vez de UUID)
-- - Incluye TODAS las tablas necesarias (25 tablas)
-- - Incluye gaps resueltos: accounts, password_history, webhook_events
-- - NO incluye: voice_inputs (audios solo en S3, no en DB)
--
-- MÓDULOS:
-- 1. Sistema y Autenticación (4 tablas)
-- 2. Suscripciones y Pagos (5 tablas)
-- 3. Tareas (4 tablas)
-- 4. Finanzas (5 tablas)
-- 5. Contraseñas (2 tablas)
-- 6. IA (2 tablas)
-- 7. AI Memory (3 tablas)
-- 8. Auditoría (1 tabla)
-- ============================================================================

BEGIN;

-- ============================================================================
-- EXTENSIONES POSTGRESQL
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";        -- Funciones de encriptación
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- Búsquedas fuzzy/similitud
CREATE EXTENSION IF NOT EXISTS "vector";          -- pgvector para búsqueda semántica (AI Memory)

COMMENT ON EXTENSION pgcrypto IS 'Funciones criptográficas para encriptación de contraseñas';
COMMENT ON EXTENSION pg_trgm IS 'Búsqueda por similitud y fuzzy search en texto';
COMMENT ON EXTENSION vector IS 'Vectores para búsqueda semántica con IA (embeddings)';

-- ============================================================================
-- FUNCIONES AUXILIARES
-- ============================================================================

-- Función: Actualizar columna updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Trigger function para actualizar updated_at automáticamente';

-- ============================================================================
-- MÓDULO 1: SISTEMA Y AUTENTICACIÓN (4 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: organizations
-- ----------------------------------------------------------------------------
CREATE TABLE organizations (
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    slug                VARCHAR(100) NOT NULL UNIQUE,
    timezone            VARCHAR(50) DEFAULT 'America/Bogota',
    locale              VARCHAR(10) DEFAULT 'es_CO',
    is_active           BOOLEAN DEFAULT true,
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_organizations_slug ON organizations(slug);
CREATE INDEX idx_organizations_is_active ON organizations(is_active);
CREATE INDEX idx_organizations_deleted_at ON organizations(deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE organizations IS 'Organizaciones - Modelo Netflix: 1 org = múltiples usuarios (familia/empresa)';
COMMENT ON COLUMN organizations.slug IS 'Identificador único legible (ej: familia-garcia)';

-- ----------------------------------------------------------------------------
-- Tabla: users
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    id                      SERIAL PRIMARY KEY,
    organization_id         INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    email                   VARCHAR(255) NOT NULL UNIQUE,
    password_hash           VARCHAR(255) NOT NULL,
    name                    VARCHAR(255) NOT NULL,
    avatar_url              TEXT,
    phone                   VARCHAR(20),
    role                    VARCHAR(50) NOT NULL DEFAULT 'user',
                            CHECK (role IN ('superadmin', 'admin', 'user')),
    is_active               BOOLEAN DEFAULT true,
    is_email_verified       BOOLEAN DEFAULT false,
    email_verified_at       TIMESTAMP WITH TIME ZONE,
    preferences             JSONB DEFAULT '{"theme": "light", "locale": "es_CO", "currency": "COP", "timezone": "America/Bogota"}',

    -- AI Memory
    ai_memory_storage_bytes BIGINT DEFAULT 0,
    ai_memory_email         VARCHAR(255) UNIQUE,  -- memories+{user_id}@temis.app

    last_login_at           TIMESTAMP WITH TIME ZONE,
    password_changed_at     TIMESTAMP WITH TIME ZONE,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_organization_id ON users(organization_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE users IS 'Usuarios del sistema - Autenticación JWT RS256 sin AWS Cognito';
COMMENT ON COLUMN users.password_hash IS 'Hash bcrypt de la contraseña (cost factor 10)';
COMMENT ON COLUMN users.role IS 'superadmin: acceso total, admin: gestión org, user: usuario normal';
COMMENT ON COLUMN users.ai_memory_email IS 'Email único para reenvío de emails a AI Memory (memories+123@temis.app)';

-- ----------------------------------------------------------------------------
-- Tabla: refresh_tokens
-- ----------------------------------------------------------------------------
CREATE TABLE refresh_tokens (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash          VARCHAR(255) NOT NULL UNIQUE,
    device_id           VARCHAR(255),
    device_name         VARCHAR(255),
    ip_address          INET,
    user_agent          TEXT,
    expires_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked          BOOLEAN DEFAULT false,
    revoked_at          TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_organization_user ON refresh_tokens(organization_id, user_id);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_refresh_tokens_is_revoked ON refresh_tokens(is_revoked);

COMMENT ON TABLE refresh_tokens IS 'Tokens de refresco JWT - Duración 7 días - Renovación de access tokens';
COMMENT ON COLUMN refresh_tokens.token_hash IS 'Hash SHA-256 del refresh token (nunca almacenar en texto plano)';

-- ----------------------------------------------------------------------------
-- Tabla: audit_logs
-- ----------------------------------------------------------------------------
CREATE TABLE audit_logs (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action              VARCHAR(100) NOT NULL,
    resource_type       VARCHAR(100) NOT NULL,
    resource_id         INTEGER,
    changes             JSONB,
    ip_address          INET,
    user_agent          TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_organization_user ON audit_logs(organization_id, user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

COMMENT ON TABLE audit_logs IS 'Registro de auditoría de todas las acciones críticas del sistema';
COMMENT ON COLUMN audit_logs.action IS 'Acción realizada: create, update, delete, login, logout, etc';
COMMENT ON COLUMN audit_logs.changes IS 'JSON con {before: {...}, after: {...}}';

-- ============================================================================
-- MÓDULO 2: SUSCRIPCIONES Y PAGOS (5 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: plans
-- ----------------------------------------------------------------------------
CREATE TABLE plans (
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(100) NOT NULL UNIQUE,
    slug                VARCHAR(50) NOT NULL UNIQUE,
    description         TEXT,
    price_monthly       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    price_yearly        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    trial_days          INTEGER DEFAULT 14,
    is_active           BOOLEAN DEFAULT true,
    features            JSONB DEFAULT '{}',
    sort_order          INTEGER DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_plans_slug ON plans(slug);
CREATE INDEX idx_plans_is_active ON plans(is_active);

CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE plans IS 'Planes de suscripción - Tabla global (no multitenant)';

-- Insertar planes iniciales
INSERT INTO plans (name, slug, price_monthly, price_yearly, features, sort_order) VALUES
('Free', 'free', 0.00, 0.00, '{"tasks": 50, "transactions": 100, "passwords": 0, "ai_quota": 0, "storage_gb": 0}', 1),
('Basic', 'basic', 4.99, 49.90, '{"tasks": 200, "transactions": 1000, "passwords": 100, "ai_quota": 20, "storage_gb": 5}', 2),
('Pro', 'pro', 9.99, 99.90, '{"tasks": 1000, "transactions": 10000, "passwords": 1000, "ai_quota": 100, "storage_gb": 20}', 3),
('Premium', 'premium', 19.99, 199.90, '{"tasks": -1, "transactions": -1, "passwords": -1, "ai_quota": 500, "storage_gb": 100}', 4);

-- ----------------------------------------------------------------------------
-- Tabla: subscriptions
-- ----------------------------------------------------------------------------
CREATE TABLE subscriptions (
    id                      SERIAL PRIMARY KEY,
    organization_id         INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id                 INTEGER NOT NULL REFERENCES plans(id),
    status                  VARCHAR(50) NOT NULL DEFAULT 'trial',
                            CHECK (status IN ('trial', 'active', 'past_due', 'expired', 'cancelled', 'suspended')),
    billing_cycle           VARCHAR(20) NOT NULL DEFAULT 'monthly',
                            CHECK (billing_cycle IN ('monthly', 'yearly')),
    current_period_start    TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_end      TIMESTAMP WITH TIME ZONE NOT NULL,
    trial_end               TIMESTAMP WITH TIME ZONE,
    cancelled_at            TIMESTAMP WITH TIME ZONE,
    cancel_at_period_end    BOOLEAN DEFAULT false,
    metadata                JSONB DEFAULT '{}',
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscriptions_organization_user ON subscriptions(organization_id, user_id);
CREATE INDEX idx_subscriptions_plan_id ON subscriptions(plan_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_current_period_end ON subscriptions(current_period_end);

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE subscriptions IS 'Suscripciones activas - 1 suscripción por organización (modelo Netflix)';
COMMENT ON COLUMN subscriptions.status IS 'trial: período de prueba, active: pagando, past_due: pago atrasado, expired: expirada, cancelled: cancelada, suspended: suspendida';

-- ----------------------------------------------------------------------------
-- Tabla: payment_methods
-- ----------------------------------------------------------------------------
CREATE TABLE payment_methods (
    id                      SERIAL PRIMARY KEY,
    organization_id         INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    wompi_payment_source_id VARCHAR(255) NOT NULL UNIQUE,  -- Token de Wompi
    type                    VARCHAR(50) NOT NULL,  -- 'CARD', 'NEQUI', 'PSE'
    card_brand              VARCHAR(50),  -- 'VISA', 'MASTERCARD', 'AMEX'
    card_last4              VARCHAR(4),
    card_exp_month          INTEGER,
    card_exp_year           INTEGER,
    is_default              BOOLEAN DEFAULT false,
    is_active               BOOLEAN DEFAULT true,
    metadata                JSONB DEFAULT '{}',
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_payment_methods_organization_user ON payment_methods(organization_id, user_id);
CREATE INDEX idx_payment_methods_wompi_id ON payment_methods(wompi_payment_source_id);
CREATE INDEX idx_payment_methods_is_default ON payment_methods(is_default);

CREATE TRIGGER update_payment_methods_updated_at BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE payment_methods IS 'Métodos de pago tokenizados (PCI compliant) - Solo almacenamos tokens de Wompi';
COMMENT ON COLUMN payment_methods.wompi_payment_source_id IS 'Token de Wompi - NUNCA almacenar número de tarjeta completo';

-- ----------------------------------------------------------------------------
-- Tabla: payment_audit_logs
-- ----------------------------------------------------------------------------
CREATE TABLE payment_audit_logs (
    id                      SERIAL PRIMARY KEY,
    organization_id         INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id         INTEGER REFERENCES subscriptions(id),
    payment_method_id       INTEGER REFERENCES payment_methods(id),
    wompi_transaction_id    VARCHAR(255),
    type                    VARCHAR(50) NOT NULL,  -- 'charge', 'refund', 'failed'
    status                  VARCHAR(50) NOT NULL,  -- 'pending', 'approved', 'declined', 'error'
    amount                  DECIMAL(10,2) NOT NULL,
    currency                VARCHAR(3) DEFAULT 'COP',
    wompi_response          JSONB,
    error_message           TEXT,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_audit_logs_organization_user ON payment_audit_logs(organization_id, user_id);
CREATE INDEX idx_payment_audit_logs_subscription_id ON payment_audit_logs(subscription_id);
CREATE INDEX idx_payment_audit_logs_wompi_transaction_id ON payment_audit_logs(wompi_transaction_id);
CREATE INDEX idx_payment_audit_logs_status ON payment_audit_logs(status);
CREATE INDEX idx_payment_audit_logs_created_at ON payment_audit_logs(created_at DESC);

COMMENT ON TABLE payment_audit_logs IS 'Auditoría completa de todos los intentos de pago y transacciones con Wompi';

-- ----------------------------------------------------------------------------
-- Tabla: webhook_events (NUEVO - Gap resuelto)
-- ----------------------------------------------------------------------------
CREATE TABLE webhook_events (
    id                      SERIAL PRIMARY KEY,
    event_id                VARCHAR(255) NOT NULL UNIQUE,  -- ID único del proveedor
    event_type              VARCHAR(100) NOT NULL,
    provider                VARCHAR(50) NOT NULL DEFAULT 'wompi',
    payload                 JSONB NOT NULL,
    signature               VARCHAR(500),
    signature_verified      BOOLEAN DEFAULT false,
    status                  VARCHAR(50) DEFAULT 'pending',
                            CHECK (status IN ('pending', 'processing', 'processed', 'failed', 'duplicate', 'invalid_signature')),
    processed_at            TIMESTAMP WITH TIME ZONE,
    error_message           TEXT,
    retry_count             INTEGER DEFAULT 0,
    organization_id         INTEGER REFERENCES organizations(id),
    user_id                 INTEGER REFERENCES users(id),
    subscription_id         INTEGER REFERENCES subscriptions(id),
    ip_address              INET,
    user_agent              TEXT,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_webhook_events_event_id ON webhook_events(event_id);
CREATE INDEX idx_webhook_events_provider_event_type ON webhook_events(provider, event_type);
CREATE INDEX idx_webhook_events_status ON webhook_events(status);
CREATE INDEX idx_webhook_events_created_at ON webhook_events(created_at DESC);
CREATE INDEX idx_webhook_events_subscription_id ON webhook_events(subscription_id) WHERE subscription_id IS NOT NULL;

COMMENT ON TABLE webhook_events IS 'Registro de webhooks externos (Wompi) - Garantiza idempotencia (sin duplicados)';
COMMENT ON COLUMN webhook_events.event_id IS 'ID único del evento de Wompi - Previene procesamiento duplicado';

-- ============================================================================
-- MÓDULO 3: TAREAS (4 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: tasks
-- ----------------------------------------------------------------------------
CREATE TABLE tasks (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title               VARCHAR(500) NOT NULL,
    description         TEXT,
    status              VARCHAR(50) NOT NULL DEFAULT 'pending',
                        CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority            VARCHAR(20) DEFAULT 'medium',
                        CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date            TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    is_all_day          BOOLEAN DEFAULT false,
    recurrence_rule     VARCHAR(255),  -- Formato iCalendar RRULE
    parent_task_id      INTEGER REFERENCES tasks(id) ON DELETE CASCADE,  -- Para subtareas
    sort_order          INTEGER DEFAULT 0,
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_tasks_organization_user ON tasks(organization_id, user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_parent_task_id ON tasks(parent_task_id) WHERE parent_task_id IS NOT NULL;
CREATE INDEX idx_tasks_deleted_at ON tasks(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_title_trgm ON tasks USING gin(title gin_trgm_ops);  -- Búsqueda fuzzy

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE tasks IS 'Tareas TODO - Límites por plan: Free 50/mes, Basic 200/mes, Pro 1000/mes, Premium ilimitado';
COMMENT ON COLUMN tasks.parent_task_id IS 'Subtareas: máximo 1 nivel de profundidad, 50 subtareas por tarea';

-- ----------------------------------------------------------------------------
-- Tabla: tags
-- ----------------------------------------------------------------------------
CREATE TABLE tags (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name                VARCHAR(100) NOT NULL,
    color               VARCHAR(7) DEFAULT '#3B82F6',  -- Hex color
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, user_id, name)
);

CREATE INDEX idx_tags_organization_user ON tags(organization_id, user_id);
CREATE INDEX idx_tags_name ON tags(name);

COMMENT ON TABLE tags IS 'Etiquetas personalizables - Uso transversal: tareas, transacciones, contraseñas';

-- ----------------------------------------------------------------------------
-- Tabla: task_tags (relación N:M)
-- ----------------------------------------------------------------------------
CREATE TABLE task_tags (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id             INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    tag_id              INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(task_id, tag_id)
);

CREATE INDEX idx_task_tags_organization_user ON task_tags(organization_id, user_id);
CREATE INDEX idx_task_tags_task_id ON task_tags(task_id);
CREATE INDEX idx_task_tags_tag_id ON task_tags(tag_id);

COMMENT ON TABLE task_tags IS 'Relación muchos a muchos: tareas <-> etiquetas';

-- ----------------------------------------------------------------------------
-- Tabla: reminders
-- ----------------------------------------------------------------------------
CREATE TABLE reminders (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id             INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    remind_at           TIMESTAMP WITH TIME ZONE NOT NULL,
    status              VARCHAR(50) DEFAULT 'pending',
                        CHECK (status IN ('pending', 'sent', 'cancelled', 'failed')),
    sent_at             TIMESTAMP WITH TIME ZONE,
    notification_type   VARCHAR(50) DEFAULT 'push',
                        CHECK (notification_type IN ('push', 'email', 'both')),
    is_recurring        BOOLEAN DEFAULT false,
    recurrence_rule     VARCHAR(255),
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reminders_organization_user ON reminders(organization_id, user_id);
CREATE INDEX idx_reminders_task_id ON reminders(task_id);
CREATE INDEX idx_reminders_remind_at ON reminders(remind_at);
CREATE INDEX idx_reminders_status ON reminders(status);

COMMENT ON TABLE reminders IS 'Recordatorios de tareas - Procesados cada minuto por EventBridge';
COMMENT ON COLUMN reminders.status IS 'pending: por enviar, sent: enviado, cancelled: cancelado, failed: error al enviar';

-- ============================================================================
-- MÓDULO 4: FINANZAS (5 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: categories
-- ----------------------------------------------------------------------------
CREATE TABLE categories (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER REFERENCES organizations(id) ON DELETE CASCADE,  -- NULL = global
    user_id             INTEGER REFERENCES users(id) ON DELETE CASCADE,  -- NULL = global
    name                VARCHAR(100) NOT NULL,
    type                VARCHAR(50) NOT NULL,
                        CHECK (type IN ('income', 'expense', 'task', 'password', 'general')),
    icon                VARCHAR(50),  -- Emoji
    color               VARCHAR(7) DEFAULT '#3B82F6',
    parent_category_id  INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    is_default          BOOLEAN DEFAULT false,  -- Categorías del sistema
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_organization_user ON categories(organization_id, user_id);
CREATE INDEX idx_categories_type ON categories(type);
CREATE INDEX idx_categories_is_default ON categories(is_default);
CREATE INDEX idx_categories_parent_category_id ON categories(parent_category_id) WHERE parent_category_id IS NOT NULL;

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE categories IS 'Categorías - Globales (is_default=true) y personalizadas por usuario';

-- Insertar categorías globales iniciales
INSERT INTO categories (name, type, icon, is_default) VALUES
-- Ingresos
('Salario', 'income', '💰', true),
('Freelance', 'income', '💼', true),
('Inversiones', 'income', '📈', true),
('Otros Ingresos', 'income', '💵', true),
-- Gastos
('Alimentación', 'expense', '🍔', true),
('Transporte', 'expense', '🚗', true),
('Entretenimiento', 'expense', '🎬', true),
('Servicios', 'expense', '💡', true),
('Salud', 'expense', '⚕️', true),
('Educación', 'expense', '📚', true),
('Vivienda', 'expense', '🏠', true),
('Ropa', 'expense', '👕', true),
('Otros Gastos', 'expense', '💸', true);

-- ----------------------------------------------------------------------------
-- Tabla: accounts (NUEVO - Gap resuelto)
-- ----------------------------------------------------------------------------
CREATE TABLE accounts (
    id                      SERIAL PRIMARY KEY,
    organization_id         INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name                    VARCHAR(255) NOT NULL,
    type                    VARCHAR(50) NOT NULL,
                            CHECK (type IN ('bank', 'cash', 'credit_card', 'investment', 'savings', 'other')),
    currency                VARCHAR(3) DEFAULT 'COP',
    initial_balance         DECIMAL(15,2) DEFAULT 0.00,
    current_balance         DECIMAL(15,2) DEFAULT 0.00,
    bank_name               VARCHAR(255),
    account_number_last4    VARCHAR(4),
    color                   VARCHAR(7) DEFAULT '#3B82F6',
    icon                    VARCHAR(50) DEFAULT '💳',
    is_active               BOOLEAN DEFAULT true,
    is_included_in_total    BOOLEAN DEFAULT true,
    metadata                JSONB DEFAULT '{}',
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_accounts_organization_user ON accounts(organization_id, user_id);
CREATE INDEX idx_accounts_type ON accounts(type);
CREATE INDEX idx_accounts_currency ON accounts(currency);
CREATE INDEX idx_accounts_is_active ON accounts(is_active);
CREATE INDEX idx_accounts_deleted_at ON accounts(deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE accounts IS 'Cuentas bancarias, efectivo, tarjetas - Esencial para módulo finanzas';
COMMENT ON COLUMN accounts.current_balance IS 'Balance calculado automáticamente con transacciones';

-- ----------------------------------------------------------------------------
-- Tabla: transactions
-- ----------------------------------------------------------------------------
CREATE TABLE transactions (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id          INTEGER REFERENCES accounts(id) ON DELETE SET NULL,  -- NUEVO campo
    category_id         INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    type                VARCHAR(20) NOT NULL,
                        CHECK (type IN ('income', 'expense')),
    amount              DECIMAL(15,2) NOT NULL,
    currency            VARCHAR(3) DEFAULT 'COP',
    description         TEXT,
    transaction_date    TIMESTAMP WITH TIME ZONE NOT NULL,
    source              VARCHAR(50) DEFAULT 'manual',
                        CHECK (source IN ('manual', 'voice', 'sms', 'import')),
    source_reference    VARCHAR(255),
    payment_method      VARCHAR(50),
                        CHECK (payment_method IN ('cash', 'credit_card', 'debit_card', 'transfer', 'other')),
    tags                TEXT[],
    location            VARCHAR(255),
    is_recurring        BOOLEAN DEFAULT false,
    recurrence_rule     VARCHAR(255),
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_transactions_organization_user ON transactions(organization_id, user_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_category_id ON transactions(category_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_transaction_date ON transactions(transaction_date DESC);
CREATE INDEX idx_transactions_source ON transactions(source);
CREATE INDEX idx_transactions_deleted_at ON transactions(deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE transactions IS 'Transacciones financieras - Límites: Free 100/mes, Basic 1000/mes, Pro 10k/mes, Premium ilimitado';
COMMENT ON COLUMN transactions.account_id IS 'Cuenta asociada (Bancolombia, Efectivo, Visa, etc)';

-- ----------------------------------------------------------------------------
-- Tabla: budgets
-- ----------------------------------------------------------------------------
CREATE TABLE budgets (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id         INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    name                VARCHAR(255) NOT NULL,
    amount              DECIMAL(15,2) NOT NULL,
    currency            VARCHAR(3) DEFAULT 'COP',
    period_type         VARCHAR(50) NOT NULL DEFAULT 'monthly',
                        CHECK (period_type IN ('weekly', 'monthly', 'quarterly', 'yearly', 'custom')),
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    alert_threshold     INTEGER DEFAULT 80,  -- Porcentaje para alertar
                        CHECK (alert_threshold BETWEEN 1 AND 100),
    is_recurring        BOOLEAN DEFAULT false,
    status              VARCHAR(50) DEFAULT 'active',
                        CHECK (status IN ('active', 'exceeded', 'inactive')),
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_budgets_organization_user ON budgets(organization_id, user_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);
CREATE INDEX idx_budgets_period_type ON budgets(period_type);
CREATE INDEX idx_budgets_start_date ON budgets(start_date);
CREATE INDEX idx_budgets_status ON budgets(status);

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE budgets IS 'Presupuestos por categoría - Límites: Free 3, Basic 10, Pro 50, Premium ilimitado';

-- ----------------------------------------------------------------------------
-- Tabla: sms_messages
-- ----------------------------------------------------------------------------
CREATE TABLE sms_messages (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone_number_hash   VARCHAR(255) NOT NULL,  -- Hash SHA-256 del número
    message_body        TEXT NOT NULL,
    sender_name         VARCHAR(100),
    received_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    is_processed        BOOLEAN DEFAULT false,
    processed_at        TIMESTAMP WITH TIME ZONE,
    transaction_id      INTEGER REFERENCES transactions(id),
    device_id           VARCHAR(255),
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sms_messages_organization_user ON sms_messages(organization_id, user_id);
CREATE INDEX idx_sms_messages_is_processed ON sms_messages(is_processed);
CREATE INDEX idx_sms_messages_received_at ON sms_messages(received_at DESC);

COMMENT ON TABLE sms_messages IS 'SMS bancarios capturados (solo Premium Android) - NO almacena número de teléfono (solo hash)';
COMMENT ON COLUMN sms_messages.phone_number_hash IS 'SHA-256 del número de teléfono - GDPR compliance';

-- ============================================================================
-- MÓDULO 5: CONTRASEÑAS (2 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: passwords
-- ----------------------------------------------------------------------------
CREATE TABLE passwords (
    id                      SERIAL PRIMARY KEY,
    organization_id         INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name                    VARCHAR(255) NOT NULL,
    username                VARCHAR(255),
    encrypted_password      BYTEA NOT NULL,  -- AES-256-GCM
    encryption_iv           BYTEA NOT NULL,  -- Initialization Vector
    encryption_tag          BYTEA,  -- Authentication Tag (GCM)
    url                     TEXT,
    notes                   TEXT,
    category                VARCHAR(50) DEFAULT 'other',
                            CHECK (category IN ('website', 'bank', 'wifi', 'email', 'app', 'other')),
    tags                    TEXT[],
    last_used_at            TIMESTAMP WITH TIME ZONE,
    expires_at              TIMESTAMP WITH TIME ZONE,
    is_favorite             BOOLEAN DEFAULT false,
    metadata                JSONB DEFAULT '{}',
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_passwords_organization_user ON passwords(organization_id, user_id);
CREATE INDEX idx_passwords_category ON passwords(category);
CREATE INDEX idx_passwords_is_favorite ON passwords(is_favorite);
CREATE INDEX idx_passwords_deleted_at ON passwords(deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER update_passwords_updated_at BEFORE UPDATE ON passwords
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE passwords IS 'Contraseñas encriptadas AES-256-GCM - Límites: Free 10, Basic 100, Pro 1000, Premium ilimitado';
COMMENT ON COLUMN passwords.encrypted_password IS 'NUNCA almacenar en texto plano - Solo AES-256-GCM';

-- ----------------------------------------------------------------------------
-- Tabla: password_history (NUEVO - Gap resuelto)
-- ----------------------------------------------------------------------------
CREATE TABLE password_history (
    id                      SERIAL PRIMARY KEY,
    organization_id         INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_id             INTEGER NOT NULL REFERENCES passwords(id) ON DELETE CASCADE,
    encrypted_password      BYTEA NOT NULL,
    encryption_iv           BYTEA NOT NULL,
    encryption_tag          BYTEA,
    changed_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_reason          VARCHAR(255),
                            CHECK (changed_reason IN ('manual', 'expired', 'compromised', 'policy', 'forgot')),
    changed_by_user_id      INTEGER REFERENCES users(id),
    ip_address              INET,
    user_agent              TEXT,
    metadata                JSONB DEFAULT '{}'
);

CREATE INDEX idx_password_history_organization_user ON password_history(organization_id, user_id);
CREATE INDEX idx_password_history_password_id ON password_history(password_id);
CREATE INDEX idx_password_history_changed_at ON password_history(changed_at DESC);

COMMENT ON TABLE password_history IS 'Historial de cambios de contraseñas - Auditoría y compliance';

-- ============================================================================
-- MÓDULO 6: IA (2 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: ai_conversations
-- ----------------------------------------------------------------------------
CREATE TABLE ai_conversations (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title               VARCHAR(255),
    messages            JSONB NOT NULL DEFAULT '[]',  -- Array de mensajes
    model_used          VARCHAR(100) DEFAULT 'claude-3-5-sonnet-20241022-v2:0',
    total_tokens        INTEGER DEFAULT 0,
    total_cost_usd      DECIMAL(10,6) DEFAULT 0.000000,
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_conversations_organization_user ON ai_conversations(organization_id, user_id);
CREATE INDEX idx_ai_conversations_created_at ON ai_conversations(created_at DESC);

CREATE TRIGGER update_ai_conversations_updated_at BEFORE UPDATE ON ai_conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE ai_conversations IS 'Conversaciones con asistente IA - Límites: Free 0, Basic 20/mes, Pro 100/mes, Premium 500/mes';

-- ----------------------------------------------------------------------------
-- Tabla: ai_usage
-- ----------------------------------------------------------------------------
CREATE TABLE ai_usage (
    id                              SERIAL PRIMARY KEY,
    organization_id                 INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature_type                    VARCHAR(50) NOT NULL,
                                    CHECK (feature_type IN ('chat', 'voice_task', 'voice_finance', 'insight', 'prediction', 'memory_processing')),
    month_year                      VARCHAR(7) NOT NULL,  -- '2026-09'
    usage_count                     INTEGER DEFAULT 0,
    tokens_consumed                 INTEGER DEFAULT 0,
    cost_usd                        DECIMAL(10,6) DEFAULT 0.000000,
    plan_limit                      INTEGER,

    -- Cuotas de AI Memory
    memory_conversations_created    INTEGER DEFAULT 0,
    memory_photos_ocr               INTEGER DEFAULT 0,
    memory_documents_processed      INTEGER DEFAULT 0,
    memory_emails_received          INTEGER DEFAULT 0,
    memory_voice_notes              INTEGER DEFAULT 0,
    memory_ai_searches              INTEGER DEFAULT 0,
    memory_insights_generated       INTEGER DEFAULT 0,

    created_at                      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, user_id, feature_type, month_year)
);

CREATE INDEX idx_ai_usage_organization_user ON ai_usage(organization_id, user_id);
CREATE INDEX idx_ai_usage_feature_type ON ai_usage(feature_type);
CREATE INDEX idx_ai_usage_month_year ON ai_usage(month_year);

CREATE TRIGGER update_ai_usage_updated_at BEFORE UPDATE ON ai_usage
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE ai_usage IS 'Control de cuotas y uso de IA por feature y mes';

-- ============================================================================
-- MÓDULO 7: AI MEMORY (3 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabla: memories
-- ----------------------------------------------------------------------------
CREATE TABLE memories (
    id                      SERIAL PRIMARY KEY,
    organization_id         INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id                 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title                   VARCHAR(500),
    description             TEXT,
    memory_type             VARCHAR(50) NOT NULL,
                            CHECK (memory_type IN ('conversation', 'photo', 'document', 'email', 'voice_note')),
    status                  VARCHAR(50) DEFAULT 'processing',
                            CHECK (status IN ('processing', 'ready', 'failed')),
    captured_at             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    location_lat            DECIMAL(10, 8),
    location_lng            DECIMAL(11, 8),
    location_name           VARCHAR(255),
    ai_summary              TEXT,
    ai_extracted_entities   JSONB,  -- {persons: [], places: [], dates: []}
    ai_suggested_tags       TEXT[],
    ai_processing_error     TEXT,
    is_favorite             BOOLEAN DEFAULT false,
    is_archived             BOOLEAN DEFAULT false,
    tags                    TEXT[],
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_memories_organization_user ON memories(organization_id, user_id);
CREATE INDEX idx_memories_memory_type ON memories(memory_type);
CREATE INDEX idx_memories_status ON memories(status);
CREATE INDEX idx_memories_captured_at ON memories(captured_at DESC);
CREATE INDEX idx_memories_is_favorite ON memories(is_favorite);
CREATE INDEX idx_memories_is_archived ON memories(is_archived);
CREATE INDEX idx_memories_deleted_at ON memories(deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER update_memories_updated_at BEFORE UPDATE ON memories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE memories IS 'Segunda Memoria Digital - 5 tipos de captura con IA';
COMMENT ON COLUMN memories.memory_type IS 'conversation: grabada, photo: OCR, document: PDF/DOCX, email: reenviado, voice_note: transcrita';

-- ----------------------------------------------------------------------------
-- Tabla: memory_attachments
-- ----------------------------------------------------------------------------
CREATE TABLE memory_attachments (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    memory_id           INTEGER NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
    file_name           VARCHAR(500) NOT NULL,
    file_size_bytes     BIGINT NOT NULL,
    file_type           VARCHAR(100),  -- MIME type
    s3_key              VARCHAR(500) NOT NULL,
    s3_bucket           VARCHAR(255),
    thumbnail_s3_key    VARCHAR(500),
    ocr_text            TEXT,  -- Texto extraído de imágenes/PDFs
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_memory_attachments_organization_user ON memory_attachments(organization_id, user_id);
CREATE INDEX idx_memory_attachments_memory_id ON memory_attachments(memory_id);
CREATE INDEX idx_memory_attachments_file_type ON memory_attachments(file_type);

COMMENT ON TABLE memory_attachments IS 'Archivos adjuntos de memorias - Almacenados en S3';
COMMENT ON COLUMN memory_attachments.ocr_text IS 'Texto extraído con AWS Textract (fotos, PDFs)';

-- ----------------------------------------------------------------------------
-- Tabla: memory_embeddings
-- ----------------------------------------------------------------------------
CREATE TABLE memory_embeddings (
    id                  SERIAL PRIMARY KEY,
    organization_id     INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    memory_id           INTEGER NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
    embedding           vector(1536) NOT NULL,  -- Vector de 1536 dimensiones (Claude 3.5 Sonnet)
    chunk_text          TEXT NOT NULL,
    chunk_index         INTEGER DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_memory_embeddings_organization_user ON memory_embeddings(organization_id, user_id);
CREATE INDEX idx_memory_embeddings_memory_id ON memory_embeddings(memory_id);

-- Índice HNSW para búsqueda vectorial rápida (similitud coseno)
CREATE INDEX idx_embeddings_vector ON memory_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

COMMENT ON TABLE memory_embeddings IS 'Vectores para búsqueda semántica con IA - Requiere extensión pgvector';
COMMENT ON COLUMN memory_embeddings.embedding IS 'Vector generado por Amazon Bedrock para búsqueda semántica';

-- ============================================================================
-- FUNCIONES SQL AVANZADAS
-- ============================================================================

-- Función: Verificar feature habilitada en plan
CREATE OR REPLACE FUNCTION check_plan_feature(
    p_organization_id INTEGER,
    p_user_id INTEGER,
    p_feature VARCHAR(100)
) RETURNS BOOLEAN AS $$
DECLARE
    v_feature_value INTEGER;
BEGIN
    SELECT (pl.features->>p_feature)::INTEGER INTO v_feature_value
    FROM subscriptions s
    JOIN plans pl ON s.plan_id = pl.id
    WHERE s.organization_id = p_organization_id
      AND s.user_id = p_user_id
      AND s.status IN ('trial', 'active')
    ORDER BY s.created_at DESC
    LIMIT 1;

    -- Si no hay suscripción, asumir plan Free
    IF v_feature_value IS NULL THEN
        RETURN false;
    END IF;

    -- -1 significa ilimitado
    IF v_feature_value = -1 THEN
        RETURN true;
    END IF;

    -- 0 o NULL significa feature no disponible
    RETURN v_feature_value > 0;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION check_plan_feature IS 'Verifica si un feature está habilitado en el plan actual del usuario';

-- Función: Verificar cuota de IA disponible
CREATE OR REPLACE FUNCTION check_ai_quota(
    p_organization_id INTEGER,
    p_user_id INTEGER,
    p_feature_type VARCHAR(50)
) RETURNS BOOLEAN AS $$
DECLARE
    v_usage_count INTEGER;
    v_plan_limit INTEGER;
    v_current_month VARCHAR(7);
BEGIN
    v_current_month := TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM');

    -- Obtener límite del plan
    SELECT (pl.features->>'ai_quota')::INTEGER INTO v_plan_limit
    FROM subscriptions s
    JOIN plans pl ON s.plan_id = pl.id
    WHERE s.organization_id = p_organization_id
      AND s.user_id = p_user_id
      AND s.status IN ('trial', 'active')
    ORDER BY s.created_at DESC
    LIMIT 1;

    -- Si no hay plan, asumir 0
    IF v_plan_limit IS NULL THEN
        v_plan_limit := 0;
    END IF;

    -- -1 = ilimitado
    IF v_plan_limit = -1 THEN
        RETURN true;
    END IF;

    -- Obtener uso actual
    SELECT COALESCE(usage_count, 0) INTO v_usage_count
    FROM ai_usage
    WHERE organization_id = p_organization_id
      AND user_id = p_user_id
      AND feature_type = p_feature_type
      AND month_year = v_current_month;

    RETURN v_usage_count < v_plan_limit;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION check_ai_quota IS 'Verifica si el usuario tiene cuota de IA disponible';

-- Función: Verificar límite de tareas del mes
CREATE OR REPLACE FUNCTION check_task_limit(
    p_organization_id INTEGER,
    p_user_id INTEGER
) RETURNS TABLE(allowed BOOLEAN, current_count INTEGER, plan_limit INTEGER) AS $$
DECLARE
    v_plan_slug VARCHAR(50);
    v_limit INTEGER;
    v_count INTEGER;
BEGIN
    -- Obtener plan del usuario
    SELECT pl.slug INTO v_plan_slug
    FROM subscriptions s
    JOIN plans pl ON s.plan_id = pl.id
    WHERE s.organization_id = p_organization_id
      AND s.user_id = p_user_id
      AND s.status IN ('trial', 'active')
    ORDER BY s.created_at DESC
    LIMIT 1;

    v_plan_slug := COALESCE(v_plan_slug, 'free');

    -- Límites por plan
    v_limit := CASE v_plan_slug
        WHEN 'free' THEN 50
        WHEN 'basic' THEN 200
        WHEN 'pro' THEN 1000
        WHEN 'premium' THEN 999999
        ELSE 50
    END;

    -- Contar tareas del mes actual
    SELECT COUNT(*) INTO v_count
    FROM tasks
    WHERE organization_id = p_organization_id
      AND user_id = p_user_id
      AND created_at >= DATE_TRUNC('month', CURRENT_TIMESTAMP)
      AND deleted_at IS NULL;

    RETURN QUERY SELECT (v_count < v_limit), v_count, v_limit;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION check_task_limit IS 'Verifica límite mensual de tareas según plan';

-- Función: Actualizar balance de cuenta
CREATE OR REPLACE FUNCTION update_account_balance(
    p_account_id INTEGER,
    p_amount DECIMAL(15,2),
    p_operation VARCHAR(10)
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
        RAISE EXCEPTION 'Invalid operation: %. Use add or subtract', p_operation;
    END IF;

    IF v_new_balance IS NULL THEN
        RAISE EXCEPTION 'Account not found: %', p_account_id;
    END IF;

    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_account_balance IS 'Actualiza balance de cuenta sumando o restando monto';

-- Función: Calcular storage usado por usuario (AI Memory)
CREATE OR REPLACE FUNCTION calculate_user_storage(p_user_id INTEGER)
RETURNS BIGINT AS $$
DECLARE
    v_total_bytes BIGINT;
BEGIN
    SELECT COALESCE(SUM(ma.file_size_bytes), 0) INTO v_total_bytes
    FROM memory_attachments ma
    JOIN memories m ON ma.memory_id = m.id
    WHERE m.user_id = p_user_id
      AND m.deleted_at IS NULL;

    -- Actualizar en tabla users
    UPDATE users
    SET ai_memory_storage_bytes = v_total_bytes
    WHERE id = p_user_id;

    RETURN v_total_bytes;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_user_storage IS 'Calcula espacio total usado en AI Memory por usuario';

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Habilitar RLS en todas las tablas de usuario
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE passwords ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_embeddings ENABLE ROW LEVEL SECURITY;

-- Policy para users
CREATE POLICY users_isolation_policy ON users
    FOR ALL
    USING (id = current_setting('app.current_user_id', TRUE)::INTEGER);

-- Policy para refresh_tokens
CREATE POLICY refresh_tokens_isolation_policy ON refresh_tokens
    FOR ALL
    USING (user_id = current_setting('app.current_user_id', TRUE)::INTEGER);

-- Policy para audit_logs
CREATE POLICY audit_logs_isolation_policy ON audit_logs
    FOR ALL
    USING (user_id = current_setting('app.current_user_id', TRUE)::INTEGER);

-- Policy para subscriptions
CREATE POLICY subscriptions_isolation_policy ON subscriptions
    FOR ALL
    USING (user_id = current_setting('app.current_user_id', TRUE)::INTEGER);

-- Policy para payment_methods
CREATE POLICY payment_methods_isolation_policy ON payment_methods
    FOR ALL
    USING (user_id = current_setting('app.current_user_id', TRUE)::INTEGER);

-- Policy para payment_audit_logs
CREATE POLICY payment_audit_logs_isolation_policy ON payment_audit_logs
    FOR ALL
    USING (user_id = current_setting('app.current_user_id', TRUE)::INTEGER);

-- Policy para tasks
CREATE POLICY tasks_isolation_policy ON tasks
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para tags
CREATE POLICY tags_isolation_policy ON tags
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para task_tags
CREATE POLICY task_tags_isolation_policy ON task_tags
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para reminders
CREATE POLICY reminders_isolation_policy ON reminders
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para categories (permite globales + personalizadas)
CREATE POLICY categories_isolation_policy ON categories
    FOR ALL
    USING (
        is_default = true
        OR (
            organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
            AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
        )
    );

-- Policy para accounts
CREATE POLICY accounts_isolation_policy ON accounts
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para transactions
CREATE POLICY transactions_isolation_policy ON transactions
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para budgets
CREATE POLICY budgets_isolation_policy ON budgets
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para sms_messages
CREATE POLICY sms_messages_isolation_policy ON sms_messages
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para passwords
CREATE POLICY passwords_isolation_policy ON passwords
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para password_history
CREATE POLICY password_history_isolation_policy ON password_history
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para ai_conversations
CREATE POLICY ai_conversations_isolation_policy ON ai_conversations
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para ai_usage
CREATE POLICY ai_usage_isolation_policy ON ai_usage
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para memories
CREATE POLICY memories_isolation_policy ON memories
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para memory_attachments
CREATE POLICY memory_attachments_isolation_policy ON memory_attachments
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- Policy para memory_embeddings
CREATE POLICY memory_embeddings_isolation_policy ON memory_embeddings
    FOR ALL
    USING (
        organization_id = current_setting('app.current_organization_id', TRUE)::INTEGER
        AND user_id = current_setting('app.current_user_id', TRUE)::INTEGER
    );

-- ============================================================================
-- TRIGGERS PARA AUTO-POBLAR ORGANIZATION_ID Y USER_ID
-- ============================================================================

-- Trigger para task_tags
CREATE OR REPLACE FUNCTION set_task_tag_owner()
RETURNS TRIGGER AS $$
BEGIN
    SELECT organization_id, user_id INTO NEW.organization_id, NEW.user_id
    FROM tasks WHERE id = NEW.task_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER task_tags_set_owner BEFORE INSERT ON task_tags
    FOR EACH ROW EXECUTE FUNCTION set_task_tag_owner();

-- Trigger para memory_attachments
CREATE OR REPLACE FUNCTION set_memory_attachment_owner()
RETURNS TRIGGER AS $$
BEGIN
    SELECT organization_id, user_id INTO NEW.organization_id, NEW.user_id
    FROM memories WHERE id = NEW.memory_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER memory_attachments_set_owner BEFORE INSERT ON memory_attachments
    FOR EACH ROW EXECUTE FUNCTION set_memory_attachment_owner();

-- Trigger para memory_embeddings
CREATE OR REPLACE FUNCTION set_memory_embedding_owner()
RETURNS TRIGGER AS $$
BEGIN
    SELECT organization_id, user_id INTO NEW.organization_id, NEW.user_id
    FROM memories WHERE id = NEW.memory_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER memory_embeddings_set_owner BEFORE INSERT ON memory_embeddings
    FOR EACH ROW EXECUTE FUNCTION set_memory_embedding_owner();

-- ============================================================================
-- VISTAS ÚTILES
-- ============================================================================

-- Vista: Información de suscripción del usuario
CREATE OR REPLACE VIEW user_subscription_info AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.email,
    o.name AS organization_name,
    pl.name AS plan_name,
    pl.slug AS plan_slug,
    s.status AS subscription_status,
    s.current_period_end,
    s.trial_end,
    pl.features
FROM users u
JOIN organizations o ON u.organization_id = o.id
LEFT JOIN subscriptions s ON s.user_id = u.id AND s.status IN ('trial', 'active')
LEFT JOIN plans pl ON s.plan_id = pl.id;

-- Vista: Estadísticas de tareas
CREATE OR REPLACE VIEW task_statistics AS
SELECT
    user_id,
    COUNT(*) FILTER (WHERE status = 'pending') AS pending_tasks,
    COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress_tasks,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed_tasks,
    COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled_tasks,
    COUNT(*) AS total_tasks
FROM tasks
WHERE deleted_at IS NULL
GROUP BY user_id;

-- Vista: Cuentas con balance calculado
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

-- ============================================================================
-- DATOS INICIALES
-- ============================================================================

-- Crear cuenta "Efectivo" para cada usuario existente (ejecutar después de migración)
-- INSERT INTO accounts (organization_id, user_id, name, type, currency, color, icon)
-- SELECT u.organization_id, u.id, 'Efectivo', 'cash', 'COP', '#10B981', '💵'
-- FROM users u
-- WHERE u.is_active = true AND u.deleted_at IS NULL
-- ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================================
-- VALIDACIONES FINALES
-- ============================================================================

-- Verificar que todas las tablas fueron creadas
DO $$
DECLARE
    v_table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

    RAISE NOTICE '✅ Total de tablas creadas: %', v_table_count;

    IF v_table_count < 25 THEN
        RAISE EXCEPTION 'ERROR: Se esperaban 25 tablas, se crearon %', v_table_count;
    END IF;
END $$;

-- ============================================================================
-- RESUMEN
-- ============================================================================
-- Tablas creadas: 25
-- Extensiones: 3 (pgcrypto, pg_trgm, vector)
-- Funciones: 6
-- Triggers: 17 (14 updated_at + 3 auto-population)
-- RLS Policies: 21
-- Vistas: 3
--
-- Primary Keys: INTEGER AUTOINCREMENT (SERIAL)
-- Gaps resueltos: accounts, password_history, webhook_events
-- Gap excluido: voice_inputs (audios solo en S3, no en DB)
--
-- LISTO PARA PRODUCCIÓN ✅
-- ============================================================================
