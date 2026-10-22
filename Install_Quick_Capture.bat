@echo off
rem Installs Quick Capture for the current user (Start Menu + Desktop shortcuts). No admin needed.
if not exist "%~dp0Install_Quick_Capture.ps1" (
  echo Install_Quick_Capture.ps1 not found next to this file.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Install_Quick_Capture.ps1"
