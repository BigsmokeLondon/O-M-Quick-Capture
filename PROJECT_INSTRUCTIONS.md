# Quick Capture - project instructions (paste into the new Claude Project's instructions)

Quick Capture (O.M. Industries Inc) is a standalone Windows tool, separate from O.M. Video Studio, for on-demand screen / window / region / webcam video, system sound, and still pictures, built on ffmpeg.

Files (all live together in C:\Users\Admin\Claude projects\Quick Capture\ on the user's PC; this is the only project for Quick Capture):
- Quick_Capture_GUI.bat + Quick_Capture_GUI.ps1 : the main app (PowerShell WinForms window). Needs only ffmpeg; offers to install it.
- Quick_Capture.bat (+ Window_Rect.ps1, List_Windows.bat): the older command-window version, kept as a fallback.
- QUICK_CAPTURE.md: usage and notes.

Key facts learned (do not re-learn the hard way):
- Never capture a window with gdigrab title= (Windows apps like Calculator record black). Record the window's screen rectangle instead.
- In PowerShell, "sc" is an alias for Set-Content: never name a function Sc.
- System sound uses built-in WASAPI loopback (C# via Add-Type), recorded to a .wav and muxed in; Boost (dB) defaults to 12.
- Record into %TEMP%\QuickCapture, then let ffmpeg write the final .mp4 to the save folder; Windows Controlled folder access can block writes (fall back to temp and tell the user).
- If ffmpeg ignores the stop request, end it directly; .mkv survives being cut off.
- Window title: "Quick Capture O.M. Industries Inc (c) 2026" (use [char]0xA9 for the copyright sign; keep scripts ASCII).
- Open the save folder by focusing an already-open Explorer window, else open it.
- Test machines: a main PC (has mic, ffmpeg 9) and a guest/VM (no audio input, older ffmpeg).
- Parked idea: an in-app recorder inside O.M. Video Studio.
