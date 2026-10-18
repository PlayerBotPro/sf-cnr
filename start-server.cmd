@echo off
cd /d "%~dp0"
python tools\server.py start
exit /b %errorlevel%
