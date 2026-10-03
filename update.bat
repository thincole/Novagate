@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Thin Aptm - Cập Nhật NovaGate Từ GitHub
color 0B

:: ====================================================================
:: CẤU HÌNH GITHUB REPOSITORY
:: Bạn có thể chỉnh sửa link GitHub tại đây nếu dùng repository khác
:: ====================================================================
set "REPO_URL=https://github.com/thincole/Novagate.git"
set "REPO_ZIP_MAIN=https://github.com/thincole/Novagate/archive/refs/heads/main.zip"
set "REPO_ZIP_MASTER=https://github.com/thincole/Novagate/archive/refs/heads/master.zip"

echo ====================================================================
echo    CẬP NHẬT PHIÊN BẢN MỚI NOVAGATE TỪ GITHUB
echo    Kho lưu trữ: %REPO_URL%
echo ====================================================================
echo.

:: 1. Tự động đóng phần mềm nếu đang chạy để không bị khóa file (File Lock)
echo [*] Đang kiểm tra và đóng tiến trình NovaGate cũ (nếu đang chạy)...
taskkill /f /fi "WINDOWTITLE eq Thin Aptm*" >nul 2>&1
taskkill /f /im NovaGate.exe >nul 2>&1
powershell -NoProfile -Command "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*novagate_app.py*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1

:: 2. Sao lưu file cấu hình cài đặt (API Key, Client ID...) vào thư mục Temp
set "SETTINGS_BAK=%TEMP%\novagate_settings_backup_%RANDOM%.json"
if exist "seedvis_settings.json" (
    echo [*] Đang sao lưu cấu hình cá nhân (API Key, Client ID...)...
    copy /y "seedvis_settings.json" "%SETTINGS_BAK%" >nul 2>&1
)

:: 3. Tiến hành cập nhật mã nguồn
set UPDATE_SUCCESS=0

where git >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Đã tìm thấy Git. Tiến hành cập nhật qua Git...
    
    :: Thêm safe.directory để tránh lỗi phân quyền (dubious ownership) trên Windows
    git config --global --add safe.directory "%~dp0" >nul 2>&1
    git config --global --add safe.directory * >nul 2>&1

    if not exist ".git" (
        echo [*] Khởi tạo Git repository liên kết với GitHub...
        git -c safe.directory=* init >nul 2>&1
        git -c safe.directory=* remote add origin %REPO_URL% >nul 2>&1
    ) else (
        git -c safe.directory=* remote get-url origin >nul 2>&1
        if %errorlevel% equ 0 (
            git -c safe.directory=* remote set-url origin %REPO_URL% >nul 2>&1
        ) else (
            git -c safe.directory=* remote add origin %REPO_URL% >nul 2>&1
        )
    )

    :: Thử nhánh main trước, nếu không có thử nhánh master
    set "BRANCH=main"
    echo [*] Đang tải mã nguồn mới nhất từ nhánh main...
    git -c safe.directory=* fetch origin main >nul 2>&1
    if %errorlevel% neq 0 (
        echo [*] Không thấy nhánh main, thử nhánh master...
        git -c safe.directory=* fetch origin master >nul 2>&1
        if %errorlevel% equ 0 set "BRANCH=master"
    )

    git -c safe.directory=* rev-parse --verify origin/%BRANCH% >nul 2>&1
    if %errorlevel% equ 0 (
        git -c safe.directory=* checkout -f -B %BRANCH% origin/%BRANCH% >nul 2>&1
        git -c safe.directory=* reset --hard origin/%BRANCH% >nul 2>&1
        if %errorlevel% equ 0 (
            git -c safe.directory=* clean -fd -e seedvis_settings.json -e log.txt -e temp_render -e "*.rar" >nul 2>&1
            set UPDATE_SUCCESS=1
        )
    )
)

:: Nếu máy không có Git hoặc Git kéo lỗi, tải trực tiếp file ZIP từ GitHub (Fallback)
if %UPDATE_SUCCESS% neq 1 (
    echo.
    echo [*] Đang tải bản cập nhật trực tiếp từ GitHub (ZIP fallback)...
    set "ZIP_TEMP=%TEMP%\novagate_main_%RANDOM%.zip"
    set "DIR_TEMP=%TEMP%\novagate_extract_%RANDOM%"

    set "DOWNLOAD_URL=%REPO_ZIP_MAIN%"
    where curl.exe >nul 2>&1
    if %errorlevel% equ 0 (
        curl.exe -L -s -f -o "%ZIP_TEMP%" "%REPO_ZIP_MAIN%" >nul 2>&1
        if %errorlevel% neq 0 (
            curl.exe -L -s -f -o "%ZIP_TEMP%" "%REPO_ZIP_MASTER%" >nul 2>&1
            if %errorlevel% equ 0 set "DOWNLOAD_URL=%REPO_ZIP_MASTER%"
        )
    ) else (
        powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { (New-Object System.Net.WebClient).DownloadFile('%REPO_ZIP_MAIN%', '%ZIP_TEMP%') } catch { (New-Object System.Net.WebClient).DownloadFile('%REPO_ZIP_MASTER%', '%ZIP_TEMP%') }" >nul 2>&1
    )

    if exist "%ZIP_TEMP%" (
        echo [*] Đang giải nén bản cập nhật...
        powershell -NoProfile -Command "Expand-Archive -Path '%ZIP_TEMP%' -DestinationPath '%DIR_TEMP%' -Force" >nul 2>&1
        
        :: Tìm thư mục giải nén được (thường là novagate-main hoặc novagate-master)
        for /d %%D in ("%DIR_TEMP%\*") do (
            if exist "%%D" (
                powershell -NoProfile -Command "Get-ChildItem -Path '%%D\*' | Copy-Item -Destination '.\' -Recurse -Force" >nul 2>&1
                set UPDATE_SUCCESS=1
            )
        )
        rmdir /s /q "%DIR_TEMP%" >nul 2>&1
        del /f /q "%ZIP_TEMP%" >nul 2>&1
    )
)

:: 4. Khôi phục lại file cấu hình người dùng
if exist "%SETTINGS_BAK%" (
    echo [*] Đang khôi phục cài đặt cấu hình...
    copy /y "%SETTINGS_BAK%" "seedvis_settings.json" >nul 2>&1
    del /f /q "%SETTINGS_BAK%" >nul 2>&1
)

:: 5. Kiểm tra kết quả cập nhật mã nguồn
echo.
if %UPDATE_SUCCESS% equ 1 (
    color 0A
    if exist "version.txt" (
        set /p VER_CODE=<version.txt
        echo [OK] Đã cập nhật thành công lên phiên bản: v%VER_CODE%
    ) else (
        echo [OK] Đã cập nhật mã nguồn thành công từ GitHub!
    )
) else (
    color 0C
    echo [ERROR] Không thể kết nối hoặc tải bản cập nhật từ GitHub.
    echo Vui lòng kiểm tra lại:
    echo   1. Đường dẫn kho lưu trữ: %REPO_URL%
    echo   2. Kết nối mạng Internet trên máy tính.
    echo.
    pause
    exit /b 1
)

:: 6. Tự động kiểm tra và nâng cấp thư viện Python nếu có file requirements.txt
echo.
echo [*] Đang kiểm tra thư viện Python...
set PYTHON_CMD=
python --version >nul 2>&1
if %errorlevel% equ 0 (
    set "PYTHON_CMD=python"
) else (
    py --version >nul 2>&1
    if %errorlevel% equ 0 (
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
        echo [*] Đang kiểm tra và cài đặt thư viện phụ thuộc...
        "%PYTHON_CMD%" -m pip install -r requirements.txt --upgrade --quiet 2>nul
        if %errorlevel% equ 0 (
            echo [OK] Thư viện Python đã sẵn sàng.
        ) else (
            echo [WARN] Không thể tự động nâng cấp thư viện (bạn có thể cài thủ công bằng pip install -r requirements.txt).
        )
    )
) else (
    echo [WARN] Chưa phát hiện Python trong PATH.
)

echo.
echo ====================================================================
echo    CẬP NHẬT HOÀN TẤT THÀNH CÔNG!
echo    Bạn có thể khởi động lại phần mềm bằng file: run_novagate.bat
echo ====================================================================
echo.
pause
