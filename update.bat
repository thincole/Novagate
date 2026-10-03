@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"
title Cap Nhat NovaGate Tu GitHub
color 0B

rem ====================================================================
rem CAU HINH GITHUB REPOSITORY
rem ====================================================================
set "REPO_URL=https://github.com/thincole/Novagate.git"
set "REPO_ZIP_MAIN=https://github.com/thincole/Novagate/archive/refs/heads/main.zip"
set "REPO_ZIP_MASTER=https://github.com/thincole/Novagate/archive/refs/heads/master.zip"

echo ====================================================================
echo    CAP NHAT PHIEN BAN MOI NOVAGATE TU GITHUB
echo    Kho luu tru: !REPO_URL!
echo ====================================================================
echo.

rem 0. Go bo khoa bao mat Windows (Zone.Identifier - Unblock files)
powershell -NoProfile -Command "Get-ChildItem -Path '%~dp0' -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue" >nul 2>&1

rem 1. Tu dong dong tien trinh cu
echo [*] Kiem tra va dong tien trinh cu...
taskkill /f /fi "WINDOWTITLE eq Thin Aptm*" >nul 2>&1
taskkill /f /im NovaGate.exe >nul 2>&1
powershell -NoProfile -Command "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*novagate_app.py*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1

rem 2. Sao luu file cau hinh cai dat
set "SETTINGS_BAK=%TEMP%\novagate_settings_backup_%RANDOM%.json"
if exist "seedvis_settings.json" (
    echo [*] Dang sao luu cau hinh API Key va Client ID...
    copy /y "seedvis_settings.json" "!SETTINGS_BAK!" >nul 2>&1
)

rem 3. Cap nhat ma nguon
set UPDATE_SUCCESS=0

where git >nul 2>&1
if !errorlevel! equ 0 (
    echo [*] Tim thay Git. Tien hanh cap nhat qua Git...
    git config --global --add safe.directory "%~dp0" >nul 2>&1
    git config --global --add safe.directory * >nul 2>&1

    if not exist ".git" (
        echo [*] Khoi tao Git repository lien ket voi GitHub...
        git -c safe.directory=* init >nul 2>&1
        git -c safe.directory=* remote add origin !REPO_URL! >nul 2>&1
    ) else (
        git -c safe.directory=* remote get-url origin >nul 2>&1
        if !errorlevel! equ 0 (
            git -c safe.directory=* remote set-url origin !REPO_URL! >nul 2>&1
        ) else (
            git -c safe.directory=* remote add origin !REPO_URL! >nul 2>&1
        )
    )

    set "BRANCH=main"
    echo [*] Dang tai ma nguon moi nhat tu nhanh main...
    git -c safe.directory=* fetch origin main >nul 2>&1
    if !errorlevel! neq 0 (
        echo [*] Thu nhanh master...
        git -c safe.directory=* fetch origin master >nul 2>&1
        if !errorlevel! equ 0 set "BRANCH=master"
    )

    git -c safe.directory=* rev-parse --verify origin/!BRANCH! >nul 2>&1
    if !errorlevel! equ 0 (
        git -c safe.directory=* checkout -f -B !BRANCH! origin/!BRANCH! >nul 2>&1
        git -c safe.directory=* reset --hard origin/!BRANCH! >nul 2>&1
        if !errorlevel! equ 0 (
            git -c safe.directory=* clean -fd -e seedvis_settings.json -e log.txt -e temp_render -e "*.rar" >nul 2>&1
            set UPDATE_SUCCESS=1
        )
    )
)

rem Fallback neu khong co Git hoac Git loi
if !UPDATE_SUCCESS! neq 1 (
    echo.
    echo [*] Dang tai ban cap nhat truc tiep tu GitHub - ZIP fallback...
    set "ZIP_TEMP=%TEMP%\novagate_main_%RANDOM%.zip"
    set "DIR_TEMP=%TEMP%\novagate_extract_%RANDOM%"

    where curl.exe >nul 2>&1
    if !errorlevel! equ 0 (
        curl.exe -L -s -f -o "!ZIP_TEMP!" "!REPO_ZIP_MAIN!" >nul 2>&1
        if !errorlevel! neq 0 (
            curl.exe -L -s -f -o "!ZIP_TEMP!" "!REPO_ZIP_MASTER!" >nul 2>&1
        )
    ) else (
        powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('!REPO_ZIP_MAIN!', '!ZIP_TEMP!')" >nul 2>&1
    )

    if exist "!ZIP_TEMP!" (
        echo [*] Dang giai nen ban cap nhat...
        powershell -NoProfile -Command "Expand-Archive -Path '!ZIP_TEMP!' -DestinationPath '!DIR_TEMP!' -Force" >nul 2>&1
        for /d %%D in ("!DIR_TEMP!\*") do (
            if exist "%%D" (
                powershell -NoProfile -Command "Get-ChildItem -Path '%%D\*' | Copy-Item -Destination '.\' -Recurse -Force" >nul 2>&1
                set UPDATE_SUCCESS=1
            )
        )
        rmdir /s /q "!DIR_TEMP!" >nul 2>&1
        del /f /q "!ZIP_TEMP!" >nul 2>&1
    )
)

rem 4. Khoi phuc file cau hinh
if exist "!SETTINGS_BAK!" (
    echo [*] Khoi phuc cai dat cau hinh...
    copy /y "!SETTINGS_BAK!" "seedvis_settings.json" >nul 2>&1
    del /f /q "!SETTINGS_BAK!" >nul 2>&1
)

rem 5. Kiem tra ket qua
echo.
if !UPDATE_SUCCESS! equ 1 (
    color 0A
    if exist "version.txt" (
        set /p VER_CODE=<version.txt
        echo [OK] Cap nhat thanh cong len phien ban: v!VER_CODE!
    ) else (
        echo [OK] Cap nhat ma nguon thanh cong tu GitHub!
    )
) else (
    color 0C
    echo [ERROR] Khong the ket noi hoac tai ban cap nhat tu GitHub.
    echo Vui long kiem tra ket noi mang hoac kho luu tru: !REPO_URL!
    echo.
    pause
    exit /b 1
)

rem 6. Nang cap thu vien Python
echo.
echo [*] Kiem tra thu vien Python...
set PYTHON_CMD=
python --version >nul 2>&1
if !errorlevel! equ 0 (
    set "PYTHON_CMD=python"
) else (
    py --version >nul 2>&1
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=py"
    ) else (
        if exist "%LocalAppData%\Programs\Python\Python312\python.exe" set "PYTHON_CMD=%LocalAppData%\Programs\Python\Python312\python.exe"
        if exist "%LocalAppData%\Programs\Python\Python311\python.exe" set "PYTHON_CMD=%LocalAppData%\Programs\Python\Python311\python.exe"
        if exist "%LocalAppData%\Programs\Python\Python310\python.exe" set "PYTHON_CMD=%LocalAppData%\Programs\Python\Python310\python.exe"
        if exist "C:\Python312\python.exe" set "PYTHON_CMD=C:\Python312\python.exe"
        if exist "C:\Python311\python.exe" set "PYTHON_CMD=C:\Python311\python.exe"
    )
)

if defined PYTHON_CMD (
    if exist "requirements.txt" (
        echo [*] Dang kiem tra va cai dat thu vien phu thuoc...
        "!PYTHON_CMD!" -m pip install -r requirements.txt --upgrade --quiet 2>nul
        if !errorlevel! equ 0 (
            echo [OK] Thu vien Python da san sang.
        ) else (
            echo [WARN] Khong the tu dong nang cap thu vien.
        )
    )
)

echo.
echo ====================================================================
echo    CAP NHAT HOAN TAT THANH CONG!
echo    Khoi dong lai bang file: run_novagate.bat
echo ====================================================================
echo.
pause
