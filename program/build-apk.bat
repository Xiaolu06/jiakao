@echo off
rem ============================================
rem  夜间灯光模拟考试 APK 一键构建脚本
rem  双击运行即可，产物输出到 program\app-debug.apk
rem ============================================
setlocal
cd /d "%~dp0"

set "JAVA_HOME=%~dp0tools\jdk-17.0.13+11"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "GRADLE=%~dp0tools\gradle-8.7\bin\gradle.bat"

echo [1/2] 构建 APK（首次运行需下载依赖，请耐心等待）...
call "%GRADLE%" -p "%~dp0" assembleDebug --no-daemon
if errorlevel 1 (
  echo.
  echo [错误] 构建失败，请查看上方日志。
  pause
  exit /b 1
)

echo [2/2] 复制 APK 到 program 目录...
copy /y "%~dp0app\build\outputs\apk\debug\app-debug.apk" "%~dp0夜间灯光模拟考试.apk" >nul

echo.
echo ============================================
echo   构建完成！
echo   APK 位置：%~dp0夜间灯光模拟考试.apk
echo   直接拷贝到手机安装即可（需允许"未知来源"）
echo ============================================
pause
