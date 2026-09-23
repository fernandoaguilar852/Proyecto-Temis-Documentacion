# Lambda AI Monitoring - Resumen Ejecutivo

## 📋 ¿Qué se creó?

Una **lambda completa de monitoreo y control de consumo de AWS Bedrock** para el panel de administración.

---

## 🎯 Propósito

Permitir a los administradores:
1. **Ver costos** reales de AWS Bedrock en tiempo real
2. **Controlar presupuesto** con alertas automáticas
3. **Habilitar/deshabilitar** funcionalidad de IA instantáneamente
4. **Ajustar cuotas** por plan dinámicamente
5. **Monitorear uso** por usuario y feature

---

## 📁 Archivos Creados

### 1. `TEMIS_CONTRATO_AI_MONITORING_V1.0.yaml`
- **Contrato Swagger/OpenAPI 2.0** completo
- **11 endpoints** para administración de IA
- Solo accesible con rol `admin`

### 2. `lambda-ai-monitoring-implementation.md`
- **Código completo de implementación** (Node.js)
- Estructura de archivos y módulos
- Handlers para cada endpoint
- Integración con AWS Cost Explorer
- Servicios de notificaciones
- Tests unitarios
- Instrucciones de despliegue

### 3. `LAMBDAS-RESUMEN.md` (actualizado)
- Agregada **lambda #16: lambda-ai-monitoring**
- Total de lambdas: **16 funciones serverless**

---

## 🚀 Funcionalidades Principales

### 1. Dashboard de Monitoreo
```
GET /admin/ai-monitoring/dashboard

Retorna:
- Costo actual del mes
- Costo proyectado fin de mes
- Total de llamadas y tokens
- Estado del presupuesto (healthy/warning/critical/exceeded)
- Uso por feature (chat, voice, insights, predictions)
- Top 10 usuarios por consumo
```

**Ejemplo de respuesta:**
```json
{
  "dashboard": {
    "current_month": {
      "cost": 125.50,
      "projected_cost": 387.25,
      "total_calls": 25000,
      "total_tokens_input": 12500000,
      "total_tokens_output": 5000000
    },
    "budget_status": {
      "monthly_budget": 500.00,
      "spent": 125.50,
      "remaining": 374.50,
      "percentage_used": 25.1,
      "status": "healthy"
    }
  }
}
```

### 2. Consulta de Costos (Cost Explorer)
```
GET /admin/ai-monitoring/costs?start_date=2026-07-01&end_date=2026-07-12

Retorna:
- Costos diarios/mensuales reales de AWS
- Total gastado en período
- Desglose por día
```

**Importante:** Usa **AWS Cost Explorer API** para obtener costos REALES.

### 3. Feature Flag (Control de Emergencia)
```
PUT /admin/ai-monitoring/feature-flag
{
  "enabled": false,
  "reason": "Monthly budget exceeded"
}
```

**Efecto inmediato:**
- Todas las llamadas a `lambda-ai` y `lambda-voice` retornan 503
- Los usuarios ven: "Servicio temporalmente no disponible"
- Se registra en base de datos quién lo deshabilitó y por qué
- Notificación a Slack/Email

### 4. Gestión Dinámica de Cuotas
```
PUT /admin/ai-monitoring/quotas
{
  "free": 0,
  "basic": 10,
  "pro": 50,
  "premium": 200
}
```

**Ventajas:**
- Sin redespliegue
- Cambios inmediatos
- Almacenado en Parameter Store

### 5. Configuración de Presupuesto
```
PUT /admin/ai-monitoring/budget
{
  "monthly_budget": 500.00,
  "alert_thresholds": {
    "warning": 80,
    "critical": 90,
    "emergency": 100
  }
}
```

**Alertas automáticas:**
- 80%: Email a equipo dev
- 90%: Email + Slack (crítico)
- 100%: Alerta de emergencia + posible auto-deshabilitación

### 6. Uso por Usuario
```
GET /admin/ai-monitoring/users

Retorna:
- Lista de usuarios ordenados por consumo
- Cuota usada vs límite
- Costo estimado por usuario
- Última llamada
```

---

## 💡 Cómo Funciona

### Arquitectura

```
┌─────────────────────┐
│  Panel Admin Web    │
│  (React Frontend)   │
└──────────┬──────────┘
           │ HTTPS
           ▼
┌─────────────────────┐
│   API Gateway       │
│   /admin/ai-*       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  lambda-ai-monitoring               │
│  ┌───────────────────────────────┐  │
│  │ 1. Valida JWT + rol admin     │  │
│  │ 2. Procesa request            │  │
│  │ 3. Consulta Cost Explorer     │◄─┼─── AWS Cost Explorer
│  │ 4. Consulta DB (ai_usage)     │◄─┼─── PostgreSQL
│  │ 5. Lee/Escribe Parameter Store│◄─┼─── Parameter Store
│  │ 6. Retorna respuesta          │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Flujo de Control de Presupuesto

```
1. Admin configura presupuesto: $500/mes
2. Lambda-ai-monitoring consulta costos cada hora (EventBridge)
3. Si costo > 80%: Alerta warning
4. Si costo > 90%: Alerta crítica
5. Si costo > 100%:
   a. Alerta de emergencia
   b. (Opcional) Auto-deshabilitar feature flag
   c. Notificación inmediata a admin
```

---

## 🔒 Seguridad

### Solo Administradores
```javascript
// Middleware valida rol admin
if (user.role !== 'admin') {
  return 403 Forbidden;
}
```

### JWT con Claim de Rol
```json
{
  "sub": "user-id",
  "email": "admin@temis.com",
  "role": "admin",  ← Requerido
  "iat": 1234567890
}
```

### Audit Logs
Todas las acciones se registran:
- Cambio de feature flag
- Actualización de cuotas
- Actualización de presupuesto

---

## 💰 Respuesta a tu Pregunta: Pago por Consumo

### ✅ SÍ, AWS Bedrock es pago por consumo

**Costos:**
- Input: $3.00 / 1M tokens
- Output: $15.00 / 1M tokens

**Ejemplo real:**
```
Usuario hace 100 llamadas al mes:
- Promedio 500 tokens input cada una = 50,000 tokens
- Promedio 200 tokens output cada una = 20,000 tokens

Costo = (50,000 × $3.00 / 1M) + (20,000 × $15.00 / 1M)
      = $0.15 + $0.30
      = $0.45 por usuario/mes
```

### ❌ NO tiene límite de presupuesto nativo

AWS Bedrock **NO detiene** automáticamente cuando alcanzas cierto costo.

### ✅ Solución: Esta Lambda

**Control implementado:**

1. **AWS Budgets** (Alertas)
   - Configurar en AWS Console
   - Alerta cuando llegas a 80%, 90%, 100%
   - Solo notifica, NO detiene

2. **Lambda-ai-monitoring** (Control activo)
   - Consulta costos en tiempo real
   - Calcula proyección
   - **Deshabilita automáticamente** si excede presupuesto
   - Control de cuotas por usuario

3. **Cuotas en Código** (Primera línea de defensa)
   ```javascript
   // En lambda-ai y lambda-voice
   const AI_QUOTAS = {
     free: 0,
     basic: 20,    // Máximo 20 llamadas/mes
     pro: 100,
     premium: 500
   };

   // Validar ANTES de llamar a Bedrock
   if (usageThisMonth >= quota) {
     throw new Error('AI_QUOTA_EXCEEDED');
   }
   ```

---

## 📊 Panel de Administración

### Vista Sugerida

```
┌─────────────────────────────────────────────────┐
│  🤖 AI Monitoring Dashboard                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  💰 Budget Status                               │
│  ┌─────────────────────────────────────────┐   │
│  │ $125.50 / $500.00 (25.1%)              │   │
│  │ ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │   │
│  │ Status: ✅ Healthy                      │   │
│  │ Projected: $387.25                      │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  📊 Usage This Month                            │
│  - Total Calls: 25,000                          │
│  - Input Tokens: 12.5M                          │
│  - Output Tokens: 5M                            │
│                                                 │
│  👥 Top Users                                   │
│  1. user@example.com - $12.50 (2,500 calls)    │
│  2. user2@example.com - $8.30 (1,650 calls)    │
│  ...                                            │
│                                                 │
│  🎯 By Feature                                  │
│  - Chat: 15,000 calls ($75.00)                  │
│  - Voice Tasks: 8,000 calls ($40.00)            │
│  - Insights: 2,000 calls ($10.50)               │
│                                                 │
│  🎛️ Controls                                    │
│  [🟢 AI Enabled ] [⚙️ Edit Quotas] [💰 Budget] │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Próximos Pasos

### 1. Desplegar Lambda
```bash
cd lambda-ai-monitoring
npm install
npm run deploy
```

### 2. Configurar AWS Budgets
```
AWS Console → Billing → Budgets
- Create Budget
- Type: Cost Budget
- Amount: $500/month
- Alerts: 80%, 90%, 100%
```

### 3. Configurar Parameter Store
```bash
# Feature flag
aws ssm put-parameter \
  --name /temis/ai/feature-enabled \
  --value "true" \
  --type String

# Quotas
aws ssm put-parameter \
  --name /temis/ai/quotas \
  --value '{"free":0,"basic":20,"pro":100,"premium":500}' \
  --type String

# Budget
aws ssm put-parameter \
  --name /temis/ai/budget \
  --value '{"monthlyBudget":500,"alertThresholds":{"warning":80,"critical":90,"emergency":100}}' \
  --type String
```

### 4. Crear Tablas en PostgreSQL
```sql
-- Ver archivo de implementación para SQL completo
CREATE TABLE ai_feature_flag_history (...);
CREATE TABLE ai_budget_alerts (...);
```

### 5. Desarrollar Frontend
```javascript
// React component
import { getAIDashboard, disableAIFeature } from './services/aiMonitoring';

function AIDashboard() {
  const [dashboard, setDashboard] = useState(null);

  useEffect(() => {
    getAIDashboard(token).then(setDashboard);
  }, []);

  // Renderizar dashboard...
}
```

---

## ✅ Beneficios

1. **Control Total** - Deshabilitar IA en emergencia
2. **Transparencia** - Ver costos reales de AWS
3. **Predicción** - Proyección de fin de mes
4. **Alertas** - Notificaciones automáticas
5. **Flexibilidad** - Ajustar cuotas sin redespliegue
6. **Visibilidad** - Ver qué usuarios consumen más
7. **Compliance** - Audit logs completos

---

## 📞 Soporte

**Documentos disponibles:**
- `TEMIS_CONTRATO_AI_MONITORING_V1.0.yaml` - Contrato API
- `lambda-ai-monitoring-implementation.md` - Código completo
- `LAMBDAS-RESUMEN.md` - Resumen de todas las lambdas
- `AI-MONITORING-RESUMEN.md` - Este documento

**Próximas mejoras sugeridas:**
- EventBridge rule para monitoreo automático cada hora
- Dashboard con gráficas en tiempo real
- Predicciones con Machine Learning
- Integración con Slack para alertas
- Exportar reportes a Excel/PDF

---

**Documento creado**: 2026-07-12
**Versión**: 1.0.0
**Lambda**: lambda-ai-monitoring (Lambda #16)
