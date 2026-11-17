@echo off
chcp 65001 >nul
cd /d "%~dp0"
where git >nul 2>nul
if errorlevel 1 (
  echo No se encontro Git. Instalalo desde https://git-scm.com/download/win y vuelve a ejecutar este archivo.
  pause
  exit /b 1
)
for /f "delims=" %%i in ('git config --global user.email') do set GIT_EMAIL=%%i
if "%GIT_EMAIL%"=="" (
  set /p GIT_NAME=Tu nombre para los commits: 
  set /p GIT_EMAIL=Tu correo de GitHub: 
)
if not "%GIT_NAME%"=="" git config --global user.name "%GIT_NAME%"
git config --global user.email "%GIT_EMAIL%"
set /p REPO_URL=Pega la URL del repositorio (ej. https://github.com/usuario/sr-robot-app.git): 
if "%REPO_URL%"=="" (echo Falta la URL & pause & exit /b 1)
if not exist .git (
  git init
  git branch -M main
)
git add .
git commit -m "Sr Robot: app movil Flutter (fases 1 a 4, modo demo y CI)"
git remote remove origin >nul 2>nul
git remote add origin %REPO_URL%
git push -u origin main
echo.
echo Listo. Revisa la pestana Actions de tu repositorio para ver las pruebas y descargar el APK.
pause
