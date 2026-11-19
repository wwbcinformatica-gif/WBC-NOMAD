@echo off
title Limpar memoria - Project NOMAD
setlocal

set "DD=C:\Users\User\AppData\Local\Programs\DockerDesktop"

echo ==========================================================
echo    LIMPAR MEMORIA - Project NOMAD
echo ==========================================================
echo.
echo Memoria livre agora:
powershell -NoProfile -Command "$o=Get-CimInstance Win32_OperatingSystem; '   {0:N1} GB livres de {1:N1} GB' -f ($o.FreePhysicalMemory/1MB),($o.TotalVisibleMemorySize/1MB)"
echo.

echo [1/6] Encerrando o Docker Desktop...
if exist "%DD%\DockerCli.exe" "%DD%\DockerCli.exe" -Shutdown >nul 2>&1
ping -n 9 127.0.0.1 >nul

echo [2/6] Desligando a VM do WSL (limpa os processos orfaos)...
wsl --shutdown >nul 2>&1
ping -n 9 127.0.0.1 >nul

echo [3/6] Matando os processos restantes do Docker/WSL...
for %%P in ("Docker Desktop.exe" "com.docker.backend.exe" "com.docker.build.exe" "com.docker.dev-envs.exe" "docker-agent.exe" "docker.exe" "docker-compose.exe" "vmmemWSL.exe" "wslhost.exe" "wslrelay.exe") do taskkill /F /IM %%P /T >nul 2>&1
ping -n 6 127.0.0.1 >nul

echo [4/6] Iniciando o Docker Desktop...
if exist "%DD%\Docker Desktop.exe" (
  start "" "%DD%\Docker Desktop.exe"
) else (
  echo    [AVISO] Docker Desktop nao encontrado em %DD%
)

echo [5/6] Aguardando o engine subir (ate 6 minutos)...
set /a _n=0
:_wait
ping -n 6 127.0.0.1 >nul
docker ps >nul 2>&1
if not errorlevel 1 goto _ok
set /a _n+=1
if %_n% LSS 72 goto _wait
echo    [ERRO] O engine nao subiu. Abra o Docker Desktop manualmente.
goto _fim

:_ok
echo    Engine no ar. Containers NOMAD:
docker ps --format "    {{.Names}} - {{.Status}}" | findstr /i "nomad"

:_fim
echo.
echo Memoria livre depois:
powershell -NoProfile -Command "$o=Get-CimInstance Win32_OperatingSystem; '   {0:N1} GB livres de {1:N1} GB' -f ($o.FreePhysicalMemory/1MB),($o.TotalVisibleMemorySize/1MB)"
echo.
echo Pronto. Pode fechar esta janela.
pause
