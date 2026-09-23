# 📱 SMS Capture - Transacciones Automáticas desde Notificaciones Bancarias

**Fecha**: 2026-09-23
**Versión**: 1.0
**Feature**: Premium (Plan Pro y Premium)

---

## 🎯 Objetivo

Permitir a usuarios de **Plan Pro y Premium** capturar automáticamente transacciones financieras desde notificaciones SMS de bancos colombianos, eliminando la necesidad de registro manual.

---

## 📋 Características

### Soporte de Bancos
- ✅ **Bancolombia** (prioridad 1)
- ✅ **Davivienda** (prioridad 1)
- ✅ **BBVA Colombia** (prioridad 2)
- ⏳ Otros bancos (futuro)

### Tipos de Transacciones Detectadas
- 💳 Compras con tarjeta débito/crédito
- 💵 Retiros en cajeros automáticos
- 📲 Transferencias salientes
- 💰 Pagos de servicios
- ⚠️ **NO captura:** Consultas de saldo, promociones, publicidad

---

## 🏗️ Arquitectura del Sistema

### Componentes

```
[App Android] → [Broadcast Receiver] → [Lambda-Transactions]
                     ↓                           ↓
                [Amazon Bedrock]          [PostgreSQL]
                     ↓                           ↓
              [Datos Extraídos]        [Transacción Creada]
```

### Stack Tecnológico
- **Android**: BroadcastReceiver (SMS)
- **iOS**: ❌ No soportado (Apple no permite acceso programático a SMS)
- **Backend**: Lambda-transactions con endpoint POST /transactions/from-sms
- **IA**: Amazon Bedrock (Claude 3.5 Sonnet) para extraer datos
- **Database**: PostgreSQL (tabla transactions con flag `created_from_sms`)

---

## 📱 Implementación Android

### 1. Permisos en AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.temis.app">

    <!-- Permisos para leer SMS -->
    <uses-permission android:name="android.permission.RECEIVE_SMS" />
    <uses-permission android:name="android.permission.READ_SMS" />

    <application>
        <!-- Broadcast Receiver para SMS -->
        <receiver
            android:name=".receivers.SMSCaptureReceiver"
            android:enabled="true"
            android:exported="true"
            android:permission="android.permission.BROADCAST_SMS">
            <intent-filter android:priority="999">
                <action android:name="android.provider.Telephony.SMS_RECEIVED" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### 2. SMSCaptureReceiver.kt

```kotlin
package com.temis.app.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import com.temis.app.services.TransactionService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class SMSCaptureReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SMSCaptureReceiver"

        // Remitentes de bancos colombianos
        private val BANK_SENDERS = setOf(
            "BANCOLOMBIA",
            "Bancolombia",
            "DAVIVIENDA",
            "Davivienda",
            "BBVA",
            "BBVAColombia"
        )

        // Palabras clave que indican transacción (no consulta/publicidad)
        private val TRANSACTION_KEYWORDS = setOf(
            "compra",
            "retiro",
            "transferencia",
            "pago",
            "débito",
            "aprobada",
            "rechazada"
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Verificar que el feature esté habilitado
        val prefs = context.getSharedPreferences("temis_settings", Context.MODE_PRIVATE)
        val smsCaptureEnabled = prefs.getBoolean("sms_capture_enabled", false)

        if (!smsCaptureEnabled) {
            Log.d(TAG, "SMS Capture está deshabilitado")
            return
        }

        // Obtener mensajes SMS del intent
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)

        messages?.forEach { sms ->
            val sender = sms.originatingAddress ?: return@forEach
            val messageBody = sms.messageBody ?: return@forEach

            Log.d(TAG, "SMS recibido de: $sender")

            // Verificar si es SMS de banco
            if (isBankSMS(sender)) {
                // Verificar si es transacción (no publicidad/consulta)
                if (isTransactionSMS(messageBody)) {
                    Log.i(TAG, "SMS de transacción detectado: $messageBody")

                    // Procesar en background
                    CoroutineScope(Dispatchers.IO).launch {
                        processBankSMS(context, sender, messageBody)
                    }
                } else {
                    Log.d(TAG, "SMS bancario pero no es transacción (consulta/publicidad)")
                }
            }
        }
    }

    private fun isBankSMS(sender: String): Boolean {
        return BANK_SENDERS.any { bankSender ->
            sender.contains(bankSender, ignoreCase = true)
        }
    }

    private fun isTransactionSMS(messageBody: String): Boolean {
        val lowerBody = messageBody.lowercase()
        return TRANSACTION_KEYWORDS.any { keyword ->
            lowerBody.contains(keyword)
        }
    }

    private suspend fun processBankSMS(context: Context, sender: String, messageBody: String) {
        try {
            val transactionService = TransactionService(context)

            // Enviar a backend
            val response = transactionService.createFromSMS(
                smsText = messageBody,
                sender = sender,
                receivedAt = System.currentTimeMillis()
            )

            if (response.isSuccessful) {
                Log.i(TAG, "Transacción creada automáticamente: ${response.data?.id}")

                // Mostrar notificación al usuario
                showNotification(
                    context,
                    "Transacción capturada",
                    "Se detectó: ${response.data?.description} - $${response.data?.amount}"
                )
            } else {
                Log.w(TAG, "Error al crear transacción: ${response.error}")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error procesando SMS bancario", e)
        }
    }

    private fun showNotification(context: Context, title: String, message: String) {
        // Implementar NotificationManager...
    }
}
```

### 3. TransactionService.kt

```kotlin
package com.temis.app.services

import android.content.Context
import com.temis.app.api.ApiClient
import com.temis.app.models.Transaction
import java.util.UUID

class TransactionService(private val context: Context) {

    suspend fun createFromSMS(
        smsText: String,
        sender: String,
        receivedAt: Long
    ): ApiResponse<Transaction> {

        val deviceId = getDeviceId(context)

        val request = SMSTransactionRequest(
            smsText = smsText,
            sender = sender,
            receivedAt = receivedAt,
            deviceId = deviceId
        )

        return ApiClient.post("/v1/transactions/from-sms", request)
    }

    private fun getDeviceId(context: Context): String {
        val prefs = context.getSharedPreferences("temis_settings", Context.MODE_PRIVATE)

        var deviceId = prefs.getString("device_id", null)

        if (deviceId == null) {
            deviceId = UUID.randomUUID().toString()
            prefs.edit().putString("device_id", deviceId).apply()
        }

        return deviceId
    }
}

data class SMSTransactionRequest(
    val smsText: String,
    val sender: String,
    val receivedAt: Long,
    val deviceId: String
)
```

---

## 🔧 Backend - Lambda-Transactions

### Endpoint: POST /transactions/from-sms

```javascript
const { BedrockRuntime } = require('@aws-sdk/client-bedrock-runtime');
const bedrock = new BedrockRuntime({ region: 'us-east-1' });

async function createTransactionFromSMS(event) {
  const { smsText, sender, receivedAt, deviceId } = JSON.parse(event.body);

  // 1. Validar que el usuario tenga plan Pro o Premium
  const subscription = await getSubscription(userId, organizationId);

  if (!['Pro', 'Premium'].includes(subscription.planName)) {
    return {
      statusCode: 403,
      body: JSON.stringify({
        error: 'SMS Capture solo disponible en planes Pro y Premium'
      })
    };
  }

  // 2. Validar device_id (seguridad)
  const isValidDevice = await validateDevice(userId, deviceId);
  if (!isValidDevice) {
    return {
      statusCode: 401,
      body: JSON.stringify({
        error: 'Dispositivo no autorizado'
      })
    };
  }

  // 3. Extraer datos con Amazon Bedrock
  const extractedData = await extractTransactionDataWithAI(smsText, sender);

  if (!extractedData.success) {
    return {
      statusCode: 422,
      body: JSON.stringify({
        error: 'No se pudo extraer información del SMS',
        smsText
      })
    };
  }

  // 4. Crear transacción con flag created_from_sms=true
  const transaction = await db.query(`
    INSERT INTO transactions (
      id, organization_id, user_id,
      transaction_type, amount, currency,
      description, transaction_date,
      created_from_sms, sms_text, sms_sender,
      status, created_at
    ) VALUES (
      gen_random_uuid(), $1, $2,
      $3, $4, $5,
      $6, $7,
      true, $8, $9,
      'pending_review', NOW()
    )
    RETURNING *
  `, [
    organizationId, userId,
    extractedData.type,
    extractedData.amount,
    extractedData.currency || 'COP',
    extractedData.description,
    extractedData.date,
    smsText,
    sender
  ]);

  return {
    statusCode: 201,
    body: JSON.stringify({
      success: true,
      transaction: transaction.rows[0]
    })
  };
}

async function extractTransactionDataWithAI(smsText, sender) {
  const prompt = `
Eres un asistente experto en extraer información de SMS bancarios colombianos.

SMS del banco ${sender}:
"${smsText}"

Extrae la siguiente información en formato JSON:
{
  "success": true/false,
  "type": "expense" | "income" | "transfer",
  "amount": número decimal,
  "currency": "COP" (por defecto),
  "merchant": "nombre del comercio",
  "description": "descripción clara",
  "category": "categoría sugerida",
  "date": "YYYY-MM-DD HH:mm:ss",
  "card_last_four": "últimos 4 dígitos" (si aplica)
}

Ejemplos:
- "Compra aprobada por $50,000 en EXITO el 12/07/2026" →
  { "type": "expense", "amount": 50000, "merchant": "EXITO", "category": "Supermercado", "date": "2026-07-12 14:30:00" }

- "Retiro aprobado por $200,000 en ATM BANCOLOMBIA" →
  { "type": "expense", "amount": 200000, "merchant": "ATM", "category": "Retiro Efectivo", ... }

IMPORTANTE:
- Si no puedes extraer la información, retorna success: false
- Si el SMS es consulta de saldo o publicidad, retorna success: false
`;

  const response = await bedrock.invokeModel({
    modelId: 'anthropic.claude-3-5-sonnet-20240620-v2:0',
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify({
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 500,
      messages: [{
        role: 'user',
        content: prompt
      }]
    })
  });

  const result = JSON.parse(new TextDecoder().decode(response.body));
  const aiResponse = JSON.parse(result.content[0].text);

  return aiResponse;
}
```

---

## 📊 Patrones de SMS Soportados

### Bancolombia

```
✅ Compra aprobada por $50,000 en EXITO el 15/07/2026
✅ Retiro aprobado por $200,000 en ATM BANCOLOMBIA el 15/07/2026
✅ Transferencia de $100,000 a JUAN PEREZ el 15/07/2026
✅ Pago de $80,000 en RAPPI el 15/07/2026

❌ Su saldo disponible es $1,500,000 (consulta, no capturar)
❌ Conoce nuestros nuevos créditos (publicidad, no capturar)
```

### Davivienda

```
✅ Compra con tu tarjeta *4242 por $75,000 en CARULLA
✅ Retiro por $100,000 en CAJERO DAVIVIENDA
✅ Pago de tarjeta de credito por $500,000

❌ Consulta de saldo: $2,000,000 (no capturar)
```

### BBVA Colombia

```
✅ Compra $45,000 PANADERIA EL SOL Tarjeta *1234
✅ Transferencia enviada $150,000

❌ Tu saldo actual es $800,000 (no capturar)
```

---

## 🔒 Seguridad y Privacidad

### Permisos Android
- ⚠️ **READ_SMS** y **RECEIVE_SMS** son permisos sensibles
- 📱 App debe solicitar explícitamente en tiempo de ejecución (Android 6+)
- ✅ Usuario puede revocar en cualquier momento

### Almacenamiento de SMS
- ❌ **NO se almacenan SMS completos** en base de datos
- ✅ Solo se almacena `sms_text` en campo de transacción (para auditoría)
- ✅ Se puede eliminar el texto SMS después de N días (GDPR)

### Validación de Dispositivos
- 📱 Cada dispositivo tiene `device_id` único (UUID)
- ✅ Backend valida que `device_id` pertenece al usuario
- ⚠️ Si se detecta `device_id` no autorizado → rechaza SMS

### Hashing de Número de Teléfono
- 📞 Número de teléfono se hashea con SHA-256
- ✅ Solo se almacena hash, no número real
- 🔐 Cumple con GDPR

---

## 🎛️ Configuración en App (Settings)

### UI - Sección SMS Capture

```
┌─────────────────────────────────────┐
│ SMS Capture                        │
│                                     │
│ [✓] Habilitar captura automática   │
│                                     │
│ Banco: [Bancolombia ▼]            │
│                                     │
│ Estado: ✅ Activo                  │
│ Última captura: Hace 2 horas       │
│                                     │
│ [Historial de SMS capturados] →    │
│                                     │
│ ⚠️ Requiere Plan Pro o Premium     │
└─────────────────────────────────────┘
```

### Tabla: user_settings

```sql
ALTER TABLE user_settings ADD COLUMN sms_capture_enabled BOOLEAN DEFAULT false;
ALTER TABLE user_settings ADD COLUMN sms_bank_selected TEXT; -- 'bancolombia', 'davivienda', 'bbva'
ALTER TABLE user_settings ADD COLUMN sms_device_id TEXT UNIQUE;
ALTER TABLE user_settings ADD COLUMN sms_phone_hash TEXT; -- SHA-256 del número
```

---

## 📈 Métricas y Monitoring

### CloudWatch Metrics
- `SMSCaptured/Count`: Total de SMS procesados
- `SMSCaptured/Success`: SMS convertidos en transacción
- `SMSCaptured/Failed`: SMS que no se pudieron procesar
- `SMSCaptured/Latency`: Tiempo de procesamiento

### Logs
```
[INFO] SMS captured from BANCOLOMBIA: "Compra por $50,000..."
[INFO] Bedrock extraction successful: { amount: 50000, merchant: "EXITO" }
[INFO] Transaction created: txn_abc123
```

---

## 🚀 Roadmap Futuro

### Fase 1 (Actual)
- ✅ Bancolombia, Davivienda, BBVA
- ✅ Solo Android
- ✅ Estado `pending_review` (usuario confirma/edita)

### Fase 2 (Q4 2026)
- 📅 Auto-aprobación de transacciones (si confianza IA > 95%)
- 📊 Dashboard de accuracy de SMS Capture
- 🏦 Más bancos: Scotiabank, Banco de Bogotá

### Fase 3 (2027)
- 🤖 Machine Learning para mejorar extracción
- 📧 Email parsing (extractos bancarios por email)
- 🌎 Soporte internacional (México, Argentina, Chile)

---

## ❓ FAQ

**Q: ¿Por qué no funciona en iPhone?**
A: Apple no permite acceso programático a SMS por seguridad. Solo Android soporta esta feature.

**Q: ¿Se puede desactivar?**
A: Sí, en Settings → SMS Capture → Deshabilitar. También se puede revocar el permiso desde Configuración de Android.

**Q: ¿Qué pasa si tengo plan Free o Basic?**
A: El feature no está disponible. Upgrade a Pro ($9.99/mes) o Premium ($19.99/mes).

**Q: ¿Se capturan TODOS los SMS?**
A: No, solo SMS de bancos listados y solo los que contienen palabras clave de transacciones.

**Q: ¿Puedo editar la transacción?**
A: Sí, las transacciones creadas por SMS tienen estado `pending_review` y puedes editarlas o eliminarlas.

---

**Autor**: Equipo TEMIS
**Última actualización**: 2026-09-23
