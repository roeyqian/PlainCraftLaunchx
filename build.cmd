@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0.github\scripts\build-release.ps1"
set "buildExitCode=%ERRORLEVEL%"
if /I not "%~1"=="--no-pause" pause
exit /b %buildExitCode%
