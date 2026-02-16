@echo off
chcp 65001 >nul
echo ========================================
echo SpringTemplate 服务生成脚本
echo ========================================
echo.

set /p ServiceName="请输入服务名称（例如：gordon）: "

if "%ServiceName%"=="" (
    echo 错误：服务名称不能为空！
    pause
    exit /b 1
)

echo.
echo 正在使用PowerShell执行脚本...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0generate-service.ps1" -ServiceName "%ServiceName%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo 执行失败！错误代码：%ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
pause

