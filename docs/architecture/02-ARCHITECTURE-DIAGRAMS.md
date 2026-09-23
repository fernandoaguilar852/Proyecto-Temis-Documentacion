# Diagramas de Arquitectura - TEMIS
## Diagramas Técnicos del Sistema

---

## 1. Arquitectura General del Sistema

```mermaid
graph TB
    subgraph "Frontend Layer"
        MobileApp[App Móvil<br/>React Native<br/>iOS + Android]
        WebAdmin[Web Admin<br/>Angular<br/>Superusuario]
    end

    subgraph "AWS Cloud"
        subgraph "API Layer"
            APIGateway[API Gateway<br/>REST API]
            Authorizer[Lambda Authorizer<br/>JWT Validation RS256]
        end

        subgraph "Security Services"
            ParamStore[AWS Parameter Store<br/>JWT Keys RS256]
        end

        subgraph "Business Logic"
            LambdaTasks[Lambda Functions<br/>Tasks Module]
            LambdaPasswords[Lambda Functions<br/>Passwords Module]
            LambdaFinance[Lambda Functions<br/>Finance Module]
            LambdaAdmin[Lambda Functions<br/>Admin Module]
            LambdaVoice[Lambda<br/>Voice Processing]
            LambdaAI[Lambda<br/>AI Chat & Insights]
        end

        subgraph "Data Layer"
            RDS[(RDS PostgreSQL<br/>db.t4g.micro)]
        end

        subgraph "AI Services"
            Bedrock[Amazon Bedrock<br/>Claude 3.5 Sonnet]
            Transcribe[AWS Transcribe<br/>Speech-to-Text]
        end

        subgraph "Storage & Services"
            S3[S3 Bucket<br/>Files & Backups]
            SNS[SNS<br/>Push Notifications]
            SES[SES<br/>Email Service]
            CloudWatch[CloudWatch<br/>Logs & Metrics]
            EventBridge[EventBridge<br/>Scheduled Tasks]
        end
    end

    MobileApp -->|HTTPS + JWT| APIGateway
    WebAdmin -->|HTTPS + JWT| APIGateway

    APIGateway --> Authorizer
    Authorizer --> ParamStore

    APIGateway --> LambdaTasks
    APIGateway --> LambdaPasswords
    APIGateway --> LambdaFinance
    APIGateway --> LambdaAdmin
    APIGateway --> LambdaVoice
    APIGateway --> LambdaAI

    LambdaTasks --> RDS
    LambdaPasswords --> RDS
    LambdaFinance --> RDS
    LambdaAdmin --> RDS
    LambdaVoice --> RDS
    LambdaAI --> RDS

    LambdaVoice --> Transcribe
    LambdaVoice --> Bedrock
    LambdaAI --> Bedrock

    LambdaFinance --> S3
    LambdaAdmin --> S3
    LambdaVoice --> S3

    EventBridge --> LambdaTasks

    LambdaTasks --> SNS
    LambdaFinance --> SNS
    LambdaAdmin --> SES

    LambdaTasks -.->|Logs| CloudWatch
    LambdaPasswords -.->|Logs| CloudWatch
    LambdaFinance -.->|Logs| CloudWatch
    LambdaAdmin -.->|Logs| CloudWatch
    LambdaVoice -.->|Logs| CloudWatch
    LambdaAI -.->|Logs| CloudWatch
```

---

## 2. Arquitectura de Red (VPC)

```mermaid
graph TB
    subgraph "Internet"
        Users[Usuarios]
    end

    subgraph "AWS Region: us-east-1"
        subgraph "Public Zone"
            APIGateway[API Gateway]
            NAT[NAT Gateway]
        end

        subgraph "VPC - 10.0.0.0/16"
            subgraph "Public Subnet - 10.0.1.0/24"
                IGW[Internet Gateway]
            end

            subgraph "Private Subnet A - 10.0.10.0/24"
                Lambda1[Lambda Functions]
                RDSProxy1[RDS Proxy<br/>futuro]
            end

            subgraph "Private Subnet B - 10.0.11.0/24"
                Lambda2[Lambda Functions]
                RDSProxy2[RDS Proxy<br/>futuro]
            end

            subgraph "Database Subnet A - 10.0.20.0/24"
                RDSPrimary[(RDS PostgreSQL<br/>Primary)]
            end

            subgraph "Database Subnet B - 10.0.21.0/24"
                RDSStandby[(RDS PostgreSQL<br/>Standby - futuro)]
            end
        end
    end

    Users -->|HTTPS| APIGateway
    APIGateway --> Lambda1
    APIGateway --> Lambda2

    Lambda1 --> RDSPrimary
    Lambda2 --> RDSPrimary

    RDSPrimary -.->|Replication| RDSStandby

    Lambda1 --> NAT
    Lambda2 --> NAT
    NAT --> IGW
```

---

## 3. Flujo de Autenticación JWT

```mermaid
sequenceDiagram
    actor Usuario
    participant App as App Móvil
    participant API as API Gateway
    participant Lambda as Lambda Auth
    participant ParamStore as Parameter Store
    participant DB as PostgreSQL

    Usuario->>App: Ingresa credenciales
    App->>API: POST /auth/login
    API->>Lambda: Invoke

    Lambda->>DB: Query user by email
    DB-->>Lambda: User data (hashed password)

    Lambda->>Lambda: Verify password<br/>(bcrypt compare)

    alt Contraseña válida
        Lambda->>DB: Query user profile & subscription
        DB-->>Lambda: User data + organization + plan

        Lambda->>ParamStore: Get JWT private key (RS256)
        ParamStore-->>Lambda: Private key

        Lambda->>Lambda: Generate JWT Token<br/>(userId, organizationId, role)

        Lambda-->>API: JWT Token + User Info
        API-->>App: 200 OK (Token)
        App->>App: Guarda token en storage seguro
        App-->>Usuario: Acceso concedido
    else Contraseña inválida
        Lambda-->>API: 401 Unauthorized
        API-->>App: Error
        App-->>Usuario: Credenciales inválidas
    end
```

---

## 4. Flujo de Operación CRUD (Tareas)

```mermaid
sequenceDiagram
    actor Usuario
    participant App as App Móvil
    participant API as API Gateway
    participant Auth as Lambda Authorizer
    participant Lambda as Lambda Tasks
    participant DB as PostgreSQL
    participant SNS as SNS/Push

    Usuario->>App: Crea nueva tarea
    App->>API: POST /tasks (+ JWT Token)

    API->>Auth: Validate token
    Auth-->>API: Token válido + Claims

    API->>Lambda: Invoke with user context

    Lambda->>DB: BEGIN TRANSACTION
    Lambda->>DB: Verificar permisos & plan

    alt Usuario tiene permisos
        Lambda->>DB: INSERT INTO tasks
        Lambda->>DB: INSERT INTO reminders (si aplica)
        Lambda->>DB: COMMIT
        DB-->>Lambda: Task ID

        opt Recordatorio programado
            Lambda->>SNS: Schedule push notification
        end

        Lambda-->>API: 201 Created (Task data)
        API-->>App: Success
        App-->>Usuario: Tarea creada
    else Sin permisos
        Lambda->>DB: ROLLBACK
        Lambda-->>API: 403 Forbidden
        API-->>App: Error
        App-->>Usuario: Upgrade plan necesario
    end
```

---

## 5. Flujo de Registro por Voz (Tareas y Finanzas)

```mermaid
sequenceDiagram
    actor Usuario
    participant App as App Móvil
    participant API as API Gateway
    participant Lambda as Lambda Voice
    participant S3 as S3 Bucket
    participant Transcribe as AWS Transcribe
    participant Bedrock as Amazon Bedrock
    participant QuotaMW as AI Quota Middleware
    participant DB as PostgreSQL

    Usuario->>App: Graba audio<br/>"Gasté $50 en supermercado"<br/>o "Recordarme llamar al médico mañana"
    App->>App: Codifica audio (AAC/MP3)
    App->>API: POST /voice/process<br/>(type: finance|task)
    API->>Lambda: Invoke con audio base64

    Lambda->>QuotaMW: Check voice quota
    QuotaMW->>DB: Query ai_usage
    DB-->>QuotaMW: Current usage

    alt Cuota disponible
        Lambda->>S3: Upload audio file
        S3-->>Lambda: S3 URI

        Lambda->>Transcribe: StartTranscriptionJob
        Transcribe-->>Lambda: Job ID
        Lambda-->>API: 202 Accepted (Job ID)
        API-->>App: Procesando...

        Note over Transcribe: Procesamiento asíncrono<br/>5-15 segundos

        Transcribe->>Lambda: Transcription complete (webhook)
        Lambda->>Transcribe: GetTranscriptionResult
        Transcribe-->>Lambda: Texto transcrito

        Lambda->>Bedrock: InvokeModel (Claude 3.5 Sonnet)<br/>Prompt: "Extraer datos estructurados"
        Bedrock-->>Lambda: JSON estructurado<br/>{amount, category, date} o {title, priority, dueDate}

        Lambda->>DB: INSERT INTO transactions o tasks
        Lambda->>DB: INSERT INTO ai_usage (voice_transcription)
        DB-->>Lambda: Record ID

        Lambda->>App: Push notification<br/>"Gasto/Tarea registrado"
        App-->>Usuario: Notificación
    else Cuota excedida
        Lambda-->>API: 403 Forbidden (Upgrade required)
        API-->>App: Error + upgrade message
        App-->>Usuario: "Límite de voz alcanzado"
    end
```

---

## 6. Flujo de Captura Automática de SMS

```mermaid
sequenceDiagram
    actor Sistema as Sistema Móvil
    participant App as App TEMIS
    participant Listener as SMS Listener
    participant API as API Gateway
    participant Lambda as Lambda SMS Parser
    participant DB as PostgreSQL

    Sistema->>Listener: SMS recibido<br/>"Compra $35.50 Starbucks"

    Listener->>Listener: Filtrar SMS financieros<br/>(regex patterns)

    alt SMS es transacción
        Listener->>App: Notificar nuevo SMS
        App->>App: Extraer datos del SMS
        App->>API: POST /finance/sms-transaction
        API->>Lambda: Invoke

        Lambda->>Lambda: Parse SMS<br/>- Banco/Emisor<br/>- Monto<br/>- Comercio<br/>- Tipo (débito/crédito)

        Lambda->>DB: INSERT INTO transactions<br/>(source: 'sms')
        DB-->>Lambda: Transaction ID

        Lambda-->>API: 201 Created
        API-->>App: Success
        App->>App: Actualizar UI
        App-->>Usuario: Mostrar notificación<br/>"Nueva transacción registrada"
    else SMS no relevante
        Listener->>Listener: Ignorar
    end
```

---

## 7. Flujo de Chat IA Conversacional

```mermaid
sequenceDiagram
    actor Usuario
    participant App as App Móvil
    participant API as API Gateway
    participant Lambda as Lambda AI Chat
    participant QuotaMW as AI Quota Middleware
    participant Bedrock as Amazon Bedrock
    participant DB as PostgreSQL

    Usuario->>App: Escribe mensaje<br/>"¿Cuánto gasté en restaurantes?"
    App->>API: POST /ai/chat<br/>{message, conversationId?}
    API->>Lambda: Invoke

    Lambda->>QuotaMW: Check chat quota
    QuotaMW->>DB: Query ai_usage (chat_messages)
    DB-->>QuotaMW: Current usage

    alt Cuota disponible
        Lambda->>DB: Get conversation history (últimos 10 mensajes)
        DB-->>Lambda: Previous messages

        Lambda->>DB: Query user financial data<br/>(filtered by user_id + organization_id)
        DB-->>Lambda: Transactions, budgets, categories

        Lambda->>Lambda: Build context prompt<br/>+ Conversation history<br/>+ User data<br/>+ Current question

        Lambda->>Bedrock: InvokeModel<br/>(Claude 3.5 Sonnet)
        Note over Bedrock: Procesa contexto<br/>Genera respuesta<br/>inteligente
        Bedrock-->>Lambda: AI Response

        Lambda->>DB: INSERT INTO ai_conversations<br/>(user message + AI response)
        Lambda->>DB: INSERT INTO ai_usage (chat_message)
        DB-->>Lambda: Conversation ID

        Lambda-->>API: 200 OK + AI Response
        API-->>App: AI Response
        App-->>Usuario: "Gastaste $450 en restaurantes<br/>este mes, 20% más que el anterior"
    else Cuota excedida
        Lambda-->>API: 403 Forbidden (Upgrade required)
        API-->>App: Error + upgrade options
        App-->>Usuario: "Límite de chat alcanzado.<br/>Mejora tu plan."
    end
```

---

## 8. Modelo de Datos Multitenancy

```mermaid
erDiagram
    ORGANIZATIONS ||--o{ USERS : has
    ORGANIZATIONS ||--|| SUBSCRIPTIONS : has
    USERS ||--o{ TASKS : creates
    USERS ||--o{ PASSWORDS : stores
    USERS ||--o{ TRANSACTIONS : records
    USERS ||--o{ CATEGORIES : defines
    USERS ||--o{ AI_CONVERSATIONS : has
    USERS ||--o{ AI_USAGE : tracks

    ORGANIZATIONS {
        uuid id PK
        string name
        string slug
        timestamp created_at
        boolean is_active
    }

    SUBSCRIPTIONS {
        uuid id PK
        uuid organization_id FK
        enum plan_type
        timestamp start_date
        timestamp end_date
        boolean is_active
        json features
        json ai_limits
    }

    USERS {
        uuid id PK
        uuid organization_id FK
        string email
        string password_hash
        string name
        enum role
        boolean is_active
    }

    TASKS {
        uuid id PK
        uuid user_id FK
        uuid organization_id FK
        string title
        text description
        enum priority
        enum status
        timestamp due_date
        enum source
    }

    PASSWORDS {
        uuid id PK
        uuid user_id FK
        uuid organization_id FK
        string name
        bytea encrypted_data
        enum category
    }

    TRANSACTIONS {
        uuid id PK
        uuid user_id FK
        uuid organization_id FK
        decimal amount
        enum type
        uuid category_id FK
        enum source
        timestamp transaction_date
    }

    AI_CONVERSATIONS {
        uuid id PK
        uuid user_id FK
        uuid organization_id FK
        text user_message
        text ai_response
        string model_used
        timestamp created_at
    }

    AI_USAGE {
        uuid id PK
        uuid user_id FK
        uuid organization_id FK
        enum feature_type
        string month_year
        integer usage_count
        timestamp last_used_at
    }
```

---

## 9. Arquitectura de Seguridad

```mermaid
graph TB
    subgraph "Capas de Seguridad"
        subgraph "Capa 1: Transporte"
            TLS[TLS 1.3<br/>Encriptación en tránsito]
        end

        subgraph "Capa 2: Autenticación"
            JWT[JWT Tokens<br/>RS256]
            MFA[MFA Optional<br/>TOTP futuro]
            ParamStore[Parameter Store<br/>JWT Keys]
        end

        subgraph "Capa 3: Autorización"
            RBAC[Role-Based Access<br/>Admin/User/Viewer]
            PlanCheck[Plan Validation<br/>Feature Gating]
            AIQuota[AI Quota Middleware<br/>Usage Limits]
            RLS[Row Level Security<br/>PostgreSQL]
            MandatoryFilter[Mandatory Filters<br/>organization_id + user_id]
        end

        subgraph "Capa 4: Datos"
            EncryptRest[Encriptación en Reposo<br/>RDS KMS]
            EncryptApp[Encriptación App<br/>AES-256-GCM Passwords]
            Hashing[Password Hashing<br/>bcrypt rounds=10]
            AIDataPrivacy[AI Data Privacy<br/>No PII to Bedrock]
        end

        subgraph "Capa 5: Auditoría"
            CloudTrail[AWS CloudTrail<br/>Audit Logs]
            AppLogs[Application Logs<br/>CloudWatch]
            SecurityEvents[Security Events<br/>Failed logins, AI usage]
        end
    end

    TLS --> JWT
    JWT --> ParamStore
    ParamStore --> RBAC
    MFA -.->|futuro| JWT
    RBAC --> PlanCheck
    PlanCheck --> AIQuota
    AIQuota --> RLS
    RLS --> MandatoryFilter
    MandatoryFilter --> EncryptRest
    EncryptRest --> CloudTrail
    EncryptApp --> AppLogs
    Hashing --> SecurityEvents
    AIDataPrivacy --> SecurityEvents
```

---

## 10. Ciclo de Vida de Suscripción

```mermaid
stateDiagram-v2
    [*] --> TrialCreated: Usuario se registra

    TrialCreated --> TrialActive: Confirmación email
    TrialActive --> TrialExpiring: 7 días restantes
    TrialExpiring --> TrialExpired: Fin trial (14 días)

    TrialActive --> PaidActive: Upgrade a plan pago
    TrialExpiring --> PaidActive: Upgrade a plan pago

    PaidActive --> PaidExpiring: 7 días antes de renovación
    PaidExpiring --> PaidActive: Pago exitoso
    PaidExpiring --> PaymentFailed: Pago fallido

    PaymentFailed --> GracePeriod: Notificar usuario
    GracePeriod --> PaidActive: Pago exitoso
    GracePeriod --> Suspended: 3 días sin pago

    Suspended --> PaidActive: Pago realizado
    Suspended --> Cancelled: 30 días suspendido

    TrialExpired --> FreePlan: Downgrade automático
    PaidActive --> Cancelled: Usuario cancela

    Cancelled --> [*]: Soft delete (180 días)

    note right of TrialActive
        - Acceso a features según trial
        - Emails onboarding
    end note

    note right of PaidActive
        - Facturación automática
        - Acceso completo a features
    end note

    note right of Suspended
        - Acceso solo lectura
        - No puede crear nuevos registros
    end note
```

---

## 11. Despliegue CI/CD

```mermaid
graph LR
    subgraph "Development"
        Dev[Desarrollador]
        Git[GitHub Repo]
    end

    subgraph "CI/CD Pipeline"
        subgraph "Build Stage"
            Checkout[Checkout Code]
            Install[Install Dependencies]
            Lint[Lint & Format]
            Test[Run Tests]
            Build[Build Artifacts]
        end

        subgraph "Deploy Stage"
            DeployDev[Deploy to Dev]
            IntegrationTest[Integration Tests]
            DeployStaging[Deploy to Staging]
            E2ETest[E2E Tests]
            Approval[Manual Approval]
            DeployProd[Deploy to Production]
        end
    end

    subgraph "Environments"
        EnvDev[Dev Environment<br/>AWS Account Dev]
        EnvStaging[Staging Environment<br/>AWS Account Staging]
        EnvProd[Production Environment<br/>AWS Account Prod]
    end

    Dev -->|git push| Git
    Git -->|trigger| Checkout
    Checkout --> Install
    Install --> Lint
    Lint --> Test
    Test --> Build

    Build -->|Serverless Deploy| DeployDev
    DeployDev --> EnvDev
    DeployDev --> IntegrationTest

    IntegrationTest -->|Pass| DeployStaging
    DeployStaging --> EnvStaging
    DeployStaging --> E2ETest

    E2ETest -->|Pass| Approval
    Approval -->|Approved| DeployProd
    DeployProd --> EnvProd

    DeployProd -->|Rollback if error| DeployStaging
```

---

## 12. Monitoreo y Observabilidad

```mermaid
graph TB
    subgraph "Sources"
        Lambda[Lambda Functions]
        RDS[RDS PostgreSQL]
        API[API Gateway]
        App[Mobile App]
    end

    subgraph "Collection"
        CloudWatch[CloudWatch Logs]
        Metrics[CloudWatch Metrics]
        XRay[AWS X-Ray<br/>Tracing]
    end

    subgraph "Processing"
        LogInsights[CloudWatch Insights<br/>Query Logs]
        Alarms[CloudWatch Alarms]
        Dashboard[CloudWatch Dashboards]
    end

    subgraph "Notifications"
        SNS[SNS Topic]
        Email[Email Alerts]
        Slack[Slack Integration]
        PagerDuty[PagerDuty<br/>On-Call]
    end

    Lambda -->|Logs| CloudWatch
    RDS -->|Metrics| Metrics
    API -->|Access Logs| CloudWatch
    App -->|Errors| CloudWatch

    Lambda -->|Traces| XRay

    CloudWatch --> LogInsights
    Metrics --> Alarms
    Metrics --> Dashboard

    LogInsights --> Dashboard

    Alarms -->|Trigger| SNS
    SNS --> Email
    SNS --> Slack
    SNS --> PagerDuty
```

---

## 13. Estrategia de Backup y Recovery

```mermaid
graph TB
    subgraph "Production Database"
        RDSProd[(RDS PostgreSQL<br/>Production)]
    end

    subgraph "Automated Backups"
        AutoSnapshot[Automated Snapshots<br/>Daily - 7 days retention]
        ManualSnapshot[Manual Snapshots<br/>Weekly - 30 days retention]
    end

    subgraph "Disaster Recovery"
        S3Backup[S3 Bucket<br/>Long-term backups<br/>1 year retention]
        CrossRegion[Cross-Region Backup<br/>us-west-2<br/>Compliance]
    end

    subgraph "Recovery Options"
        PITR[Point-in-Time Recovery<br/>Último 5 minutos]
        RestoreSnapshot[Restore from Snapshot<br/>30-60 minutos]
        CrossRegionRestore[Restore from Cross-Region<br/>1-2 horas]
    end

    RDSProd -->|Daily 3 AM| AutoSnapshot
    RDSProd -->|Sunday 2 AM| ManualSnapshot
    RDSProd -->|Transaction Logs| PITR

    AutoSnapshot -->|Export| S3Backup
    ManualSnapshot -->|Replicate| CrossRegion

    AutoSnapshot -.->|RTO: 30-60 min| RestoreSnapshot
    PITR -.->|RTO: 15-30 min| RestoreSnapshot
    CrossRegion -.->|RTO: 1-2 hours| CrossRegionRestore

    RestoreSnapshot --> RDSProd
    CrossRegionRestore --> RDSProd
```

---

## Changelog

### v1.1.0 (2026-07-12)
- ✅ Actualizada arquitectura con Amazon Bedrock (Claude 3.5 Sonnet)
- ✅ Eliminado AWS Cognito, implementado JWT con Parameter Store (RS256)
- ✅ Agregado Lambda AI Chat y Lambda Voice Processing
- ✅ Nuevo diagrama: Flujo de Chat IA Conversacional
- ✅ Actualizado: Flujo de Voz incluye tareas y finanzas con IA
- ✅ Modelo de datos actualizado con tablas AI (ai_conversations, ai_usage)
- ✅ Arquitectura de seguridad actualizada (AI Quota Middleware, filtros obligatorios)
- ✅ Diagrama de autenticación actualizado (JWT sin Cognito)

### v1.0.0 (2026-07-12)
- Versión inicial con 12 diagramas base

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.1.0

**Nota**: Los diagramas Mermaid se pueden visualizar en:
- GitHub (renderizado automático)
- VS Code (con extensión Mermaid)
- [Mermaid Live Editor](https://mermaid.live)
