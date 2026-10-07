@echo off
chcp 65001 >nul 2>&1
title Ativar WSL2 / Virtual Machine Platform
setlocal EnableExtensions

rem ==========================================================
rem  ativar-wsl2.bat
rem
rem  Habilita as 2 features do Windows que o Docker Desktop
rem  precisa para ligar o engine Linux (backend WSL2):
rem
rem    - VirtualMachinePlatform          <- a que o log pede
rem    - Microsoft-Windows-Subsystem-Linux
rem
rem  Precisa de administrador (auto-eleva).
rem  Gera o log %~dp0ativar-wsl2.log
rem  AO FINAL E PRECISA REINICIAR O WINDOWS.
rem ==========================================================

set "LOG=%~dp0ativar-wsl2.log"

powershell -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if not errorlevel 1 goto com_admin

echo Solicitando privilegios de administrador...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
if errorlevel 1 (
    echo.
    echo Nao foi possivel elevar. Clique com o botao DIREITO
    echo neste arquivo e escolha "Executar como administrador".
    echo.
    pause
    exit /b 1
)
echo Janela de administrador aberta - pode fechar esta.
echo.
pause
exit /b 0

:com_admin
cls
echo ================================================
echo   Ativando WSL2 e Virtual Machine Platform
echo ================================================
echo.
echo Leva de 1 a 3 minutos.
echo AO TERMINAR E PRECISA REINICIAR O WINDOWS.
echo.

echo === ativar-wsl2.bat === > "%LOG%"
echo Data: %date% %time% >> "%LOG%"
echo Maquina: %COMPUTERNAME% / %USERNAME% >> "%LOG%"
echo. >> "%LOG%"

echo [1/2] VirtualMachinePlatform ...
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >> "%LOG%" 2>&1
set "RC1=%errorlevel%"
if "%RC1%"=="3010" set "RC1=0"
echo   exit=%RC1%  (0 = ok, 3010 tratado como ok com reboot)
echo VirtualMachinePlatform exit=%RC1% >> "%LOG%"

echo.
echo [2/2] Microsoft-Windows-Subsystem-Linux ...
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >> "%LOG%" 2>&1
set "RC2=%errorlevel%"
if "%RC2%"=="3010" set "RC2=0"
echo   exit=%RC2%  (0 = ok, 3010 tratado como ok com reboot)
echo Microsoft-Windows-Subsystem-Linux exit=%RC2% >> "%LOG%"

echo. >> "%LOG%"
if "%RC1%"=="0" if "%RC2%"=="0" echo RESULTADO=OK >> "%LOG%"
if not "%RC1%"=="0" echo RESULTADO=FALHA_VMP exit=%RC1% >> "%LOG%"
if not "%RC2%"=="0" echo RESULTADO=FALHA_WSL exit=%RC2% >> "%LOG%"

echo.
echo ================================================
if "%RC1%"=="0" if "%RC2%"=="0" goto tudo_ok
echo   FALHA - veja o log:
echo   %LOG%
echo ================================================
echo.
pause
exit /b 1

:tudo_ok
echo   PRONTO - AGORA REINICIE O WINDOWS
echo ================================================
echo.
echo Depois do reboot:
echo   1. Abra o Docker Desktop e espere o icone verde
echo   2. Rode  G:\WBC-NOMAD\start.bat  e escolha [1]
echo.
echo Log: %LOG%
echo.
pause
exit /b 0