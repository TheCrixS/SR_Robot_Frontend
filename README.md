# Sr Robot — App móvil (Flutter)

Frontend del marketplace Sr Robot. Backend: `https://sr-robot-backend.onrender.com/api/v1`.

## Primer arranque (Windows)
1. Doble clic en `PREPARAR.bat` (crea android/ios, descarga paquetes, genera textos, analiza y prueba).
   El resultado queda en `verificacion.txt`.
2. Abre un emulador Android (Android Studio → Device Manager) o conecta tu celular con depuración USB.
3. Doble clic en `EJECUTAR.bat` (o `flutter run`).

Para apuntar a otro backend: `flutter run --dart-define=API_HOST=http://10.0.2.2:3000`
(10.0.2.2 = localhost de tu PC visto desde el emulador).

## APK de instalación
Doble clic en `CONSTRUIR_APK.bat` (limpia, analiza, prueba y compila).
El instalable queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Modo demo (sin servidor)
En el login activa **Modo demo (sin servidor)**: la app usa un backend simulado en memoria
con técnicos, órdenes, chat, repuestos, etc. También: `flutter run --dart-define=MOCK=true`.
Usuarios: `cliente@srrobot.com` / `tecnico@srrobot.com`, cualquier contraseña de 8+ caracteres; OTP `123456`.

## Pruebas
`flutter test` ejecuta pruebas unitarias, de widgets y una prueba de humo de la app completa en modo demo.

## Usuarios de prueba (si el backend tiene SEED_DATA=true)
Contraseña: `Password123!` — `cliente@srrobot.com`, `tecnico@srrobot.com`.
En el login elige **Correo** → **Entrar con contraseña**.
El primer request puede tardar ~30 s (Render despierta el servidor).

## Arquitectura
Feature-First + Riverpod + Dio + go_router.
- `lib/core`: config (EnvConfig, RegionProfile), red (ApiClient, AuthInterceptor con refresh, WebSocket), tema, utilidades.
- `lib/shared`: modelos, repositorios compartidos y widgets del sistema de diseño (BrandHeader, SrButton, SrCard, RobotAvatar, OrderTimeline…).
- `lib/features/*`: pantallas por módulo.
- Textos en `lib/l10n/app_es.arb` y `app_en.arb` (no hay textos quemados en pantalla).

## Estado
Fase 1 (lista): login/OTP/registro, modo dual, inicio cliente, búsqueda con lista y mapa, perfil del técnico.
Fase 2 (lista): cotizaciones, agendar cita, órdenes y detalle, chat en tiempo real, notificaciones.
Fase 3 (lista): panel del técnico, verificación, solicitudes y cotización, agenda y ejecución de órdenes (evidencias y sobrecostos), repuestos con carrito, perfil, horario, servicios, suscripción, billetera y reseñas.
Fase 4 (lista): perfil del cliente (mis equipos, direcciones, métodos de pago, favoritos), soporte y disputas, idioma (es/en) y país/moneda, permisos iOS, pruebas unitarias y script de APK.
