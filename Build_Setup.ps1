# Builds QuickCapture_Setup.exe (one file) using IExpress, which is built into Windows.
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$files = 'Install_Quick_Capture.bat','Install_Quick_Capture.ps1','Uninstall_Quick_Capture.ps1','Quick_Capture_GUI.ps1','Quick_Capture_GUI.bat','Quick_Capture.bat','Window_Rect.ps1','List_Windows.bat','QUICK_CAPTURE.md'
foreach ($f in $files) { if (-not (Test-Path (Join-Path $dir $f))) { throw ('Missing: ' + $f) } }
$target = Join-Path $dir 'QuickCapture_Setup.exe'
if (Test-Path $target) { Remove-Item $target -Force }
$sed = New-Object System.Collections.Generic.List[string]
$sed.Add('[Version]'); $sed.Add('Class=IEXPRESS'); $sed.Add('SEDVersion=3')
$sed.Add('[Options]'); $sed.Add('PackagePurpose=InstallApp'); $sed.Add('ShowInstallProgramWindow=0'); $sed.Add('HideExtractAnimation=1')
$sed.Add('UseLongFileName=1'); $sed.Add('InsideCompressed=0'); $sed.Add('CAB_FixedSize=0'); $sed.Add('CAB_ResvCodeSigning=0'); $sed.Add('RebootMode=N')
$sed.Add('InstallPrompt=%InstallPrompt%'); $sed.Add('DisplayLicense=%DisplayLicense%'); $sed.Add('FinishMessage=%FinishMessage%')
$sed.Add('TargetName=%TargetName%'); $sed.Add('FriendlyName=%FriendlyName%'); $sed.Add('AppLaunched=%AppLaunched%')
$sed.Add('PostInstallCmd=%PostInstallCmd%'); $sed.Add('AdminQuietInstCmd=%AdminQuietInstCmd%'); $sed.Add('UserQuietInstCmd=%UserQuietInstCmd%')
$sed.Add('SourceFiles=SourceFiles')
$sed.Add('[Strings]'); $sed.Add('InstallPrompt='); $sed.Add('DisplayLicense='); $sed.Add('FinishMessage=')
$sed.Add('TargetName=' + $target); $sed.Add('FriendlyName=Quick Capture Setup')
$sed.Add('AppLaunched=cmd /c Install_Quick_Capture.bat'); $sed.Add('PostInstallCmd=<None>')
$sed.Add('AdminQuietInstCmd='); $sed.Add('UserQuietInstCmd=')
for ($i = 0; $i -lt $files.Count; $i++) { $sed.Add('FILE' + $i + '="' + $files[$i] + '"') }
$sed.Add('[SourceFiles]'); $sed.Add('SourceFiles0=' + $dir + '\')
$sed.Add('[SourceFiles0]'); for ($i = 0; $i -lt $files.Count; $i++) { $sed.Add('%FILE' + $i + '%=') }
$sedPath = Join-Path $env:TEMP 'QuickCapture_Setup.sed'
[System.IO.File]::WriteAllLines($sedPath, $sed, [System.Text.Encoding]::ASCII)
& "$env:SystemRoot\System32\iexpress.exe" /N /Q $sedPath | Out-Null
$t = 0; while (-not (Test-Path $target) -and $t -lt 60) { Start-Sleep -Seconds 1; $t++ }
if (Test-Path $target) { Write-Host ('Built: ' + $target) } else { throw 'IExpress did not produce QuickCapture_Setup.exe' }
