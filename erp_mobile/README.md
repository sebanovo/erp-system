# ERP Inteligente con IA - Sistema de Gestión Empresarial

Sistema ERP (Enterprise Resource Planning) con integración de inteligencia artificial para gestión de clientes, productos, ventas, compras e inventario. Desarrollado con Flutter para multiplataforma (Android, iOS, Web, Windows/macOS) con procesamiento **100% local y offline**.

## ✨ Características principales

- 👥 **Gestión de Clientes** - CRUD completo con búsqueda y filtros
- 📦 **Gestión de Productos** - Control de SKU, precios, costos y categorías
- 💰 **Módulo de Ventas** - Registro de ventas con actualización automática de inventario
- 🛒 **Módulo de Compras** - Control de compras a proveedores
- 📊 **Control de Inventario** - Stock en tiempo real, movimientos y ajustes
- 🤖 **Asistente IA Local** - Procesamiento de lenguaje natural para operaciones del ERP
- 🎤 **Reconocimiento de Voz Local** - Transcripción offline con Whisper
- 📱 **Multiplataforma** - Android, iOS, Windows, macOS, Linux y Web
- 🔒 **Privacidad Total** - Todo el procesamiento se realiza en el dispositivo

## 📋 Requisitos previos

| Requisito | Versión |
|-----------|---------|
| **Flutter** | 3.16.0 o superior |
| **Dart** | 3.2.0 o superior |
| **Android Studio / VS Code** | Opcional |
| **Git** | Para clonar el repositorio |
| **Espacio en disco** | Mínimo 500 MB + modelo IA (~1.5 GB) |

## 🤖 Modelos de IA Soportados

### Modelos LLM (Procesamiento de lenguaje)

El plugin `flutter_gemma` soporta múltiples modelos. Puedes descargarlos desde:

[Gemma 4 E2B/E4B](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm) (❌ Requiere buen telefono)
[Gemma3n E2B/E4B](https://huggingface.co/google/gemma-3n-E2B-it-litert-preview) (❌ Requiere buen telefono)
[FastVLM 0.5B](https://huggingface.co/litert-community/FastVLM-0.5B)  (❌ Requiere buen telefono)
[Gemma-3 1B](https://huggingface.co/litert-community/Gemma3-1B-IT) (❌ Requiere buen telefono)
[Gemma 3 270M](https://huggingface.co/litert-community/gemma-3-270m-it) (❌ Requiere buen telefono)
[FunctionGemma 270M](https://huggingface.co/sasha-denisov/function-gemma-270M-it) (🟦 Muy tonto)
[Qwen3 0.6B](https://huggingface.co/litert-community/Qwen3-0.6B) (🟧 Más o menos)
[Qwen 2.5](https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct) (✅ Recomendado)
[Phi-4 Mini](https://huggingface.co/litert-community/Phi-4-mini-instruct) (❌ Requiere buen telefono)
[DeepSeek R1](https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B) (❌ Requiere buen telefono)
[SmolLM 135M](https://huggingface.co/litert-community/SmolLM-135M-Instruct). (❌ Requiere buen telefono)

### Tabla de modelos

| Model Family | Best For | Function Calling | Thinking Mode | Vision | Languages | Size |
|---|---|:---:|:---:|:---:|---|---|
| **Gemma 4 E2B** | Next-gen multimodal chat — text, image, audio | ✅ | ✅ | ✅ | Multilingual | 2.4GB |
| **Gemma 4 E4B** | Next-gen multimodal chat — text, image, audio | ✅ | ✅ | ✅ | Multilingual | 4.3GB |
| **Gemma3n** | On-device multimodal chat and image analysis | ✅ | ❌ | ✅ | Multilingual | 3-6GB |
| **FastVLM 0.5B** | Fast vision-language inference | ❌ | ❌ | ✅ | Multilingual | 0.5GB |
| **Phi-4 Mini** | Advanced reasoning and instruction following | ✅ | ❌ | ❌ | Multilingual | 3.9GB |
| **DeepSeek R1** | High-performance reasoning and code generation | ✅ | ✅ | ❌ | Multilingual | 1.7GB |
| **Qwen3 0.6B** | Compact multilingual chat with function calling | ✅ | ✅ | ❌ | Multilingual | 586MB |
| **Qwen 2.5** | Strong multilingual chat and instruction following | ✅ | ❌ | ❌ | Multilingual | 0.5-1.6GB |
| **Gemma 3 1B** | Balanced and efficient text generation | ✅ | ❌ | ❌ | Multilingual | 0.5GB |
| **Gemma 3 270M** | Ideal for fine-tuning (LoRA) for specific tasks | ❌ | ❌ | ❌ | Multilingual | 0.3GB |
| **FunctionGemma 270M** | Specialized for function calling on-device | ✅ | ❌ | ❌ | Multilingual | 284MB |
| **SmolLM 135M** | Ultra-compact, resource-constrained devices | ❌ | ❌ | ❌ | English | 135MB |
| **TranslateGemma 4B** † | Single-shot 55-language translation | ❌ | ❌ | ❌ | 55 languages | 2-4GB |


### 🎤 Modelo de Reconocimiento de Voz (Whisper)

Puedes obtener el modelo en: [Official Whisper GGML Models](https://huggingface.co/ggerganov/whisper.cpp/tree/main)

Puedes escoger entre cualquier modelo y colocarlo en assets/. Modelos disponibles.
- `ggml-tiny.bin` — facil y rapido (✅ Recomendado)
- `ggml-base.bin` o `ggml-base-q5_0.bin` — Buen balance (🟧 Sigue siendo bueno) 
- `ggml-small-5_1.bin` — mayor precisión con mayor consumo de memoria  (❌ Lento) 
- `ggml-large-v3-turbo-q5_0.bin` — mejor calidad, mayor tiempo de ejecución y consumo de memoria (❌ Tener buen telefono)

**Instrucciones:**
1. Descarga el archivo del modelo (normalmente `.task`, `model.tflite` o `model.bin`)
2. Crea la siguiente carpeta en tu proyecto:
   ```bash
   mkdir -p assets/models/
   ```
3. Copia el archivo descargado a `assets/models/gemma3.task` (o la extensión correspondiente)
4. **Verifica que el archivo existe:**
   ```bash
   ls -lh assets/models/
   ```
5. **Generar los jsons:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

> ⚠️ **Nota:** El modelo pesa aproximadamente 1.2-1.8 GB. Asegúrate de tener suficiente espacio y una conexión estable.

### 5. Ejecutar la aplicación

```bash
# Para correr en modo debug
flutter run

# Para correr en un dispositivo específico
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d android       # Android (requiere emulador o dispositivo físico)
```

## 🧠 Integración del modelo de IA

El sistema carga el modelo desde `assets/models/` usando:

```dart
// Ejemplo de carga (ajustar según tu implementación)
final modelPath = 'assets/models/gemma3.task';
final aiService = AIService(modelPath: modelPath);
```

**Funciones del modelo:**
- Predicción de demanda de productos
- Análisis de tendencias de ventas
- Recomendaciones de reabastecimiento
- Clasificación inteligente de clientes

## 🔧 Solución de problemas comunes

## 📱 Compilar para producción

```bash
# Android APK
flutter build apk --release

# iOS (requiere Mac)
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## ⚡ Notas adicionales

- El sistema funciona **offline-first** gracias al modelo local
- Para usar la versión web, el modelo se carga desde IndexedDB
- Recomendado: mínimo 4GB RAM para el modelo de IA
- El primer arranque puede ser lento mientras se carga el modelo en memoria
