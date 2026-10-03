@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Build NovaGate

echo Sao luu cau hinh (API key, Client ID...) truoc khi build...
if exist "dist\NovaGate\seedvis_settings.json" copy /y "dist\NovaGate\seedvis_settings.json" "%TEMP%\novagate_settings_backup.json" >nul

echo Dang build...
python -m PyInstaller NovaGate.spec --noconfirm
if errorlevel 1 goto loi

echo Khoi phuc cau hinh...
if exist "%TEMP%\novagate_settings_backup.json" copy /y "%TEMP%\novagate_settings_backup.json" "dist\NovaGate\seedvis_settings.json" >nul

rmdir /s /q build 2>nul
echo.
echo XONG! File chay: dist\NovaGate\NovaGate.exe
pause
exit /b 0

:loi
echo.
echo BUILD THAT BAI. Neu bao file dang bi khoa, hay tat NovaGate.exe roi chay lai.
pause
exit /b 1
