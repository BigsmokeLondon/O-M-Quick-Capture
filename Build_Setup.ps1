# =====================================================================
#  Build_Setup.ps1  -  Quick Capture (O.M. Industries Inc)
#
#  WHAT THIS SCRIPT DOES
#  Packs all the Quick Capture files into ONE file called
#  QuickCapture_Setup.exe. When someone double-clicks that .exe it
#  unpacks itself to a temporary folder and runs Install_Quick_Capture.bat,
#  which installs the app and makes the Start Menu / Desktop shortcuts.
#
#  HOW THE PACKING WORKS
#  Windows has a built-in tool called IExpress (iexpress.exe) that makes
#  self-extracting installers. It is driven by a small text "recipe" called
#  a .SED file. This script writes that recipe for us, then hands it to
#  IExpress. Nothing extra needs to be installed.
#
#  HOW TO RUN IT
#  Double-click Build_Setup.bat (it just starts this script).
# =====================================================================

# Stop immediately on any error instead of carrying on half-finished.
$ErrorActionPreference = 'Stop'


# ---------------------------------------------------------------------
#  SECTION 1 - Where am I, and which files go into the installer?
#
#  $dir   = the folder this script lives in. Every file is looked for here.
#  $files = the complete list of files that get packed into the .exe.
#           (The first one, Install_Quick_Capture.bat, is what runs after
#           the .exe unpacks itself.)
# ---------------------------------------------------------------------
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

$files = @(
    'Install_Quick_Capture.bat',      # starts the installer
    'Install_Quick_Capture.ps1',      # does the real installing + makes shortcuts
    'Uninstall_Quick_Capture.ps1',    # copied into the install so Settings > Apps can remove it
    'Quick_Capture_GUI.ps1',          # the main app window
    'Quick_Capture_GUI.bat',          # launcher for the main app
    'Quick_Capture.bat',              # older command-window version (fallback)
    'Window_Rect.ps1',                # helper used by the older version
    'List_Windows.bat',               # helper used by the older version
    'QUICK_CAPTURE.md'                # usage notes
)


# ---------------------------------------------------------------------
#  SECTION 2 - Safety check: is anything missing?
#
#  If even one file is absent the finished installer would be broken, so
#  we stop here and say which file is missing.
# ---------------------------------------------------------------------
foreach ($f in $files) {
    if (-not (Test-Path (Join-Path $dir $f))) { throw ('Missing: ' + $f) }
}


# ---------------------------------------------------------------------
#  SECTION 3 - Decide the output name and clear out any old build
#
#  $target = the .exe we are about to create, placed next to this script.
#  If an older QuickCapture_Setup.exe exists it is deleted first so we
#  never mistake an old file for a fresh one.
# ---------------------------------------------------------------------
$target = Join-Path $dir 'QuickCapture_Setup.exe'
if (Test-Path $target) { Remove-Item $target -Force }


# ---------------------------------------------------------------------
#  SECTION 4 - Write the IExpress "recipe" (.SED file), line by line
#
#  The recipe is a plain text file in .ini style. We build it as a list of
#  lines in $sed and write it out in Section 5. It has these parts:
#
#   [Version]      says "this is an IExpress recipe, format version 3".
#   [Options]      switches: make an installer that runs a program after
#                  unpacking (InstallApp), hide the progress windows, no
#                  restart afterwards, no licence screen, no prompts.
#   [Strings]      the values those switches point at:
#                    TargetName   - the .exe to create
#                    FriendlyName - the title shown on the package
#                    AppLaunched  - the command to run after unpacking
#                                   ("cmd /c Install_Quick_Capture.bat")
#   FILE0..FILEn   a short nickname for each file in $files
#   [SourceFiles]  which folder the files are taken from ($dir)
#   [SourceFiles0] the list of nicknames to pack from that folder
# ---------------------------------------------------------------------
$sed = New-Object System.Collections.Generic.List[string]

# -- Part 4a: [Version] -----------------------------------------------
$sed.Add('[Version]')
$sed.Add('Class=IEXPRESS')
$sed.Add('SEDVersion=3')

# -- Part 4b: [Options] - behaviour switches --------------------------
$sed.Add('[Options]')
$sed.Add('PackagePurpose=InstallApp')            # unpack, then run a program
$sed.Add('ShowInstallProgramWindow=0')           # don't show a console window while installing
$sed.Add('HideExtractAnimation=1')               # no "extracting files" animation
$sed.Add('UseLongFileName=1')                    # allow normal (non 8.3) file names
$sed.Add('InsideCompressed=0')
$sed.Add('CAB_FixedSize=0')
$sed.Add('CAB_ResvCodeSigning=0')
$sed.Add('RebootMode=N')                         # never restart the PC
$sed.Add('InstallPrompt=%InstallPrompt%')        # the %Name% bits are filled in from [Strings] below
$sed.Add('DisplayLicense=%DisplayLicense%')
$sed.Add('FinishMessage=%FinishMessage%')
$sed.Add('TargetName=%TargetName%')
$sed.Add('FriendlyName=%FriendlyName%')
$sed.Add('AppLaunched=%AppLaunched%')
$sed.Add('PostInstallCmd=%PostInstallCmd%')
$sed.Add('AdminQuietInstCmd=%AdminQuietInstCmd%')
$sed.Add('UserQuietInstCmd=%UserQuietInstCmd%')
$sed.Add('SourceFiles=SourceFiles')

# -- Part 4c: [Strings] - the actual values ---------------------------
$sed.Add('[Strings]')
$sed.Add('InstallPrompt=')                       # empty = no "Do you want to install?" question
$sed.Add('DisplayLicense=')                      # empty = no licence screen
$sed.Add('FinishMessage=')                       # empty = no "finished" box (our installer shows its own)
$sed.Add('TargetName=' + $target)                # where the finished .exe is saved
$sed.Add('FriendlyName=Quick Capture Setup')
$sed.Add('AppLaunched=cmd /c Install_Quick_Capture.bat')   # what runs after unpacking
$sed.Add('PostInstallCmd=<None>')
$sed.Add('AdminQuietInstCmd=')
$sed.Add('UserQuietInstCmd=')

# -- Part 4d: give every file a nickname (FILE0, FILE1, ...) ----------
for ($i = 0; $i -lt $files.Count; $i++) {
    $sed.Add('FILE' + $i + '="' + $files[$i] + '"')
}

# -- Part 4e: say which folder the files come from, and list them -----
$sed.Add('[SourceFiles]')
$sed.Add('SourceFiles0=' + $dir + '\')
$sed.Add('[SourceFiles0]')
for ($i = 0; $i -lt $files.Count; $i++) {
    $sed.Add('%FILE' + $i + '%=')
}


# ---------------------------------------------------------------------
#  SECTION 5 - Save the recipe to a temporary file
#
#  The recipe goes in the Windows temp folder (not in your project), as
#  plain ASCII text, because IExpress is fussy about the file format.
# ---------------------------------------------------------------------
$sedPath = Join-Path $env:TEMP 'QuickCapture_Setup.sed'
[System.IO.File]::WriteAllLines($sedPath, $sed, [System.Text.Encoding]::ASCII)


# ---------------------------------------------------------------------
#  SECTION 6 - Run IExpress to build the .exe
#
#  /N = use a recipe file (no wizard)   /Q = quiet (no pop-up windows).
#  iexpress.exe returns straight away and finishes in the background,
#  so Section 7 waits for the result.
# ---------------------------------------------------------------------
& "$env:SystemRoot\System32\iexpress.exe" /N /Q $sedPath | Out-Null


# ---------------------------------------------------------------------
#  SECTION 7 - Wait for the result and report
#
#  Check once a second, for up to 60 seconds, for the new .exe to appear.
#  Then either report where it is, or fail with a clear message.
# ---------------------------------------------------------------------
$t = 0
while (-not (Test-Path $target) -and $t -lt 60) {
    Start-Sleep -Seconds 1
    $t++
}

if (Test-Path $target) {
    Write-Host ('Built: ' + $target)
} else {
    throw 'IExpress did not produce QuickCapture_Setup.exe'
}
