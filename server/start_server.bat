@echo off
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo Creating venv...
  py -3.11 -m venv .venv
  call .venv\Scripts\activate.bat
  pip install -r requirements.txt
) else (
  call .venv\Scripts\activate.bat
)
if "%OPENAI_API_KEY%"=="" (
  echo Warning: OPENAI_API_KEY not set on this PC.
  echo You can still generate from the app if you saved a LaoZhang key in Settings.
  echo Or run: set OPENAI_API_KEY=your-laozhang-key
)
echo Starting Music Director API on http://0.0.0.0:8080
echo Test on PC: http://127.0.0.1:8080/health
echo On phone: http://YOUR_PC_IP:8080  (run ipconfig, use Ethernet/Wi-Fi IPv4 — e.g. 192.168.1.7)
echo If phone cannot connect: right-click server\open_firewall.ps1 - Run as administrator
.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8080 --timeout-keep-alive 300 --timeout-graceful-shutdown 120
pause
