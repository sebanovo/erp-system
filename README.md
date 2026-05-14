# ERP Inteligente con IA - Sistema de Gestión Empresarial

Sistema ERP (Enterprise Resource Planning) con integración de inteligencia artificial para gestión de clientes, productos, inventario y análisis predictivo. Desarrollado con Flutter para multiplataforma (Android, iOS, Web, Windows/macOS).

## ✨ Características principales

- 📊 Gestión de clientes y proveedores
- 📦 Control de inventario y productos
- 📈 Ventas y facturación
- 🤖 Asistente IA para predicción de demanda y análisis
- 📱 Cross-platform (móvil, escritorio, web)
- 🔄 Sincronización en tiempo real

## 📋 Requisitos previos

- **Flutter** 3.16.0 o superior
- **Dart** 3.2.0 o superior
- **Android Studio** / **VS Code** (opcional)
- **Git** (para clonar el repositorio)
- Espacio en disco: mínimo 500 MB (más 1.5 GB del modelo IA)

### **DESCARGAR EL MODELO DE IA (OBLIGATORIO)**

El sistema requiere un modelo de lenguaje local para funcionar offline. Descárgalo desde Google Drive:

[🔗 **MODELO**](https://drive.google.com/drive/folders/1QqtKFIbqFQJJkcCAJiaO7qydY8W0whYX?usp=sharing)

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
   dart run build_runner build --delete-conflicting-outputs
   flutt pub run build_runner build --delete-conflicting-outputs
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
