@echo off
chcp 65001 >nul
title GENERADOR DE LICENCIAS - VPS LICENSE GATE
cd /d "%~dp0"

echo ===============================================
echo    GENERADOR DE ENTREGA - VPS LICENSE GATE
echo    (doble clic = listo)
echo ===============================================
echo.

rem Pedir nombre del cliente
set /p CLIENTE=Nombre del cliente: 

rem Si no puso nombre, usar anonimo
if "%CLIENTE%"=="" set CLIENTE=anonimo

echo.
echo Generando key y subiendo a Firebase...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0generar-entrega.ps1" -Cliente "%CLIENTE%" -Dias 30

echo.
echo ===============================================
echo    LISTO! El archivo .txt esta en la carpeta:
echo    %~dp0entregas
echo ===============================================
echo.
pause
