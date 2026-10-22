@echo off
rem Keep the window open no matter what: relaunch inside cmd /k
if /i not "%~1"=="child" (
  start "Quick Capture" cmd /k call "%~f0" child
  exit /b
)
setlocal enabledelayedexpansion
title Quick Capture
if exist "%~dp0List_Windows.bat" start "" "%~dp0List_Windows.bat"
set "LOG=%TEMP%\quick_capture_log.txt"
echo Quick Capture log > "%LOG%"

set "FF="
for /f "delims=" %%i in ('where ffmpeg 2^>nul') do if not defined FF set "FF=%%i"
if not defined FF for /r "%LOCALAPPDATA%\O.M. Video Studio" %%f in (ffmpeg.exe*) do if not defined FF set "FF=%%f"
if not defined FF goto :noff
echo Using ffmpeg: %FF%

set "OUTDIR=%USERPROFILE%\Videos\Captures"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
for /f %%t in ('powershell -nologo -command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%t"
set "MKV=%OUTDIR%\capture_%TS%.mkv"
set "MP4=%OUTDIR%\capture_%TS%.mp4"

echo.
echo  1 = Whole screen
echo  2 = One window (a numbered list of open windows is shown)
echo  3 = Region (you type x, y, width, height)
echo  4 = Webcam
echo.
set "MODE="
set /p MODE=Choose 1-4 (just the number): 
set "PRE="
if not "%MODE:~1%"=="" set "PRE=%MODE:~2%"
set "MODE=%MODE:~0,1%"
set "FPS="
set /p FPS=Frame rate [30]: 
if "%FPS%"=="" set "FPS=30"
set "LEN="
set /p LEN=Stop automatically after how many seconds? [blank = press Q to stop]: 
set "LENARG="
if not "%LEN%"=="" set "LENARG=-t %LEN%"
set "AUD="
set "MIC="
set /p MIC=Record a microphone? y or n [n]: 
if /i "%MIC%"=="y" goto :askmic
:afteraudio

set "SRC="
if "%MODE%"=="1" set "SRC=-f gdigrab -framerate %FPS% -i desktop"
if "%MODE%"=="2" goto :win
if "%MODE%"=="3" goto :region
if "%MODE%"=="4" goto :cam
if not defined SRC goto :badchoice
goto :record

:askmic
"%FF%" -hide_banner -list_devices true -f dshow -i dummy 2>&1 | findstr /i "audio"
set "MICN="
set /p MICN=Type the microphone name exactly as listed: 
set AUD=-f dshow -i audio="%MICN%"
goto :afteraudio

:win
powershell -nologo -command "Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -notlike 'Quick Capture*' } | Sort-Object MainWindowTitle -Unique | ForEach-Object { $_.MainWindowTitle }" > "%TEMP%\qc_windows.txt"
set "WT=%PRE%"
if not "%WT%"=="" goto :haveTitle
echo.
echo Open windows:
powershell -nologo -command "$i=0; Get-Content '%TEMP%\qc_windows.txt' | ForEach-Object { $i++; '{0,3}   {1}' -f $i,$_ }"
echo.
set /p WT=Type the number from the list (or part of the title): 
:haveTitle
echo %WT%| findstr /r "^[0-9][0-9]*$" >nul && for /f "delims=" %%n in ('powershell -nologo -command "(Get-Content '%TEMP%\qc_windows.txt')[%WT%-1]"') do set "WT=%%n"
echo Window: %WT%
set "RECT="
for /f "delims=" %%r in ('powershell -nologo -ExecutionPolicy Bypass -File "%~dp0Window_Rect.ps1" "%WT%"') do set "RECT=%%r"
if "%RECT%"=="" goto :nowin
for /f "tokens=1-4" %%a in ("%RECT%") do set "RX=%%a" & set "RY=%%b" & set "RW=%%c" & set "RH=%%d"
echo Capturing window area %RECT% (keep it visible, not minimised and not covered)
set SRC=-f gdigrab -framerate %FPS% -offset_x %RX% -offset_y %RY% -video_size %RW%x%RH% -i desktop
goto :record

:region
set /p RX=x offset: 
set /p RY=y offset: 
set /p RW=width: 
set /p RH=height: 
set "SRC=-f gdigrab -framerate %FPS% -offset_x %RX% -offset_y %RY% -video_size %RW%x%RH% -i desktop"
goto :record

:cam
"%FF%" -hide_banner -list_devices true -f dshow -i dummy 2>&1 | findstr /i "video"
set "CAM="
set /p CAM=Type the camera name exactly as listed: 
set SRC=-f dshow -framerate %FPS% -i video="%CAM%"
goto :record

:record
echo.
echo Recording... press Q in this window to stop (or wait for the timer).
echo Command: "%FF%" -y %SRC% %AUD% %LENARG% >> "%LOG%"
"%FF%" -y -hide_banner %SRC% %AUD% %LENARG% -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" -c:v libx264 -preset ultrafast -crf 20 -pix_fmt yuv420p -c:a aac "%MKV%"
echo.
if not exist "%MKV%" goto :failed
"%FF%" -y -v error -i "%MKV%" -c copy -movflags +faststart "%MP4%"
if exist "%MP4%" del "%MKV%"
echo Saved: %MP4%
goto :end

:nowin
echo Could not find a window with that title. Check the list and try again.
goto :end

:failed
echo No file was created. Read the ffmpeg messages above for the reason.
echo (Window title must match exactly and the window must not be minimised.)
goto :end

:badchoice
echo That was not a valid choice. Close this window and run again.
goto :end

:noff
echo ffmpeg was not found. Install O.M. Video Studio first, or put ffmpeg on PATH.
goto :end

:end
if exist "%USERPROFILE%\Videos\Captures" start "" "%USERPROFILE%\Videos\Captures"
echo.
echo Press any key to close this window.
pause >nul
