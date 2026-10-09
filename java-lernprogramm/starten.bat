@echo off
rem Java-Trainer im Browser starten (Windows): Doppelklick auf diese Datei.
cd /d "%~dp0"
where java >nul 2>nul
if errorlevel 1 (
    echo Java wurde nicht gefunden. Bitte ein JDK ab Version 17 installieren.
    pause
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File werkzeuge\sdk-laden.ps1
if errorlevel 1 (
    echo Das Anthropic-SDK konnte nicht geladen werden. Bist du online?
    pause
    exit /b 1
)
java -cp "lib\*" Trainer.java
if errorlevel 1 pause
