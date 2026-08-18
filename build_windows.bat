@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] flutter not found in PATH. Install Flutter SDK first:
    echo         https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

rem --- Flutter/Dart 版本检查 -------------------------------------------
rem 项目 pubspec.yaml 的 sdk 约束为 ">=2.17.0 <3.0.0"(Dart 2.x),
rem 对应 Flutter 3.0 ~ 3.7,不支持新版 Flutter(Dart 3.x)。
set FV=
for /f "tokens=2" %%i in ('flutter --version 2^>nul ^| findstr /b /c:"Flutter"') do set FV=%%i
echo Flutter version: %FV%
if defined FV if not "%FV:~0,2%"=="3." (
    echo.
    echo [ERROR] 需要 Flutter 3.x(Dart 2.x),当前是 %FV%。
    echo 项目依赖锁定在 Dart 2.x,请安装 Flutter 3.0 ~ 3.7 再构建。
    echo 可下载: https://docs.flutter.dev/release/archive
    pause
    exit /b 1
)

echo [1/3] flutter pub get ...
call flutter pub get
if errorlevel 1 goto fail

echo [2/3] flutter build windows --release ...
call flutter build windows --release
if errorlevel 1 goto fail

set "ZIP=%cd%\rivergod_music_windows.zip"
echo [3/3] Packing %ZIP% ...
rem 自动定位 Release 产物目录(兼容不同 Flutter 版本的路径差异)
set "OUT="
for /d %%d in ("%cd%\build\windows\runner\Release" "%cd%\build\windows\x64\runner\Release") do if exist "%%d" set "OUT=%%d"
if not defined OUT (
    echo [ERROR] 未找到 Release 产物目录,请检查 build\windows 下的结构
    goto fail
)
echo     Release dir: %OUT%
if exist "%ZIP%" del /q "%ZIP%"
powershell -NoProfile -Command "Compress-Archive -Path '%OUT%\*' -DestinationPath '%ZIP%' -Force"
if errorlevel 1 goto fail

echo.
echo ============================================================
echo  Build OK!
echo    exe:  %OUT%\RiverGodMusic.exe
echo    zip:  %ZIP%
echo  The zip can be copied to other PCs and unzipped to run.
echo ============================================================
explorer "%OUT%"
goto end

:fail
echo.
echo [ERROR] Build failed. Check the output above.
pause
exit /b 1

:end
pause
