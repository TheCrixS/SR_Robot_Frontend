@echo off
chcp 65001 >nul
set "PATH=C:\Users\TS3 PLUS\develop\flutter\bin;%PATH%"
cd /d "%~dp0"
set LOG=construir_log.txt
echo Construyendo... el detalle queda en %LOG%
echo === 1/5 Limpiando === > %LOG%
call flutter clean >> %LOG% 2>&1
echo === 2/5 Dependencias === >> %LOG%
call flutter pub get >> %LOG% 2>&1
echo === 3/5 Analisis estatico === >> %LOG%
call flutter analyze >> %LOG% 2>&1
echo === 4/5 Pruebas === >> %LOG%
call flutter test >> %LOG% 2>&1
echo === 5/5 APK release === >> %LOG%
call flutter build apk --release >> %LOG% 2>&1
type %LOG%
echo.
echo APK en: build\app\outputs\flutter-apk\app-release.apk
pause
