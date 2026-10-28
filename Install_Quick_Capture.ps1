# Quick Capture installer - O.M. Industries Inc
# Installs for the current user (no admin needed): copies the app, makes Start Menu + Desktop shortcuts,
# and registers an uninstall entry in Settings > Apps.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$title = 'Quick Capture Setup'
$version = '1.2.1'
try {
  $src  = Split-Path -Parent $MyInvocation.MyCommand.Path
  $dest = Join-Path $env:LOCALAPPDATA 'Programs\Quick Capture'
  $files = 'Quick_Capture_GUI.ps1','Quick_Capture_GUI.bat','Quick_Capture.bat','Window_Rect.ps1','List_Windows.bat','QUICK_CAPTURE.md','Uninstall_Quick_Capture.ps1'
  foreach ($f in $files) { if (-not (Test-Path (Join-Path $src $f))) { throw ('Missing file next to the installer: ' + $f) } }

  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  foreach ($f in $files) { Copy-Item -LiteralPath (Join-Path $src $f) -Destination $dest -Force }

  # App icon (red record dot), drawn here so no extra file is needed
  $ico = Join-Path $dest 'QuickCapture.ico'
  $bmp = New-Object System.Drawing.Bitmap 48, 48
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(40,40,48))), 1, 1, 45, 45)
  $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(230,40,40))), 11, 11, 26, 26)
  $g.Dispose()
  $icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
  $fs = [System.IO.File]::Create($ico); $icon.Save($fs); $fs.Close()
  $icon.Dispose(); $bmp.Dispose()

  # Shortcuts
  $ps  = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $app = Join-Path $dest 'Quick_Capture_GUI.ps1'
  $lnkArgs = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "try { & ''' + $app + ''' } catch { Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show(($_ | Out-String), ''Quick Capture error'') }"'
  $startDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Quick Capture'
  New-Item -ItemType Directory -Force -Path $startDir | Out-Null
  $desktop = [Environment]::GetFolderPath('Desktop')
  $wsh = New-Object -ComObject WScript.Shell
  foreach ($lnk in @((Join-Path $startDir 'Quick Capture.lnk'), (Join-Path $desktop 'Quick Capture.lnk'))) {
    $s = $wsh.CreateShortcut($lnk)
    $s.TargetPath = $ps
    $s.Arguments = $lnkArgs
    $s.WorkingDirectory = $dest
    $s.IconLocation = $ico
    $s.Description = 'Quick Capture - screen, window, region and webcam recording'
    $s.WindowStyle = 7
    $s.Save()
  }

  # Uninstall entry (Settings > Apps)
  $uk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\QuickCapture'
  New-Item -Path $uk -Force | Out-Null
  $unPs = Join-Path $dest 'Uninstall_Quick_Capture.ps1'
  $props = @{
    DisplayName = 'Quick Capture'; DisplayVersion = $version; Publisher = 'O.M. Industries Inc'
    InstallLocation = $dest; DisplayIcon = $ico; NoModify = 1; NoRepair = 1
    UninstallString = ('"' + $ps + '" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $unPs + '"')
  }
  foreach ($k in $props.Keys) {
    $t = 'String'; if ($props[$k] -is [int]) { $t = 'DWord' }
    New-ItemProperty -Path $uk -Name $k -Value $props[$k] -PropertyType $t -Force | Out-Null
  }

  $r = [System.Windows.Forms.MessageBox]::Show("Quick Capture is installed.`n`nShortcuts were added to your Desktop and Start Menu.`n`nOpen it now?", $title, 'YesNo', 'Information')
  if ($r -eq 'Yes') { Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + (Join-Path $startDir 'Quick Capture.lnk') + '"') }
} catch {
  [void][System.Windows.Forms.MessageBox]::Show(('Setup failed:' + "`n`n" + ($_ | Out-String)), $title, 'OK', 'Error')
  exit 1
}
