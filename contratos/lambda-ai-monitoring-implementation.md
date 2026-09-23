# Lambda AI Monitoring - Implementación Completa

## 📁 Estructura de Archivos

```
lambda-ai-monitoring/
├── package.json
├── index.js                    # Entry point
├── config/
│   └── config.js              # Configuración
├── handlers/
│   ├── dashboard.js           # Dashboard principal
│   ├── costs.js               # Consulta de costos
│   ├── usage.js               # Estadísticas de uso
│   ├── featureFlag.js         # Control de feature flag
│   ├── quotas.js              # Gestión de cuotas
│   ├── budget.js              # Gestión de presupuesto
│   └── alerts.js              # Gestión de alertas
├── services/
│   ├── costExplorer.js        # AWS Cost Explorer
│   ├── database.js            # PostgreSQL queries
│   ├── parameterStore.js      # AWS Systems Manager
│   └── notifications.js       # SNS/SES notifications
├── middleware/
│   ├── auth.js                # Validación JWT + Admin
│   └── errorHandler.js        # Manejo de errores
└── utils/
    ├── logger.js              # Logging
    └── calculations.js        # Cálculos de costos
```

---

## 📦 package.json

```json
{
  "name": "lambda-ai-monitoring",
  "version": "1.0.0",
  "description": "Lambda para monitoreo y control de consumo de IA (AWS Bedrock)",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "deploy": "zip -r function.zip . && aws lambda update-function-code --function-name lambda-ai-monitoring --zip-file fileb://function.zip"
  },
  "dependencies": {
    "pg": "^8.11.3",
    "@aws-sdk/client-cost-explorer": "^3.450.0",
    "@aws-sdk/client-ssm": "^3.450.0",
    "@aws-sdk/client-sns": "^3.450.0",
    "@aws-sdk/client-ses": "^3.450.0",
    "jsonwebtoken": "^9.0.2"
  },
  "devDependencies": {
    "jest": "^29.7.0"
  }
}
```

---

## 🔧 config/config.js

```javascript
module.exports = {
  // Database
  database: {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    max: 10, // Connection pool
    idleTimeoutMillis: 30000,
  },

  // JWT
  jwt: {
    publicKeyParamName: '/temis/jwt/public-key',
  },

  // AI Monitoring
  aiMonitoring: {
    featureFlagParamName: '/temis/ai/feature-enabled',
    quotasParamName: '/temis/ai/quotas',
    budgetParamName: '/temis/ai/budget',
  },

  // Default values
  defaults: {
    monthlyBudget: 500.00, // USD
    alertThresholds: {
      warning: 80,    // 80%
      critical: 90,   // 90%
      emergency: 100, // 100%
    },
    quotas: {
      free: 0,
      basic: 20,
      pro: 100,
      premium: 500,
    },
  },

  // Cost Explorer
  costExplorer: {
    service: 'Amazon Bedrock',
    region: process.env.AWS_REGION || 'us-east-1',
  },
};
```

---

## 🎯 index.js (Entry Point)

```javascript
const { authMiddleware } = require('./middleware/auth');
const { errorHandler } = require('./middleware/errorHandler');
const logger = require('./utils/logger');

// Handlers
const dashboardHandler = require('./handlers/dashboard');
const costsHandler = require('./handlers/costs');
const usageHandler = require('./handlers/usage');
const featureFlagHandler = require('./handlers/featureFlag');
const quotasHandler = require('./handlers/quotas');
const budgetHandler = require('./handlers/budget');
const alertsHandler = require('./handlers/alerts');

// Route mapping
const routes = {
  'GET /admin/ai-monitoring/dashboard': dashboardHandler.getDashboard,
  'GET /admin/ai-monitoring/costs': costsHandler.getCosts,
  'GET /admin/ai-monitoring/usage': usageHandler.getUsage,
  'GET /admin/ai-monitoring/users': usageHandler.getUsersUsage,
  'GET /admin/ai-monitoring/feature-flag': featureFlagHandler.getFeatureFlag,
  'PUT /admin/ai-monitoring/feature-flag': featureFlagHandler.updateFeatureFlag,
  'GET /admin/ai-monitoring/quotas': quotasHandler.getQuotas,
  'PUT /admin/ai-monitoring/quotas': quotasHandler.updateQuotas,
  'GET /admin/ai-monitoring/budget': budgetHandler.getBudget,
  'PUT /admin/ai-monitoring/budget': budgetHandler.updateBudget,
  'GET /admin/ai-monitoring/alerts': alertsHandler.getAlerts,
};

exports.handler = async (event) => {
  try {
    logger.info('Lambda invoked', {
      httpMethod: event.httpMethod,
      path: event.path,
      requestId: event.requestContext?.requestId,
    });

    // Validar autenticación y rol admin
    const user = await authMiddleware(event);
    if (!user.isAdmin) {
      return {
        statusCode: 403,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          headers: {
            httpStatusCode: 403,
            httpStatusDesc: 'FORBIDDEN',
            messageUuid: event.headers['message-uuid'],
            requestDatetime: new Date().toISOString(),
            requestAppId: event.headers['request-app-id'],
          },
          messageResponse: {
            responseCode: '0403',
            responseMessage: 'Forbidden',
            responseDetail: 'Admin role required',
          },
        }),
      };
    }

    // Routing
    const routeKey = `${event.httpMethod} ${event.path}`;
    const handler = routes[routeKey];

    if (!handler) {
      return {
        statusCode: 404,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          error: 'Route not found',
        }),
      };
    }

    // Ejecutar handler
    const result = await handler(event, user);

    logger.info('Handler executed successfully', {
      statusCode: result.statusCode,
    });

    return result;

  } catch (error) {
    logger.error('Lambda error', { error: error.message, stack: error.stack });
    return errorHandler(error, event);
  }
};
```

---

## 🔐 middleware/auth.js

```javascript
const jwt = require('jsonwebtoken');
const { getParameter } = require('../services/parameterStore');
const config = require('../config/config');

async function authMiddleware(event) {
  // Obtener token del header
  const authHeader = event.headers?.Authorization || event.headers?.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('UNAUTHORIZED: Missing or invalid Authorization header');
  }

  const token = authHeader.replace('Bearer ', '');

  // Obtener clave pública de Parameter Store
  const publicKey = await getParameter(config.jwt.publicKeyParamName);

  // Verificar JWT
  let decoded;
  try {
    decoded = jwt.verify(token, publicKey, {
      algorithms: ['RS256'],
    });
  } catch (error) {
    throw new Error('UNAUTHORIZED: Invalid token');
  }

  // Validar que tenga rol admin
  const isAdmin = decoded.role === 'admin';

  return {
    userId: decoded.sub,
    email: decoded.email,
    organizationId: decoded.organization_id,
    role: decoded.role,
    isAdmin,
  };
}

module.exports = { authMiddleware };
```

---

## 📊 handlers/dashboard.js

```javascript
const costExplorerService = require('../services/costExplorer');
const databaseService = require('../services/database');
const { calculateProjectedCost } = require('../utils/calculations');
const { getParameter } = require('../services/parameterStore');
const config = require('../config/config');

async function getDashboard(event, user) {
  // 1. Obtener costos del mes actual
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  const endOfMonth = new Date();
  endOfMonth.setMonth(endOfMonth.getMonth() + 1);
  endOfMonth.setDate(0);
  endOfMonth.setHours(23, 59, 59, 999);

  const costs = await costExplorerService.getCosts(
    startOfMonth.toISOString().split('T')[0],
    endOfMonth.toISOString().split('T')[0],
    'DAILY'
  );

  const totalCost = costs.reduce((sum, c) => sum + c.amount, 0);
  const projectedCost = calculateProjectedCost(totalCost, new Date());

  // 2. Obtener estadísticas de uso de DB
  const usageStats = await databaseService.query(`
    SELECT
      COUNT(*) as total_calls,
      SUM(tokens_input) as total_tokens_input,
      SUM(tokens_output) as total_tokens_output,
      feature_type,
      COUNT(*) as calls_by_feature
    FROM ai_usage
    WHERE created_at >= $1
    GROUP BY feature_type
  `, [startOfMonth]);

  const totalCalls = usageStats.rows.reduce((sum, r) => sum + parseInt(r.calls_by_feature), 0);
  const totalTokensInput = usageStats.rows.reduce((sum, r) => sum + parseInt(r.total_tokens_input || 0), 0);
  const totalTokensOutput = usageStats.rows.reduce((sum, r) => sum + parseInt(r.total_tokens_output || 0), 0);

  // 3. Obtener presupuesto
  const budgetParam = await getParameter(config.aiMonitoring.budgetParamName);
  const budget = budgetParam ? JSON.parse(budgetParam) : config.defaults;
  const monthlyBudget = budget.monthlyBudget || config.defaults.monthlyBudget;

  const percentageUsed = (totalCost / monthlyBudget) * 100;
  let status = 'healthy';
  if (percentageUsed >= 100) status = 'exceeded';
  else if (percentageUsed >= 90) status = 'critical';
  else if (percentageUsed >= 80) status = 'warning';

  // 4. Top usuarios
  const topUsers = await databaseService.query(`
    SELECT
      u.id as user_id,
      u.email,
      COUNT(ai.id) as calls,
      SUM(ai.cost_usd) as cost
    FROM ai_usage ai
    JOIN users u ON ai.user_id = u.id
    WHERE ai.created_at >= $1
    GROUP BY u.id, u.email
    ORDER BY cost DESC
    LIMIT 10
  `, [startOfMonth]);

  // 5. Por feature
  const byFeature = {};
  usageStats.rows.forEach(row => {
    byFeature[row.feature_type] = {
      calls: parseInt(row.calls_by_feature),
      cost: parseFloat(row.cost || 0),
    };
  });

  // Construir respuesta
  const response = {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      headers: {
        httpStatusCode: 200,
        httpStatusDesc: 'OK',
        messageUuid: event.headers['message-uuid'],
        requestDatetime: new Date().toISOString(),
        requestAppId: event.headers['request-app-id'],
      },
      messageResponse: {
        responseCode: '0000',
        responseMessage: 'Success',
      },
      data: {
        dashboard: {
          current_month: {
            cost: totalCost,
            projected_cost: projectedCost,
            total_calls: totalCalls,
            total_tokens_input: totalTokensInput,
            total_tokens_output: totalTokensOutput,
          },
          budget_status: {
            monthly_budget: monthlyBudget,
            spent: totalCost,
            remaining: monthlyBudget - totalCost,
            percentage_used: percentageUsed,
            status,
          },
          by_feature: byFeature,
          top_users: topUsers.rows,
        },
      },
    }),
  };

  return response;
}

module.exports = { getDashboard };
```

---

## 💰 services/costExplorer.js

```javascript
const { CostExplorerClient, GetCostAndUsageCommand } = require('@aws-sdk/client-cost-explorer');
const config = require('../config/config');
const logger = require('../utils/logger');

const client = new CostExplorerClient({ region: config.costExplorer.region });

async function getCosts(startDate, endDate, granularity = 'DAILY') {
  try {
    const command = new GetCostAndUsageCommand({
      TimePeriod: {
        Start: startDate, // 'YYYY-MM-DD'
        End: endDate,     // 'YYYY-MM-DD'
      },
      Granularity: granularity, // 'DAILY' | 'MONTHLY'
      Metrics: ['UnblendedCost'],
      Filter: {
        Dimensions: {
          Key: 'SERVICE',
          Values: [config.costExplorer.service], // 'Amazon Bedrock'
        },
      },
    });

    const response = await client.send(command);

    // Parsear respuesta
    const costs = response.ResultsByTime.map(result => ({
      date: result.TimePeriod.Start,
      amount: parseFloat(result.Total.UnblendedCost.Amount),
      unit: result.Total.UnblendedCost.Unit,
    }));

    logger.info('Costs retrieved from Cost Explorer', {
      startDate,
      endDate,
      granularity,
      resultsCount: costs.length,
    });

    return costs;

  } catch (error) {
    logger.error('Error retrieving costs from Cost Explorer', {
      error: error.message,
      startDate,
      endDate,
    });
    throw error;
  }
}

module.exports = { getCosts };
```

---

## 🗄️ services/database.js

```javascript
const { Pool } = require('pg');
const config = require('../config/config');
const logger = require('../utils/logger');

// Connection pool
const pool = new Pool(config.database);

pool.on('error', (err) => {
  logger.error('Unexpected database error', { error: err.message });
});

async function query(text, params) {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    logger.info('Database query executed', { duration, rows: result.rowCount });
    return result;
  } catch (error) {
    logger.error('Database query error', { error: error.message, query: text });
    throw error;
  }
}

async function getClient() {
  return await pool.connect();
}

module.exports = { query, getClient };
```

---

## ⚙️ services/parameterStore.js

```javascript
const { SSMClient, GetParameterCommand, PutParameterCommand } = require('@aws-sdk/client-ssm');
const config = require('../config/config');
const logger = require('../utils/logger');

const client = new SSMClient({ region: config.costExplorer.region });

async function getParameter(name) {
  try {
    const command = new GetParameterCommand({
      Name: name,
      WithDecryption: true,
    });

    const response = await client.send(command);
    return response.Parameter.Value;

  } catch (error) {
    if (error.name === 'ParameterNotFound') {
      logger.warn('Parameter not found', { name });
      return null;
    }
    logger.error('Error getting parameter', { error: error.message, name });
    throw error;
  }
}

async function setParameter(name, value, type = 'String') {
  try {
    const command = new PutParameterCommand({
      Name: name,
      Value: value,
      Type: type,
      Overwrite: true,
    });

    await client.send(command);
    logger.info('Parameter updated', { name });

  } catch (error) {
    logger.error('Error setting parameter', { error: error.message, name });
    throw error;
  }
}

module.exports = { getParameter, setParameter };
```

---

## 🎛️ handlers/featureFlag.js

```javascript
const { getParameter, setParameter } = require('../services/parameterStore');
const databaseService = require('../services/database');
const notificationService = require('../services/notifications');
const config = require('../config/config');

async function getFeatureFlag(event, user) {
  const value = await getParameter(config.aiMonitoring.featureFlagParamName);
  const enabled = value === 'true';

  // Obtener detalles de quién lo deshabilitó
  let disabledDetails = null;
  if (!enabled) {
    const result = await databaseService.query(`
      SELECT disabled_at, disabled_by, reason
      FROM ai_feature_flag_history
      ORDER BY disabled_at DESC
      LIMIT 1
    `);
    if (result.rows.length > 0) {
      disabledDetails = result.rows[0];
    }
  }

  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      headers: {
        httpStatusCode: 200,
        httpStatusDesc: 'OK',
        messageUuid: event.headers['message-uuid'],
        requestDatetime: new Date().toISOString(),
        requestAppId: event.headers['request-app-id'],
      },
      messageResponse: {
        responseCode: '0000',
        responseMessage: 'Success',
      },
      data: {
        feature_flag: {
          enabled,
          disabled_at: disabledDetails?.disabled_at,
          disabled_by: disabledDetails?.disabled_by,
          reason: disabledDetails?.reason,
        },
      },
    }),
  };
}

async function updateFeatureFlag(event, user) {
  const body = JSON.parse(event.body);
  const { enabled, reason } = body;

  // Actualizar Parameter Store
  await setParameter(
    config.aiMonitoring.featureFlagParamName,
    enabled ? 'true' : 'false'
  );

  // Registrar en base de datos
  if (!enabled) {
    await databaseService.query(`
      INSERT INTO ai_feature_flag_history (disabled_at, disabled_by, reason)
      VALUES (NOW(), $1, $2)
    `, [user.email, reason || 'No reason provided']);

    // Enviar notificación
    await notificationService.sendSlackAlert(
      `🚨 AI Feature Disabled by ${user.email}\nReason: ${reason || 'N/A'}`
    );
  } else {
    await notificationService.sendSlackAlert(
      `✅ AI Feature Enabled by ${user.email}`
    );
  }

  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      headers: {
        httpStatusCode: 200,
        httpStatusDesc: 'OK',
        messageUuid: event.headers['message-uuid'],
        requestDatetime: new Date().toISOString(),
        requestAppId: event.headers['request-app-id'],
      },
      messageResponse: {
        responseCode: '0000',
        responseMessage: 'Feature flag updated successfully',
      },
    }),
  };
}

module.exports = { getFeatureFlag, updateFeatureFlag };
```

---

## 📈 utils/calculations.js

```javascript
/**
 * Calcula el costo proyectado al final del mes
 * @param {number} currentCost - Costo actual hasta hoy
 * @param {Date} currentDate - Fecha actual
 * @returns {number} Costo proyectado
 */
function calculateProjectedCost(currentCost, currentDate) {
  const daysInMonth = new Date(
    currentDate.getFullYear(),
    currentDate.getMonth() + 1,
    0
  ).getDate();

  const daysElapsed = currentDate.getDate();

  if (daysElapsed === 0) return 0;

  const dailyAverage = currentCost / daysElapsed;
  const projectedCost = dailyAverage * daysInMonth;

  return Math.round(projectedCost * 100) / 100;
}

/**
 * Calcula el costo de tokens de Bedrock
 * @param {number} inputTokens - Tokens de entrada
 * @param {number} outputTokens - Tokens de salida
 * @returns {number} Costo en USD
 */
function calculateBedrockCost(inputTokens, outputTokens) {
  const INPUT_COST_PER_1M = 3.00;
  const OUTPUT_COST_PER_1M = 15.00;

  const inputCost = (inputTokens / 1000000) * INPUT_COST_PER_1M;
  const outputCost = (outputTokens / 1000000) * OUTPUT_COST_PER_1M;

  return inputCost + outputCost;
}

module.exports = {
  calculateProjectedCost,
  calculateBedrockCost,
};
```

---

## 🔔 services/notifications.js

```javascript
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const config = require('../config/config');
const logger = require('../utils/logger');

const snsClient = new SNSClient({ region: config.costExplorer.region });
const sesClient = new SESClient({ region: config.costExplorer.region });

async function sendSlackAlert(message) {
  // Aquí se integraría con Slack via SNS o webhook
  // Por ahora solo log
  logger.info('Slack alert', { message });
}

async function sendEmailAlert(email, subject, body) {
  try {
    const command = new SendEmailCommand({
      Source: 'noreply@temis.com',
      Destination: {
        ToAddresses: [email],
      },
      Message: {
        Subject: { Data: subject },
        Body: {
          Text: { Data: body },
        },
      },
    });

    await sesClient.send(command);
    logger.info('Email sent', { email, subject });

  } catch (error) {
    logger.error('Error sending email', { error: error.message, email });
  }
}

module.exports = {
  sendSlackAlert,
  sendEmailAlert,
};
```

---

## 🗂️ SQL: Tablas Necesarias

```sql
-- Tabla para historial de cambios de feature flag
CREATE TABLE ai_feature_flag_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  disabled_at TIMESTAMP WITH TIME ZONE NOT NULL,
  disabled_by VARCHAR(255) NOT NULL,
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para alertas de presupuesto
CREATE TABLE ai_budget_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  severity VARCHAR(20) CHECK (severity IN ('info', 'warning', 'critical', 'emergency')),
  type VARCHAR(50) CHECK (type IN ('budget_threshold', 'daily_limit', 'user_quota', 'feature_disabled')),
  message TEXT NOT NULL,
  data JSONB,
  acknowledged BOOLEAN DEFAULT false,
  acknowledged_by VARCHAR(255),
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_budget_alerts_severity ON ai_budget_alerts(severity);
CREATE INDEX idx_ai_budget_alerts_created_at ON ai_budget_alerts(created_at DESC);

-- Índices adicionales en ai_usage para consultas rápidas
CREATE INDEX idx_ai_usage_created_at ON ai_usage(created_at DESC);
CREATE INDEX idx_ai_usage_user_month ON ai_usage(user_id, DATE_TRUNC('month', created_at));
CREATE INDEX idx_ai_usage_feature_type ON ai_usage(feature_type);
```

---

## 🚀 Despliegue

### 1. Crear función Lambda

```bash
# Instalar dependencias
npm install

# Crear ZIP
zip -r function.zip . -x "*.git*" "node_modules/aws-sdk/*"

# Crear Lambda
aws lambda create-function \
  --function-name lambda-ai-monitoring \
  --runtime nodejs20.x \
  --role arn:aws:iam::ACCOUNT_ID:role/lambda-ai-monitoring-role \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --memory-size 512 \
  --environment Variables="{
    DB_HOST=temis-db.us-east-1.rds.amazonaws.com,
    DB_PORT=5432,
    DB_NAME=temis,
    DB_USER=temis_app,
    DB_PASSWORD=stored-in-secrets-manager
  }"
```

### 2. Permisos IAM

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:PutParameter"
      ],
      "Resource": "arn:aws:ssm:us-east-1:ACCOUNT_ID:parameter/temis/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "arn:aws:sns:us-east-1:ACCOUNT_ID:temis-alerts"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Configurar API Gateway

```yaml
# Agregar rutas en API Gateway
/admin/ai-monitoring/dashboard:
  get:
    integration: lambda-ai-monitoring

/admin/ai-monitoring/costs:
  get:
    integration: lambda-ai-monitoring

# ... todas las rutas del contrato
```

---

## ✅ Testing

```javascript
// test/dashboard.test.js
const { getDashboard } = require('../handlers/dashboard');

describe('Dashboard Handler', () => {
  test('should return dashboard data', async () => {
    const event = {
      httpMethod: 'GET',
      path: '/admin/ai-monitoring/dashboard',
      headers: {
        'message-uuid': '123e4567-e89b-12d3-a456-426614174000',
        'request-app-id': '223e4567-e89b-12d3-a456-426614174000',
      },
    };

    const user = { isAdmin: true, userId: 'admin-123' };

    const result = await getDashboard(event, user);

    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.data.dashboard).toBeDefined();
    expect(body.data.dashboard.current_month).toBeDefined();
    expect(body.data.dashboard.budget_status).toBeDefined();
  });
});
```

---

## 📚 Documentación de Uso

### Ejemplo de Uso desde Frontend (React)

```javascript
// services/aiMonitoring.js
const API_BASE = 'https://api.temis.app/v1';

export async function getAIDashboard(token) {
  const response = await fetch(`${API_BASE}/admin/ai-monitoring/dashboard`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'message-uuid': crypto.randomUUID(),
      'request-app-id': 'web-admin-app-id',
    },
  });

  if (!response.ok) throw new Error('Failed to fetch dashboard');
  return await response.json();
}

export async function disableAIFeature(token, reason) {
  const response = await fetch(`${API_BASE}/admin/ai-monitoring/feature-flag`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'message-uuid': crypto.randomUUID(),
      'request-app-id': 'web-admin-app-id',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      enabled: false,
      reason,
    }),
  });

  if (!response.ok) throw new Error('Failed to update feature flag');
  return await response.json();
}
```

---

**Documento creado**: 2026-07-12
**Versión**: 1.0.0
**Lambda**: lambda-ai-monitoring
