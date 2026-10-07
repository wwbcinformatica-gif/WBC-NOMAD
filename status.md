# STATUS — WBC NOMAD

> Snapshot do estado atual. Atualizado a cada sessão.
> Memória acumulada e histórico: [memoria.md](./memoria.md)
> Relato completo no Windows: [manual.md](./manual.md)

**Última atualização:** 2026-10-06 (parte 7) — ✅ **STACK 100%** · 🔄 **Wikipédia PT baixando** · 🆕 **§16–§19 do manual escritos** (§19 = subir no **Linux e no Windows**)
**Máquina:** `DESKTOP-9HVGSQB` — Windows 11 Enterprise LTSC (build 26100), AMD Ryzen 5 1400, 7,9 GB RAM
**Local:** `G:\WBC-NOMAD`
**Versão:** 1.35.1

> 🆕 **Tudo que é problema + solução agora está no `manual.md` §16–§19:**
> - **§16** = tabela de problemas com sintoma → causa → solução (§16.1 é a tabela rápida)
> - **§17** = guia de quem **só usa** o NOMAD (sem terminal)
> - **§18** = runbook de quem **administra** (diagnóstico + recuperação de emergência)
> - **§19** = **como subir o NOMAD em Linux e em Windows**, lado a lado

---

## Resumo

O Project NOMAD **roda no Windows**. Painel `http://localhost:8080` → **HTTP 200**, **23 containers**, engine `29.8.2`.

**Dois bugs do template Linux corrigidos** (detalhe em [manual.md](./manual.md)):

| # | Bug | Correção | Seção |
|---|---|---|---|
| 1 | `/:/host:ro,rslave` recusado pelo WSL2 | trocar por `/:/host:ro` | §12 |
| 2 | **`ENOSPC`** — dados num tmpfs de 1,9 GB **na RAM** | migrar `/opt/project-nomad` → **`/var/lib/nomad`** | §13 |
| 3 | `localhost` morto pelo `wslrelay` (IPv6) | `Stop-Process -Name wslrelay` | §15 |
| 4 | Disco em `C:` (198,85 GB) | **✅ migrado para `G:` — `C:` ganhou 196 GB** | §14 |

### Pendências
1. ~~Apagar `G:\Local\Docker\backup_copia_1749`~~ — ✅ **feito** (198,9 GB liberados)
2. 🔄 Baixar **Wikipédia PT** `wikipedia_pt_all_maxi_2026-05.zim` — **19,22 GB** — *em andamento* (22:08 → **3,28 GB = 17,1%**)
   - destino: `/app/storage/zim/wikipedia_pt_all_maxi_2026-05.zim.part`
   - ~1,2 MB/s → **ETA ~3,7 h**; retomável com `curl -C -`
   - ⛔ **não reiniciar `nomad_admin` enquanto baixa** (mata o `curl`) — ver `manual.md` §16.3
   - 👀 um monitor em background vigia e avisa ao concluir (ou se parar 15 min)
3. 🔧 **APÓS o download:** `docker restart nomad_admin` — o `ECONNREFUSED` do Redis **já sumiu sozinho** e o Content Explorer **já está OK**, mas o restart deixa o cache 100% limpo — `manual.md` §18.5
4. 🔧 Limpar `.zim.tmp` de 0 byte em `/app/storage/zim` — `manual.md` §18.6
5. ~~Commit na branch `windows`~~ — ✅ **`01be6f4`** (6 arquivos, 2660 linhas; `docker-compose.yml` fora)
6. ⏸️ Push para `origin` — **adiado pelo usuário**; sem credencial salva nesta máquina
   - fazer pelo **Git Bash** ou **Git CMD**: `cd G:\WBC-NOMAD` → `git push -u origin windows`
   - o Git Credential Manager abre a janela do GitHub pra autorizar
7. Instalar **Information Library** (Kiwix) → *Supply Depot*
8. Considerar `AutoStart: true` — hoje `false`, o Docker não sobe no boot

---

## Componentes

| Componente | Status | Detalhe |
|---|---|---|
| Código-fonte | ✅ OK | 659 arquivos + `start.bat`, `manual.md`, `ativar-wsl2.bat` |
| Branch | 🌿 `windows` | tudo *staged*; `docker-compose.yml` **fora** do git (senhas) |
| Commit | ⬜ Pendente | identidade **pronta** (`Wilson Barbosa Coimbra`); `git commit` nunca executado |
| Docker Desktop | ✅ OK | 4.94.0 · CLI 29.8.2 · Compose v5.5.1 |
| Engine | ✅ OK | `wsl2` · **v29.8.2** |
| **Stack** | ✅ **NO AR** | **23 containers** · `nomad_admin` **healthy** |
| **Painel `:8080`** | ✅ **HTTP 200** | testar com `127.0.0.1` (ver aviso 5 ↓) |
| Dozzle `:9999` | ✅ OK | logs |
| **Storage / MySQL / Redis** | ✅ **NO DISCO** | `/var/lib/nomad` — ver aviso ↓ |
| ENOSPC / crash loop | ✅ **RESOLVIDO** | era 24 reinícios; agora **nenhum** no log |
| `rslave` do disk-collector | ✅ Corrigido | §12 |
| **GPU (RTX 3060)** | ✅ **FUNCIONANDO** | `CUDA0` na descoberta; **regrediu p/ CPU após restart brusco → `docker restart nomad_ollama` consertou** (§16.8) |
| **AI Assistant / Ollama** | ✅ **INSTALADO** | `nomad_ollama` · `ollama/ollama:0.33.3` · `nomic-embed-text:v1.5` · API `http=200` |
| 🆕 **API do Docker (21:14)** | ✅ **RESTAURADA** | travava (`docker ps` pendurado) → `docker desktop stop` + `wsl --shutdown` + AppID · 4 min (§18.4) |
| 🆕 **Redis / Content Explorer** | ✅ **CONSERTEI** | `ECONNREFUSED` sumiu sozinho após restart · `nomad_admin` **healthy** · 500 sumiu |
| 🆕 **Arquitetura compose** | ℹ️ 2 projetos | `project-nomad` (6, seu YAML) + `project-nomad-managed` (17, criados pelo NOMAD) — §18.8 |
| **Downloads (Kiwix)** | ✅ **CONCLUÍDOS** | fila `downloads` zerada · **46 ZIMs** · DNS ok |
| **RAG / embeddings** | 🔄 Em fila | 4 falhos limpos · **37 re-enfileirados** (`/api/rag/sync`) |
| **Disco do Docker** | ✅ **NO `G:`** | `G:\Local\Docker\Wsl\DockerDesktopWSL` · 198,85 GB · `CustomWslDistroDir` gravada · `C:` **+196 GB** |
| App **Information Library** (Kiwix) | ⬜ Pendente | Supply Depot → instalar |
| Wikipédia PT | ⬜ Pendente | 19,22 GB, `q=portugues` no catálogo |
| Modelos Ollama (host) | ⚠️ | 16,3 GB em `C:\Users\User\.ollama\models` |

**Bloqueadores: nenhum** — a stack está de pé e funcional.

---

## ⚠️ Avisos operacionais

### 1. ONDE FICAM OS DADOS (não mexer sem ler)

| | Caminho | Filesystem | Livre |
|---|---|---|---|
| ❌ **ANTES (bug)** | `/opt/project-nomad` | **tmpfs 1,9 GB (RAM)** | **0 bytes** → ENOSPC |
| ✅ **AGORA** | **`/var/lib/nomad`** | `/dev/sdf` = `docker_data.vhdx` (ext4) | **948,3 GB** |

`
admin:          /var/lib/nomad/storage -> /app/storage
mysql:          /var/lib/nomad/mysql   -> /var/lib/mysql
redis:          /var/lib/nomad/redis   -> /data
updater:        /var/lib/nomad         -> /var/lib/nomad
disk-collector: /var/lib/nomad/storage -> /storage
NOMAD_STORAGE_PATH = /var/lib/nomad/storage   ← tem de bater igual
`

> 🔴 **Nunca voltar para `/opt/project-nomad`.** No Docker Desktop/WSL2 esse
> caminho cai no rootfs overlay da VM, cujo *upperdir* é tmpfs de 1,9 GB na RAM:
> enche rápido, dá `ENOSPC` e **some em todo restart da VM**.

### 2. Se regerar o `docker-compose.yml`
O arquivo **não entra no git** (contém senhas). Se vier de novo de
`install\management_compose.yaml`, **reaplicar as 2 correções**:
- §12 → `/:/host:ro` (sem `rslave`)
- §13 → os 7 caminhos `/opt/project-nomad` → `/var/lib/nomad`

### 3. RAM — 7,9 GB no total
VM limitada a **3,79 GB**; NOMAD ~1,15 GB. Livre após a migração: **+1,9 GB**
(o tacho de RAM foi esvaziado). Ainda assim: **nunca rode Ollama com modelo
carregado junto com o NOMAD** → `ollama stop` antes.

### 4. Dados do Docker — onde estão hoje
**No `G:`** — `G:\Local\Docker\Wsl\DockerDesktopWSL\disk\docker_data.vhdx`
(**198,85 GB**). O `C:` ficou com **327,9 GB livres** (+196 GB).

Configuração que mantém isso (em `%APPDATA%\Docker\settings-store.json`):

```json
"CustomWslDistroDir": "G:\\Local\\Docker\\Wsl\\DockerDesktopWSL"
```

> ⚠️ **Não mexer nessa chave nem apagar a pasta.** Se voltar pro `C:`, ver
> [manual.md](./manual.md) §14 (procedimento e "o que NÃO fazer").
>
> ✅ O backup `G:\Local\Docker\backup_copia_1749` (198,9 GB) foi **apagado** após
> a validação (23 containers, painel 200, storage 197 GB) — `G:` está com
> **1393 GB livres**.

### 5. `localhost` não responde mas o container está de pé
Quase sempre é o **`wslrelay.exe`** preso em `[::1]:8080` (aceita TCP e não
responde). O `localhost` do Windows tenta IPv6 primeiro e dá timeout.

```powershell
# diagnosticar: se 127.0.0.1 responder e localhost não, é isso
Invoke-WebRequest http://127.0.0.1:8080 -TimeoutSec 10
Stop-Process -Name wslrelay -Force      # some até o próximo wsl --shutdown
```

### 6. Docker não sobe / `no route to host` na VM
Sintoma: `docker version` e `wsl -d docker-desktop` em timeout, log com
`connect tcp 192.168.65.7:2376: no route to host`. Correção:

```powershell
# fechar Docker Desktop, depois:
wsl --shutdown
# e relançar PELO APPID (o exe direto falha com "no argument received")
$a = Get-StartApps | Where-Object Name -match 'Docker'
Start-Process explorer.exe -ArgumentList "shell:AppsFolder\$($a.AppID)"
```

---

## Wikipédia PT — onde buscar

- Seção **"Wikipedia"** do Content Explorer = **só inglês** (`collections/wikipedia.json`)
- **Certo:** Content Explorer → **Browse the Kiwix Library** → busca **`portugues`**
- API: `/api/zim/list-remote?query=portugues` (usa `q=` + `lang=por`)

| Arquivo | Tamanho |
|---|---|
| `wikipedia_pt_top_mini_2026-07` | 160 MB |
| `wikipedia_pt_all_mini_2026-05` | 1,59 GB |
| `wikipedia_pt_top_maxi_2026-07` | 3,29 GB |
| `wikipedia_pt_all_nopic_2026-05` | 6,59 GB |
| **`wikipedia_pt_all_maxi_2026-05`** | **19,22 GB** ← escolhido |

---

## Operação do dia a dia

**LIGAR — dia a dia (clique duplo):**

```bat
G:\WBC-NOMAD\iniciar-nomad.bat
   abre o Docker Desktop -> espera o engine -> espera os containers
   -> confere o painel -> abre o navegador
   (testado hoje: 23 containers, HTTP 200, ~1 min com tudo pronto)
```

**GERENCIAR — menu completo:**

```bat
G:\WBC-NOMAD\start.bat
   [1] Iniciar   [2] Parar    [3] Status
   [4] Logs      [5] Painel   [6] Sair
```

**DESLIGAR** (libera ~3 GB de RAM): `docker desktop stop`

> `AutoStart` está **`false`** — o Docker **não** sobe sozinho no login, de
> propósito: ele consome ~3 GB dos 7,92 GB de RAM e o `C:` vai ser usado pra
> outros projetos. Se preferir automático: Settings → General →
> *Start Docker Desktop when you sign in*.

| Item | Valor |
|---|---|
| **Ligar tudo** | `G:\WBC-NOMAD\iniciar-nomad.bat` (clique duplo) |
| Gerenciar / parar stack | `G:\WBC-NOMAD\start.bat` (menu) |
| Painel | `http://localhost:8080` |
| Logs (Dozzle) | `http://localhost:9999` |
| Information Library | `http://localhost:8090` (após instalar) |
| Compose | `G:\WBC-NOMAD\docker-compose.yml` (fora do git) |
| Correções manuais | `manual.md` §12 (rslave) + §13 (ENOSPC) + §14 (disco `G:`) + §15 (`wslrelay`) |
| Problemas + soluções | `manual.md` §16 (tabela dos 18 problemas) + §17 (usuário) + §18 (admin) |
| **Subir no Linux / Windows** | `manual.md` **§19** |
| `origin/main` | `adb390039a2ae14712f91279ef4bbeb42880ca37` |
| Repo pessoal | `wwbcinformatica-gif/WBC-NOMAD` (público) |
| Upstream | `Crosstalk-Solutions/project-nomad` |