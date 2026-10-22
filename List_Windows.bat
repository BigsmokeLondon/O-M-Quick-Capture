@echo off
set "F=%USERPROFILE%\Videos\Captures\open_windows.txt"
if not exist "%USERPROFILE%\Videos\Captures" mkdir "%USERPROFILE%\Videos\Captures"
powershell -nologo -command "Get-Process | Where-Object { $_.MainWindowTitle } | Sort-Object MainWindowTitle | ForEach-Object { $_.MainWindowTitle }" > "%F%"
start "" notepad "%F%"
