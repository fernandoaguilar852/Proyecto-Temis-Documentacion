# Módulo AI Memory - TEMIS
## "Tu Segunda Memoria Digital"

---

## 1. Visión General

**AI Memory** es un módulo revolucionario de TEMIS que funciona como una "segunda memoria" inteligente para los usuarios. Permite capturar, almacenar y recuperar información de múltiples fuentes (conversaciones, fotos, documentos, correos, notas de voz) mediante búsqueda semántica potenciada por IA.

### 1.1 Propuesta de Valor

**Problema que resuelve**:
- Las personas olvidan detalles importantes de conversaciones, lugares visitados, consejos recibidos, o dónde guardaron información.
- La información personal está dispersa en múltiples apps (fotos, notas, correo, mensajes).
- Es difícil encontrar información específica cuando se necesita.

**Solución**:
- Captura todo tipo de información en un solo lugar
- Procesamiento inteligente con IA para extraer contexto
- Búsqueda en lenguaje natural: "¿Cómo se llamaba el restaurante al que fui hace 3 meses?"
- Acceso instantáneo a memorias pasadas

### 1.2 Casos de Uso Reales

- "¿Qué dijo el médico sobre mi colesterol en la última consulta?"
- "¿Dónde guardé la garantía del televisor?"
- "¿Cuál era el nombre del contacto que me recomendaron en aquella reunión?"
- "¿Cuál es la talla de zapatos de mi hijo?"
- "¿Qué vino me recomendó el sommelier en ese restaurante italiano?"
- "¿Qué ingredientes tenía esa receta que me pasó mi abuela?"

---

## 2. Funcionalidades Principales

### 2.1 Captura de Memorias

#### 2.1.1 Grabar Conversaciones
**Descripción**: Grabación de audio de conversaciones importantes.

**Características**:
- Grabación de audio (máx 10 minutos por memoria)
- Formatos: AAC, MP3
- Pausar/reanudar durante grabación
- Vista de forma de onda en tiempo real
- Reproducción antes de guardar
- Transcripción automática con AWS Transcribe
- Detección automática de idioma (es-ES, es-MX, en-US)
- Identificación de múltiples hablantes (diarization)
- Timestamps de la transcripción
- Marcadores temporales manuales durante grabación

**Procesamiento Inteligente**:
- Transcripción completa del audio
- Extracción de entidades (nombres, lugares, fechas)
- Generación de título automático basado en contenido
- Detección de temas principales
- Generación de resumen de la conversación (3-5 bullet points)
- Creación de embeddings para búsqueda semántica

**Validaciones**:
- Duración máxima: 10 minutos (Free/Basic), 30 minutos (Pro), ilimitado (Premium)
- Tamaño máximo archivo: 50 MB
- Formatos permitidos: .aac, .mp3, .m4a, .wav

**Cuota de Uso**:
- Free: 5 conversaciones/mes
- Basic: 20 conversaciones/mes
- Pro: 100 conversaciones/mes
- Premium: Ilimitado

**Plan requerido**: Free o superior

---

#### 2.1.2 Tomar Fotos
**Descripción**: Captura de fotos con procesamiento OCR inteligente.

**Características**:
- Cámara integrada en la app
- Selección desde galería
- Múltiples fotos por memoria (hasta 10)
- Vista previa antes de guardar
- Recorte y rotación básica
- Compresión inteligente (mantiene calidad)
- Metadatos automáticos:
  - Fecha y hora de captura
  - Ubicación GPS (si está habilitado)
  - Dimensiones de la imagen

**Procesamiento Inteligente con IA**:
- OCR con AWS Textract:
  - Extracción de texto visible en la imagen
  - Detección de documentos (ID, recibos, facturas)
  - Extracción de tablas y formularios
- Análisis de contenido con Amazon Bedrock:
  - Descripción automática de la imagen
  - Detección de objetos y escenas
  - Extracción de información relevante (ej: menú de restaurante → platos y precios)
  - Generación de etiquetas automáticas
- Generación de embeddings del texto extraído

**Ejemplos de Uso**:
- Foto de receta en un libro → OCR extrae ingredientes y pasos
- Foto de tarjeta de presentación → extrae nombre, email, teléfono
- Foto de menú de restaurante → extrae platos y precios
- Foto de garantía/factura → extrae fecha, producto, número de serie
- Foto de pizarra/whiteboard → extrae texto y diagramas

**Validaciones**:
- Tamaño máximo: 10 MB por foto
- Formatos: .jpg, .jpeg, .png, .heic
- Máximo 10 fotos por memoria

**Cuota de Uso**:
- Free: 10 fotos con OCR/mes
- Basic: 50 fotos con OCR/mes
- Pro: 200 fotos con OCR/mes
- Premium: Ilimitado

**Plan requerido**: Free o superior

---

#### 2.1.3 Guardar Documentos
**Descripción**: Almacenamiento y procesamiento de documentos.

**Características**:
- Subida de archivos desde dispositivo
- Tipos soportados:
  - PDFs
  - Word (.doc, .docx)
  - Excel (.xls, .xlsx)
  - PowerPoint (.ppt, .pptx)
  - Texto plano (.txt, .md)
- Vista previa de documentos en la app
- Búsqueda dentro del documento
- Versionado (guardar múltiples versiones)
- Organización por carpetas/etiquetas
- Descarga del documento original

**Procesamiento Inteligente**:
- Extracción de texto completo:
  - PDFs → extracción directa con PyPDF2 o AWS Textract
  - Word/Excel/PPT → conversión a texto
- Análisis de contenido con Amazon Bedrock:
  - Generación de resumen automático
  - Extracción de puntos clave
  - Detección de información sensible (números de cuenta, SSN)
  - Clasificación automática del tipo de documento
  - Sugerencia de etiquetas relevantes
- Generación de embeddings del contenido completo

**Ejemplos de Uso**:
- Guardar pólizas de seguro
- Almacenar contratos importantes
- Guardar manuales de productos
- Almacenar certificados y diplomas
- Guardar recetas médicas

**Validaciones**:
- Tamaño máximo por documento:
  - Free: 5 MB
  - Basic: 10 MB
  - Pro: 50 MB
  - Premium: 200 MB
- Formatos permitidos: pdf, doc, docx, xls, xlsx, ppt, pptx, txt, md

**Cuota de Almacenamiento**:
- Consume del storage total del usuario

**Plan requerido**: Basic o superior

---

#### 2.1.4 Reenviar Correos
**Descripción**: Guardar emails importantes mediante reenvío.

**Características**:
- Email único por usuario: `memories+{user_id}@temis.app`
- Parser automático de emails entrantes
- Extracción de:
  - Asunto
  - Remitente
  - Fecha del email original
  - Cuerpo del mensaje (texto plano y HTML)
  - Adjuntos (procesados como documentos)
- Preservación del formato original
- Links a archivos adjuntos procesados
- Notificación cuando se recibe un email

**Procesamiento Inteligente**:
- Limpieza de HTML y formato
- Extracción de información clave del email
- Detección de tipo de email:
  - Confirmación de compra/reserva
  - Factura/recibo
  - Newsletter/boletín
  - Comunicación personal
  - Notificación de servicio
- Generación de resumen del email
- Extracción de fechas, direcciones, números importantes
- Procesamiento de adjuntos (aplicar OCR, extracción de texto)
- Generación de embeddings del contenido

**Ejemplos de Uso**:
- Confirmaciones de reservas de hotel/vuelo
- Recibos de compras online
- Emails con instrucciones importantes
- Correos con direcciones de lugares a visitar
- Emails de trabajo con información relevante

**Implementación Técnica**:
- SES recibe emails en `memories@temis.app`
- SES trigger invoca Lambda Email Parser
- Lambda extrae user_id del destinatario (+suffix)
- Lambda procesa contenido y adjuntos
- Lambda crea memoria en BD
- Lambda envía notificación push al usuario

**Validaciones**:
- Tamaño máximo email: 10 MB (incluyendo adjuntos)
- Adjuntos procesados individualmente (aplican límites de documentos)
- Emails de remitentes bloqueados se descartan automáticamente

**Cuota de Uso**:
- Free: 5 emails/mes
- Basic: 20 emails/mes
- Pro: 100 emails/mes
- Premium: Ilimitado

**Plan requerido**: Basic o superior

---

#### 2.1.5 Notas de Voz
**Descripción**: Grabación rápida de notas y recordatorios por voz.

**Características**:
- Grabación rápida (acceso desde widget/shortcut)
- Duración: 10 segundos a 5 minutos
- Pausar/reanudar
- Reproducción con control de velocidad (0.5x, 1x, 1.5x, 2x)
- Guardado automático
- Organización cronológica
- Búsqueda por contenido transcrito

**Procesamiento Inteligente**:
- Transcripción automática con AWS Transcribe
- Detección de idioma automática
- Generación de título basado en primeras palabras
- Extracción de acciones/tareas mencionadas:
  - Si menciona "recordar" o "tarea" → sugiere crear tarea en módulo Tareas
  - Si menciona montos → sugiere crear transacción en Finanzas
  - Si menciona evento/fecha → sugiere crear recordatorio
- Detección de información clave (fechas, nombres, lugares)
- Generación de embeddings de la transcripción

**Ejemplos de Uso**:
- Ideas rápidas mientras conduces
- Recordatorios verbales
- Lista de compras dictada
- Pensamientos/reflexiones
- Instrucciones recibidas verbalmente

**Validaciones**:
- Duración mínima: 1 segundo
- Duración máxima: 5 minutos (Free/Basic), 15 minutos (Pro/Premium)
- Tamaño máximo: 25 MB

**Cuota de Uso**:
- Free: 10 notas/mes
- Basic: 50 notas/mes
- Pro: 200 notas/mes
- Premium: Ilimitado

**Plan requerido**: Free o superior

---

### 2.2 Búsqueda Inteligente con IA

#### 2.2.1 Búsqueda Semántica
**Descripción**: Búsqueda en lenguaje natural sobre todas las memorias.

**Características**:
- Búsqueda por pregunta en lenguaje natural
- No requiere palabras clave exactas
- Búsqueda por contexto y significado
- Resultados ordenados por relevancia
- Resaltado de fragmentos relevantes
- Filtros opcionales:
  - Por tipo de memoria (conversación, foto, documento, email, voz)
  - Por rango de fechas
  - Por etiquetas
  - Por ubicación (si disponible)

**Tecnología**:
- Embeddings generados con Amazon Bedrock (Claude 3.5 Sonnet)
- Vector database con PostgreSQL + pgvector extension
- Búsqueda de similitud coseno
- Re-ranking con modelo de Bedrock
- Contexto enriquecido con metadatos

**Algoritmo de Búsqueda**:
1. Usuario hace pregunta en lenguaje natural
2. Sistema genera embedding de la pregunta con Bedrock
3. Búsqueda de vectores similares en BD (top 20 candidatos)
4. Re-ranking con Bedrock considerando contexto completo
5. Presentar top 5-10 resultados más relevantes
6. Generar snippet explicativo de por qué es relevante

**Ejemplos de Búsquedas**:
- "¿Qué restaurante me recomendaron hace dos meses?"
  → Busca en conversaciones y notas de voz de hace ~2 meses sobre restaurantes
- "Instrucciones del médico sobre mi colesterol"
  → Busca en conversaciones, fotos (recetas) y documentos con contexto médico
- "Dónde guardé la garantía del televisor"
  → Busca en documentos y fotos con palabras "garantía", "televisor", "TV"
- "Información sobre ese hotel en Cancún"
  → Busca en emails (confirmaciones), fotos, documentos con contexto de hoteles/Cancún

**Respuesta de IA**:
Además de mostrar resultados, la IA puede:
- Sintetizar información de múltiples memorias
- Responder la pregunta directamente si tiene suficiente contexto
- Sugerir memorias relacionadas que podrían ser útiles
- Indicar si falta información

**Performance**:
- Búsqueda: < 2 segundos
- Generación de embeddings: < 1 segundo
- Caché de embeddings frecuentes

**Cuota de Uso**:
- Free: 10 búsquedas IA/mes
- Basic: 50 búsquedas IA/mes
- Pro: 200 búsquedas IA/mes
- Premium: Ilimitado

**Plan requerido**: Free o superior (búsqueda básica), Pro (búsqueda semántica avanzada)

---

#### 2.2.2 Búsqueda por Texto
**Descripción**: Búsqueda tradicional por palabras clave.

**Características**:
- Búsqueda full-text en PostgreSQL
- Operadores booleanos (AND, OR, NOT)
- Búsqueda por frase exacta (entre comillas)
- Autocompletado de búsqueda
- Historial de búsquedas recientes
- Búsqueda en:
  - Títulos de memorias
  - Transcripciones de audio
  - Texto extraído por OCR
  - Contenido de documentos
  - Cuerpo de emails
  - Notas/descripciones manuales

**Performance**:
- Índice GIN en PostgreSQL para full-text search
- Búsqueda instantánea (< 500ms)
- Debounce de 300ms en input

**Plan requerido**: Free o superior

---

### 2.3 Organización y Gestión

#### 2.3.1 Etiquetas y Categorías
**Descripción**: Organización flexible de memorias.

**Características**:
- Etiquetas personalizadas ilimitadas
- Múltiples etiquetas por memoria
- Colores personalizables
- Categorías predefinidas:
  - 🏥 Salud
  - 💼 Trabajo
  - 👨‍👩‍👧‍👦 Familia
  - 🎓 Educación
  - 🏠 Hogar
  - 🛒 Compras
  - 🍽️ Restaurantes
  - ✈️ Viajes
  - 💡 Ideas
  - 📝 Otros
- Etiquetado automático sugerido por IA
- Filtrar memorias por etiqueta
- Estadísticas por etiqueta

**Plan requerido**: Free o superior

---

#### 2.3.2 Edición de Memorias
**Descripción**: Edición posterior de memorias guardadas.

**Características**:
- Editar título
- Añadir/editar descripción manual
- Añadir/quitar etiquetas
- Marcar como favorito
- Archivar memoria (ocultar de búsqueda principal)
- Eliminar memoria (soft delete con recuperación 30 días)
- Compartir memoria (exportar como PDF o link)
- Editar transcripción (si el OCR/transcripción tuvo errores)
- Añadir archivos adicionales a una memoria existente

**Validaciones**:
- Título: máx 500 caracteres
- Descripción: máx 5000 caracteres

**Plan requerido**: Free o superior

---

### 2.4 Gestión de Almacenamiento

#### 2.4.1 Cuotas de Almacenamiento por Plan

| Plan | Almacenamiento | Precio Adicional |
|------|----------------|------------------|
| **Free** | 2 GB | $0.99/GB adicional |
| **Basic** | 5 GB | $0.79/GB adicional |
| **Pro** | 20 GB | $0.49/GB adicional |
| **Premium** | 100 GB | $0.29/GB adicional |

**Cálculo de Uso**:
- Audio: tamaño original del archivo
- Fotos: tamaño comprimido
- Documentos: tamaño original
- Emails: tamaño del email + adjuntos
- Metadatos (transcripciones, embeddings): no cuentan

**Límites de Archivo Individual**:
- Audio: 50 MB (Free/Basic), 100 MB (Pro/Premium)
- Foto: 10 MB por foto
- Documento: 5 MB (Free), 10 MB (Basic), 50 MB (Pro), 200 MB (Premium)
- Email: 10 MB total

---

#### 2.4.2 Dashboard de Almacenamiento
**Descripción**: Visualización del uso de storage.

**Características**:
- Uso actual vs límite del plan
- Barra de progreso visual
- Desglose por tipo de memoria:
  - % usado por conversaciones
  - % usado por fotos
  - % usado por documentos
  - % usado por emails
  - % usado por notas de voz
- Lista de memorias más grandes
- Recomendaciones de limpieza
- Opción de comprar almacenamiento adicional
- Alertas cuando se alcanza:
  - 70% del almacenamiento
  - 90% del almacenamiento
  - 100% del almacenamiento

**Plan requerido**: Free o superior

---

### 2.5 Insights y Análisis

#### 2.5.1 Resúmenes Automáticos
**Descripción**: Resúmenes generados por IA de períodos de tiempo.

**Características**:
- Resumen semanal de memorias guardadas
- Resumen mensual con estadísticas
- Temas más frecuentes en tus memorias
- Personas más mencionadas
- Lugares más visitados/mencionados
- Tendencias en tus intereses

**Ejemplo de Resumen Semanal**:
```
📊 Tu Semana en AI Memory (7-13 Jul)

✅ Guardaste 12 memorias esta semana
   - 5 conversaciones
   - 4 fotos
   - 2 documentos
   - 1 nota de voz

🏆 Temas principales:
   1. Salud (3 memorias sobre citas médicas)
   2. Trabajo (4 memorias sobre proyectos)
   3. Familia (2 eventos familiares)

🔍 Búsquedas más frecuentes:
   - Información sobre seguro médico
   - Restaurante recomendado

💡 Sugerencia: Tienes 3 documentos sin etiquetar,
   ¿quieres que te ayude a organizarlos?
```

**Cuota de Uso**:
- Free: 0 resúmenes/mes
- Basic: 1 resumen/mes
- Pro: 4 resúmenes/mes (semanal)
- Premium: Ilimitado (semanal + mensual)

**Plan requerido**: Basic o superior

---

#### 2.5.2 Sugerencias Inteligentes
**Descripción**: Sugerencias proactivas de la IA.

**Características**:
- Recordatorios inteligentes:
  - "Hace 6 meses guardaste la garantía del refrigerador,
     ¿quieres marcar cuándo expira?"
- Conexiones entre memorias:
  - "Esta nota de voz menciona el Dr. González, tienes
     2 memorias más sobre él"
- Sugerencias de organización:
  - "Tienes 5 fotos de recetas sin etiquetar"
- Oportunidades de acción:
  - "En esta conversación mencionaste llamar a María,
     ¿quieres crear una tarea?"

**Plan requerido**: Pro o superior

---

## 3. Casos de Uso Detallados

### Caso de Uso 1: Guardar Conversación con Médico

```
Actor: Usuario (Plan Pro)
Precondición: Usuario autenticado, permisos de micrófono

Flujo:
1. Usuario está en consulta médica
2. Usuario abre app, navega a AI Memory
3. Usuario toca "Grabar Conversación"
4. Usuario permite permiso de micrófono
5. Sistema inicia grabación, muestra timer y forma de onda
6. Usuario graba conversación de 8 minutos
7. Usuario toca "Detener"
8. Sistema muestra vista previa con player de audio
9. Usuario añade título manual: "Consulta Dr. López - Colesterol"
10. Usuario selecciona etiqueta: "Salud"
11. Usuario toca "Guardar"
12. Sistema sube audio a S3
13. Sistema invoca Lambda AI Memory Processor
14. Lambda procesa en background:
    a. Invoca AWS Transcribe para transcripción
    b. Espera resultado de Transcribe (1-2 min)
    c. Invoca Bedrock para análisis:
       - Extrae entidades (Dr. López, colesterol, medicamentos)
       - Genera resumen: "Consulta sobre niveles de colesterol..."
       - Extrae puntos clave:
         * Colesterol LDL: 180 mg/dL (alto)
         * Recomendación: dieta baja en grasas
         * Medicamento: Atorvastatina 20mg
         * Próxima cita: 3 meses
    d. Genera embeddings del contenido
    e. Guarda en BD: memory, memory_attachments, memory_embeddings
15. Sistema notifica al usuario: "✅ Memoria procesada y lista para búsqueda"
16. Usuario puede buscar: "¿Qué medicamento me recetó el doctor?"

Postcondición: Conversación guardada, transcrita, analizada y lista para búsqueda
```

---

### Caso de Uso 2: Foto de Receta con OCR

```
Actor: Usuario (Plan Basic)
Precondición: Usuario autenticado, permisos de cámara

Flujo:
1. Usuario ve receta en un libro de cocina
2. Usuario abre app, navega a AI Memory
3. Usuario toca "Tomar Foto"
4. Usuario toma foto de la receta
5. Sistema muestra preview de la foto
6. Usuario toca "Guardar"
7. Sistema comprime imagen inteligentemente
8. Sistema sube a S3
9. Sistema invoca Lambda AI Memory Processor
10. Lambda procesa en background:
    a. Invoca AWS Textract para OCR
    b. Textract extrae:
       - Título: "Lasaña de Espinacas"
       - Ingredientes (lista completa)
       - Pasos de preparación
       - Tiempo de cocción: 45 min
    c. Invoca Bedrock para análisis:
       - Identifica que es una receta
       - Genera etiquetas sugeridas: "Recetas", "Cocina", "Italiana"
       - Extrae información estructurada (ingredientes como lista)
    d. Genera embeddings del texto extraído
    e. Guarda en BD
11. Sistema notifica: "✅ Receta guardada. Encontramos 12 ingredientes"
12. Sistema sugiere etiquetas: "Recetas, Italiana"
13. Usuario acepta etiquetas
14. Más tarde, usuario busca: "receta de lasaña con espinacas"
15. Sistema encuentra la memoria inmediatamente

Postcondición: Foto guardada con OCR completo y búsqueda semántica
```

---

### Caso de Uso 3: Búsqueda Inteligente

```
Actor: Usuario (Plan Premium)
Precondición: Usuario tiene 50+ memorias guardadas

Flujo:
1. Usuario navega a AI Memory
2. Usuario toca barra de búsqueda inteligente
3. Usuario pregunta: "¿Qué restaurante me recomendaron hace 3 meses?"
4. Sistema valida cuota de búsquedas IA (verifica ai_usage)
5. Sistema genera embedding de la pregunta con Bedrock
6. Sistema realiza búsqueda vectorial en memory_embeddings:
   - Filtra por rango de fechas (~3 meses atrás ±2 semanas)
   - Calcula similitud coseno
   - Obtiene top 20 candidatos
7. Sistema invoca Bedrock para re-ranking:
   - Envía pregunta + contexto de cada candidato
   - Bedrock analiza y rankea por relevancia real
   - Selecciona top 5 memorias más relevantes
8. Sistema muestra resultados:

   Resultado #1 (95% relevancia)
   🎙️ Conversación - "Cena con Ana" - 12 Abr 2026
   "...me recomendó un restaurante italiano increíble
   que se llama La Trattoria, está en la calle Reforma..."
   [Ver memoria completa]

   Resultado #2 (87% relevancia)
   📧 Email - "Recomendaciones CDMX" - 15 Abr 2026
   "Hola! Te paso la lista de restaurantes que te comenté..."
   [Ver memoria completa]

9. Usuario toca "Ver memoria completa" del Resultado #1
10. Sistema muestra:
    - Título de la memoria
    - Transcripción completa
    - Audio original (puede reproducir)
    - Etiquetas
    - Entidades extraídas: Ana (persona), La Trattoria (lugar)
    - Opción de crear nueva memoria relacionada
11. Sistema incrementa ai_usage (ai_searches)

Postcondición: Usuario encuentra la información que buscaba
```

---

### Caso de Uso 4: Email con Confirmación de Reserva

```
Actor: Usuario (Plan Pro)
Precondición: Usuario tiene email memories configurado

Flujo:
1. Usuario reserva hotel online
2. Usuario recibe email de confirmación: "Confirmación Reserva - Hotel Paradiso"
3. Usuario reenvía email a: memories+user123@temis.app
4. AWS SES recibe el email
5. SES invoca Lambda Email Parser
6. Lambda procesa:
   a. Extrae user_id del destinatario: user123
   b. Valida que user existe y tiene plan Pro
   c. Verifica cuota de emails del mes (45/100 usado)
   d. Parsea email:
      - From: reservas@hotelparadiso.com
      - Subject: Confirmación Reserva - Hotel Paradiso
      - Body: extrae HTML y convierte a texto limpio
      - Adjunto: confirmacion.pdf
   e. Invoca Bedrock para análisis:
      - Detecta tipo: "Confirmación de reserva"
      - Extrae información clave:
        * Hotel: Paradiso Beach Resort
        * Check-in: 15 Ago 2026
        * Check-out: 20 Ago 2026
        * Código reserva: HPR-123456
        * Habitación: Suite Ocean View
        * Precio: $850 total
      - Genera título: "Reserva Hotel Paradiso - Agosto 2026"
      - Sugiere etiquetas: "Viajes", "Hoteles"
   f. Procesa adjunto (confirmacion.pdf):
      - Sube a S3
      - Extrae texto con Textract
      - Añade a contexto de la memoria
   g. Genera embeddings del contenido completo
   h. Guarda en BD (memory + memory_attachments)
7. Lambda envía notificación push al usuario:
   "📧 Nueva memoria guardada: Reserva Hotel Paradiso"
8. Lambda incrementa ai_usage (emails_processed)
9. Usuario abre notificación, ve memoria
10. Sistema sugiere: "¿Quieres crear un recordatorio 1 día antes del check-in?"
11. Usuario acepta
12. Sistema crea recordatorio automáticamente en módulo de Tareas

Postcondición: Email guardado, procesado y disponible para búsqueda
```

---

## 4. Arquitectura Técnica

### 4.1 Componentes AWS

#### S3 Buckets
```
temis-ai-memory-prod/
├── audios/
│   └── {organization_id}/{user_id}/{memory_id}.aac
├── photos/
│   └── {organization_id}/{user_id}/{memory_id}/{photo_id}.jpg
├── documents/
│   └── {organization_id}/{user_id}/{memory_id}/{document_name}
└── emails/
    └── {organization_id}/{user_id}/{memory_id}/email.html
```

**Configuración**:
- Lifecycle policy: archival a Glacier después de 1 año (Premium), 6 meses (Pro), 3 meses (Basic/Free)
- Encriptación: AES-256 server-side
- Versionado: habilitado (solo Premium)
- CORS: habilitado para subida directa desde app

---

#### Lambda Functions

**1. lambda-ai-memory**
- CRUD de memorias
- Endpoints:
  - POST /memories - crear
  - GET /memories - listar
  - GET /memories/{id} - obtener
  - PUT /memories/{id} - actualizar
  - DELETE /memories/{id} - eliminar
  - POST /memories/{id}/attachments - subir archivo
- Validación de cuotas por plan
- Control de storage usado

**2. lambda-ai-memory-search**
- Búsqueda semántica con embeddings
- Endpoints:
  - POST /memories/search - búsqueda IA
  - GET /memories/search/text - búsqueda texto
- Generación de embeddings de query
- Búsqueda vectorial en PostgreSQL
- Re-ranking con Bedrock

**3. lambda-ai-memory-processor** (Async)
- Procesamiento en background de archivos
- Triggers:
  - S3 event cuando se sube archivo
  - SQS queue para procesamiento pesado
- Funciones:
  - AWS Transcribe para audio
  - AWS Textract para imágenes/documentos
  - Amazon Bedrock para análisis y embeddings
  - Actualizar BD con resultados

**4. lambda-ai-memory-email-parser**
- Parsing de emails entrantes
- Trigger: SES receipt rule
- Funciones:
  - Extraer user_id del destinatario
  - Parsear contenido HTML/texto
  - Procesar adjuntos
  - Invocar Bedrock para análisis
  - Crear memoria en BD
  - Enviar notificación push

**5. lambda-ai-memory-insights** (Scheduled)
- Generación de resúmenes y insights
- Trigger: EventBridge (lunes 9 AM)
- Funciones:
  - Analizar memorias de la semana
  - Generar resumen con Bedrock
  - Detectar patrones
  - Enviar notificaciones

---

#### AWS Transcribe
- Conversión de audio a texto
- Configuración:
  - Idiomas: es-ES, es-MX, en-US
  - Speaker diarization: habilitado
  - Timestamps: habilitados
  - Formato salida: JSON
- Pricing: $0.024/minuto (primeros 250k minutos gratis primer año)

---

#### AWS Textract
- OCR de imágenes y documentos
- Configuración:
  - Detect Document Text API (texto simple)
  - Analyze Document API (tablas, formularios)
- Pricing: $0.0015/página

---

#### Amazon Bedrock (Claude 3.5 Sonnet)
- Análisis de contenido
- Generación de resúmenes
- Extracción de entidades
- Generación de embeddings (1536 dimensiones)
- Re-ranking de resultados
- Pricing: $3/1M tokens input, $15/1M tokens output

---

#### SES (Simple Email Service)
- Recepción de emails para memories
- Dominio: memories@temis.app
- Receipt rules:
  - Guardar email en S3
  - Invocar Lambda parser

---

#### SNS (Notificaciones Push)
- Notificar cuando memoria está procesada
- Notificar cuando se recibe email
- Alertas de almacenamiento

---

#### EventBridge
- Scheduler para insights semanales/mensuales
- Cron: 0 9 * * MON (lunes 9 AM)

---

#### SQS
- Cola de procesamiento para tareas pesadas
- Dead-letter queue para errores
- Retry policy: 3 intentos

---

### 4.2 Esquema de Base de Datos

#### Tabla: memories
```sql
CREATE TABLE memories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  user_id UUID NOT NULL REFERENCES users(id),

  title VARCHAR(500) NOT NULL,
  description TEXT,

  memory_type VARCHAR(50) NOT NULL,
  -- 'conversation', 'photo', 'document', 'email', 'voice_note'

  status VARCHAR(50) DEFAULT 'processing',
  -- 'processing', 'ready', 'failed'

  -- Metadatos
  captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  location_name VARCHAR(255),

  -- Procesamiento IA
  ai_summary TEXT, -- resumen generado por IA
  ai_extracted_entities JSONB, -- {persons: [], places: [], dates: []}
  ai_suggested_tags VARCHAR(255)[],

  -- Archivado y favoritos
  is_favorite BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,

  -- Etiquetas
  tags VARCHAR(100)[],

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP,

  CONSTRAINT fk_memory_organization FOREIGN KEY (organization_id)
    REFERENCES organizations(id),
  CONSTRAINT fk_memory_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
);

-- Índices
CREATE INDEX idx_memories_user ON memories(user_id, created_at DESC);
CREATE INDEX idx_memories_type ON memories(user_id, memory_type);
CREATE INDEX idx_memories_tags ON memories USING GIN(tags);
CREATE INDEX idx_memories_captured_at ON memories(captured_at);
CREATE INDEX idx_memories_favorite ON memories(user_id, is_favorite)
  WHERE is_favorite = TRUE;

-- Full-text search
CREATE INDEX idx_memories_fts ON memories USING GIN(
  to_tsvector('spanish', coalesce(title, '') || ' ' || coalesce(description, ''))
);
```

---

#### Tabla: memory_attachments
```sql
CREATE TABLE memory_attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  memory_id UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,

  attachment_type VARCHAR(50) NOT NULL,
  -- 'audio', 'photo', 'document', 'email_attachment'

  -- Storage
  s3_bucket VARCHAR(255) NOT NULL,
  s3_key VARCHAR(500) NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  mime_type VARCHAR(100),

  -- Metadatos de archivo
  original_filename VARCHAR(500),
  duration_seconds INT, -- para audios
  width INT, -- para imágenes
  height INT,

  -- Contenido procesado
  transcription_text TEXT, -- para audio
  ocr_text TEXT, -- para imágenes/documentos
  extracted_data JSONB, -- datos estructurados extraídos

  processing_status VARCHAR(50) DEFAULT 'pending',
  -- 'pending', 'processing', 'completed', 'failed'

  processing_error TEXT,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_attachment_memory FOREIGN KEY (memory_id)
    REFERENCES memories(id) ON DELETE CASCADE
);

-- Índices
CREATE INDEX idx_attachments_memory ON memory_attachments(memory_id);
CREATE INDEX idx_attachments_type ON memory_attachments(attachment_type);
CREATE INDEX idx_attachments_status ON memory_attachments(processing_status);

-- Full-text search en transcripciones y OCR
CREATE INDEX idx_attachments_fts ON memory_attachments USING GIN(
  to_tsvector('spanish',
    coalesce(transcription_text, '') || ' ' || coalesce(ocr_text, '')
  )
);
```

---

#### Tabla: memory_embeddings
```sql
-- Requiere extensión pgvector
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE memory_embeddings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  memory_id UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,

  -- Vector embedding (1536 dimensiones para Claude 3.5 Sonnet)
  embedding vector(1536) NOT NULL,

  -- Texto del chunk que generó este embedding
  chunk_text TEXT NOT NULL,
  chunk_index INT DEFAULT 0, -- para textos largos divididos en chunks

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_embedding_memory FOREIGN KEY (memory_id)
    REFERENCES memories(id) ON DELETE CASCADE
);

-- Índice HNSW para búsqueda vectorial rápida
CREATE INDEX idx_embeddings_vector ON memory_embeddings
  USING hnsw (embedding vector_cosine_ops);

CREATE INDEX idx_embeddings_memory ON memory_embeddings(memory_id);
```

---

#### Actualización tabla users
```sql
-- Añadir columna de storage usado
ALTER TABLE users
  ADD COLUMN ai_memory_storage_bytes BIGINT DEFAULT 0,
  ADD COLUMN ai_memory_email VARCHAR(255) UNIQUE;

-- Index
CREATE INDEX idx_users_storage ON users(ai_memory_storage_bytes);

-- Function para calcular storage usado
CREATE OR REPLACE FUNCTION calculate_user_storage(p_user_id UUID)
RETURNS BIGINT AS $$
  SELECT COALESCE(SUM(file_size_bytes), 0)
  FROM memory_attachments ma
  JOIN memories m ON ma.memory_id = m.id
  WHERE m.user_id = p_user_id
    AND m.deleted_at IS NULL;
$$ LANGUAGE SQL;

-- Trigger para actualizar storage al subir/borrar archivo
CREATE OR REPLACE FUNCTION update_user_storage()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE users
    SET ai_memory_storage_bytes = calculate_user_storage(
      (SELECT user_id FROM memories WHERE id = NEW.memory_id)
    )
    WHERE id = (SELECT user_id FROM memories WHERE id = NEW.memory_id);
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE users
    SET ai_memory_storage_bytes = calculate_user_storage(
      (SELECT user_id FROM memories WHERE id = OLD.memory_id)
    )
    WHERE id = (SELECT user_id FROM memories WHERE id = OLD.memory_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_user_storage
AFTER INSERT OR DELETE ON memory_attachments
FOR EACH ROW EXECUTE FUNCTION update_user_storage();
```

---

#### Actualización tabla subscriptions - Cuotas AI Memory
```sql
-- Añadir cuotas de AI Memory a la tabla de uso de IA
ALTER TABLE ai_usage
  ADD COLUMN memory_conversations_created INT DEFAULT 0,
  ADD COLUMN memory_photos_ocr INT DEFAULT 0,
  ADD COLUMN memory_documents_processed INT DEFAULT 0,
  ADD COLUMN memory_emails_received INT DEFAULT 0,
  ADD COLUMN memory_voice_notes INT DEFAULT 0,
  ADD COLUMN memory_ai_searches INT DEFAULT 0,
  ADD COLUMN memory_insights_generated INT DEFAULT 0;

-- Límites por plan (se guardan en tabla plans)
-- Ver sección 4.3 para definición de límites
```

---

### 4.3 Límites por Plan

#### Storage Limits
```json
{
  "free": {
    "storage_gb": 2,
    "max_audio_duration_minutes": 10,
    "max_audio_file_mb": 50,
    "max_photo_size_mb": 10,
    "max_document_size_mb": 5,
    "max_email_size_mb": 10
  },
  "basic": {
    "storage_gb": 5,
    "max_audio_duration_minutes": 10,
    "max_audio_file_mb": 50,
    "max_photo_size_mb": 10,
    "max_document_size_mb": 10,
    "max_email_size_mb": 10
  },
  "pro": {
    "storage_gb": 20,
    "max_audio_duration_minutes": 30,
    "max_audio_file_mb": 100,
    "max_photo_size_mb": 10,
    "max_document_size_mb": 50,
    "max_email_size_mb": 25
  },
  "premium": {
    "storage_gb": 100,
    "max_audio_duration_minutes": null,
    "max_audio_file_mb": 200,
    "max_photo_size_mb": 10,
    "max_document_size_mb": 200,
    "max_email_size_mb": 50
  }
}
```

#### Monthly Quotas
```json
{
  "free": {
    "conversations_per_month": 5,
    "photos_ocr_per_month": 10,
    "documents_per_month": 0,
    "emails_per_month": 0,
    "voice_notes_per_month": 10,
    "ai_searches_per_month": 10,
    "insights_per_month": 0
  },
  "basic": {
    "conversations_per_month": 20,
    "photos_ocr_per_month": 50,
    "documents_per_month": 20,
    "emails_per_month": 20,
    "voice_notes_per_month": 50,
    "ai_searches_per_month": 50,
    "insights_per_month": 1
  },
  "pro": {
    "conversations_per_month": 100,
    "photos_ocr_per_month": 200,
    "documents_per_month": 100,
    "emails_per_month": 100,
    "voice_notes_per_month": 200,
    "ai_searches_per_month": 200,
    "insights_per_month": 4
  },
  "premium": {
    "conversations_per_month": null,
    "photos_ocr_per_month": null,
    "documents_per_month": null,
    "emails_per_month": null,
    "voice_notes_per_month": null,
    "ai_searches_per_month": null,
    "insights_per_month": null
  }
}
```

---

## 5. Estimación de Costos AWS

### 5.1 Costo por Usuario Activo (Mensual)

**Asumiendo**: 1000 usuarios, 50% en Free, 30% Basic, 15% Pro, 5% Premium

#### S3 Storage
- Free (500 users × 1 GB avg): 500 GB
- Basic (300 users × 2.5 GB avg): 750 GB
- Pro (150 users × 10 GB avg): 1,500 GB
- Premium (50 users × 50 GB avg): 2,500 GB
- **Total**: 5,250 GB = **$120/mes**

#### AWS Transcribe
- Conversaciones: 1000 users × 3 conversaciones/mes × 5 min avg = 15,000 min
- Notas de voz: 1000 users × 10 notas/mes × 1 min avg = 10,000 min
- **Total**: 25,000 min × $0.024 = **$600/mes**
- (Nota: Primeros 250k min gratis primer año)

#### AWS Textract
- Fotos OCR: 1000 users × 5 fotos/mes = 5,000 páginas
- Documentos: 1000 users × 2 docs/mes × 3 páginas avg = 6,000 páginas
- **Total**: 11,000 páginas × $0.0015 = **$16.50/mes**

#### Amazon Bedrock
- Análisis de contenido: 1000 users × 10 memorias/mes × 1000 tokens = 10M tokens
- Embeddings: 1000 users × 10 memorias/mes × 2000 tokens = 20M tokens
- Búsquedas IA: 1000 users × 5 búsquedas/mes × 500 tokens = 2.5M tokens
- **Total input**: 32.5M tokens × $3/1M = $97.50
- **Total output**: 10M tokens × $15/1M = $150
- **Total Bedrock**: **$247.50/mes**

#### Lambda
- Invocaciones: 1000 users × 30 memorias/mes × 3 lambdas = 90,000 invocaciones
- Compute: 90,000 × 2 GB × 5 sec avg = 250 GB-seconds
- **Total**: Gratis (dentro de free tier)

#### SES (Email Reception)
- 1000 users × 10 emails/mes = 10,000 emails
- **Total**: 10,000 × $0.10/1000 = **$1/mes**

#### Data Transfer
- Subidas: 1000 users × 50 MB/mes = 50 GB (gratis)
- Descargas: 1000 users × 20 MB/mes = 20 GB
- **Total**: 20 GB × $0.09/GB = **$1.80/mes**

### 5.2 Costo Total Mensual
- S3: $120
- Transcribe: $600 (después del free tier inicial)
- Textract: $16.50
- Bedrock: $247.50
- Lambda: $0 (free tier)
- SES: $1
- Data Transfer: $1.80
- **TOTAL**: **$986.80/mes** para 1000 usuarios

**Por usuario**: $0.99/mes

---

## 6. Integración con Otros Módulos TEMIS

### 6.1 Integración con Tareas
- Si una conversación/nota menciona una tarea, sugerir crearla automáticamente
- Ejemplo: "Tengo que llamar al dentista mañana" → crear tarea
- Vincular memoria con tarea creada

### 6.2 Integración con Finanzas
- Si un documento/email contiene factura/recibo, sugerir registrar transacción
- OCR de recibos → extraer monto, comercio, fecha → prellenar transacción
- Vincular memoria con transacción

### 6.3 Integración con Contraseñas
- Si un email contiene credenciales, sugerir guardarlas en bóveda
- Detección automática de: usuario, contraseña, URL
- Notificar al usuario para confirmación de seguridad

### 6.4 Integración con Asistente IA
- El asistente IA puede acceder a memorias para responder preguntas
- Contexto enriquecido con información de AI Memory
- Ejemplo: "¿Qué me recomendó el doctor?" → busca en memorias de salud

---

## 7. Roadmap de Implementación

### Fase 1 - MVP (Meses 1-2)
- ✅ Esquema de BD (memories, memory_attachments)
- ✅ Lambda CRUD básico (crear, listar, eliminar memorias)
- ✅ Subida de fotos y documentos a S3
- ✅ Búsqueda por texto simple
- ✅ UI básica: crear memoria manual, ver lista
- ✅ Cuotas de storage por plan

### Fase 2 - Procesamiento IA (Meses 3-4)
- ✅ Integración AWS Transcribe para audio
- ✅ Integración AWS Textract para OCR
- ✅ Lambda processor asíncrono
- ✅ Grabación de conversaciones
- ✅ Notas de voz
- ✅ OCR de fotos

### Fase 3 - Búsqueda Semántica (Meses 5-6)
- ✅ Integración Amazon Bedrock para embeddings
- ✅ Tabla memory_embeddings con pgvector
- ✅ Lambda search con búsqueda vectorial
- ✅ UI de búsqueda inteligente
- ✅ Re-ranking de resultados

### Fase 4 - Email y Análisis (Meses 7-8)
- ✅ Configuración SES para recepción de emails
- ✅ Lambda email parser
- ✅ Procesamiento de adjuntos
- ✅ Análisis avanzado con Bedrock (extracción de entidades)
- ✅ Insights semanales/mensuales

### Fase 5 - Optimización y Features Avanzadas (Meses 9-10)
- ✅ Sugerencias inteligentes
- ✅ Conexión entre memorias
- ✅ Integración con otros módulos (tareas, finanzas)
- ✅ Widget de acceso rápido
- ✅ Compartir memorias
- ✅ Exportar memorias

### Futuro
- Modo offline (sync cuando hay conexión)
- Reconocimiento facial en fotos
- Transcripción en tiempo real
- Grabación de llamadas telefónicas (con permiso)
- Integración con asistentes de voz (Siri, Google Assistant)
- Apple Watch / Wear OS app para captura rápida

---

## 8. Seguridad y Privacidad

### 8.1 Protección de Datos
- Todos los archivos en S3 encriptados con AES-256
- Transmisión HTTPS/TLS 1.3
- Acceso a archivos mediante pre-signed URLs (expiran en 5 minutos)
- Row-Level Security en PostgreSQL (filtrado por organization_id + user_id)

### 8.2 Privacidad
- Procesamiento de datos con IA:
  - Datos anonimizados antes de enviar a Bedrock
  - No se entrena modelo con datos del usuario
  - Claude no retiene datos después del request
- OCR y transcripciones:
  - Se procesan en AWS (no salen de infraestructura)
  - Resultados almacenados solo en BD del usuario
- Emails:
  - Solo se procesan emails enviados explícitamente por el usuario
  - No se lee buzón de entrada del usuario

### 8.3 Eliminación de Datos
- Soft delete: 30 días de recuperación
- Hard delete permanente después de 30 días
- Archivos en S3 eliminados permanentemente
- Embeddings y transcripciones también se eliminan

### 8.4 Compartir Memorias
- Usuario puede generar link de compartir (opcional)
- Link expirable (1 hora, 24 horas, 7 días, permanente)
- Protección con contraseña (opcional)
- Solo se comparte la memoria específica, no el perfil completo

---

## 9. Métricas de Éxito

### 9.1 Métricas de Adopción
- % de usuarios que crean al menos 1 memoria/semana
- Memorias promedio por usuario activo
- Tasa de conversión Free → Basic/Pro
- Retención a 30 días, 90 días

### 9.2 Métricas de Engagement
- Búsquedas IA por usuario/mes
- Tasa de éxito de búsquedas (usuario encuentra lo que busca)
- % de memorias etiquetadas vs sin etiquetar
- Tiempo promedio desde captura hasta búsqueda

### 9.3 Métricas Técnicas
- Tiempo promedio de procesamiento (transcripción, OCR, embeddings)
- Tasa de error en procesamiento
- Precisión de OCR (% de texto correctamente extraído)
- Precisión de búsqueda semántica

### 9.4 Métricas de Negocio
- Ingresos por módulo AI Memory
- Costo por usuario (AWS)
- Margen de contribución
- Usuarios que compran storage adicional

---

## Changelog

### v1.0.0 (2026-08-14)
- ✅ Versión inicial del módulo AI Memory
- ✅ Especificación completa de funcionalidades
- ✅ Arquitectura técnica definida
- ✅ Esquema de base de datos
- ✅ Integración con servicios AWS
- ✅ Cuotas por plan de suscripción
- ✅ Casos de uso detallados
- ✅ Roadmap de implementación

---

**Documento creado**: 2026-08-14
**Última actualización**: 2026-08-14
**Versión**: 1.0.0
**Autor**: Claude Sonnet 4.5 + Fernando Aguilar
