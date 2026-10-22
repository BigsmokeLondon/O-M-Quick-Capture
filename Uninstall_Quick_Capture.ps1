# Quick Capture uninstaller - O.M. Industries Inc
# Removes the app, its shortcuts and the Settings > Apps entry. Your recordings are not touched.
Add-Type -AssemblyName System.Windows.Forms
$title = 'Quick Capture Uninstall'
$r = [System.Windows.Forms.MessageBox]::Show("Remove Quick Capture?`n`nYour saved recordings are not deleted.", $title, 'YesNo', 'Question')
if ($r -ne 'Yes') { exit 0 }
try {
  $dest = Join-Path $env:LOCALAPPDATA 'Programs\Quick Capture'
  $startDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Quick Capture'
  $desktop = [Environment]::GetFolderPath('Desktop')
  Remove-Item -LiteralPath (Join-Path $desktop 'Quick Capture.lnk') -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $startDir -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\QuickCapture' -Recurse -Force -ErrorAction SilentlyContinue
  # This script lives in the folder being removed, so delete it from a separate process after we exit
  Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList ('/c ping 127.0.0.1 -n 3 >nul & rmdir /s /q "' + $dest + '"')
  [void][System.Windows.Forms.MessageBox]::Show('Quick Capture has been removed.', $title, 'OK', 'Information')
} catch {
  [void][System.Windows.Forms.MessageBox]::Show(('Uninstall failed:' + "`n`n" + ($_ | Out-String)), $title, 'OK', 'Error')
}
