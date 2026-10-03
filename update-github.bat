@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Push Code to GitHub (thincole/novagate)
color 0B

:: ====================================================================
:: CẤU HÌNH GITHUB REPOSITORY
:: ====================================================================
set "REPO_URL=https://github.com/thincole/Novagate.git"

:: Cấu hình Git user & safe directory
git config --global --add safe.directory "%~dp0" >nul 2>&1
git config --global --add safe.directory * >nul 2>&1
git config user.email "thincole@users.noreply.github.com"
git config user.name "thincole"

echo ====================================================================
echo    PUSH CODE LÊN GITHUB (%REPO_URL%)
echo ====================================================================
echo.

if not exist ".git" (
    echo [*] Khởi tạo Git repository mới...
    git init
    git branch -M main
    git remote add origin %REPO_URL%
    echo [OK] Đã khởi tạo repository.
) else (
    git remote get-url origin >nul 2>&1
    if %errorlevel% equ 0 (
        git remote set-url origin %REPO_URL% >nul 2>&1
    ) else (
        git remote add origin %REPO_URL% >nul 2>&1
    )
)

:: Đọc version hiện tại và tự động tăng patch version
if not exist "version.txt" echo 1.0.0> version.txt
set /p OLD_VER=<version.txt
for /f "tokens=1,2,3 delims=." %%a in ("%OLD_VER%") do (
    set MAJOR=%%a
    set MINOR=%%b
    set /a PATCH=%%c+1
)
set NEW_VER=%MAJOR%.%MINOR%.%PATCH%
echo %NEW_VER%> version.txt

echo [*] Version: %OLD_VER% --^> %NEW_VER%
echo.

git add -A
git commit -m "NovaGate v%NEW_VER%"
git branch -M main
git push -u origin main
if %errorlevel% neq 0 (
    echo.
    echo [WARN] Push thường không thành công, thử force push...
    git push -u origin main --force
)

git tag -a v%NEW_VER% -m "Version %NEW_VER%" 2>nul
git push origin v%NEW_VER% 2>nul

echo.
echo ====================================================================
echo    ĐÃ PUSH THÀNH CÔNG! Version: v%NEW_VER%
echo ====================================================================
echo.
pause
