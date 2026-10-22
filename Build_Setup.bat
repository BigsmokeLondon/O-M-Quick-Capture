@echo off
rem Makes QuickCapture_Setup.exe in this folder (uses Windows' built-in IExpress).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build_Setup.ps1"
pause
