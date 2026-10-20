@echo off
cd /d "%~dp0"
python tools\distribute.py %*
exit /b %errorlevel%
