# Flutter Setup

## Instalación

- **Ubicación:** `C:\flutter`
- **Versión:** 3.44.8 (stable)
- **Canal:** stable

## Variables de Entorno

| Variable | Valor |
|---|---|
| `PATH` | `C:\flutter\bin` agregado |
| `ANDROID_HOME` | `C:\Users\Victor\AppData\Local\Android\Sdk` |
| `ANDROID_SDK_ROOT` | `C:\Users\Victor\AppData\Local\Android\Sdk` |
| `JAVA_HOME` | `C:\Program Files\Android\Android Studio\jbr` |

## Android SDK

- **SDK Version:** 36.0.0
- **cmdline-tools:** Instalado en `$ANDROID_HOME\cmdline-tools\latest`
- **Licencias Android:** Aceptadas

## Estado (`flutter doctor`)

- ✅ Flutter
- ✅ Windows Version
- ✅ Android toolchain
- ✅ Chrome
- ✅ Connected device (Windows, Chrome, Edge)
- ✅ Network resources
- ❌ Visual Studio (no necesario para Android)

## Visual Studio Code

Extensiones recomendadas:
- **Flutter** (Dart Code)
- **Dart** (Dart Code)

## Uso Básico

```bash
flutter create mi_app
cd mi_app
flutter run
```

Para ver dispositivos disponibles:

```bash
flutter devices
```
