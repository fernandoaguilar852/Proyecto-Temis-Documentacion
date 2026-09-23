# Arquitectura General del Sistema
## Proyecto: TEMIS - Gestión de Tareas y Finanzas Personales

### Información del Proyecto
- **Nombre**: TEMIS
- **Tipo**: Aplicación Móvil Multiplataforma + Web Admin
- **Versión**: 1.0.0
- **Fecha**: Julio 2026

---

## 1. Descripción General

TEMIS es una aplicación multitenante **potenciada por IA** que permite a los usuarios gestionar tres áreas principales de su vida digital:
- **Módulo de Tareas y Calendario**: Gestión de tareas con **IA y voz**, eventos, recordatorios inteligentes y alertas programadas
- **Módulo de Gestor de Contraseñas**: Almacenamiento seguro de credenciales con análisis de seguridad IA
- **Módulo de Finanzas Personales**: Registro por voz/SMS, análisis con IA, predicciones y recomendaciones inteligentes
- **Asistente IA Integrado**: Chat conversacional para consultas, análisis y recomendaciones personalizadas

---

## 2. Arquitectura de Alto Nivel

### 2.1 Stack Tecnológico

#### Frontend
- **Móvil**: React Native (iOS + Android)
- **Web Admin**: Angular
- **Lenguaje**: TypeScript/JavaScript

#### Backend
- **Arquitectura**: Serverless con Microservicios
- **Runtime**: Node.js 18.x+
- **Compute**: AWS Lambda (12+ funciones independientes)
- **API Gateway**: AWS API Gateway (REST)
- **Autenticación**: JWT puro (RS256) - Claves en Parameter Store

#### Base de Datos
- **Principal**: Amazon RDS PostgreSQL (db.t4g.micro)
- **Versión**: PostgreSQL 15.x
- **Motor**: PostgreSQL con extensiones (uuid-ossp, pgcrypto)

#### Infraestructura AWS
- **Región Principal**: us-east-1 (N. Virginia)
- **VPC**: VPC privada para RDS
- **Lambda**: Funciones serverless en Node.js (microservicios)
- **S3**: Almacenamiento de archivos estáticos y backups
- **Parameter Store**: Almacenamiento de secrets (JWT keys)
- **CloudWatch**: Logs y monitoreo
- **SNS/SES**: Notificaciones push y email
- **EventBridge**: Programación de tareas recurrentes

#### Servicios de IA
- **Amazon Bedrock**: LLM para chat IA y análisis (Claude 3.5 Sonnet)
- **AWS Transcribe**: Conversión de voz a texto
- **Amazon Comprehend**: NLP y análisis de sentimientos (opcional)
- **Amazon Forecast**: Predicciones financieras (opcional)

---

## 3. Principios Arquitectónicos

### 3.1 Multitenancy
- Arquitectura de tenant único por organización
- Aislamiento de datos a nivel de base de datos (Row-Level Security)
- Cada usuario pertenece a una organización
- Las organizaciones tienen suscripciones con diferentes planes

### 3.2 Seguridad
- **Encriptación en tránsito**: TLS 1.3
- **Encriptación en reposo**:
  - RDS: Encriptación nativa de AWS KMS
  - Contraseñas guardadas: AES-256-GCM por registro
- **Autenticación**: JWT RS256 + bcrypt para passwords
- **Autorización**: RBAC (Role-Based Access Control) + Feature Gating por plan
- **Secrets Management**: AWS Parameter Store (claves JWT, encriptación)
- **Aislamiento de datos**: Filtrado obligatorio por `organization_id` + `user_id`
- **Row-Level Security**: Políticas RLS en PostgreSQL

### 3.3 Escalabilidad
- **Horizontal**: Lambda escala automáticamente
- **Vertical**: RDS puede escalar a instancias mayores
- **Conexiones DB**: Connection pooling con RDS Proxy (futuro)
- **Cache**: ElastiCache Redis (implementación futura)

### 3.4 Disponibilidad
- **SLA Objetivo**: 99.5% uptime
- **Backups**: Automáticos diarios (7 días de retención)
- **Disaster Recovery**: Snapshots manuales semanales
- **Multi-AZ**: Implementación futura para producción

---

## 4. Flujos Principales

### 4.1 Flujo de Autenticación
```
Usuario → App Móvil → API Gateway → Lambda Auth → PostgreSQL
→ JWT Token (firmado con clave de Parameter Store)
```

### 4.2 Flujo de Operación CRUD
```
App → API Gateway → Lambda Authorizer (valida JWT) → Lambda Function
→ RDS PostgreSQL (con filtrado obligatorio por user_id) → Response
```

### 4.3 Flujo de Registro de Tareas por Voz
```
Usuario (Audio: "Recordarme comprar leche mañana")
→ App → API Gateway → Lambda Tasks
→ AWS Transcribe (Speech-to-Text)
→ Amazon Bedrock (parsear intención, fecha, prioridad)
→ PostgreSQL → Response
```

### 4.4 Flujo de Registro de Finanzas por Voz
```
Usuario (Audio: "Gasté 50 dólares en el supermercado")
→ App → API Gateway → Lambda Transactions
→ AWS Transcribe (Speech-to-Text)
→ Amazon Bedrock (extraer monto, categoría, tipo)
→ PostgreSQL → Response
```

### 4.5 Flujo de Chat IA
```
Usuario: "¿Cuánto gasté en restaurantes este mes?"
→ App → API Gateway → Lambda AI-Chat
→ PostgreSQL (obtener datos del usuario)
→ Amazon Bedrock (generar respuesta contextual)
→ Response al usuario
```

### 4.6 Flujo de Captura SMS
```
SMS Bancario → App (Listener Local) → API Gateway → Lambda SMS Parser
→ PostgreSQL → Notificación Push (según prioridad)
```

---

## 5. Módulos del Sistema

### 5.1 Módulo de Tareas y Calendario
**Funcionalidades**:
- CRUD de tareas (manual y **por voz**)
- **Creación por voz con IA**: "Recordarme llamar al doctor mañana a las 3"
- Calendario mensual/semanal/diario
- **Recordatorios inteligentes**: Notificación según prioridad (alarma vs push)
- **Sugerencias de IA**: Auto-completar fecha/hora, estimar duración
- Etiquetas y categorías con auto-etiquetado IA
- Prioridades automáticas sugeridas por IA
- Estados y seguimiento de progreso

### 5.2 Módulo de Gestor de Contraseñas
**Funcionalidades**:
- Almacenamiento encriptado de credenciales (AES-256-GCM)
- Categorías: Sitios web, bancos, WiFi, otros
- Generador de contraseñas seguras
- **Análisis de seguridad con IA**: Contraseñas débiles, reutilizadas, comprometidas
- **Detección de brechas**: Alertas si password fue filtrada
- Búsqueda y filtrado inteligente
- Auditoría de seguridad (Plan Premium)

### 5.3 Módulo de Finanzas Personales
**Funcionalidades**:
- Registro manual de ingresos/egresos
- **Registro por voz con IA**: "Gasté 50 dólares en supermercado"
- **Captura automática de SMS** bancarios (Android)
- **Categorización inteligente con IA**: Aprende de patrones del usuario
- **Predicciones financieras**: "Gastarás ~$1,200 en alimentación este mes"
- **Detección de anomalías**: "Gastaste 300% más en entretenimiento"
- **Recomendaciones personalizadas**: "Puedes ahorrar $200/mes si..."
- Dashboard financiero con insights IA
- Presupuestos inteligentes
- Reportes avanzados (PDF/Excel)

### 5.4 Asistente IA (Chat Conversacional)
**Funcionalidades**:
- **Chat con IA contextual**: Responde preguntas sobre tus datos
- Ejemplos de preguntas:
  - "¿Cuánto gasté en restaurantes este mes?"
  - "¿Cuántas tareas completé esta semana?"
  - "¿Cuál es mi contraseña más débil?"
  - "Dame un resumen de mis finanzas"
- **Análisis inteligente**: Identifica patrones y tendencias
- **Recomendaciones proactivas**: Sugerencias basadas en comportamiento
- **Resúmenes automáticos**: Diarios, semanales, mensuales
- **Límites por plan**: Mensajes limitados según suscripción

---

## 6. Sistema de Suscripciones

### 6.1 Planes Disponibles con Límites de IA

| Feature | Free | Basic | Pro | Premium |
|---------|------|-------|-----|---------|
| **Precio/mes** | $0 | $4.99 | $9.99 | $19.99 |
| **Usuarios** | 1 | 1 | 1 | 1 |
| **Tareas** | Manual | Manual | Manual + Voz | Manual + Voz |
| **Voz Tareas/mes** | 0 | 10 | 100 | Ilimitado |
| **Contraseñas** | ❌ | ✅ Ilimitadas | ✅ Ilimitadas | ✅ Ilimitadas |
| **Auditoría Passwords** | ❌ | ❌ | ❌ | ✅ |
| **Finanzas** | ❌ | ❌ | ✅ | ✅ |
| **Voz Finanzas/mes** | 0 | 0 | 50 | 200 |
| **Captura SMS** | ❌ | ❌ | ❌ | ✅ |
| **Chat IA msgs/mes** | 0 | 20 | 100 | 500 |
| **Predicciones IA/mes** | 0 | 0 | 5 | 20 |
| **Auto-categorización** | ❌ | ❌ | ✅ | ✅ |
| **Insights IA** | ❌ | ❌ | Semanal | Diario |
| **Reportes** | ❌ | ❌ | CSV | PDF/Excel |
| **Soporte** | Email | Email | Email + Chat | Priority |

### 6.2 Control de Acceso y Límites
- **Feature Gating**: Basado en el plan de suscripción activo
- **AI Quota System**: Límites mensuales de uso de IA por plan
- **Tracking**: Tabla `ai_usage` registra uso de cada feature IA
- **Verificación**: En Lambda Authorizer (features) y middleware (cuotas IA)
- **Upgrade prompts**: Cuando se excede límite, sugerir upgrade
- **Reset mensual**: Cuotas se resetean el 1ro de cada mes

---

## 7. Integraciones Externas

### 7.1 AWS Services
- **Parameter Store**: Almacenamiento de claves JWT y secrets
- **Amazon Bedrock**: LLM (Claude 3.5 Sonnet) para chat IA y análisis
- **AWS Transcribe**: Transcripción de audio a texto (voz)
- **SNS**: Notificaciones push móviles (con prioridad por tarea)
- **SES**: Envío de emails transaccionales
- **S3**: Almacenamiento de archivos, audio y backups
- **CloudWatch**: Logs, métricas y alarmas
- **EventBridge**: Programación de recordatorios y tareas recurrentes
- **Amazon Comprehend** (opcional): NLP y análisis de sentimientos
- **Amazon Forecast** (opcional): Predicciones financieras avanzadas

### 7.2 Servicios de Terceros (Futuros)
- **Stripe/PayPal**: Procesamiento de pagos
- **Have I Been Pwned API**: Detección de contraseñas comprometidas
- **Plaid**: Integración bancaria automática (opcional)
- **Twilio**: SMS y WhatsApp (opcional)

---

## 8. Consideraciones de Rendimiento

### 8.1 Objetivos
- **Latencia API**: < 500ms (p95)
- **Cold Start Lambda**: < 1s
- **Tiempo de carga app**: < 2s

### 8.2 Optimizaciones
- Paginación en listados (20-50 items)
- Índices de base de datos optimizados
- Compresión de respuestas (gzip)
- Lazy loading en frontend
- Caché local en app móvil

---

## 9. Monitoreo y Observabilidad

### 9.1 Métricas Clave
- Número de usuarios activos (DAU/MAU)
- Tasa de error de APIs
- Latencia de endpoints
- Uso de base de datos (CPU, memoria, conexiones)
- Cold starts de Lambda

### 9.2 Alertas
- Error rate > 5%
- Latencia p95 > 1s
- DB connections > 80%
- Costos mensuales > presupuesto

---

## 10. Estrategia de Despliegue

### 10.1 Ambientes
- **dev**: Desarrollo local y pruebas
- **staging**: Pre-producción para QA
- **production**: Ambiente productivo

### 10.2 CI/CD
- **Source Control**: Git (GitHub/GitLab)
- **Pipeline**: GitHub Actions / AWS CodePipeline
- **Testing**: Jest (backend), React Native Testing Library (frontend)
- **Deployment**: Serverless Framework / AWS SAM

### 10.3 Estrategia de Rollout
- Despliegue gradual (canary deployment)
- Feature flags para nuevas funcionalidades
- Rollback automático en caso de errores

---

## 11. Costos Estimados (Mensual)

### 11.1 Infraestructura Base (Sin usuarios)
| Servicio | Costo Estimado |
|----------|----------------|
| RDS PostgreSQL (db.t4g.micro) | $12-15 |
| Lambda (1M requests) | $0.20 |
| API Gateway (1M requests) | $3.50 |
| Parameter Store (Standard) | Gratis |
| S3 (10 GB) | $0.23 |
| CloudWatch Logs (5 GB) | $2.50 |
| **TOTAL Base** | **~$20/mes** |

### 11.2 Con IA y 1000 Usuarios Activos
| Servicio | Costo Estimado |
|----------|----------------|
| RDS PostgreSQL | $15-20 |
| Lambda (5M requests) | $18 |
| API Gateway (5M requests) | $18 |
| S3 (50 GB) | $2 |
| Transcribe (2K min audio) | $48 |
| **Amazon Bedrock** (Claude 3.5) | $25-40 |
| SNS (Push notifications) | $1 |
| SES (Emails) | $1 |
| NAT Gateway | $37 |
| CloudWatch | $6 |
| **TOTAL con IA** | **~$170-220/mes** |

### 11.3 Desglose de Costos de IA
- **Amazon Bedrock** (Claude 3.5 Sonnet):
  - Input: $3 por millón de tokens (~$15/mes)
  - Output: $15 por millón de tokens (~$25/mes)
  - Estimado para 1000 usuarios: $25-40/mes

- **AWS Transcribe**:
  - $0.024 por minuto de audio
  - Estimado 2000 min/mes: $48/mes

- **Estrategia de monetización**:
  - Free/Basic: Subsidiar con planes pagos
  - Pro/Premium: Cubren costos de IA + margen

---

## 12. Roadmap Técnico

### Fase 1 - MVP (Meses 1-3)
- ✅ Arquitectura base documentada
- Autenticación JWT (sin Cognito)
- Módulo de tareas básico (manual)
- Lambda como microservicios
- RDS PostgreSQL con RLS
- App móvil React Native básica
- Web admin Angular básica
- Sistema de cuotas de IA

### Fase 2 - Módulos Core (Meses 4-6)
- Módulo de contraseñas encriptadas
- Módulo de finanzas (manual)
- Sistema de suscripciones y pagos
- Notificaciones push inteligentes (alarma vs notificación)
- Integración con Stripe
- Panel admin completo

### Fase 3 - Features de IA (Meses 7-9)
- **Registro por voz en Tareas** (Transcribe + Bedrock)
- **Registro por voz en Finanzas** (Transcribe + Bedrock)
- **Chat IA interno** (Amazon Bedrock/Claude)
- **Auto-categorización con IA**
- Captura automática de SMS
- Predicciones financieras básicas
- Reportes avanzados (PDF/Excel)

### Fase 4 - IA Avanzada (Meses 10-12)
- **Insights automáticos con IA**
- **Recomendaciones personalizadas**
- **Detección de anomalías financieras**
- **Predicciones avanzadas** (Amazon Forecast)
- **Análisis de seguridad de passwords** (Have I Been Pwned)
- Resúmenes automáticos por IA
- Optimización de costos de IA

### Fase 5 - Optimización (Meses 13-15)
- Cache con Redis/ElastiCache
- RDS Proxy para conexiones
- Multi-región (DR)
- Integraciones bancarias (Plaid)
- Performance tuning
- Mobile app refinamiento

---

## 13. Riesgos y Mitigaciones

| Riesgo | Impacto | Probabilidad | Mitigación |
|--------|---------|--------------|------------|
| Costo de IA mayor a estimado | Alto | Media | Sistema de cuotas por plan, monitoreo constante, optimizar prompts |
| Costo de RDS mayor a estimado | Alto | Media | Monitoreo continuo, optimización de queries, RDS Proxy |
| Calidad de IA inconsistente | Medio | Media | Testing extensivo, feedback loop, fine-tuning de prompts |
| Cold starts de Lambda | Medio | Alta | Provisioned concurrency en endpoints críticos |
| Seguridad de contraseñas | Crítico | Baja | Auditoría de seguridad, encriptación AES-256-GCM |
| Escalabilidad de conexiones DB | Alto | Media | Implementar RDS Proxy cuando sea necesario |
| Captura SMS en iOS | Alto | Media | Uso de APIs nativas limitadas, educación al usuario |
| Abuso de cuotas de IA | Medio | Media | Rate limiting, validación en backend, alertas automáticas |
| Privacidad de datos con IA | Alto | Baja | No enviar datos sensibles a IA, anonimización, compliance |

---

## 14. Referencias

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS Transcribe Best Practices](https://docs.aws.amazon.com/transcribe/)
- [React Native Best Practices](https://reactnative.dev/docs/getting-started)
- [PostgreSQL Performance Tuning](https://www.postgresql.org/docs/current/performance-tips.html)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Claude API Documentation](https://docs.anthropic.com/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.1.0 - Actualizado con features de IA
