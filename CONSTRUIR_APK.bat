@echo off
chcp 65001 >nul
set "PATH=C:\Users\TS3 PLUS\develop\flutter\bin;%PATH%"
cd /d "%~dp0"
echo === 1/5 Limpiando ===
call flutter clean
echo === 2/5 Dependencias ===
call flutter pub get
echo === 3/5 Analisis estatico ===
call flutter analyze
echo === 4/5 Pruebas ===
call flutter test
echo === 5/5 APK release ===
call flutter build apk --release
echo.
echo APK listo en: build\app\outputs\flutter-apk\app-release.apk
pause
