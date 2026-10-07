@echo off
chcp 65001 >nul 2>&1
title Project NOMAD - iniciar
setlocal EnableExtensions

rem ==========================================================
rem  iniciar-nomad.bat - liga o Docker Desktop e o Project NOMAD
rem
rem  Clique duplo. Ele faz, nesta ordem:
rem    1) ve se o docker esta no PATH
rem    2) abre o Docker Desktop se o engine nao estiver no ar
rem    3) espera o engine ficar pronto (ate ~6 min)
rem    4) espera os containers subirem (ate ~7 min)
rem    5) confere o painel em http://localhost:8080
rem    6) abre o navegador
rem
rem  Quando usar este e o start.bat:
rem    - Dia a dia, ligar tudo      ->  iniciar-nomad.bat
rem    - Parar / status / logs      ->  start.bat  (menu)
rem    - Desligar o Docker e liberar ~3 GB de RAM:
rem          docker desktop stop
rem
rem  Os containers voltam sozinhos (restart policy) - nao precisa
rem  rodar "docker compose up" toda vez. So na primeira montagem.
rem ==========================================================

set "PAINEL=http://localhost:8080"
set "ESPERA_ENGINE=36"
set "ESPERA_CONTAINERS=42"
set "PASTA_DADOS=G:\Local\Docker\Wsl\DockerDesktopWSL"

rem Docker Desktop normalmente instala o CLI neste caminho.
if exist "%ProgramFiles%\Docker\Docker\resources\bin\docker.exe" set "PATH=%ProgramFiles%\Docker\Docker\resources\bin;%PATH%"

:inicio
cls
echo ============================================
echo        Project NOMAD - iniciar
echo ============================================
echo.
echo [1/5] Verificando o Docker...

where docker >nul 2>&1
if errorlevel 1 goto erro_docker

docker version --format "{{.Server.Version}}" >nul 2>&1
if not errorlevel 1 goto engine_ja_pronto

echo        O engine ainda nao esta no ar.
echo        Abrindo o Docker Desktop (pode levar ~2 min)...
docker desktop start --timeout 300
if errorlevel 1 (
    echo        [!] Comando "docker desktop start" indisponivel.
    echo        Abrindo pelo atalho do Windows...
    powershell -NoProfile -Command "Start-Process explorer.exe -ArgumentList 'shell:AppsFolder\Docker.DockerForWindows.Settings'"
)

rem ---------------------------------------------------------
rem  Espera o engine
rem ---------------------------------------------------------
:esperar_engine
echo.
echo [2/5] Aguardando o engine (ate %ESPERA_ENGINE% x 10 s)...
set /a tentativas=0

:esperar_engine_loop
set /a tentativas+=1
if %tentativas% GTR %ESPERA_ENGINE% goto erro_engine
docker version --format "{{.Server.Version}}" >nul 2>&1
if not errorlevel 1 goto engine_ok
echo        ... engine subindo  [tentativa %tentrivas% de %ESPERA_ENGINE%]
timeout /t 10 /nobreak >nul
goto esperar_engine_loop

:engine_ja_pronto
echo        [OK] Engine ja estava no ar.
goto containers_check

rem ---------------------------------------------------------
rem  Engine no ar - ve se os containers voltaram sozinhos
rem ---------------------------------------------------------
:engine_ok
echo        [OK] Engine no ar.

:containers_check
set "n=0"
for /f "tokens=*" %%a in ('docker ps -q 2^>nul') do set /a n+=1
if %n% GEQ 1 goto esperar_containers

rem Nenhum container = provavelmente nunca subiu com este compose.
echo.
echo        Nenhum container no ar - subindo via docker compose...
if not exist "%~dp0docker-compose.yml" goto aviso_compose
docker compose up -d
echo.

rem ---------------------------------------------------------
rem  Espera os containers
rem ---------------------------------------------------------
:esperar_containers
echo [3/5] Aguardando os containers (ate %ESPERA_CONTAINERS% x 10 s)...
set /a tentativas=0

:esperar_containers_loop
set /a tentativas+=1
if %tentativas% GTR %ESPERA_CONTAINERS% goto erro_containers
set "n=0"
for /f "tokens=*" %%a in ('docker ps -q 2^>nul') do set /a n+=1
if %n% GEQ 20 goto containers_ok
echo        ... %n% containers  [tentativa %tentrivas% de %ESPERA_CONTAINERS%]
timeout /t 10 /nobreak >nul
goto esperar_containers_loop

:containers_ok
echo        [OK] %n% containers no ar.

rem ---------------------------------------------------------
rem  Confere o painel
rem ---------------------------------------------------------
:verificar_painel
echo.
echo [4/5] Conferindo o painel em %PAINEL% ...
powershell -NoProfile -Command "try { $r=Invoke-WebRequest 'http://localhost:8080' -UseBasicParsing -TimeoutSec 20; Write-Output $r.StatusCode } catch { Write-Output 0 }" > "%TEMP%\nomad_http.txt" 2>nul
set "http=0"
set /p http=<"%TEMP%\nomad_http.txt"
del "%TEMP%\nomad_http.txt" >nul 2>&1
if "%http%"=="200" goto painel_ok
echo        [!] Resposta HTTP %http% - o painel pode ainda estar iniciando.
goto resumo

:painel_ok
echo        [OK] Painel respondeu HTTP 200.

rem ---------------------------------------------------------
rem  Resumo
rem ---------------------------------------------------------
:resumo
echo.
echo [5/5] Resumo
echo ============================================
echo   Containers : %n%
echo   Painel     : HTTP %http%
echo   Endereco   : %PAINEL%
echo.
powershell -NoProfile -Command "$c=Get-PSDrive C; $g=Get-PSDrive G; Write-Output ('   C: ' + [math]::Round($c.Free/1GB,1) + ' GB livres'); Write-Output ('   G: ' + [math]::Round($g.Free/1GB,1) + ' GB livres')"
echo   Dados      : %PASTA_DADOS%
echo ============================================
echo.
echo Abrindo o painel no navegador...
start "" %PAINEL%
echo.
echo Para parar / ver status / ver logs: abra o start.bat
echo Para desligar o Docker e liberar RAM:  docker desktop stop
echo.
pause
goto fim

rem ---------------------------------------------------------
rem  Erros e avisos
rem ---------------------------------------------------------
:aviso_compose
echo.
echo [AVISO] docker-compose.yml nao encontrado em:
echo         %~dp0
echo         Os containers nao voltam sozinhos sem ele.
echo         Use o start.bat para montar a stack.
goto esperar_containers

:erro_docker
echo.
echo [ERRO] Docker nao encontrado nesta maquina.
echo.
echo Instale o Docker Desktop - ele usa o WSL2 no Windows:
echo        https://www.docker.com/products/docker-desktop/
echo.
pause
goto fim

:erro_engine
echo.
echo [ERRO] O engine nao ficou pronto em %ESPERA_ENGINE% tentativas.
echo.
echo Tente novamente. Se insistir:
echo        1) abra o Docker Desktop e ve a mensagem de erro
echo        2) rode:  wsl --shutdown   e abra o Docker de novo
echo.
pause
goto fim

:erro_containers
echo.
echo [ERRO] Apenas %n% container(s) subiram (esperado 20+).
echo.
echo Veja o que falhou com:  start.bat  opcao 4  (logs do painel)
echo Ou:  docker ps -a
echo.
pause
goto fim

:fim
endlocal
