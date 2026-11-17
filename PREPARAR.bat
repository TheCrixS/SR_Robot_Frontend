@echo off
chcp 65001 >nul
set "PATH=C:\Users\TS3 PLUS\develop\flutter\bin;%PATH%"
cd /d "%~dp0"
echo === 1/5 Generando carpetas nativas (android, ios) ===
call flutter create --org com.srrobot --project-name sr_robot_app --platforms android,ios .
echo === 2/5 Descargando dependencias ===
call flutter pub get
echo === 3/5 Generando textos (l10n) ===
call flutter gen-l10n
echo === 4/5 Analizando codigo ===
call flutter analyze > verificacion.txt 2>&1
echo === 5/5 Ejecutando pruebas ===
call flutter test >> verificacion.txt 2>&1
type verificacion.txt
echo.
echo Listo. El resultado quedo en verificacion.txt
pause
