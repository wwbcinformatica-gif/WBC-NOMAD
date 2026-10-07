@echo off
chcp 65001 >nul 2>&1
title Project NOMAD - Windows
setlocal EnableExtensions

rem ==========================================================
rem  Project NOMAD - start.bat para Windows
rem  Sobe o Command Center e as dependencias via Docker Compose.
rem
rem  Requer:
rem    - Docker Desktop  ou  Docker Engine + WSL2
rem    - plugin "docker compose" v2
rem    - docker-compose.yml  (gerado a partir de
rem      install\management_compose.yaml, com as senhas preenchidas)
rem ==========================================================

set "NOMAD_HOME=%~dp0"
if "%NOMAD_HOME:~-1%"=="\" set "NOMAD_HOME=%NOMAD_HOME:~0,-1%"
set "COMPOSE=%NOMAD_HOME%\docker-compose.yml"
set "PAINEL=http://localhost:8080"
cd /d "%NOMAD_HOME%"

:menu
cls
echo ============================================
echo        Project NOMAD - Windows
echo ============================================
echo.
echo Pasta  : %NOMAD_HOME%
echo Painel : %PAINEL%
echo.
echo   [1] Iniciar NOMAD
echo   [2] Parar NOMAD
echo   [3] Status dos containers
echo   [4] Logs do painel
echo   [5] Abrir painel no navegador
echo   [6] Sair
echo.
set "opcao="
set /p opcao="Opcao: "

if "%opcao%"=="1" goto iniciar
if "%opcao%"=="2" goto parar
if "%opcao%"=="3" goto status
if "%opcao%"=="4" goto logs
if "%opcao%"=="5" goto navegador
if "%opcao%"=="6" goto fim
echo Opcao invalida.
echo.
pause
goto menu

rem ---------------------------------------------------------
rem  Verificacoes de pre-requisito
rem ---------------------------------------------------------
:checar
set "OK=1"
where docker >nul 2>&1
if errorlevel 1 goto erro_docker
docker info >nul 2>&1
if errorlevel 1 goto erro_daemon
docker compose version >nul 2>&1
if errorlevel 1 goto erro_compose
if not exist "%COMPOSE%" goto erro_arquivo
goto :eof

:erro_docker
set "OK=0"
echo.
echo [ERRO] Docker nao encontrado nesta maquina.
echo.
echo O Project NOMAD roda em containers. Sem Docker ele nao sobe.
echo.
echo Instale o Docker Desktop - ele usa o WSL2 no Windows:
echo        https://www.docker.com/products/docker-desktop/
echo.
echo Depois rode este arquivo de novo.
echo.
pause
goto :eof

:erro_daemon
set "OK=0"
echo.
echo [ERRO] Docker instalado, mas o servico nao responde.
echo        Abra o Docker Desktop e espere o icone ficar verde.
echo.
pause
goto :eof

:erro_compose
set "OK=0"
echo.
echo [ERRO] Plugin "docker compose" v2 nao encontrado.
echo        O NOMAD precisa do Compose v2 - o docker-compose v1 nao serve.
echo.
pause
goto :eof

:erro_arquivo
set "OK=0"
echo.
echo [ERRO] docker-compose.yml nao encontrado:
echo        %COMPOSE%
echo        Ele acompanha o start.bat. Copie os dois juntos.
echo.
pause
goto :eof

rem ---------------------------------------------------------
rem  Acoes
rem ---------------------------------------------------------
:iniciar
call :checar
if not "%OK%"=="1" goto menu
echo.
echo Iniciando o Project NOMAD...
echo Na primeira execucao demora, pois baixa as imagens.
echo.
docker compose -f "%COMPOSE%" up -d
if errorlevel 1 (
    echo.
    echo [ERRO] Falha ao subir os containers - veja a mensagem acima.
    echo.
    pause
    goto menu
)
echo.
docker compose -f "%COMPOSE%" ps
echo.
echo Abrindo o painel em %PAINEL% ...
start "" %PAINEL%
goto menu

:parar
call :checar
if not "%OK%"=="1" goto menu
echo.
echo Parando os containers do Project NOMAD...
docker compose -f "%COMPOSE%" stop
echo.
pause
goto menu

:status
call :checar
if not "%OK%"=="1" goto menu
echo.
docker compose -f "%COMPOSE%" ps
echo.
pause
goto menu

:logs
call :checar
if not "%OK%"=="1" goto menu
echo.
echo Ctrl+C para voltar ao menu.
echo.
docker compose -f "%COMPOSE%" logs -f --tail=100 admin
goto menu

:navegador
start "" %PAINEL%
goto menu

:fim
echo.
pause
endlocal