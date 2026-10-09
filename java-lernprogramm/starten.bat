@echo off
rem Java-Trainer starten (Windows): Doppelklick auf diese Datei.
cd /d "%~dp0"
where java >nul 2>nul
if errorlevel 1 (
    echo Java wurde nicht gefunden. Bitte ein JDK ab Version 17 installieren.
    pause
    exit /b 1
)
java Trainer.java
if errorlevel 1 pause
