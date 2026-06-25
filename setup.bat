@echo off
rmdir /s /q myenv 2>nul
python -m venv myenv
call myenv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements.txt
pause
