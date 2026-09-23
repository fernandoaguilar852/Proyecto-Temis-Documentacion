# TEMIS - Gestión de Tareas y Finanzas Personales 🤖
## Aplicación Multiplataforma Potenciada por IA con Backend Serverless

---

## Descripción del Proyecto

TEMIS es una aplicación multiplataforma (iOS y Android) **potenciada por Inteligencia Artificial** construida con React Native, que permite a los usuarios gestionar cinco áreas principales:

1. **Tareas y Calendario con IA**: Gestión por voz, recordatorios inteligentes, sugerencias automáticas
2. **Gestor de Contraseñas**: Almacenamiento seguro con análisis de seguridad IA
3. **Finanzas Personales con IA**: Registro por voz/SMS, predicciones, recomendaciones personalizadas
4. **AI Memory - Tu Segunda Memoria**: Captura de conversaciones, fotos, documentos y emails con búsqueda semántica inteligente
5. **Asistente IA Conversacional**: Chat inteligente para consultas y análisis de datos

### Stack Tecnológico

- **Frontend Móvil**: React Native (iOS + Android)
- **Frontend Web**: Angular (Panel de administración)
- **Backend**: AWS Lambda (Node.js) - Arquitectura de microservicios
- **Base de Datos**: Amazon RDS PostgreSQL con pgvector para búsqueda semántica
- **IA**: Amazon Bedrock (Claude 3.5 Sonnet) para chat, análisis y embeddings
- **Voz**: AWS Transcribe para speech-to-text
- **OCR**: AWS Textract para extracción de texto de imágenes y documentos
- **Almacenamiento**: Amazon S3 para archivos multimedia
- **Infraestructura**: AWS (Serverless)

---

## Estructura del Proyecto

```
PROTECTO-TEMIS(TAREAS-FINANZAS)/
├── README.md                          # Este archivo
│
├── docs/                              # Documentación técnica
│   ├── architecture/                  # Arquitectura del sistema
│   │   ├── 01-ARCHITECTURE-OVERVIEW.md
│   │   ├── 02-ARCHITECTURE-DIAGRAMS.md
│   │   ├── 03-MODULES-FEATURES.md
│   │   ├── 04-AWS-INFRASTRUCTURE.md
│   │   ├── 05-SECURITY-MULTITENANCY.md
│   │   └── 06-MODULE-AI-MEMORY.md     # Nuevo módulo AI Memory
│   │
│   ├── database/                      # Esquema de base de datos
│   │   └── DATABASE-SCHEMA.md
│   │
│   └── api/                           # Documentación de APIs
│       └── API-ENDPOINTS.md
│
├── contratos/                         # Contratos API Swagger (15 archivos)
│   ├── TEMIS_CONTRATO_AI_MEMORY_V1.0.yaml  # Nuevo
│   └── ...otros contratos...
│
├── backend/                           # Código del backend (futuro)
│   └── lambdas/
│
├── frontend-mobile/                   # App React Native (futuro)
│   └── src/
│
└── frontend-web/                      # Panel Angular (futuro)
    └── src/
```

---

## Documentación Técnica

### 📋 Arquitectura

#### [01. Visión General de la Arquitectura](docs/architecture/01-ARCHITECTURE-OVERVIEW.md)
Descripción completa de la arquitectura del sistema, stack tecnológico, principios arquitectónicos, módulos, sistema de suscripciones, integraciones, roadmap y costos estimados.

**Contenido**:
- Stack tecnológico completo
- Principios de multitenancy
- Estrategia de seguridad
- Módulos del sistema
- Planes de suscripción
- Integraciones AWS
- Costos estimados mensuales
- Roadmap técnico por fases

#### [02. Diagramas de Arquitectura](docs/architecture/02-ARCHITECTURE-DIAGRAMS.md)
Diagramas visuales (Mermaid) de la arquitectura del sistema, flujos de datos, secuencias de operaciones y modelos de datos.

**Contenido**:
- Arquitectura general del sistema
- Arquitectura de red (VPC)
- Flujos de autenticación
- Flujos de operaciones CRUD
- Flujo de registro por voz
- Flujo de captura de SMS
- Modelo de datos multitenancy
- Arquitectura de seguridad
- Ciclo de vida de suscripciones
- CI/CD pipeline
- Monitoreo y observabilidad
- Estrategia de backup

#### [03. Módulos y Funcionalidades](docs/architecture/03-MODULES-FEATURES.md)
Especificación detallada de cada módulo, funcionalidades, casos de uso, validaciones y matriz de features por plan.

**Contenido**:
- **Módulo Tareas**: CRUD, etiquetas, calendario, recordatorios inteligentes
- **Módulo Contraseñas**: Bóveda segura, generador, auditoría de seguridad
- **Módulo Finanzas**: Registro manual/voz/SMS, dashboard, presupuestos, reportes
- **Autenticación**: JWT sin Cognito
- **Suscripciones**: 4 planes (Free, Basic, Pro, Premium)
- **Administración**: Panel web para superusuarios
- Matriz completa de features por plan
- Roadmap de desarrollo

#### [04. Infraestructura AWS](docs/architecture/04-AWS-INFRASTRUCTURE.md)
Configuración detallada de todos los servicios AWS, lambdas como microservicios, networking, monitoreo y despliegue.

**Contenido**:
- **12+ Lambda Functions** (microservicios independientes)
- API Gateway con rutas y authorizer
- RDS PostgreSQL (db.t4g.micro)
- VPC y Security Groups
- Parameter Store para secrets (JWT keys)
- SNS para push notifications con prioridad automática
- EventBridge para recordatorios
- AWS Transcribe para voz
- S3 para almacenamiento
- CloudWatch para monitoreo
- Costos estimados detallados (~$157/mes para 1000 usuarios)
- Serverless Framework configuration

#### [05. Seguridad y Multitenancy](docs/architecture/05-SECURITY-MULTITENANCY.md)
Estrategias de seguridad en múltiples capas, aislamiento de datos, encriptación, autenticación JWT y mejores prácticas.

**Contenido**:
- **Multitenancy**: Aislamiento por `organization_id` + `user_id`
- **JWT**: Generación y validación de tokens (RS256)
- **Filtrado obligatorio**: Middleware y helpers seguros
- **Row-Level Security (RLS)**: Políticas de PostgreSQL
- **Encriptación**: bcrypt (usuarios), AES-256-GCM (contraseñas guardadas)
- **RBAC**: Control de acceso por roles
- **Feature gating**: Validación de plan
- **Auditoría**: Logging de eventos sensibles
- **Protección**: SQL injection, XSS, CSRF, rate limiting
- Checklist de seguridad completo
- Plan de respuesta a incidentes

#### [06. Módulo AI Memory](docs/architecture/06-MODULE-AI-MEMORY.md)
Especificación completa del módulo "Tu Segunda Memoria Digital" - captura, almacenamiento y búsqueda inteligente de información personal.

**Contenido**:
- **Visión General**: Propuesta de valor y casos de uso reales
- **Funcionalidades Principales**:
  - Grabar conversaciones con transcripción automática (AWS Transcribe)
  - Capturar fotos con procesamiento OCR inteligente (AWS Textract)
  - Guardar documentos con extracción de texto
  - Recibir y procesar emails reenviados automáticamente
  - Crear notas de voz rápidas con transcripción
- **Búsqueda Inteligente**:
  - Búsqueda semántica con embeddings (Amazon Bedrock)
  - Búsqueda vectorial con PostgreSQL + pgvector
  - Preguntas en lenguaje natural
  - Re-ranking con IA para mayor precisión
- **Organización**: Etiquetas, favoritos, archivado
- **Gestión de Storage**: Cuotas por plan (2 GB a 100 GB)
- **Insights**: Resúmenes automáticos semanales/mensuales
- **Arquitectura Técnica**: S3, Lambda processors, embeddings, OCR
- **Casos de Uso Detallados**: Flujos completos de captura y búsqueda
- **Estimación de Costos**: ~$987/mes para 1000 usuarios
- **Integración con Otros Módulos**: Tareas, Finanzas, Contraseñas
- **Roadmap de Implementación**: 5 fases (10 meses)

---

### 🗄️ Base de Datos

#### [Esquema de Base de Datos PostgreSQL](docs/database/DATABASE-SCHEMA.md)
Esquema completo de la base de datos con tablas, relaciones, índices, triggers, funciones, vistas y scripts de mantenimiento.

**Contenido**:
- **16+ tablas principales**: organizations, users, tasks, passwords, transactions, memories, etc.
- **Extensiones PostgreSQL**: uuid-ossp, pgcrypto, pg_trgm, **vector (pgvector para búsqueda semántica)**
- **Row-Level Security (RLS)** policies en todas las tablas
- Índices optimizados (full-text search, búsqueda vectorial HNSW)
- Triggers para `updated_at` y actualización automática de storage
- Funciones de seguridad y validación (cuotas de storage, cuotas mensuales)
- Vistas útiles (resúmenes financieros, stats de tareas, resumen de memorias)
- Scripts de inicialización
- Scripts de mantenimiento (incluye limpieza de memorias soft-deleted)
- **CRÍTICO**: Todas las tablas con `organization_id` + `user_id` para aislamiento

**Tablas Principales**:
- `organizations` - Organizaciones (multitenancy)
- `users` - Usuarios con autenticación JWT y storage de AI Memory
- `refresh_tokens` - Tokens de refresco
- `memories` - **Memorias guardadas (conversaciones, fotos, documentos, emails, notas de voz)**
- `memory_attachments` - **Archivos adjuntos a memorias (almacenados en S3)**
- `memory_embeddings` - **Embeddings vectoriales para búsqueda semántica (vector 1536)**
- `plans` - Planes de suscripción
- `subscriptions` - Suscripciones activas
- `tasks` - Tareas con prioridades
- `tags` - Etiquetas personalizables
- `reminders` - Recordatorios programados
- `passwords` - Contraseñas encriptadas
- `categories` - Categorías de transacciones
- `transactions` - Transacciones financieras
- `sms_messages` - SMS capturados
- `budgets` - Presupuestos mensuales
- `audit_logs` - Auditoría del sistema

---

### 🔌 API

#### [Endpoints de la API REST](docs/api/API-ENDPOINTS.md)
Documentación completa de todos los endpoints de la API, incluyendo rutas, métodos, parámetros, respuestas y ejemplos.

**Contenido**:
- **Arquitectura de microservicios**: Una Lambda por entidad
- Formato estándar de respuestas (success, error, paginación)
- Autenticación JWT y headers
- Rate limiting por plan
- **Endpoints organizados por Lambda**:
  - `/auth/*` → lambda-auth (register, login, refresh, logout)
  - `/users/*` → lambda-users (perfil, avatar, cambio password)
  - `/tasks/*` → lambda-tasks (CRUD completo, stats)
  - `/tags/*` → lambda-tags (CRUD de etiquetas)
  - `/reminders/*` → lambda-reminders (CRUD, notificaciones por prioridad)
  - `/passwords/*` → lambda-passwords (CRUD, generar, auditoría)
  - `/transactions/*` → lambda-transactions (manual, voz, SMS, dashboard, reportes)
  - `/categories/*` → lambda-categories (CRUD)
  - `/budgets/*` → lambda-budgets (CRUD)
  - `/memories/*` → **lambda-ai-memory (CRUD memorias, búsqueda semántica, storage)**
  - `/memories/search` → **lambda-ai-memory-search (búsqueda IA con embeddings)**
  - `/subscriptions/*` → lambda-subscriptions (planes, upgrade, cancelar)
  - `/admin/*` → lambda-admin (panel administrativo)
- Estructura de carpetas de lambdas en backend
- Ejemplos de request/response completos

---

## Características Principales

### 🤖 Asistente IA Conversacional

Chat inteligente que responde preguntas sobre tus datos:

```
Tú: "¿Cuánto gasté en restaurantes este mes?"
IA: "Gastaste $450 en restaurantes este mes, un 20% más que el mes pasado.
     Tu restaurante más frecuente fue Starbucks con $120."

Tú: "¿Cuántas tareas completé esta semana?"
IA: "Completaste 15 tareas esta semana. Tu día más productivo fue el lunes
     con 5 tareas completadas."
```

**Features**:
- Chat contextual con Amazon Bedrock (Claude 3.5)
- Análisis inteligente de patrones y tendencias
- Recomendaciones personalizadas
- Resúmenes automáticos diarios/semanales
- Límites por plan: 0 (Free), 20 (Basic), 100 (Pro), 500 (Premium) msgs/mes

### 🗣️ Creación por Voz con IA

**En Tareas**:
```
Tú: "Recordarme comprar leche mañana a las 10"
     ↓
AWS Transcribe + Amazon Bedrock → Tarea creada automáticamente
```

**En Finanzas**:
```
Tú: "Gasté cincuenta dólares en el supermercado"
     ↓
AWS Transcribe + Amazon Bedrock → Transacción categorizada
```

**Features**:
- Parsing inteligente con IA (fecha, hora, monto, categoría)
- Sugerencias automáticas de prioridad
- Detección de intención con NLP
- Soporta español e inglés
- Límites por plan: Basic (10 tareas/mes), Pro (100 tareas + 50 finanzas/mes), Premium (ilimitado)

### 📊 Análisis Financiero con IA

**Predicciones**:
- "Probablemente gastarás $1,200 en alimentación este mes"
- "Tu saldo al fin de mes será aproximadamente $2,500"

**Detección de Anomalías**:
- "Gastaste 300% más en entretenimiento que el mes pasado"
- "Alerta: Gasto inusual de $500 en categoría Otros"

**Recomendaciones**:
- "Puedes ahorrar $200/mes reduciendo gastos en restaurantes"
- "Considera crear un presupuesto para entretenimiento"

**Plan requerido**: Pro (5 predicciones/mes), Premium (20 predicciones/mes)

### 🧠 AI Memory - Tu Segunda Memoria

Captura y busca información importante con IA:

**Captura**:
```
- 🎙️ Grabar conversaciones → Transcripción automática
- 📷 Tomar fotos → OCR inteligente con AWS Textract
- 📄 Guardar documentos → Extracción de texto
- ✉️ Reenviar emails → Procesamiento automático
- 🎤 Notas de voz → Transcripción instantánea
```

**Búsqueda Semántica con IA**:
```
Tú: "¿Qué restaurante me recomendaron hace 3 meses?"
IA: [Busca en embeddings vectoriales]

    Resultado #1 (95% relevancia)
    🎙️ Conversación - "Cena con Ana" - 12 Abr 2026
    "...me recomendó un restaurante italiano increíble
    que se llama La Trattoria, está en la calle Reforma..."
```

**Features**:
- Búsqueda en lenguaje natural con pgvector + Amazon Bedrock
- Procesamiento automático con AWS Transcribe + Textract
- Análisis inteligente: extracción de entidades (personas, lugares, fechas)
- Resúmenes automáticos generados por IA
- Organización con etiquetas y favoritos
- Insights semanales de tus memorias
- Integración con otros módulos (crear tareas/transacciones desde memorias)

**Cuotas de Storage por Plan**:
- Free: 2 GB
- Basic: 5 GB
- Pro: 20 GB
- Premium: 100 GB

**Cuotas Mensuales por Tipo**:
- Free: 5 conversaciones, 10 fotos OCR, 10 notas voz, 10 búsquedas IA
- Basic: 20 conversaciones, 50 fotos OCR, 20 documentos, 20 emails, 50 búsquedas IA
- Pro: 100 conversaciones, 200 fotos OCR, 100 documentos, 100 emails, 200 búsquedas IA
- Premium: Todo ilimitado

**Plan requerido**: Free o superior (funcionalidades limitadas por plan)

### ⏰ Notificaciones Inteligentes

Las notificaciones se comportan **automáticamente según la prioridad** de la tarea:

| Prioridad | Tipo de Alerta | Comportamiento |
|-----------|---------------|----------------|
| 🔴 Urgente | Alarma | Sonido continuo, rompe "No Molestar", pantalla completa |
| 🟠 Alta | Alarma | Sonido continuo, rompe "No Molestar", pantalla completa |
| 🟡 Media | Notificación | Sonido breve, discreta, respeta "No Molestar" |
| 🟢 Baja | Notificación | Sonido breve, discreta, respeta "No Molestar" |

**Implementación**:
- AWS SNS con APNS (iOS) y FCM (Android)
- EventBridge para programación
- Lambda notifications determina el estilo automáticamente

### 📱 Captura Automática de SMS

Lectura automática de SMS bancarios (Android):

```
SMS: "Compra por $350.50 en STARBUCKS con tu tarjeta *1234"
         ↓
IA Parser → Transacción creada → Categoría automática → Push notification
```

**Features**:
- Detección automática de SMS financieros
- Categorización inteligente con IA
- Creación automática de transacción
- Solo procesa SMS bancarios (privacidad)
- Plan requerido: **Premium**

### 🔐 Seguridad Multicapa + IA

1. **TLS 1.3** en tránsito
2. **JWT RS256** para autenticación
3. **RBAC + Feature Gating** por plan
4. **RLS + Filtrado obligatorio** por `organization_id` y `user_id`
5. **AES-256-GCM** para contraseñas guardadas
6. **Análisis de seguridad con IA**: Detecta contraseñas débiles, reutilizadas, comprometidas
7. **Auditoría** completa de accesos

---

## Planes de Suscripción con IA

| Feature | Free | Basic | Pro ⭐ | Premium |
|---------|------|-------|--------|---------|
| **Precio/mes** | $0 | $4.99 | $9.99 | $19.99 |
| **Tareas** | Manual | Manual | Manual + Voz | Manual + Voz |
| **Voz Tareas/mes** | 0 | 10 | 100 | Ilimitado |
| **Contraseñas** | ❌ | ✅ | ✅ | ✅ |
| **Análisis Seguridad IA** | ❌ | ❌ | ❌ | ✅ |
| **Finanzas** | ❌ | ❌ | ✅ | ✅ |
| **Voz Finanzas/mes** | 0 | 0 | 50 | 200 |
| **Chat IA msgs/mes** | 0 | 20 | 100 | 500 |
| **Predicciones IA/mes** | 0 | 0 | 5 | 20 |
| **Auto-categorización IA** | ❌ | ❌ | ✅ | ✅ |
| **Insights IA** | ❌ | ❌ | Semanal | Diario |
| **Captura SMS** | ❌ | ❌ | ❌ | ✅ |
| **Reportes** | ❌ | ❌ | CSV | PDF/Excel |
| **Soporte** | Email | Email | Email + Chat | Priority |

---

## Roadmap de Desarrollo

### Fase 1 - MVP (Meses 1-3)
- ✅ Arquitectura completa documentada con IA
- Autenticación JWT (sin Cognito)
- Módulo de Tareas básico (manual)
- Lambda como microservicios
- RDS PostgreSQL con RLS
- App móvil React Native básica
- Sistema de cuotas de IA

### Fase 2 - Módulos Core (Meses 4-6)
- Módulo de Contraseñas encriptadas
- Módulo de Finanzas (manual)
- Sistema de suscripciones y pagos (Stripe)
- Notificaciones push inteligentes (alarma vs notificación)
- Panel web admin (Angular)
- Dashboard financiero básico

### Fase 3 - Features de IA (Meses 7-9)
- **Registro por voz en Tareas** (Transcribe + Bedrock)
- **Registro por voz en Finanzas** (Transcribe + Bedrock)
- **Chat IA interno** (Amazon Bedrock/Claude 3.5)
- **Auto-categorización con IA**
- Captura automática de SMS
- Predicciones financieras básicas
- Reportes avanzados (PDF/Excel)

### Fase 4 - IA Avanzada (Meses 10-12)
- **Insights automáticos con IA**
- **Recomendaciones personalizadas**
- **Detección de anomalías financieras**
- **Análisis de seguridad de passwords con IA**
- Resúmenes automáticos por IA
- Predicciones avanzadas (Amazon Forecast)
- Optimización de costos de IA

### Fase 5 - Optimización (Meses 13-15)
- RDS Proxy para conexiones
- Cache con Redis/ElastiCache
- Performance tuning
- Refinamiento UI/UX
- Multi-región (DR)
- Integraciones bancarias (Plaid)

---

## Costos Estimados

### Infraestructura Base Sin Usuarios (~$20/mes)
- RDS PostgreSQL (db.t4g.micro): $12-15
- Lambda (1M requests): $0.20
- API Gateway (1M requests): $3.50
- Parameter Store: Gratis
- S3 (10 GB): $0.23
- CloudWatch: $2.50

### Con IA y 1000 Usuarios Activos (~$170-220/mes)
- RDS PostgreSQL: $15-20
- Lambda (5M requests): $18
- API Gateway (5M requests): $18
- S3 (50 GB): $2
- **Amazon Bedrock** (Claude 3.5): $25-40
- **AWS Transcribe** (2K min audio): $48
- SNS (Push notifications): $1
- SES (Emails): $1
- NAT Gateway: $37
- CloudWatch: $6

### Desglose de Costos de IA
- **Amazon Bedrock** (Claude 3.5 Sonnet):
  - Input: $3 por millón de tokens
  - Output: $15 por millón de tokens
  - Estimado 1000 usuarios: $25-40/mes

- **AWS Transcribe**:
  - $0.024 por minuto
  - Estimado 2000 min/mes: $48/mes

### Estrategia de Monetización
- Free/Basic: Subsidiar con planes pagos
- Pro ($9.99/mes): 1000 usuarios = $9,990/mes ingresos
- Premium ($19.99/mes): 100 usuarios = $1,999/mes ingresos
- **Margen**: Con 1100 usuarios (1000 Pro + 100 Premium) = $11,989 ingresos - $220 costos = **$11,769 ganancia/mes**

---

## Seguridad

### Prioridades

1. **Filtrado obligatorio** por `organization_id` AND `user_id` en TODAS las queries
2. **Row-Level Security (RLS)** como capa adicional
3. **Encriptación** de contraseñas con AES-256-GCM
4. **JWT** con claves RS256 en Parameter Store
5. **Auditoría** de accesos a datos sensibles
6. **Rate limiting** por endpoint
7. **Validación** de inputs
8. **OWASP Top 10** compliance

---

## Contacto y Soporte

- **Proyecto**: TEMIS - Gestión Inteligente con IA
- **Versión de Documentación**: 1.1.0
- **Última actualización**: 2026-07-12
- **Nueva Features**: IA integrada, Chat conversacional, Voz en tareas, Predicciones

---

## Licencia

[Definir licencia]

---

## Siguientes Pasos

1. Revisar toda la documentación en `/docs`
2. Configurar ambiente de AWS
3. Crear repositorios Git (backend, frontend-mobile, frontend-web)
4. Configurar CI/CD pipeline
5. Desarrollar MVP (Fase 1)

---

**¡Bienvenido a TEMIS!** 🚀
