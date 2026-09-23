@echo off
cd /d "%~dp0\.."
echo.
echo EVUDDY: merging a PR on GitHub does NOT refresh sdk gphone / the emulator.
echo The phone keeps the last APK until you stop flutter run, pull, and reinstall.
echo.
echo 1. In the old Flutter terminal, press q  (or close that terminal)
echo 2. This script will: checkout main, pull, uninstall the old app, install the new one
echo.
git checkout main
if errorlevel 1 goto :fail
git fetch origin main
if errorlevel 1 goto :fail
git pull origin main
if errorlevel 1 goto :fail
call flutter pub get
if errorlevel 1 goto :fail
echo.
echo Reinstalling on the connected emulator (uninstalls the stale APK first)...
echo After launch: forest-green splash, EVUDDY wordmark on white. Mic asks for permission.
echo Cursor Agents phone preview is NOT this emulator — ignore that panel.
echo.
call flutter run --uninstall-first
goto :eof
:fail
echo.
echo Pull/build failed. Press q in the old flutter terminal, stash local edits, run again.
exit /b 1
