@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pdfunlock-gui.ps1"
