@echo off
cd /d "%~dp0"
python tools\server.py build
exit /b %errorlevel%
