@echo off
rem Opens the Quick Capture window (no black console). Keep Quick_Capture_GUI.ps1 in the same folder.
if not exist "%~dp0Quick_Capture_GUI.ps1" (
  echo Quick_Capture_GUI.ps1 not found next to this file.
  pause
  exit /b 1
)
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "try { & '%~dp0Quick_Capture_GUI.ps1' } catch { Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show(($_ | Out-String), 'Quick Capture error') }"
