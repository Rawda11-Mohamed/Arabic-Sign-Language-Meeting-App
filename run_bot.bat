@echo off
set ROOM_ID=%1
if "%ROOM_ID%"=="" set /p ROOM_ID="Enter Room ID: "
call myenv\Scripts\activate.bat
python stt_bot.py %ROOM_ID% ws://localhost:8081 ar-SA
pause
