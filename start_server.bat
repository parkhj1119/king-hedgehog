@echo off
chcp 65001 > nul
echo 로컬 서버를 실행합니다... (http://localhost:8080)
start "" "http://localhost:8080/"
powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
