@echo off
cd /d "%~dp0"
echo Starting Arabic Sign Language API (VENV)...
call myenv\Scripts\activate.bat
python flask_api\app.py
pause
