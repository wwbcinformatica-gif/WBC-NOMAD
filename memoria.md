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

### `git` ausente no sistema
Ubuntu sem pacote `git`. `sudo apt-get install -y git` resolve.
Impacto: projeto foi baixado em ZIP (Python `urllib` + `zipfile`), sem `.git`,
sem histórico, sem `git pull`. Atualizações vêm pelo `update_nomad.sh`, que
baixa do GitHub — funciona mesmo sem `git` local.

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
