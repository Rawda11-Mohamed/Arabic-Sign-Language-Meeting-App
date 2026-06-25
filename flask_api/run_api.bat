@echo off
echo Starting Flask API with venv_new...
cd /d "%~dp0"
set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
set PYTHONIOENCODING=utf-8
set PYTHONUTF8=1
call venv_new\Scripts\activate.bat
python app.py
pause
