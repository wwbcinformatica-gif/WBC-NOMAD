# MEMÓRIA — WBC NOMAD

> Memória acumulada do projeto: contexto, decisões, descobertas e histórico.
> Estado pontual de agora: [`status.md`](./status.md)
>
> **Regra:** este arquivo éAPPEND-ONLY. Para registrar uma sessão, adicione uma
> entrada em *Histórico de sessões*. Não reescreva o que já está aqui.
> O `status.md` que se reescreve a cada sessão.

---

## 1. Objetivo

Rodar o **Project NOMAD** (offline-first knowledge & education server) na máquina
local, com painel de gerenciamento próprio, para uso sem internet.

- Upstream: https://github.com/Crosstalk-Solutions/project-nomad (Apache-2.0)
- Mirror pessoal: https://github.com/wwbcinformatica-gif/WBC-NOMAD.git (vazio, criado 2026-10-04)
- Nome do projeto: **WBC NOMAD** (pasta local `WBC-NOMAD`, sem espaço, para o terminal)
- Descrição no repo pessoal: *"Projeto de recursos basicos para rodar offline nomad"*
- Conta: Wilson Barbosa Coimbra (`wwbcinformatica-gif`)

O NOMAD não guarda conteúdo pesado no GitHub. ZIMs (Wikipedia, DevDocs, FreeCodeCamp…),
mapas offline e modelos Ollama são baixados em runtime pelo painel (Easy Setup).
Por isso o repo é leve (21 MB) e o download real vai de 30 GB a 1 TB+.

---

## 2. Ambiente

| Item | Valor |
|---|---|
| Hostname | `qual-ano-do-ryzen-5-1400` |
| Kernel | 7.0.0-38-generic |
| OS | Ubuntu (noble), base x86_64 |
| CPU | Ryzen 5 1400 |
| GPU | NVIDIA GeForce RTX 3060 (GA104, rev a1) |
| Driver | nvidia/580.178.04 via DKMS (instalado p/ 6.17.0-20 e 7.0.0-38) |
| SecureBoot | Ativo, com MOK enrolled |
| Disco | 468 GB total — 108 GB usados, **337 GB livres** |
| `sudo` | Exige senha (obstáculo recorrente) |

Ausentes no sistema: `git`, `docker`. Presentes: `curl`, `gpg`, `python3`, `node`/`npm`, `ollama`.

Projetos vizinhos no mesmo ambiente (não confundir com o NOMAD):
`~/Público/DEEP-OS` — SaaS script, projeto separado.

---

## 3. Como o instalador funciona

`install/install_nomad.sh` — 686 linhas, Bootstrap-style com ASCII art.

### Ordem de execução
```
check_is_debian_based / check_is_x86_64 / check_is_bash / check_has_sudo
ensure_dependencies_installed   → curl, gpg
get_install_confirmation        → PROMPT 1
accept_terms                   → PROMPT 2
ensure_docker_installed        → baixa get.docker.com, sudo sh, systemctl start
check_docker_compose           → exige plugin v2
setup_nvidia_container_toolkit → só avisa, nunca aborta (return 0)
get_local_ip
create_nomad_directory         → /opt/project-nomad
download_helper_scripts        → start/stop/update
download_management_compose_file
start_management_containers
verify_gpu_setup
success_message
```

### Os 2 prompts interativos
| # | Linha | Texto | Sem resposta |
|---|---|---|---|
| 1 | 374 | `Are you sure you want to continue? (y/N):` | `exit 0` — cancela |
| 2 | 395 | `I have read and accept License Agreement & Terms of Use (y/N)?` | `exit 1` — aborta |

São os **únicos** `read` do script (o resto é `while read -r` em pipe).
`whiptail` está **comentado** (linhas 133-135) → não depende de TUI, roda em pipe.

**Atalho não interativo:** `printf 'y\ny\n' | sudo bash install_nomad.sh`

### Detalhes que importam
- `NOMAD_DIR=/opt/project-nomad`; painel em `http://localhost:8080` ou `http://<IP>:8080`
- O script chama `sudo` internamente (`apt-get`, `sh get-docker.sh`, `systemctl`).
  Rodando como root via `sudo bash`, essas chamadas internas não pedem senha.
- `script_option_debug='true'` → não limpa a tela (bom pra log)
- `accepted_terms='false'` inicial; vira `'true'` no prompt 2
- `free_space_check()` existe mas está **comentada** no final do arquivo → o instalador
  não checa espaço. Fiquei de olho nos 337 GB livres por conta própria.
- Exige **Docker Compose v2** (plugin). `docker-compose` v1 não serve.

---

## 4. Problemas conhecidos

### `git` ausente no sistema — RESOLVIDO
Instalado na S4 (`git 2.43.0`). Identidade configurada como
`Wilson Barbosa Coimbra <233176178+wwbcinformatica-gif@users.noreply.github.com>`
(noreply porque o e-mail público do usuário está privado no GitHub).

Três erros previstos/learned no primeiro uso:

1. **`Author identity unknown`** — falta `user.name`/`user.email` antes do primeiro
   commit. Git aborta o commit mas **mantém tudo staged**; só repetir o commit após
   configurar resolve.
2. **`src refspec main does not match any`** — consequência do item 1, não um
   problema separado: sem commit não existe branch local para enviar.
3. **`refusing to allow a Personal Access Token to create or update workflow
   .github/workflows/...`** — o GitHub exige escopo `workflow` no token para
   versionar arquivos de CI. Decidido **não** dar esse poder ao token: a alternativa
   foi adicionar `.github/workflows/` ao `.gitignore` e `git rm -r --cached`.
   Os 7 workflows continuam no disco, só não sobem para o GitHub. Correto para
   mirror de backup — o CI/CD do upstream não deve rodar no repo do usuário.

Erro que **não** era culpa do token: no prompt de senha do terminal nada aparece
(`stty` com `echo` desligado). É comportamento normal, não falha de colagem.

### `credential.helper` não configurado
O token é solicitado a cada push. Solução recomendada ao usuário:
`git config --global credential.helper store` — digita o token uma única vez,
fica em `~/.git-credentials` (local, permissão 600).

### `sudo` exige senha
Não tenho acesso a senha. Comandos privilegiados são entregues prontos para
o usuário colar no terminal. **Não pedir a senha.**

### Driver NVIDIA não carregado
```
nvidia-smi → "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver"
```
O módulo **existe e está assinado** em
`/lib/modules/7.0.0-38-generic/updates/dkms/nvidia.ko.zst`, e o DKMS reporta
`installed` para as duas versões de kernel. O SecureBoot está ativo com MOK válido.
O `lspci -k` lista `nvidiafb, nouveau, nvidia_drm, nvidia` como disponíveis,
mas **nenhum está em uso** — a placa ficou sem driver vinculado.

Hipótese principal: a queda abrupta de energia derrubou o módulo sem
recarga limpa. Teste: `sudo modprobe nvidia && nvidia-smi`.

Impacto no NOMAD: **nenhum** para a instalação. O `setup_nvidia_container_toolkit`
trata falha como warning e segue (`return 0`). Se o módulo voltar a carregar,
o NOMAD detecta a GPU sozinho ao subir os containers. Sem GPU, o Assistente de IA
roda CPU-only — funcional, mais lento.

### Queda de energia no meio de processos
Já aconteceu uma vez (perdeu o contexto da sessão 1).
Mitigação adotada: sempre rodar installs com `2>&1 | tee ~/algum.log`.

### PC reiniciado
Boot em 2026-10-04 15:28. Docker que não tivesse sido instalado como serviço
perdeu estado. O `systemd` do NOMAD não estava configurado ainda.

---

## 5. Versão do upstream

| Data | Versão / evento |
|---|---|
| 2026-09-13 | `v1.35.0-rc.1` |
| 2026-09-24 | `v1.35.0-rc.2` |
| **2026-09-29** | **`v1.35.0`** — release atual do upstream |
| 2026-09-30 | Commit `fix(collections)`: repoint de 11 ZIMs curados cujas URLs upstream sumiram (404). openZIM mantém só os 2 builds mais novos de cada título. Varredura completa: 118 URLs em `collections/*.json` respondendo 200. |

**Código local = 1.35.0** (confirmado em `package.json`), baixado em 2026-10-04
→ inclui a release v1.35.0 e o commit de correção dos ZIMs.

Pra atualizar o upstream depois (sem `git`):
```bash
curl -fsSL -o /tmp/nomad.zip https://codeload.github.com/Crosstalk-Solutions/project-nomad/zip/refs/heads/main
```

---

## 6. Estrutura do código

```
WBC-NOMAD/
├── admin/            backend AdonisJS (controllers, jobs, services, models)
│   ├── app/controllers/   easy_setup, downloads, maps, ollama, zim, rag, chat…
│   ├── app/jobs/          run_download_job, download_model_job, run_benchmark_job…
│   ├── app/services/      download_service, kiwix_library_service, ollama_service…
│   └── adonisrc.ts
├── collections/      9 arquivos — catálogos de recursos
│   ├── wikipedia.json, kiwix-categories.json, maps.json
│   ├── conditions.json, natural_remedies.json, home_remedies.json
│   └── creator-packs.json
├── install/          scripts de instalação/operação + management_compose.yaml
├── Dockerfile, package.json (1.35.0), README.md, FAQ.md, SECURITY.md
```

Tamanho: 386 `.ts`, 130 `.tsx`, 56 `.md`, 16 `.json`, 13 `.sh`, 13 `.webp`.
Maior arquivo: `install/wikipedia_en_100_mini_2026-01.zim` (4,4 MB). Nada passa de 5 MB.

O `.gitignore` do projeto já exclui `node_modules/`, chaves/certificados
(`*.pem`, `*.key`), senhas (`.env`), compose local com credenciais
(`compose.yaml`, `management_compose.local.yaml`) e `admin/storage`.
**Manter esse `.gitignore` ao popular o repo pessoal** — é proteção de credencial,
não opcional. Ver `SECURITY.md` do upstream.

---

## 7. Histórico de sessões

### S1 — 2026-10-04 ~14:26→14:45 (12m53s)
Baixou o projeto. `git clone` falhou (`git: comando não encontrado`), `sudo apt-get`
falhou (pede senha). Contornou baixando o ZIP do GitHub via Python e extraindo.
Mapeou `install/` e `collections/`. Explicou a diferença entre "código no GitHub"
e "recursos pesados baixados no setup". Terminou perguntando se devia rodar o
instalador — **sem resposta, o PC desligou**.

### S3 — 2026-10-04 15:41→15:50
Criou `status.md` e `memoria.md` no projeto (pedido explícito: registro permanente).
Usuário pediu renomear o projeto para **WBC NOMAD** e indicou o novo repo
`wwbcinformatica-gif/WBC-NOMAD`. Verifiquei via API e **o usuário já tinha renomeado
no GitHub** — `NOMAD` responde 301 Moved Permanently, `WBC-NOMAD` existe com o
mesmo `created_at` (2026-10-04T18:39:20Z), confirmando renomeação e não repo novo.
Renomeei a pasta local `project-nomad` → `WBC-NOMAD` e atualizei todos os paths
e URLs nos dois `.md`. Repo segue vazio (sem branch, sem commit).

Orientação sobre execução: **linha por linha / em blocos**, nunca colar tudo de
uma vez. Motivo: ao colar várias linhas o terminal bufferiza o resto, e um prompt
de senha (sudo, git push) acaba engolindo a linha seguinte. Regra: comando que
pede input sempre por último no bloco.

Usuário perguntou se podia colar o token do GitHub aqui. **Não** — recomendou rodar
o push localmente e ativar `git config --global credential.helper store` para
digitar o token uma única vez. Registrou na seção de decisões que o agente nunca
pede senha nem segredo.

### S4 — 2026-10-04 16:05→16:25
Instalou `git 2.43.0` via apt. `git init`/`remote add`/`git add` OK (665 arquivos),
mas o commit falhou por falta de identidade → configurou nome e e-mail noreply.
O push falhou 2x: primeiro por causa do commit ausente (`src refspec`), depois
por falta do escopo `workflow` no token (bloqueio dos 7 arquivos de CI).
Usuário pediu "opção A" (dar escopo ao token) mas executou o comando da "opção B"
(ignorar workflows); agente avisou, seguiu com a B e documentou. Pushing concluído:
branch `main` criada no GitHub com 3 commits. Confirmado via API.
Pendente: `credential.helper` para não pedir token a cada push.

### S2 — 2026-10-04 15:28→15:41
Recuperou o contexto de `~/PROJETO NOMAD 1.txt` (única memória da S1).
Verificou o sistema: Docker ausente, `/opt/project-nomad` inexistente, 337 GB livres,
RTX 3060 presente. Analisou o `install_nomad.sh` e confirmou os 2 prompts e a
viabilidade do pipe. Descobriu o driver NVIDIA descarregado.
Usuário escolheu rodar via pipe. Entregou o comando com `tee` para log.
Pediu registro permanente em `status.md` + `memoria.md` e_PASSou_ o repositório
pessoal (vazio) como destino das atualizações.

---

## 8. Decisões

1. **Opção 1 (instalador), não download em lote.** O painel gerencia os downloads
   pesados com barra de progresso unificada; o download em lote via terminal seria
   500 GB–1 TB+ sem controle e sem Visibility. Decisão da S1, mantida.
2. **Nunca pedir senha nem segredo — nem token do GitHub.** Entregar comandos
   prontos pro usuário colar. Motivo: toda mensagem sai da máquina e vai para o
   servidor do provedor do modelo, e o histórico é gravado em
   `~/.local/share/opencode/log/opencode.log` e `~/.local/share/opencode/shell/<hash>/*.out`.
   Um token com escopo `repo` dá escrita em todos os repositórios do usuário.
   Para push, **o usuário roda o comando** — o agente não precisa do token.
   Se colar por engano: orientar a revogar em https://github.com/settings/tokens
   e não pedir o valor.
3. **Logar tudo com `tee`.** Lição da queda de energia da S1.
4. **`status.md` reescreve, `memoria.md` só acumula.** Separa "agora" de "sempre".
   Facilita o commit no GitHub sem diff confuso na memória.
5. **Manter o `.gitignore` do upstream ao popular o repo pessoal.** Protege credenciais.
6. **Nome do projeto: "WBC NOMAD".** Pasta local sem espaço (`WBC-NOMAD`) — GitHub
   converte espaço em hífen, e o terminal exige aspas em todo caminho com espaço.
   `/opt/project-nomad` **não** foi renomeado: é constante fixa do instalador
   upstream (`NOMAD_DIR`), mudar quebraria o NOMAD.
7. **Registrar tudo em `status.md` + `memoria.md`, versionados no GitHub.**
   O PC já desligou e perdeu contexto uma vez; registro em arquivo + repo remoto
   é a mitigação.
8. **Não versionar `.github/workflows/`.** O GitHub exigiria escopo `workflow` no
   token — poder de alterar CI é grande demais para um token de backup. Os
   arquivos seguem em disco, apenas fora do Git.

---

## 9. Glossário

| Termo | Significado |
|---|---|
| **ZIM** | Formato de arquivo da Kiwix — Wikipedia e outros sites empacotados para leitura offline |
| **Kiwix** | Projeto por trás dos ZIMs; `kiwix-serve` serve them como site local |
| **openZIM** | Hospedagem dos arquivos ZIM (mantém só os 2 builds mais novos por título) |
| **PMTiles** | Formato de mapas offline (`.pmtiles`), usado pelo `maps_controller` |
| **Easy Setup** | Assistente do painel que baixa recursos-heavy chosen pelo usuário |
| **Command Center** | Container principal: painel de gerenciamento em `:8080` |
| **Sidecar** | Containers auxiliares (disk-collector, updater) |
| **DKMS** | Sistema que recompila drivers de kernel; `dkms status` mostra o estado do driver NVIDIA |
| **MOK** | Machine Owner Key — chave que o SecureBoot confia para carregar módulosOwners |
| **Ollama** | Runtime local de LLMs; o NOMAD usa para o assistente de IA local |
| **AdonisJS** | Framework Node.js usado no backend `admin/` |

---

## 10. Referência de comandos

```bash
# instalar
printf 'y\ny\n' | sudo bash /home/wilson/WBC-NOMAD/install/install_nomad.sh 2>&1 | tee ~/nomad-install.log

# operar
/opt/project-nomad/start_nomad.sh
/opt/project-nomad/stop_nomad.sh
/opt/project-nomad/update_nomad.sh

# diagnosticar
systemctl status docker
docker compose version
docker ps -a
journalctl -u docker -n 50 --no-pager
sudo modprobe nvidia && nvidia-smi
dkms status

# disco
df -h / && du -sh /opt/project-nomad 2>/dev/null
```

---

## 11. Sessão 06/10/2026 — trazendo o NOMAD para o Windows

**Máquina:** Windows 11 Enterprise LTSC (build 26100), Ryzen 5 1400, 7,9 GB RAM
(livre ~1,5 GB), `G:` com 1,6 TB livres.
**Local:** `G:\WBC-NOMAD` (cópia solta — antes não tinha `.git`).
**Motivo:** o usuário rodou no Zorin e **não gostou** → quer Windows.

### O que foi feito

1. **Diagnóstico da cópia** — 659 arquivos, v1.35.0. Docker e WSL ausentes;
   portas 8080/9999 livres; `G:\WBC-NOMAD` **não era repo git**.
2. **`docker-compose.yml`** gerado de `install\management_compose.yaml` com os
   6 `replaceme` preenchidos (`APP_KEY` 32 hex, `URL=http://localhost:8080`,
   senhas 48 hex). Fica fora do git — o `.gitignore` (linhas 36-43) o exclui
   de propósito por conter senhas.
3. **`start.bat`** (3.731 bytes, ASCII): menu iniciar/parar/status/logs/painel/
   sair + 4 verificações de pré-requisito. Testado no caminho "Docker ausente".
4. **`manual.md`** — relato completo.
5. **git**: `git init -b windows`, remotes `origin` + `upstream`, fetch
   (`origin/main = adb390039a2ae14712f91279ef4bbeb42880ca37`), `git add -A`.
   Diff contra `origin/main` = **só `start.bat` e `manual.md`** → prova que a
   cópia é idêntica ao repo. **Commit pendente** (sem identidade git).
6. **Docker Desktop 4.94.0** instalado pelo usuário (CLI 29.8.2, Compose v5.5.1).

### O que travou

O engine não subia — `Docker Desktop is unable to start`. Log literal em
`%LOCALAPPDATA%\Docker\log\host\com.docker.backend.exe.log`:

```
engine linux/wsl failed to start: checking preconditions: Virtual Machine Platform not enabled
no virtualization found
```

- backend `"vm.hypervisor.windows":"wsl2"`; Hyper-V indisponível porque a
  instalação do Docker é *per-user*
- `HypervisorPresent: False`; `wsl.exe` reportava "não instalado"
- BIOS **já** com virtualização ativa (`VirtualizationFirmwareEnabled: True`, SLAT ok)

### Correção aplicada

Criado `ativar-wsl2.bat` (auto-eleva, grava `ativar-wsl2.log`) que roda:

```bat
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

Resultado: **as duas com exit 3010 = sucesso + reinício pendente**
("A operação foi concluída com êxito"). O script foi corrigido para tratar
3010 como sucesso.

### Próximo passo (após o reboot)

`start.bat` → `[1]` → baixa as imagens → painel `http://localhost:8080`.

### Lições desta sessão

- **DISM 3010 não é erro** — é "sucesso, precisa reiniciar".
- No Windows o `PATH` de um shell aberto fica defasado quando se instala algo
  novo: `git` e `docker` só aparecem depois de recarregar o PATH do registro
  ou abrir um prompt novo.
- RAM de 7,9 GB limita modelos de IA (mesmo achado do OpenCode desta máquina:
  usar `qwen2.5-coder:7b`, nunca o `14b`).
- Decisão de repo: **manter o mesmo repo**, branch `windows` (não criar repo novo).
---

## 12. Sessão 06/10/2026 (parte 2) — stack no ar no Windows

Após o reboot as duas features valeram: `wsl --status` ok, engine `wsl2`
ligou e o `start.bat` → `[1]` baixou as 6 imagens (4,22 GB) em ~1 minuto.

**Falhou só um container:**

```
Error response from daemon: path / is mounted on / but it is not a shared or slave mount
```

`nomad_disk_collector` ficava em `Created`.

### Causa e correção

O template oficial (Linux) usa, na linha 131:

```yaml
- /:/host:ro,rslave   # bind propagation: exige origem shared/slave
```

No **Docker Desktop com backend WSL2** a raiz `/` da VM é mount **`private`**,
então o daemon recusa `rslave`. No Linux nativo funciona; no Windows não.

Correção em `G:\WBC-NOMAD\docker-compose.yml`:

```yaml
- /:/host:ro            # era "ro,rslave"
```

Resultado: `Container nomad_disk_collector Started` e log
`disk-collector sidecar starting...`. Detalhe no `manual.md`, seção 12.

### Verificação final

```
nomad_admin            Up (healthy)   0.0.0.0:8080->8080
nomad_mysql            Up (healthy)   3306/tcp
nomad_redis            Up (healthy)   6379/tcp
nomad_updater          Up
nomad_dozzle           Up             0.0.0.0:9999->8080
nomad_disk_collector   Up

http://localhost:8080  ->  HTTP 200 (3.541 bytes)
```

### Números da primeira execução

| Métrica | Valor |
|---|---|
| Imagens Docker | 6 · 4,22 GB |
| Dados (`.vhdx`) | 5,67 GB — em **`C:`** (não em `G:`) |
| RAM da VM (limite) | 3,79 GB |
| RAM do NOMAD | ~1,15 GB (mysql 648 MB, admin 415 MB, dozzle 62 MB) |
| RAM livre da máquina | **0,82 GB** |
| Espaço C: / G: | 341 GB / 1.630 GB livres |

### Pendências

- commit na branch `windows` — tudo *staged*, falta `user.name` / `user.email`
- `ativar-wsl2.bat` ainda `??` (não *staged*)
- recursos ZIM/mapas e modelos Ollama: 0 baixados

### Lições desta parte

- **`bind propagation` (`rslave`) não funciona no Docker Desktop/WSL2** — é a
  diferença clássica entre template Linux e Windows.
- `docker-compose.yml` fica **fora do git** (senhas) → correções manuais
  precisam ser documentadas, ou se perdem ao regerar o arquivo.
- O storage do NOMAD vive na VM (disco `C:`), mesmo com o código em `G:`.
- Shell aberto antes de instalar programa novo não enxerga o binário: recarregar
  o PATH do registro (`Machine` + `User`) antes de chamar `git`/`docker`.
---

## 14. Sessão 06/10/2026 (parte 3) — ENOSPC derrubou o painel; migração para o disco

### O que aconteceu

Painel passou a exibir `Network Error`. Causa: **`ENOSPC: no space left on
device`** — o `nomad_admin` entrou em crash loop (24 reinícios) e a API caiu.

### Causa raiz

O template Linux manda **todos** os dados para `/opt/project-nomad/...`. No
Docker Desktop/WSL2 esse caminho **não** cai no disco de dados: cai no
rootfs overlay da VM, cujo *upperdir* é um **tmpfs de 1,9 GB (RAM)**.

```
none      1.9G  1.9G  12.8M   99%  /run        ← MySQL + storage aqui
/dev/sdf  1006.9G  5.4G  950.2G   1%  /var/lib   ← disco real, ignorado
```

190 MB (MySQL) + 1,7 GB (storage) = o tacho encheu. Efeitos:
- `.zim.tmp` de **0 bytes** (toda escrita falhava)
- Redis não conseguia gravar RDB → `MISCONF`
- **Dado se perderia em qualquer restart da VM**

### Migração executada

1. `docker compose stop`
2. `docker run --rm ... mysql:8.0 -c "cp -a /src/. /dst/"` → `/opt/project-nomad` → **`/var/lib/nomad`**
3. Troca de **7 ocorrências** no `docker-compose.yml`:
   `/opt/project-nomad` → `/var/lib/nomad` (admin, `NOMAD_STORAGE_PATH`,
   mysql, redis, updater ×2, disk-collector)
4. `docker compose up -d` → 6/6, admin **healthy, 0 reinícios**
5. `rm -rf /old/*` no tacho antigo

### Resultado

| | Antes | Depois |
|---|---|---|
| Filesystem dos dados | `overlay 1.9G` **100%** (RAM) | `/dev/sdf 1006.9G` **1%** |
| Livre | **0 bytes** | **948,3 GB** |
| `/run` | 1,9 GB usado | **476 KB** (+1,9 GB de RAM) |
| Painel | Network Error | HTTP 200 |

Detalhamento no `manual.md`, seção 13.

### Lições

- **`df` de cada mount** antes de suspeitar do disco do Windows — o `C:` estava
  com 341 GB livres o tempo todo.
- "Network Error" genérico no front = **olhar `docker logs nomad_admin`**.
- No Docker Desktop/WSL2, dados de serviço só são seguros em
  `/var/lib/docker/...` ou em pasta do Windows compartilhada.
- `docker run` + `sh -c` com **aspas duplas dentro de string do PowerShell** é
  frágil (o PowerShell as remove ao repassar ao docker) → usar script **sem
  aspas**, só `;`.
---

## 15. Sessão 06/10/2026 (parte 4) — disco para o `G:`: cópia ok, migração bloqueada

### O que foi pedido

"sim pode atacar" — mover o `docker_data.vhdx` (198,84 GB) do `C:` para o `G:`.
Ao concluir a cópia, atualizar `status.md`, `memoria.md` e `manual.md`.

### Etapa que deu certo: a cópia

`robocopy /E /J` de `C:\Users\User\AppData\Local\Docker\wsl` para
`G:\Local\Docker\Wsl\DockerDesktopWSL` — 39 min, ~85 MB/s.
Verificação byte a byte: **`213467004928` dos dois lados, IDÊNTICO**.
O robocopy foi interrompido antes do `main\ext4.vhdx` (100 MB), copiado à parte.

### As 3 tentativas de trocar o caminho — todas falharam

| # | Estratégia | Resultado |
|---|---|---|
| A | **Junction** `wsl` → `G:\...` | ❌ `0x800701c0` — *"caminho não pode ser atravessado porque contém um ponto de montagem não confiável"* |
| B | **Chave `vm.resources.wslDataFolder`** no `settings-store.json` | ❌ lida, **revertida em 1 s** → *"neither WSL2 data distro nor disk exist"* → **formatou disco novo vazio** |
| C | **GUI** (Disk image location) | ❌ nas 2 execuções anteriores o backend morriu pós-robocopy (`exit 0x40010004`) e a setting não persistiu |

### Recuperação executada

Com a stack morta (0 containers, disco formatado de 1,6 GB), restaurou-se:

1. Fechar Docker + `wsl --shutdown`
2. `wsl` (formatado) → `wsl_fresco`; **`wsl.old` (original 198,9 GB) → `wsl`**
3. `settings-store.json` restaurado do backup `settings-store.json.bak_20261006_175843`
4. Relançar → **23 containers, painel HTTP 200, engine v29.8.2** ✅

A cópia do `G:` foi **mantida** — é o backup rápido e a base pra próxima tentativa.

### Descobertas desta parte

- **O WSL não monta VHDX através de junction/symlink.** Só caminho real conta.
- **`vm.resources.wslDataFolder` não é gravável via arquivo** — o Docker Desktop
  4.94 lê a chave e a ignora. O único caminho é a GUI.
- **Se a pasta default do Docker não existir, ele formata um disco novo** em vez
  de dar erro. Perda silenciosa de contexto (0 containers) — por isso sempre
  manter `wsl.old` até confirmar que tudo subiu.
- **Robocopy interrompido não retoma o arquivo no meio** — recompia do zero.
- `docker desktop` CLI **não tem** subcomando de settings (só `start/stop/restart/
  status/diagnose/logs/update/enable/disable/engine/kubernetes`).
- O backend do Docker Desktop **escuta as portas dos containers** (`:8080`,
  `:9999`, `:6333`…) — ele é o encaminhador; por isso a queda dele derruba
  tudo junto.

### Também registrado nesta parte (ver `manual.md` §15)

- **`localhost` morto pelo `wslrelay`**: `[::1]:8080` aceitava TCP e não
  respondia; `127.0.0.1` funcionava. Correção: `Stop-Process -Name wslrelay`.
- **3 episódios de `no route to host`** na VM no mesmo dia → `wsl --shutdown`
  + relançar limpo.
- **Downloads retomados**: DNS consertado, fila `downloads` zerada (46 ZIMs),
  4 jobs RAG falhos limpos + **37 re-enfileirados** com `POST /api/rag/sync`.
- **GPU confirmada** no `nomad_ollama` (`CUDA0`, DeviceRequests nvidia).
---

## 16. Sessão 06/10/2026 (parte 5) — ✅ disco migrado para o `G:`

### Resultado

```
C:\Users\User\AppData\Local\Docker\wsl   →  G:\Local\Docker\Wsl\DockerDesktopWSL
C: livre: 131,5 GB → 327,9 GB  (+196,4 GB)
23 containers · painel HTTP 200 · /app/storage 197 GB usados / 760 GB livres
```

`settings-store.json` ganhou `"CustomWslDistroDir": "G:\\Local\\Docker\\Wsl\\DockerDesktopWSL"`.

### A causa raiz do "bug" do Browse — não era bug

O diálogo de pasta **abria já dentro de `G:\Local\Docker\Wsl\DockerDesktopWSL`**
(e da `Wsl`, no caso da cópia de 17:49) e **pré-selecionava** a subpasta. Como o
Docker **acrescenta `\DockerDesktopWSL`** ao item selecionado, o campo final
saiu **sempre duplicado** (`...\DockerDesktopWSL\DockerDesktopWSL`) — 4 tentativas,
um restart, tudo igual. O usuário diagnosticou "é bug"; na verdade era pasta
pré-selecionada.

**Correção:** renomear a cópia para fora (`backup_copia_1749`, um nível acima),
deixando `Wsl` **vazia**. Aí o `Pasta:` mostrou `Wsl` e o caminho saiu certo.

### O que eu errei (e o log denunciou)

- Editei `settings-store.json` com **`vm.resources.wslDataFolder`** →
  `[settingsstore][W] unknown settings found: ...` → **ignorado**.
  Essa é a chave **interna/IPC** que aparece no log. A do arquivo é
  **`CustomWslDistroDir`**.
- Conclusão apressada de que "só a GUI serve" estava **errada**.

### Cronograma real da migração

| Hora | Evento |
|---|---|
| 18:46:21 | `appmanager: moving WSL data ... to G:\...\DockerDesktopWSL` + `robocopy /MOV /J /R:0` |
| 18:46:21 | `unregistering docker-desktop` (a distro é desregistrada → o `main\ext4.vhdx` some) |
| 18:51:14 | GUI: `found changes: true, restart needed: true` → toast **`Failed to apply settings`** |
| 18:46→19:17 | robocopy roda **26 min** a **111 MB/s** (medido por `WriteTransferCount`) |
| 19:17:25 | robocopy sai; origem `C:` esvaziada (`/MOV`) |
| 19:18:21 | Docker **recria** `main\ext4.vhdx` (96 MB) |
| 19:22:29 | engine v29.8.2 |
| 19:22:33 | **23 containers** |
| 19:23:20 | painel HTTP 200 · disco em `G:` gravando |

### Aprendizados

- **`Failed to apply settings` = timeout de 5 min do GUI, não falha da cópia.**
  Interromper ali mata a migração (e o robocopy `/MOV` já apagou parte da origem).
- **`/MOV`**: o robocopy da GUI **move**, não copia — a origem some no fim.
  Enquanto roda, os dois lados existem; só no fim o `C:` é liberado.
- **O robocopy pré-aloca o arquivo inteiro de cara** — o tamanho do destino
  alcança 198 GB em ~10 s. Progresso real só se mede pelo **I/O do processo**.
- **`main\ext4.vhdx` sumir é esperado**: é o SO da VM; a distro é desregistrada
  no move e recriada depois. **Os dados** (containers, imagens, 130 GB de mapas,
  39 GB de ZIMs) estão em `docker_data.vhdx` (`/var/lib`).
- **Deixar uma subpasta com o mesmo nome que o Docker acrescenta faz o Browse
  duplicar o caminho.** Deixar a pasta destino vazia resolve.
- `nomad_ollama` e `nomad_stirling_pdf` levam ~1–3 min pra ficar `healthy` após
  o restart — não é falha da migração.
- **Backup:** `G:\Local\Docker\backup_copia_1749` (198,9 GB, snapshot de 17:49
  com `disk` + `main`) foi mantido durante a validação e **apagado em 19:35**
  após confirmar 23 containers + painel 200 + storage 197 GB → `G:` voltou a
  **1393 GB livres**.

### Pendências remanescentes

1. Commit na branch `windows` (identidade pronta, nunca executado)
2. Baixar a Wikipédia PT (19,22 GB) + Information Library
3. Considerar `AutoStart: true` (hoje `false` → Docker não sobe no boot)

---

## 17. Sessão 06/10/2026 (parte 6) — travamento da API, GPU e a documentação

### O que foi feito

| Hora | O quê |
|---|---|
| ~20:00 | `iniciar-nomad.bat` criado (clique duplo: Docker → engine → 23 containers → painel → navegador) |
| 20:05 | **API do Docker começou a degradar** — 2º `docker exec` de uma linha já voltou `500 Internal Server Error` |
| 20:19–20:33 | Tentativas de baixar o ZIM por dentro do container (`exec -d`, `nohup`) **travaram** |
| 20:35 | Painel 8080 e Dozzle 9999 pararam de responder; Kiwix 8090 e Qdrant 6333 seguiam OK |
| 21:13 | `docker desktop stop` + `wsl --shutdown` (11 s) |
| 21:14 | Relançamento pelo AppID → engine na 2ª tentativa, **23 containers na 1ª** |
| 21:19 | Download da Wikipédia PT iniciado **dentro do `nomad_admin`** (`curl -C -`) |
| 21:25 | **Content Explorer voltou** (500 sumiu) |
| 21:31 | **GPU consertada** com `docker restart nomad_ollama` → `CUDA0` na RTX 3060 |
| 21:00–22:00 | `manual.md` ganhou **§16 (problemas + soluções), §17 (guia do usuário), §18 (runbook do admin)** |
| ~21:50 | **§19 escrito** — como subir o NOMAD no **Linux** e no **Windows**, lado a lado |

### O problema mais perigoso: a API do Docker travar

**Sintoma fácil de confundir:** `docker desktop status` respondia `running` e as
**portas aceitavam TCP** — parecia tudo certo. Mas:

- `docker ps` / `docker exec` **penduravam para sempre** (60–90 s sem retorno)
- `curl` para `127.0.0.1:8080` conectava e **nunca respondia**
- no log: `500 Internal Server Error ... pipe/dockerDesktopLinuxEngine`

**A lição:** o pipe entre CLI e engine pode morrer **com as containers vivas**.
O diagnóstico correto é **rodar `docker num job com timeout`** — rodar `docker ps`
solto trava o shell junto.

**Tempos medidos:** `stop` ~45 s · `wsl --shutdown` 11 s · engine ~25 s ·
containers imediatos · painel de volta em **~4 min no total**.

### O 500 do Content Explorer: era Redis com IP antigo

```
connect ECONNREFUSED 172.18.0.18:6379   ← admin queria esse IP
/nomad_redis -> 172.18.0.20 | healthy   ← o Redis estava aqui
```

O `nomad_admin` subiu **antes** do Redis, cacheou o IP e nunca mais acertou.
**Não precisei reiniciar nada**: depois do restart brusco do Docker, na subida
limpa o admin resolveu o DNS certo e o `ECONNREFUSED` **sumiu sozinho**.
`nomad_admin` saiu de `unhealthy` para **healthy** e a lista do Content
Explorer voltou a carregar.

> 📌 Por isso o download **não** foi reiniciado: como ele roda dentro do
> `nomad_admin`, reiniciar o container mataria o `curl`. O alinhamento certo é
> **consertar tudo e só depois reiniciar o admin** — e nessa noite deu pra
> resolver sem tocar nele.

### A GPU: não era driver, era o watchdog estourando

O sintoma assusta (`NVIDIA GPU expected but Ollama reported a CPU-only backend`)
mas o `docker exec nomad_ollama nvidia-smi` **já mostrava a RTX 3060**. A causa
real:

```
llama-server GPU discovery watchdog timed out
OLLAMA_LIBRARY_PATH=[/usr/lib/ollama /usr/lib/ollama/cuda_v12]
error="context deadline exceeded"
```

Tentou `cuda_v12`, estourou; tentou `cuda_v13`, estourou; concluiu "CPU-only".
Gatilho: **RAM com 1,2 GB livre de 7,9 GB (85%)**. Um `docker restart
nomad_ollama` bastou:

```
compute=8.6 name=CUDA0 description="NVIDIA GeForce RTX 3060" libdirs=ollama,cuda_v13 driver=13.4
```

### Descoberta de arquitetura: são DOIS projetos compose

`docker compose ls` mostrava só `running(6)` — e não era erro. Existem dois:

| Projeto | Criado por | Qtd |
|---|---|---|
| `project-nomad` | o `G:\WBC-NOMAD\docker-compose.yml` | 6 (`admin`, `dozzle`, `mysql`, `redis`, `updater`, `disk-collector`) |
| `project-nomad-managed` | o **próprio `nomad_admin`** em runtime | 17 (`ollama`, `kiwix_server`, `jellyfin`, `cyberchef`…) |

Prova: `docker inspect nomad_ollama` → `com.docker.compose.project =
project-nomad-managed`, `io.project-nomad.managed = true`.

**Por isso `ollama` não estava no YAML.** E por isso `docker compose restart`
**não** reinicia o Ollama — para a GPU é `docker restart nomad_ollama`.

### Decisões desta parte

1. **`AutoStart: false` mantido** — 3 GB de RAM que a máquina não tem.
2. **Download da Wikipédia PT ficou "por trás dos panos"** (curl no container) a
   pedido do usuário: ele preferiu não perder os GB já baixados a trocar pelo
   botão da interface, que apareceria em *Active Downloads* mas **recomeçaria do
   zero**.
3. **`iniciar-nomad.bat`** normalizado para **CRLF + ASCII puro**, junto com
   `start.bat` e `ativar-wsl2.bat` (estavam com LF) — conteúdo byte-idêntico.

### Lições

- **`Active Downloads` só mostra o que foi disparado pela interface.** Um
  `curl` solto no volume baixa igual, mas o NOMAD não sabe que ele existe.
- **Antes de reiniciar `nomad_admin`, verifique se tem `.part` em andamento.**
- **RAM no talo é o gatilho de quase tudo nesta máquina** — olhar
  `Get-CimInstance Win32_OperatingSystem` antes de culpar Docker ou GPU.
- Dois projetos compose explicam "container que some do meu YAML".
- A `.md` dos três arquivos seguiu **UTF-8 sem BOM, 0 caracteres de controle, LF**.
- **Linux e Windows são o mesmo projeto**, com caminhos de dados diferentes:
  no Linux `/opt/project-nomad` é *bind mount* visível no host; no Windows tudo
  está **dentro do `docker_data.vhdx`** e só se enxerga via `docker exec`.
  Documentado no `manual.md` §19 junto com os atalhos de cada sistema
  (`start_nomad.sh` / `stop_nomad.sh` / `update_nomad.sh` ×
  `iniciar-nomad.bat` / `start.bat`).