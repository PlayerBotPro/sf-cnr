@echo off
cd /d "%~dp0"
python tools\server.py status
exit /b %errorlevel%
