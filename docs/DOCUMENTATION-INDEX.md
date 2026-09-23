# 📚 ÍNDICE MAESTRO DE DOCUMENTACIÓN - PROYECTO TEMIS

**Fecha**: 2026-09-23
**Versión del Proyecto**: 1.3.0
**Estado**: ✅ DOCUMENTACIÓN COMPLETA

---

## 🎯 Navegación Rápida

| Categoría | Documentos | Estado |
|-----------|------------|--------|
| **🏗️ Arquitectura** | 7 documentos | ✅ 100% |
| **💾 Base de Datos** | 3 documentos | ✅ 100% |
| **🔌 APIs y Contratos** | 16 contratos YAML | ✅ 100% |
| **🎨 Diseño UI/UX** | 4 documentos | ✅ 100% |
| **📋 Gestión** | 4 documentos | ✅ 100% |
| **🔒 Seguridad** | 1 documento | ✅ 100% |
| **🚀 Backend** | 1 documento | ✅ 100% |

---

## 1️⃣ ARQUITECTURA DEL SISTEMA

### Documentos Principales

| # | Documento | Descripción | Ubicación |
|---|-----------|-------------|-----------|
| 1.1 | **01-ARCHITECTURE-OVERVIEW.md** | Visión general de la arquitectura serverless, módulos, infraestructura AWS | `/docs/architecture/` |
| 1.2 | **02-ARCHITECTURE-DIAGRAMS.md** | 13 diagramas Mermaid (arquitectura general, VPC, flujos de auth, CRUD, IA) | `/docs/architecture/` |
| 1.3 | **03-MODULES-FEATURES.md** | Especificación detallada de todos los módulos y features por plan de suscripción | `/docs/architecture/` |
| 1.4 | **04-AWS-INFRASTRUCTURE.md** | Infraestructura AWS completa (16 lambdas, RDS, S3, Bedrock, Cost Explorer) | `/docs/architecture/` |
| 1.5 | **05-SECURITY-MULTITENANCY.md** | Estrategia de seguridad, RLS policies, JWT RS256, multitenancy 100/100 | `/docs/architecture/` |
| 1.6 | **06-MODULE-AI-MEMORY.md** | Módulo "Segunda Memoria Digital" con búsqueda semántica, 5 tipos de captura | `/docs/architecture/` |
| 1.7 | **07-SMS-CAPTURE-FLOW.md** ✅ | Flujo de captura automática de SMS bancarios (Premium) con Android BroadcastReceiver | `/docs/architecture/` |

**Contenido Clave:**
- Stack tecnológico completo
- 16 Lambda functions con responsabilidades
- Integración con Amazon Bedrock (Claude 3.5 Sonnet)
- Costos estimados: $290/mes para 1000 usuarios
- 4 planes de suscripción (Free, Basic, Pro, Premium)

---

## 2️⃣ BASE DE DATOS

### Documentos PostgreSQL

| # | Documento | Descripción | Ubicación |
|---|-----------|-------------|-----------|
| 2.1 | **DATABASE-SCHEMA.md** | Schema completo v1.3.0 con 16+ tablas, RLS policies, triggers, funciones | `/docs/database/` |
| 2.2 | **MULTITENANCY-AUDIT-SUMMARY.md** | Auditoría de multitenancy, fixes aplicados, score 100/100 | `/docs/database/` |
| 2.3 | **MIGRATION-001-FIX-MULTITENANCY.sql** | Migration para bases existentes (añade organization_id, RLS policies) | `/docs/database/` |

**Contenido Clave:**
- PostgreSQL 15.x con extensiones: uuid-ossp, pgcrypto, pg_trgm, vector (pgvector)
- 16 tablas con RLS policies completas
- Funciones críticas:
  - `check_plan_feature(organization_id, user_id, feature)`
  - `check_ai_quota(organization_id, user_id, feature_type)`
  - `check_task_limit(organization_id, user_id)` ✅ **NUEVO**
  - `check_storage_quota(organization_id, user_id, file_size_bytes)`
  - `check_memory_quota(organization_id, user_id, memory_type)`
- Triggers automáticos para poblar organization_id/user_id
- Índices optimizados para queries con 1000+ usuarios (<50ms)

---

## 3️⃣ APIS Y CONTRATOS

### 3.1 Documentación General

| Documento | Descripción | Ubicación |
|-----------|-------------|-----------|
| **API-ENDPOINTS.md** | Lista completa de endpoints de las 16 lambdas con ejemplos | `/docs/api/` |
| **contratos/README.md** | Estándares de contratos Swagger 2.0, estructura de respuestas | `/contratos/` |

### 3.2 Contratos Swagger (16 Lambdas)

| # | Lambda | Contrato | Estado | Ubicación |
|---|--------|----------|--------|-----------|
| 1 | lambda-auth | **TEMIS_CONTRATO_AUTH_V1.0.yaml** | ✅ Completo + revoke/verify endpoints | `/contratos/` |
| 2 | lambda-users | **TEMIS_CONTRATO_USERS_V1.0.yaml** | ✅ Completo | `/contratos/` |
| 3 | lambda-tasks | **TEMIS_CONTRATO_TASKS_V1.0.yaml** | ✅ Completo + subtareas endpoints | `/contratos/` |
| 4 | lambda-passwords | **TEMIS_CONTRATO_PASSWORDS_V1.0.yaml** | ✅ Completo | `/contratos/` |
| 5 | lambda-transactions | **TEMIS_CONTRATO_TRANSACTIONS_V1.0.yaml** | ✅ Completo + import CSV endpoint | `/contratos/` |
| 6 | lambda-categories | **TEMIS_CONTRATO_CATEGORIES_V1.0.yaml** | ✅ Completo | `/contratos/` |
| 7 | lambda-budgets | **TEMIS_CONTRATO_BUDGETS_V1.0.yaml** | ✅ Completo + projection endpoint | `/contratos/` |
| 8 | lambda-tags | **TEMIS_CONTRATO_TAGS_V1.0.yaml** | ✅ Completo | `/contratos/` |
| 9 | lambda-reminders | **TEMIS_CONTRATO_REMINDERS_V1.0.yaml** | ✅ Completo | `/contratos/` |
| 10 | lambda-voice | **TEMIS_CONTRATO_VOICE_V1.0.yaml** | ✅ Completo + retry endpoint | `/contratos/` |
| 11 | lambda-ai | **TEMIS_CONTRATO_AI_V1.0.yaml** | ✅ Completo | `/contratos/` |
| 12 | lambda-subscriptions | **TEMIS_CONTRATO_SUBSCRIPTIONS_V1.0.yaml** | ✅ Completo + retry payment + alerts | `/contratos/` |
| 13 | lambda-webhooks | **TEMIS_CONTRATO_WEBHOOKS_V1.0.yaml** | ✅ Completo + HMAC validation completa | `/contratos/` |
| 14 | lambda-admin | **TEMIS_CONTRATO_ADMIN_V1.0.yaml** | ✅ Completo | `/contratos/` |
| 15 | lambda-ai-memory | **TEMIS_CONTRATO_AI_MEMORY_V1.0.yaml** | ✅ Completo + GDPR compliance (DELETE/export) | `/contratos/` |
| 16 | lambda-ai-monitoring | **TEMIS_CONTRATO_AI_MONITORING_V1.0.yaml** | ✅ Completo + SNS notifications | `/contratos/` |

### 3.3 Documentos de Soporte

| Documento | Descripción | Ubicación |
|-----------|-------------|-----------|
| **LAMBDAS-RESUMEN.md** | Resumen detallado de las 16 lambdas con responsabilidades | `/contratos/` |
| **AI-MONITORING-RESUMEN.md** | Especificación del sistema de monitoreo de costos de IA | `/contratos/` |
| **lambda-ai-monitoring-implementation.md** | Guía de implementación del monitoreo de IA | `/contratos/` |

---

## 4️⃣ DISEÑO UI/UX

### Mockups y Sistema de Diseño

| # | Documento | Descripción | Ubicación |
|---|-----------|-------------|-----------|
| 4.1 | **README.md** | Visión general de mockups, 100 pantallas planeadas | `/MOCKUPS/` |
| 4.2 | **DESIGN-SYSTEM.md** | Sistema de diseño completo (colores, tipografía, componentes) | `/MOCKUPS/` |
| 4.3 | **TEMPLATE-MOCKUP-SPECS.md** | Plantilla para especificar mockups individuales | `/MOCKUPS/` |
| 4.4 | **EXPORT-SPECIFICATIONS.md** | Especificaciones de exportación de diseños (@1x, @2x, @3x) | `/MOCKUPS/` |

**Contenido Clave:**
- **Colores:** Primary #3B82F6, Secondary #8B5CF6, Success #10B981
- **Tipografía:** Inter (Google Fonts), H1 32px, Body 16px
- **Componentes:** Botones, Cards, Inputs, FAB, Badges, Chips
- **100 Pantallas Planeadas:**
  - AUTH: 6 pantallas
  - ONBOARDING: 7 pantallas
  - TAREAS: 11 pantallas
  - PASSWORDS: 10 pantallas
  - FINANZAS: 13 pantallas
  - IA-ASISTENTE: 8 pantallas
  - AI-MEMORY: 23 pantallas ⭐
  - CONFIGURACION: 9 pantallas
  - SUSCRIPCIONES: 13 pantallas

---

## 5️⃣ GESTIÓN Y PLANIFICACIÓN

### Documentos de Gestión

| # | Documento | Descripción | Ubicación |
|---|-----------|-------------|-----------|
| 5.1 | **README.md** (principal) | README principal del proyecto con visión general | `/` |
| 5.2 | **DOCUMENTATION-UPDATES-REQUIRED.md** 🆕 | Lista completa de actualizaciones pendientes en contratos (17 updates) | `/docs/` |
| 5.3 | **DOCUMENTATION-INDEX.md** 🆕 | Este documento - Índice maestro de toda la documentación | `/docs/` |
| 5.4 | **Changelog** (implícito) | Historial de cambios documentado en MULTITENANCY-AUDIT-SUMMARY.md | `/docs/database/` |

---

## 6️⃣ SEGURIDAD

### Documentos de Seguridad

| # | Documento | Descripción | Ubicación |
|---|-----------|-------------|-----------|
| 6.1 | **05-SECURITY-MULTITENANCY.md** | Estrategia completa de seguridad y multitenancy | `/docs/architecture/` |

**Contenido Clave:**
- JWT RS256 (sin AWS Cognito)
- Row-Level Security (RLS) en todas las tablas
- Filtrado obligatorio: `WHERE organization_id = $1 AND user_id = $2`
- SecureQuery helper class
- Cifrado AES-256-GCM para contraseñas
- Validación de cuotas de IA
- Modo READ-ONLY al expirar suscripción
- Rate limiting documentado en contratos AUTH y VOICE

---

## 7️⃣ BACKEND

### Documentos de Backend

| # | Documento | Descripción | Ubicación |
|---|-----------|-------------|-----------|
| 7.1 | **LAMBDA-LAYERS.md** ✅ | Lambda layers compartidos (core, subscription, ai-quota middleware) | `/docs/backend/` |

**Contenido:**
- `temis-core-layer`: Database pool, JWT utils, response formatter, logger, error handling
- `temis-subscription-middleware`: Validación de suscripción y permisos de escritura
- `temis-ai-quota-middleware`: Validación de cuota de IA con check y tracking
- Reduce código en lambdas -70%, deployment size -75%, tiempo desarrollo -75%
- Código completo de implementación con ejemplos de uso

---

## 📊 RESUMEN DE DOCUMENTACIÓN

### Estadísticas Generales

| Categoría | Total Documentos | Completos | Pendientes | % Completitud |
|-----------|------------------|-----------|------------|---------------|
| **Arquitectura** | 7 | 7 | 0 | 100% ✅ |
| **Base de Datos** | 3 | 3 | 0 | 100% ✅ |
| **Contratos API** | 16 | 16 | 0 | 100% ✅ |
| **Diseño UI/UX** | 4 | 4 | 0 | 100% ✅ |
| **Gestión** | 4 | 4 | 0 | 100% ✅ |
| **Seguridad** | 1 | 1 | 0 | 100% ✅ |
| **Backend** | 1 | 1 | 0 | 100% ✅ |
| **TOTAL** | **36** | **36** | **0** | **100%** 🎉 |

### ✅ Todos los Gaps Resueltos

Todos los **17 gaps funcionales** identificados en `DOCUMENTATION-UPDATES-REQUIRED.md` han sido completados:

**Actualizaciones Completadas - Contratos YAML:**
1. ✅ AUTH: Añadido POST /auth/revoke-all-sessions
2. ✅ AUTH: Añadido POST /auth/verify con validación JWT
3. ✅ AI_MEMORY: Añadido DELETE /memories/{id} (GDPR - Derecho al Olvido)
4. ✅ AI_MEMORY: Añadido GET /memories/export (GDPR - Data Portability)
5. ✅ AI_MEMORY: Añadido GET /memories/export/{jobId}/status
6. ✅ WEBHOOKS: Mejorada documentación HMAC con código completo Node.js
7. ✅ SUBSCRIPTIONS: Añadido POST /subscriptions/retry-payment
8. ✅ SUBSCRIPTIONS: Añadido GET /subscriptions/alerts (5 tipos de alertas)
9. ✅ VOICE: Añadido POST /voice/retry/{voiceInputId}
10. ✅ TASKS: Añadido GET/POST /tasks/{taskId}/subtasks
11. ✅ VOICE/AI_MEMORY: Documentadas validaciones de tamaño (10MB photos, 25MB docs, 50MB audio)
12. ✅ AI_MONITORING: Configuradas notificaciones SNS (80%, 90%, 100% thresholds)
13. ✅ TRANSACTIONS: Añadido POST /transactions/import (CSV, máx 500 transacciones)
14. ✅ BUDGETS: Añadido GET /budgets/{id}/projection (proyección de gasto)

**Nuevos Documentos Creados:**
15. ✅ **07-SMS-CAPTURE-FLOW.md**: Flujo completo de captura SMS Android con Kotlin code
16. ✅ **LAMBDA-LAYERS.md**: 3 layers compartidos (core, subscription, ai-quota)

**Actualizaciones de Base de Datos:**
17. ✅ **DATABASE-SCHEMA.md**: Añadida función `check_task_limit()` para validar límites de tareas

---

## 🎯 ROADMAP DE DOCUMENTACIÓN

### ✅ Completado (100%)

**Fase 1 - Arquitectura Fundacional:**
- ✅ Arquitectura del sistema (7/7 documentos)
- ✅ Base de datos completa con multitenancy 100/100
- ✅ Sistema de diseño UI/UX completo
- ✅ Índice maestro de documentación

**Fase 2 - Contratos y APIs:**
- ✅ 16 contratos Swagger completados
- ✅ Todos los endpoints críticos añadidos (auth, GDPR, subscriptions)
- ✅ Validaciones de tamaño documentadas
- ✅ HMAC security completa en webhooks

**Fase 3 - Documentación Técnica Avanzada:**
- ✅ **07-SMS-CAPTURE-FLOW.md**: Captura SMS bancarios con Android BroadcastReceiver
- ✅ **LAMBDA-LAYERS.md**: 3 layers compartidos con código completo
- ✅ **check_task_limit()**: Función DB para validar límites de tareas
- ✅ Rate limiting documentado en contratos AUTH y VOICE

**Fase 4 - Compliance y Seguridad:**
- ✅ GDPR compliance completo (DELETE endpoints, export, retention)
- ✅ Security best practices en todos los módulos
- ✅ Multitenancy 100/100 score con RLS policies

### 🎉 Estado Final

**Documentación TEMIS: 100% COMPLETA**
- 36 documentos técnicos
- 16 contratos API completos con todos los endpoints
- 0 gaps pendientes
- Listo para implementación

---

## 📖 CÓMO USAR ESTA DOCUMENTACIÓN

### Para Desarrolladores Backend

1. **Inicio:** Leer `01-ARCHITECTURE-OVERVIEW.md`
2. **Base de Datos:** Ejecutar `DATABASE-SCHEMA.md`
3. **Implementación:** Usar contratos YAML en `/contratos/`
4. **Gaps:** Consultar `DOCUMENTATION-UPDATES-REQUIRED.md`

### Para Desarrolladores Frontend

1. **Diseño:** Revisar `DESIGN-SYSTEM.md`
2. **APIs:** Consultar contratos YAML para endpoints
3. **Flujos:** Ver `02-ARCHITECTURE-DIAGRAMS.md`
4. **Mockups:** Planear con `MOCKUPS/README.md`

### Para Product Managers

1. **Features:** `03-MODULES-FEATURES.md`
2. **Planes:** Ver matriz de features en arquitectura
3. **Costos:** `04-AWS-INFRASTRUCTURE.md` (sección de costos)
4. **Roadmap:** `DOCUMENTATION-UPDATES-REQUIRED.md`

### Para DevOps

1. **Infraestructura:** `04-AWS-INFRASTRUCTURE.md`
2. **Seguridad:** `05-SECURITY-MULTITENANCY.md`
3. **Lambdas:** `LAMBDAS-RESUMEN.md`
4. **Layers:** Pendiente `LAMBDA-LAYERS.md`

---

## 🔗 Enlaces Rápidos

### Documentos Más Importantes

1. 🏗️ [Arquitectura General](/docs/architecture/01-ARCHITECTURE-OVERVIEW.md)
2. 💾 [Schema de BD](/docs/database/DATABASE-SCHEMA.md)
3. 🔒 [Seguridad y Multitenancy](/docs/architecture/05-SECURITY-MULTITENANCY.md)
4. 🤖 [Módulo AI Memory](/docs/architecture/06-MODULE-AI-MEMORY.md)
5. 📋 [Updates Requeridos](/docs/DOCUMENTATION-UPDATES-REQUIRED.md) 🆕
6. 🎨 [Sistema de Diseño](/MOCKUPS/DESIGN-SYSTEM.md)

### Contratos API Críticos

1. [AUTH](/contratos/TEMIS_CONTRATO_AUTH_V1.0.yaml)
2. [TASKS](/contratos/TEMIS_CONTRATO_TASKS_V1.0.yaml)
3. [AI_MEMORY](/contratos/TEMIS_CONTRATO_AI_MEMORY_V1.0.yaml)
4. [SUBSCRIPTIONS](/contratos/TEMIS_CONTRATO_SUBSCRIPTIONS_V1.0.yaml)
5. [WEBHOOKS](/contratos/TEMIS_CONTRATO_WEBHOOKS_V1.0.yaml)

---

## 🆘 Contacto y Soporte

**Equipo de Desarrollo TEMIS**
- Email: dev@temis.app
- Slack: #temis-dev
- Wiki: https://wiki.temis.app

**Para reportar gaps o errores en documentación:**
- Crear issue en GitHub con tag `documentation`
- Actualizar `DOCUMENTATION-UPDATES-REQUIRED.md`

---

**Última Actualización:** 2026-09-23
**Mantenido por:** Equipo de Desarrollo TEMIS
**Versión del Índice:** 2.0 (Completitud 100%)
