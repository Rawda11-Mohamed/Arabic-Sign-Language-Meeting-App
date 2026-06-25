@echo off
echo ============================================================
echo TERMINATING BACKGROUND SERVERS
echo ============================================================

echo 1. Killing all python processes...
taskkill /F /IM python.exe /T 2>NUL

echo 2. Specifically searching for anything on port 5000...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000') do (
    echo Found process %%a on port 5000. Killing it...
    taskkill /F /PID %%a 2>NUL
)

echo 3. Cleaning up temporary files...
del /q flask_api\*.log 2>NUL

print "============================================================"
echo CLEANUP COMPLETE. YOU CAN NOW RUN run_server.bat
echo ============================================================
pause
