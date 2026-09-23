# Módulos y Funcionalidades - TEMIS
## Especificación Detallada de Características

---

## 1. Estructura de Módulos

TEMIS está organizado en 4 módulos principales más módulos transversales:

### Módulos Principales
1. **Tareas y Calendario** - Gestión de tareas, eventos y recordatorios
2. **Gestor de Contraseñas** - Almacenamiento seguro de credenciales
3. **Finanzas Personales** - Control de ingresos y egresos
4. **Asistente IA** - Chat conversacional, insights y análisis inteligente

### Módulos Transversales
5. **Autenticación y Usuarios** - Gestión de sesiones y perfiles
6. **Suscripciones** - Control de planes y pagos con cuotas de IA
7. **Reportes** - Generación de reportes y dashboards
8. **Administración** - Panel web para superusuarios

---

## 2. Módulo: Tareas y Calendario

### 2.1 Funcionalidades Principales

#### 2.1.1 Gestión de Tareas
**Descripción**: CRUD completo de tareas con estados y prioridades.

**Características**:
- Crear tarea con título, descripción, fecha de vencimiento
- Estados: Pendiente, En progreso, Completada, Cancelada
- Prioridades: Baja, Media, Alta, Urgente
- Tareas recurrentes (diario, semanal, mensual, personalizado)
- Subtareas (jerarquía de tareas)
- Ordenamiento manual (drag & drop)
- Búsqueda por texto completo
- Filtros: estado, prioridad, fecha, etiquetas

**Validaciones**:
- Título: obligatorio, máx 500 caracteres
- Due date: opcional, debe ser fecha futura
- Descripción: opcional, máx 5000 caracteres

**Plan requerido**: Free o superior

---

#### 2.1.2 Sistema de Etiquetas
**Descripción**: Categorización flexible mediante etiquetas personalizables.

**Características**:
- Crear/editar/eliminar etiquetas personales
- Asignar múltiples etiquetas a una tarea
- Colores personalizables (paleta de 16 colores)
- Filtrar tareas por etiquetas
- Estadísticas por etiqueta

**Validaciones**:
- Nombre: único por usuario, máx 100 caracteres
- Color: formato hexadecimal válido

**Plan requerido**: Free o superior

---

#### 2.1.3 Calendario
**Descripción**: Visualización de tareas en formato calendario.

**Características**:
- Vista mensual, semanal, diaria
- Arrastrar y soltar para cambiar fechas
- Crear tarea desde el calendario
- Eventos de día completo
- Sincronización con tareas
- Navegación rápida entre fechas
- Mini-calendario para saltar a fecha específica

**Interacciones**:
- Tap en día: ver tareas de ese día
- Long press en tarea: opciones rápidas (completar, editar, eliminar)
- Swipe en tarea: acciones rápidas

**Plan requerido**: Free o superior

---

#### 2.1.4 Recordatorios y Alertas
**Descripción**: Sistema de notificaciones programadas.

**Características**:
- Recordatorios únicos o recurrentes
- Múltiples recordatorios por tarea
- Tipos de notificación: Push, Email, Ambos
- Configuración de anticipación (5 min, 15 min, 1 hora, 1 día, personalizado)
- Notificaciones locales (no requieren internet)
- Snooze de recordatorios (5, 10, 15 min)
- Historial de notificaciones enviadas

**Reglas**:
- Mínimo 5 minutos de anticipación
- Máximo 30 días de anticipación
- Límite: 50 recordatorios activos (Free), 200 (Pro), ilimitado (Premium)

**Plan requerido**: Free (básico), Pro (avanzado)

---

#### 2.1.5 Registro de Tareas por Voz
**Descripción**: Creación de tareas mediante comando de voz con IA.

**Características**:
- Grabación de audio (máx 30 segundos)
- Transcripción con AWS Transcribe
- Procesamiento inteligente con Amazon Bedrock (Claude 3.5 Sonnet):
  - Extraer título de la tarea
  - Detectar prioridad (urgente, alta, media, baja)
  - Identificar fecha de vencimiento
  - Generar descripción estructurada
  - Sugerir etiquetas relevantes
- Vista previa antes de guardar
- Corrección manual si es necesario
- Soporte de idiomas: Español (es-ES, es-MX), Inglés

**Ejemplos de Comandos**:
- "Recordarme llamar al médico mañana a las 10"
- "Tarea urgente: enviar reporte el viernes"
- "Comprar leche y pan cuando salga del trabajo"
- "Reunión con el equipo el próximo martes 3 PM"

**Algoritmo de Procesamiento**:
1. Transcribir audio a texto con AWS Transcribe
2. Enviar transcripción a Amazon Bedrock con prompt estructurado
3. IA extrae:
   - Título (texto principal de la tarea)
   - Prioridad (palabras clave: urgente, importante, etc.)
   - Fecha/hora (parsing de expresiones temporales)
   - Descripción adicional
   - Etiquetas sugeridas
4. Presentar vista previa al usuario
5. Usuario confirma o ajusta
6. Sistema crea la tarea

**Cuota de Uso**:
- Free: 0 registros/mes
- Basic: 10 registros/mes
- Pro: 100 registros/mes
- Premium: Ilimitado

**Plan requerido**: Basic o superior

---

### 2.2 Casos de Uso

#### Caso de Uso 1: Crear Tarea con Recordatorio
```
Actor: Usuario
Precondición: Usuario autenticado

Flujo:
1. Usuario navega a "Tareas"
2. Usuario toca botón "Nueva Tarea"
3. Usuario ingresa:
   - Título: "Reunión con cliente"
   - Fecha: Mañana 10:00 AM
   - Prioridad: Alta
   - Etiquetas: Trabajo
4. Usuario toca "Agregar Recordatorio"
5. Usuario selecciona "15 minutos antes"
6. Usuario guarda la tarea
7. Sistema crea la tarea
8. Sistema programa el recordatorio
9. Sistema muestra confirmación

Postcondición: Tarea creada y recordatorio programado
```

---

## 3. Módulo: Gestor de Contraseñas

### 3.1 Funcionalidades Principales

#### 3.1.1 Almacenamiento de Credenciales
**Descripción**: Bóveda segura para guardar contraseñas.

**Características**:
- CRUD de credenciales
- Campos: Nombre, Usuario, Contraseña, URL, Notas
- Categorías: Sitio web, Banco, WiFi, Email, App, Otros
- Etiquetas personalizadas
- Mostrar/ocultar contraseña
- Copiar al portapapeles (auto-limpieza después de 30s)
- Favoritos para acceso rápido
- Fecha de última utilización
- Fecha de expiración (opcional)
- Adjuntar archivos (futuro)

**Encriptación**:
- AES-256-GCM por registro
- IV único por contraseña
- Clave derivada del password maestro del usuario
- Zero-knowledge (servidor no puede descifrar)

**Validaciones**:
- Nombre: obligatorio, máx 255 caracteres
- URL: formato válido si se proporciona
- Contraseña: obligatoria, no hay restricción de formato

**Plan requerido**: Basic o superior

---

#### 3.1.2 Generador de Contraseñas
**Descripción**: Generación de contraseñas seguras.

**Características**:
- Longitud: 8-128 caracteres
- Opciones configurables:
  - Mayúsculas (A-Z)
  - Minúsculas (a-z)
  - Números (0-9)
  - Símbolos (!@#$%^&*)
  - Excluir caracteres ambiguos (0, O, l, I)
- Medidor de fortaleza (débil, media, fuerte, muy fuerte)
- Generar múltiples opciones
- Historial de contraseñas generadas (últimas 10)

**Algoritmo**:
- Generación criptográficamente segura
- Distribución uniforme de caracteres
- No predictible

**Plan requerido**: Basic o superior

---

#### 3.1.3 Búsqueda y Organización
**Descripción**: Encontrar credenciales rápidamente.

**Características**:
- Búsqueda por texto (nombre, usuario, URL, notas)
- Filtros:
  - Por categoría
  - Por etiqueta
  - Favoritos
  - Por fecha de creación/modificación
  - Próximas a expirar
- Ordenamiento:
  - Alfabético (A-Z, Z-A)
  - Fecha de creación
  - Fecha de última utilización
  - Favoritos primero

**Performance**:
- Búsqueda con debounce de 300ms
- Índice de texto completo en BD
- Caché local de resultados recientes

**Plan requerido**: Basic o superior

---

#### 3.1.4 Auditoría de Seguridad
**Descripción**: Análisis de fortaleza de contraseñas.

**Características**:
- Dashboard de seguridad con:
  - Contraseñas débiles (< 8 caracteres o baja entropía)
  - Contraseñas reutilizadas
  - Contraseñas expirando pronto
  - Últimas modificaciones
- Recomendaciones de mejora
- Puntaje de seguridad general (0-100)
- Alertas de expiración

**Cálculo de Fortaleza**:
- Longitud
- Diversidad de caracteres
- Entropía
- No en diccionarios comunes

**Plan requerido**: Premium

---

### 3.2 Casos de Uso

#### Caso de Uso 2: Guardar Credencial Bancaria
```
Actor: Usuario
Precondición: Usuario autenticado, plan Basic o superior

Flujo:
1. Usuario navega a "Contraseñas"
2. Usuario toca botón "Nueva Contraseña"
3. Usuario selecciona categoría "Banco"
4. Usuario ingresa:
   - Nombre: "Banco Nacional"
   - Usuario: "12345678"
   - URL: "https://banco.com"
5. Usuario toca "Generar Contraseña"
6. Sistema genera contraseña segura de 16 caracteres
7. Usuario acepta la contraseña generada
8. Usuario agrega notas: "Tarjeta de débito principal"
9. Usuario guarda
10. Sistema encripta la contraseña con AES-256-GCM
11. Sistema guarda en BD
12. Sistema muestra confirmación

Postcondición: Credencial guardada y encriptada
```

---

## 4. Módulo: Finanzas Personales

### 4.1 Funcionalidades Principales

#### 4.1.1 Registro Manual de Transacciones
**Descripción**: Registro de ingresos y egresos manualmente.

**Características**:
- Tipo: Ingreso o Egreso
- Monto: decimal con 2 decimales
- Moneda: USD, MXN, COP, EUR, otros
- Categoría: selección de lista predefinida o personalizada
- Descripción: texto libre
- Fecha: por defecto hoy, ajustable
- Método de pago: Efectivo, Tarjeta de crédito, Débito, Transferencia
- Ubicación: texto libre (opcional)
- Etiquetas: múltiples (opcional)
- Adjuntos: fotos de recibos (futuro)
- Transacciones recurrentes

**Validaciones**:
- Monto: obligatorio, > 0, máx 15 dígitos
- Tipo: obligatorio
- Categoría: obligatoria
- Fecha: no puede ser futura
- Descripción: máx 1000 caracteres

**Plan requerido**: Pro o superior

---

#### 4.1.2 Registro por Voz con IA
**Descripción**: Registro de transacciones mediante comando de voz con procesamiento inteligente.

**Características**:
- Grabación de audio (máx 30 segundos)
- Transcripción con AWS Transcribe
- Procesamiento inteligente con Amazon Bedrock (Claude 3.5 Sonnet):
  - Detectar tipo (ingreso/egreso)
  - Extraer monto preciso (incluyendo decimales)
  - Detectar categoría automáticamente
  - Identificar método de pago si se menciona
  - Extraer descripción estructurada
  - Detectar fecha si se menciona (ej: "ayer", "la semana pasada")
- Vista previa antes de guardar
- Corrección manual si es necesario
- Soporte de idiomas: Español (es-ES, es-MX), Inglés

**Ejemplos de Comandos**:
- "Gasté cincuenta dólares en el supermercado"
- "Ingreso de mil pesos por freelance"
- "Compré gasolina por treinta y cinco dólares"
- "Pagué quinientos en la cuenta de luz"
- "Ayer gasté 25.50 en Starbucks con tarjeta de crédito"

**Algoritmo de Procesamiento**:
1. Transcribir audio a texto con AWS Transcribe
2. Enviar transcripción a Amazon Bedrock con prompt estructurado
3. IA extrae:
   - Tipo de transacción (ingreso/egreso)
   - Monto exacto (maneja números escritos y decimales)
   - Categoría (con lógica inteligente basada en contexto)
   - Método de pago si se menciona
   - Fecha (hoy por defecto, o si se menciona)
   - Descripción limpia
4. Presentar vista previa al usuario
5. Usuario confirma o ajusta
6. Sistema crea la transacción

**Cuota de Uso**:
- Free: 0 registros/mes
- Basic: 10 registros/mes
- Pro: 100 registros/mes
- Premium: Ilimitado

**Plan requerido**: Pro o superior

---

#### 4.1.3 Captura Automática de SMS
**Descripción**: Lectura automática de SMS bancarios.

**Características**:
- Listener de SMS en segundo plano
- Detección de SMS financieros por:
  - Remitente (bancos conocidos)
  - Palabras clave: "compra", "retiro", "depósito", "cargo"
- Parsing automático:
  - Tipo de transacción
  - Monto
  - Comercio/origen
  - Tarjeta utilizada (últimos 4 dígitos)
- Creación automática de transacción
- Notificación al usuario
- Opción de editar/confirmar antes de guardar
- Reglas personalizables por banco

**Formato de SMS Soportados**:
```
Ejemplo 1: "Compra por $350.50 en STARBUCKS con tu tarjeta *1234"
Ejemplo 2: "Retiro de $500.00 en cajero BBVA el 12/07/2026"
Ejemplo 3: "Deposito de $1,500.00 recibido en tu cuenta"
```

**Parsing con Regex**:
- Monto: `\$?\d{1,3}(?:,\d{3})*(?:\.\d{2})?`
- Tipo: compra/cargo/retiro (egreso), deposito/abono (ingreso)
- Comercio: texto después de "en" o "de"

**Privacidad**:
- Solo procesa SMS financieros
- SMS originales NO se envían al servidor
- Solo se guarda información parseada
- Usuario puede desactivar la función

**Plan requerido**: Premium

**Limitaciones iOS**:
- iOS no permite lectura automática de SMS por seguridad
- Alternativa: Copiar y pegar SMS en la app para parsing

---

#### 4.1.4 Categorización de Transacciones
**Descripción**: Organización de transacciones por categorías.

**Características**:
- Categorías predefinidas (13 categorías)
- Crear categorías personalizadas
- Subcategorías (hasta 2 niveles)
- Iconos predefinidos (emojis)
- Colores personalizables
- Asignación automática por palabras clave
- Cambio de categoría masivo
- Estadísticas por categoría

**Categorías Predefinidas de Egresos**:
- 🍔 Alimentación
- 🚗 Transporte
- 🎬 Entretenimiento
- 💡 Servicios (luz, agua, internet)
- ⚕️ Salud
- 📚 Educación
- 🏠 Vivienda (renta, hipoteca)
- 👕 Ropa
- 💳 Otros Gastos

**Categorías Predefinidas de Ingresos**:
- 💰 Salario
- 💼 Freelance
- 📈 Inversiones
- 💵 Otros Ingresos

**Plan requerido**: Pro o superior

---

#### 4.1.5 Dashboard Financiero
**Descripción**: Vista general del estado financiero.

**Características**:
- Resumen del mes actual:
  - Total ingresos
  - Total egresos
  - Balance (ingresos - egresos)
  - Comparación con mes anterior (% cambio)
- Gráficos:
  - Línea de tendencia (últimos 6 meses)
  - Pie chart de gastos por categoría
  - Barra de ingresos vs egresos mensual
- Top 5 categorías con más gastos
- Top 5 gastos más grandes del mes
- Indicador de presupuesto (si está configurado)
- Proyección de fin de mes

**Interacciones**:
- Tap en categoría: ver detalle de transacciones
- Tap en gráfico: ver período completo
- Filtros: mes, categoría, tipo

**Plan requerido**: Pro (básico), Premium (avanzado)

---

#### 4.1.6 Presupuestos
**Descripción**: Establecer límites de gasto por categoría.

**Características**:
- Crear presupuesto por categoría
- Período: Semanal, Mensual, Anual
- Monto límite
- Alertas cuando se alcanza:
  - 50% del presupuesto
  - 80% del presupuesto
  - 100% del presupuesto
- Vista de progreso con barra visual
- Histórico de cumplimiento de presupuestos
- Sugerencias basadas en gastos históricos

**Validaciones**:
- Monto: > 0, máx 15 dígitos
- Período: obligatorio
- Categoría: obligatoria

**Plan requerido**: Premium

---

#### 4.1.7 Reportes Financieros
**Descripción**: Generación de reportes detallados.

**Características**:
- Tipos de reportes:
  - Resumen mensual
  - Comparativo multi-período
  - Por categoría
  - Cash flow
  - Tendencias
- Filtros:
  - Rango de fechas
  - Categorías específicas
  - Tipo de transacción
  - Método de pago
- Formatos de exportación:
  - PDF (con gráficos)
  - Excel (.xlsx)
  - CSV
- Envío por email
- Reportes programados (semanal, mensual)

**Información Incluida**:
- Total de transacciones
- Desglose por categoría
- Gráficos visuales
- Transacciones detalladas
- Estadísticas clave

**Plan requerido**: Pro (reportes básicos), Premium (reportes avanzados)

---

### 4.2 Casos de Uso

#### Caso de Uso 3: Registro por Voz
```
Actor: Usuario
Precondición: Usuario autenticado, plan Pro o superior, permisos de micrófono

Flujo:
1. Usuario navega a "Finanzas"
2. Usuario toca botón de micrófono
3. Usuario dice: "Gasté cincuenta dólares en el supermercado"
4. Usuario suelta el botón
5. Sistema sube audio a S3
6. Sistema invoca AWS Transcribe
7. Sistema espera transcripción (mostrar loading)
8. Transcribe devuelve: "gasté cincuenta dólares en el supermercado"
9. Lambda Parser procesa el texto:
   - Tipo: egreso (palabra "gasté")
   - Monto: $50.00
   - Categoría: Alimentación (palabra "supermercado")
   - Descripción: "Supermercado"
10. Sistema muestra vista previa con los datos extraídos
11. Usuario confirma o ajusta
12. Usuario guarda
13. Sistema crea transacción
14. Sistema muestra confirmación

Postcondición: Transacción registrada por voz
```

#### Caso de Uso 4: Captura Automática de SMS
```
Actor: Sistema (automático)
Precondición: Usuario con plan Premium, permisos de lectura SMS, Android

Flujo:
1. Usuario recibe SMS: "Compra por $35.50 en STARBUCKS con tu tarjeta *1234"
2. SMS Listener detecta SMS financiero (regex match)
3. Listener envía SMS al backend
4. Lambda SMS Parser procesa:
   - Tipo: egreso (palabra "compra")
   - Monto: $35.50
   - Comercio: STARBUCKS
   - Categoría: Entretenimiento (inferencia)
   - Método: Tarjeta de crédito *1234
5. Sistema crea transacción automáticamente
6. Sistema envía notificación push al usuario:
   "Nueva transacción registrada: $35.50 en STARBUCKS"
7. Usuario puede editar desde notificación si es necesario

Postcondición: Transacción creada automáticamente desde SMS
```

---

## 5. Módulo: Asistente IA

### 5.1 Funcionalidades Principales

#### 5.1.1 Chat Conversacional Inteligente
**Descripción**: Asistente IA conversacional que responde preguntas sobre tus datos.

**Características**:
- Chat en lenguaje natural con Amazon Bedrock (Claude 3.5 Sonnet)
- Contexto conversacional (recuerda últimos 10 mensajes)
- Acceso a datos del usuario:
  - Transacciones financieras
  - Presupuestos y balance
  - Tareas y calendario
  - Estadísticas y tendencias
- Respuestas personalizadas basadas en tus datos reales
- Historial de conversaciones guardado
- Sugerencias de preguntas comunes
- Respuesta en tiempo real (< 3 segundos)

**Ejemplos de Preguntas**:
- "¿Cuánto gasté en restaurantes este mes?"
- "¿Cuál es mi categoría de gasto más alta?"
- "¿Tengo tareas pendientes urgentes para mañana?"
- "Compara mis gastos de este mes con el anterior"
- "¿Estoy cumpliendo mi presupuesto de entretenimiento?"
- "Dame un resumen de mi semana financiera"

**Tipos de Análisis**:
- **Financiero**: Gastos por categoría, tendencias, comparaciones
- **Presupuestario**: Cumplimiento, proyecciones, alertas
- **Tareas**: Pendientes, prioridades, estadísticas de cumplimiento
- **Comparativo**: Mes actual vs anterior, categoría vs categoría
- **Predictivo**: Proyección de gastos fin de mes (solo Premium)

**Seguridad y Privacidad**:
- Solo accede a datos del usuario autenticado
- Filtrado obligatorio por organization_id + user_id
- No se comparten datos con terceros
- Datos anonimizados antes de enviar a Bedrock
- No se entrena modelo con datos del usuario

**Cuota de Uso**:
- Free: 0 mensajes/mes
- Basic: 20 mensajes/mes
- Pro: 100 mensajes/mes
- Premium: 500 mensajes/mes

**Plan requerido**: Basic o superior

---

#### 5.1.2 Insights y Análisis Automáticos
**Descripción**: IA genera insights automáticos sobre tus patrones financieros.

**Características**:
- Análisis semanal/mensual automático
- Detección de patrones de gasto:
  - Gastos inusuales (outliers)
  - Categorías con incremento significativo
  - Hábitos de gasto recurrentes
  - Comparación con períodos anteriores
- Alertas proactivas:
  - "Gastaste 40% más en transporte este mes"
  - "Tu categoría 'Entretenimiento' está 80% del presupuesto"
  - "Tienes 5 tareas urgentes sin fecha de vencimiento"
- Recomendaciones personalizadas:
  - Sugerencias de ahorro
  - Optimización de presupuestos
  - Priorización de tareas
- Dashboard de insights con tarjetas visuales
- Notificaciones push de insights importantes

**Frecuencia**:
- Análisis semanal: todos los lunes
- Análisis mensual: primer día de cada mes
- Alertas en tiempo real para eventos significativos

**Cuota de Uso**:
- Free: 0 análisis/mes
- Basic: 0 análisis/mes
- Pro: 5 análisis/mes
- Premium: 20 análisis/mes

**Plan requerido**: Pro o superior

---

#### 5.1.3 Predicciones Financieras
**Descripción**: Proyecciones inteligentes basadas en historial.

**Características**:
- Predicción de gastos fin de mes
- Proyección de balance mensual
- Predicción de cumplimiento de presupuestos
- Análisis de tendencias (3, 6, 12 meses)
- Identificación de estacionalidad:
  - Meses con más gastos
  - Categorías estacionales
  - Patrones anuales
- Sugerencias proactivas de ahorro
- Alertas de riesgo:
  - "A este ritmo, excederás tu presupuesto en $200"
  - "Proyectamos un balance negativo de -$150 este mes"

**Algoritmo**:
- Análisis de historial (mínimo 3 meses de datos)
- Detección de tendencias lineales y estacionales
- Cálculo de promedios móviles
- Ajuste por outliers
- Generación de proyección con intervalo de confianza

**Visualización**:
- Gráfico de tendencia histórica + proyección
- Intervalo de confianza (90%)
- Comparación con meses anteriores

**Cuota de Uso**:
- Free: 0 predicciones/mes
- Basic: 0 predicciones/mes
- Pro: 5 predicciones/mes
- Premium: 20 predicciones/mes

**Plan requerido**: Premium

---

#### 5.1.4 Resúmenes Inteligentes
**Descripción**: Resúmenes automáticos generados por IA.

**Características**:
- Resumen diario por notificación (opcional):
  - Tareas completadas hoy
  - Gastos del día
  - Pendientes para mañana
- Resumen semanal:
  - Total de ingresos y egresos
  - Principales categorías de gasto
  - Tareas completadas vs pendientes
  - Cumplimiento de presupuestos
- Resumen mensual:
  - Estado financiero completo
  - Comparación con mes anterior
  - Top 5 gastos más grandes
  - Estadísticas de productividad (tareas)
  - Recomendaciones para el próximo mes
- Formato:
  - Texto narrativo generado por IA
  - Bullet points con métricas clave
  - Gráficos visuales
- Envío por:
  - Push notification
  - Email (opcional)
  - Disponible en app

**Personalización**:
- Frecuencia configurable
- Selección de qué módulos incluir
- Nivel de detalle (breve, normal, detallado)

**Cuota de Uso**:
Incluido en cuota de chat/análisis (no consume cuota adicional)

**Plan requerido**: Pro o superior

---

### 5.2 Casos de Uso

#### Caso de Uso 5: Chat con IA sobre Finanzas
```
Actor: Usuario
Precondición: Usuario con plan Basic o superior, cuota de chat disponible

Flujo:
1. Usuario navega a sección "Asistente IA"
2. Usuario ve sugerencias: "¿Cuánto gasté este mes?", "Muéstrame mis tareas"
3. Usuario escribe: "¿Cuánto gasté en restaurantes este mes?"
4. Sistema valida cuota de IA (verifica ai_usage)
5. Sistema obtiene datos del usuario:
   - Query: transacciones WHERE user_id = X AND category = 'Alimentación'
   - Filtrado por mes actual
6. Sistema construye prompt con contexto:
   - Historial conversación (últimos 10 mensajes)
   - Datos de transacciones
   - Pregunta del usuario
7. Sistema invoca Amazon Bedrock (Claude 3.5 Sonnet)
8. Bedrock analiza y genera respuesta
9. Sistema recibe: "Gastaste $450 en restaurantes este mes, lo cual
   representa el 20% de tus gastos totales. Esto es un 15% más que
   el mes pasado. Tu restaurante más frecuente fue Starbucks con $120."
10. Sistema guarda conversación en ai_conversations
11. Sistema incrementa ai_usage (chat_messages)
12. Sistema muestra respuesta al usuario
13. Usuario puede hacer pregunta de seguimiento

Postcondición: Conversación guardada, cuota de IA consumida
```

#### Caso de Uso 6: Insight Automático Semanal
```
Actor: Sistema (automático)
Precondición: Usuario con plan Pro o superior, lunes 9:00 AM

Flujo:
1. EventBridge trigger ejecuta cada lunes
2. Lambda AI Insights procesa usuarios elegibles
3. Para cada usuario:
   a. Obtiene transacciones de la semana pasada
   b. Obtiene tareas completadas/pendientes
   c. Calcula métricas clave
4. Sistema construye prompt para Bedrock:
   "Genera un resumen semanal basado en estos datos..."
5. Bedrock genera insight personalizado
6. Sistema crea notificación push:
   "📊 Tu resumen semanal está listo"
7. Usuario abre notificación
8. Ve insights:
   - "Esta semana gastaste $320, un 10% menos que la anterior"
   - "Completaste 8 de 12 tareas planificadas (67%)"
   - "Tu categoría de mayor gasto fue Transporte ($85)"
9. Sistema guarda insight en ai_conversations
10. Sistema incrementa ai_usage (insights_generated)

Postcondición: Insight generado y notificado al usuario
```

---

## 6. Módulo: Autenticación y Usuarios

### 6.1 Funcionalidades

#### 6.1.1 Registro de Usuario
**Características**:
- Email y contraseña
- Validación de email (link de confirmación)
- Validación de contraseña:
  - Mínimo 8 caracteres
  - Al menos 1 mayúscula
  - Al menos 1 número
  - Al menos 1 carácter especial
- Creación automática de organización personal
- Asignación a plan Free por defecto con trial de 14 días

#### 6.1.2 Login
**Características**:
- Email y contraseña
- JWT access token (15 minutos)
- JWT refresh token (7 días)
- Recuerdar sesión en dispositivo
- Login desde múltiples dispositivos
- MFA opcional (TOTP con Google Authenticator)

#### 6.1.3 Recuperación de Contraseña
**Características**:
- Envío de link por email
- Token de recuperación válido por 1 hora
- Cambio de contraseña con token

#### 6.1.4 Perfil de Usuario
**Características**:
- Editar nombre, avatar, teléfono
- Cambiar contraseña
- Preferencias:
  - Idioma (Español, Inglés)
  - Zona horaria
  - Moneda predeterminada
  - Notificaciones (push, email)
- Ver plan actual y uso
- Cerrar sesión
- Eliminar cuenta (con confirmación)

---

## 7. Módulo: Suscripciones

### 7.1 Planes Disponibles

| Característica | Free | Basic | Pro | Premium |
|----------------|------|-------|-----|---------|
| **Precio/mes** | $0 | $4.99 | $9.99 | $19.99 |
| **Trial** | 14 días | 14 días | 14 días | 14 días |
| **Usuarios** | 1 | 1 | 1 | 1 |
| **TAREAS Y CALENDARIO** | | | | |
| Tareas | ✅ Ilimitadas | ✅ Ilimitadas | ✅ Ilimitadas | ✅ Ilimitadas |
| Recordatorios | 50 | 200 | Ilimitados | Ilimitados |
| **Registro Tareas por Voz** | ❌ 0/mes | ✅ 10/mes | ✅ 100/mes | ✅ Ilimitado |
| **GESTOR DE CONTRASEÑAS** | | | | |
| Contraseñas | ❌ | ✅ Ilimitadas | ✅ Ilimitadas | ✅ Ilimitadas |
| Generador Contraseñas | ❌ | ✅ | ✅ | ✅ |
| Auditoría Seguridad | ❌ | ❌ | ❌ | ✅ |
| **FINANZAS PERSONALES** | | | | |
| Finanzas Manuales | ❌ | ❌ | ✅ Ilimitadas | ✅ Ilimitadas |
| **Registro por Voz** | ❌ 0/mes | ❌ 0/mes | ✅ 100/mes | ✅ Ilimitado |
| Captura SMS | ❌ | ❌ | ❌ | ✅ |
| Presupuestos | ❌ | ❌ | ❌ | ✅ Ilimitados |
| **ASISTENTE IA** | | | | |
| **Chat IA msgs/mes** | ❌ 0 | ✅ 20 | ✅ 100 | ✅ 500 |
| **Insights Automáticos/mes** | ❌ 0 | ❌ 0 | ✅ 5 | ✅ 20 |
| **Predicciones IA/mes** | ❌ 0 | ❌ 0 | ❌ 0 | ✅ 20 |
| **Resúmenes Inteligentes** | ❌ | ❌ | ✅ | ✅ |
| **REPORTES** | | | | |
| Reportes | ❌ | ❌ | ✅ Básicos | ✅ Avanzados |
| Exportar Datos | ❌ | ❌ | ✅ CSV | ✅ PDF/Excel |
| **SOPORTE** | Email | Email | Email + Chat | Priority |

### 7.2 Gestión de Suscripciones

#### Upgrade de Plan
- Cambio inmediato
- Prorrateo del monto restante
- Acceso instantáneo a nuevas funcionalidades

#### Downgrade de Plan
- Se aplica al final del período actual
- Notificación 7 días antes
- Pérdida de acceso a features premium

#### Cancelación
- Acceso hasta fin de período pagado
- Downgrade automático a Free
- Datos preservados por 180 días

#### Renovación
- Automática con tarjeta guardada
- Notificación 7 días antes
- Retry automático si falla (3 intentos)
- Período de gracia de 3 días

---

## 8. Módulo: Reportes

### 8.1 Tipos de Reportes

#### Reporte de Tareas
- Tareas completadas por período
- Tasa de cumplimiento
- Tiempo promedio de completado
- Tareas por prioridad
- Tareas por etiqueta

#### Reporte de Finanzas
- Ingresos vs Egresos
- Gastos por categoría
- Tendencias mensuales
- Cumplimiento de presupuestos
- Proyecciones

#### Reporte de Seguridad (Contraseñas)
- Puntaje general
- Contraseñas débiles/reutilizadas
- Últimas modificaciones
- Recomendaciones

---

## 9. Módulo: Administración Web (Angular)

### 9.1 Panel de Superusuario

**Funcionalidades**:
- Dashboard con métricas:
  - Total usuarios activos (DAU/MAU)
  - Nuevos registros (día/semana/mes)
  - Suscripciones por plan
  - Ingresos mensuales (MRR)
  - Tasa de cancelación (churn rate)
- Gestión de usuarios:
  - Buscar usuario
  - Ver perfil completo
  - Editar datos
  - Suspender/reactivar cuenta
  - Cambiar plan manualmente
  - Resetear contraseña
- Gestión de planes:
  - Crear/editar/desactivar planes
  - Modificar precios
  - Configurar features
- Reportes administrativos:
  - Usuarios registrados por día
  - Conversiones de trial a pago
  - Métodos de pago más usados
  - Exportar data de usuarios
- Logs del sistema:
  - Errores de backend
  - Eventos de seguridad
  - Audit trail

**Acceso**:
- Solo usuarios con rol `superadmin`
- Autenticación con MFA obligatorio
- Sesiones de 1 hora máximo

---

## 10. Matriz de Features por Plan

```
Feature Matrix:

┌──────────────────────────────────────┬──────┬────────┬──────┬─────────┐
│ Funcionalidad                        │ Free │ Basic  │ Pro  │ Premium │
├──────────────────────────────────────┼──────┼────────┼──────┼─────────┤
│ TAREAS Y CALENDARIO                  │      │        │      │         │
│ - Crear tareas ilimitadas            │  ✅  │   ✅   │  ✅  │   ✅    │
│ - Etiquetas y categorías             │  ✅  │   ✅   │  ✅  │   ✅    │
│ - Calendario mensual/semanal/diario  │  ✅  │   ✅   │  ✅  │   ✅    │
│ - Recordatorios (cantidad)           │  50  │   200  │  ∞   │    ∞    │
│ - Tareas recurrentes                 │  ✅  │   ✅   │  ✅  │   ✅    │
│ - Subtareas                          │  ✅  │   ✅   │  ✅  │   ✅    │
│ - Registro tareas por voz/mes        │  ❌  │   10   │ 100  │    ∞    │
├──────────────────────────────────────┼──────┼────────┼──────┼─────────┤
│ GESTOR DE CONTRASEÑAS                │      │        │      │         │
│ - Guardar contraseñas                │  ❌  │   ✅   │  ✅  │   ✅    │
│ - Generador de contraseñas           │  ❌  │   ✅   │  ✅  │   ✅    │
│ - Categorías y etiquetas             │  ❌  │   ✅   │  ✅  │   ✅    │
│ - Búsqueda avanzada                  │  ❌  │   ✅   │  ✅  │   ✅    │
│ - Auditoría de seguridad             │  ❌  │   ❌   │  ❌  │   ✅    │
├──────────────────────────────────────┼──────┼────────┼──────┼─────────┤
│ FINANZAS PERSONALES                  │      │        │      │         │
│ - Registro manual                    │  ❌  │   ❌   │  ✅  │   ✅    │
│ - Registro por voz/mes               │  ❌  │   ❌   │ 100  │    ∞    │
│ - Captura automática de SMS          │  ❌  │   ❌   │  ❌  │   ✅    │
│ - Categorías personalizadas          │  ❌  │   ❌   │  ✅  │   ✅    │
│ - Dashboard financiero               │  ❌  │   ❌   │  ✅  │   ✅    │
│ - Presupuestos                       │  ❌  │   ❌   │  ❌  │   ✅    │
│ - Reportes básicos                   │  ❌  │   ❌   │  ✅  │   ✅    │
│ - Reportes avanzados                 │  ❌  │   ❌   │  ❌  │   ✅    │
│ - Exportar CSV                       │  ❌  │   ❌   │  ✅  │   ✅    │
│ - Exportar PDF/Excel                 │  ❌  │   ❌   │  ❌  │   ✅    │
├──────────────────────────────────────┼──────┼────────┼──────┼─────────┤
│ ASISTENTE IA                         │      │        │      │         │
│ - Chat IA mensajes/mes               │  ❌  │   20   │ 100  │   500   │
│ - Insights automáticos/mes           │  ❌  │   ❌   │  5   │   20    │
│ - Predicciones financieras/mes       │  ❌  │   ❌   │  ❌  │   20    │
│ - Resúmenes inteligentes             │  ❌  │   ❌   │  ✅  │   ✅    │
│ - Análisis de patrones               │  ❌  │   ❌   │  ✅  │   ✅    │
└──────────────────────────────────────┴──────┴────────┴──────┴─────────┘
```

---

## 11. Roadmap de Funcionalidades

### Fase 1 - MVP (Meses 1-3)
- ✅ Autenticación JWT sin Cognito
- ✅ Módulo de Tareas (básico)
- ✅ Calendario mensual
- ✅ Recordatorios básicos
- ✅ Sistema de suscripciones
- ✅ App móvil básica

### Fase 2 - Módulos Core (Meses 4-6)
- ✅ Módulo de Contraseñas completo
- ✅ Módulo de Finanzas (manual)
- ✅ Dashboard financiero
- ✅ Reportes básicos
- ✅ Panel web admin

### Fase 3 - Features Avanzadas + IA (Meses 7-9)
- ✅ Registro por voz (tareas y finanzas)
- ✅ Amazon Bedrock integration (Claude 3.5 Sonnet)
- ✅ Chat IA conversacional
- ✅ Procesamiento inteligente de voz
- ✅ Captura automática de SMS
- ✅ Presupuestos
- ✅ Reportes avanzados
- ✅ Exportación PDF/Excel
- ✅ Integración Stripe

### Fase 4 - IA Avanzada + Optimización (Meses 10-12)
- ✅ Insights automáticos con IA
- ✅ Predicciones financieras
- ✅ Resúmenes inteligentes
- ✅ Sistema de cuotas de IA
- ✅ Cache con Redis
- ✅ RDS Proxy
- ✅ Performance optimization
- ✅ Mobile app refinamiento
- ✅ Analytics avanzado

### Futuro (Fase 5+)
**Funcionalidades Tradicionales**:
- Modo offline en app móvil
- Sincronización con calendarios externos (Google Calendar, Outlook)
- Integración con bancos (Plaid)
- Widget para pantalla de inicio
- Apple Watch / Wear OS app
- Dark mode
- Compartir tareas con otros usuarios (modo colaborativo)
- API pública para integraciones
- Backup automático a Dropbox/Google Drive

**Funcionalidades IA**:
- Detección de gastos anómalos con ML
- Recomendaciones personalizadas de ahorro
- Categorización automática mejorada con aprendizaje
- Análisis de sentimiento en tareas (detectar estrés/sobrecarga)
- Asistente de voz hands-free (conversación completa)
- Predicciones multi-variables (gastos + tareas + eventos)
- Integración con Amazon Comprehend para NLP avanzado
- Dashboards generados dinámicamente por IA según contexto

---

## Changelog

### v1.1.0 (2026-07-12)
- ✅ Agregado nuevo módulo: Asistente IA (Sección 5)
- ✅ Chat conversacional con Amazon Bedrock (Claude 3.5 Sonnet)
- ✅ Insights y análisis automáticos con IA
- ✅ Predicciones financieras inteligentes
- ✅ Resúmenes automáticos generados por IA
- ✅ Actualizado: Registro de tareas por voz con IA (Sección 2.1.5)
- ✅ Actualizado: Registro de finanzas por voz con IA (Sección 4.1.2)
- ✅ Tabla de suscripciones actualizada con cuotas de IA
- ✅ Matriz de features actualizada con funcionalidades de IA
- ✅ Roadmap actualizado (Fases 3 y 4 incluyen IA)
- ✅ Casos de uso de IA agregados

### v1.0.0 (2026-07-12)
- Versión inicial con 3 módulos principales y 4 transversales

---

**Documento creado**: 2026-07-12
**Última actualización**: 2026-07-12
**Versión**: 1.1.0
