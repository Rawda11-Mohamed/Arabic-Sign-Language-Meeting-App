@echo off
set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
call flask_api\venv_new\Scripts\activate.bat
cd flask_api
python app.py
pause
