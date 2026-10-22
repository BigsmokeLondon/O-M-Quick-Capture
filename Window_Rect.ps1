# Prints "x y width height" of the window whose title matches the argument (exact, then partial).
# Brings the window to the front first. Used by Quick_Capture.bat.
param([string]$Title)
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int a, out RECT r, int s);
  public struct RECT { public int L, T, R, B; }
}
"@
[W]::SetProcessDPIAware() | Out-Null
$all = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowHandle -ne 0 }
$p = $all | Where-Object { $_.MainWindowTitle -eq $Title } | Select-Object -First 1
if (-not $p) { $p = $all | Where-Object { $_.MainWindowTitle -like "*$Title*" } | Select-Object -First 1 }
if (-not $p) { exit 1 }
$h = $p.MainWindowHandle
if ([W]::IsIconic($h)) { [W]::ShowWindow($h, 9) | Out-Null }
[W]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 500
$r = New-Object W+RECT
[W]::DwmGetWindowAttribute($h, 9, [ref]$r, 16) | Out-Null
$w = $r.R - $r.L; $ht = $r.B - $r.T
if ($w % 2) { $w++ }; if ($ht % 2) { $ht++ }
"{0} {1} {2} {3}" -f $r.L, $r.T, $w, $ht
