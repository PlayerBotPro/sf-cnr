@echo off
cd /d "%~dp0"
python tools\server.py stop
exit /b %errorlevel%
