# Manual — Project NOMAD no Windows (`G:\WBC-NOMAD`)

> **Relato completo** do trabalho para trazer o Project NOMAD para rodar no Windows.
> Criado em 06/10/2026.
> Arquivos citados: `G:\WBC-NOMAD`.

---

## 1. O que é o Project NOMAD

Servidor de conhecimento e educação **offline-first**, da Crosstalk Solutions
(Licença Apache 2.0). **Versão desta cópia: 1.35.0** (igual à release upstream).

Funciona assim: um painel web chamado **Command Center** (o "admin") orquestra
uma série de containers Docker. O usuário só acessa pelo navegador.

| Componente | Tecnologia |
|---|---|
| Command Center (admin) | AdonisJS 6 + Inertia/React + Vite/Tailwind (TypeScript) |
| Banco de dados | MySQL 8.0 |
| Cache / filas | Redis 7 (BullMQ) |
| Logs | Dozzle |
| Sidecars | updater, disk-collector |
| IA | Ollama + Qdrant (RAG) |
| Biblioteca offline | Kiwix (ZIM) |
| Educação | Kolibri · Mapas: ProtoMaps · Notas: FlatNotes |

**Importante:** o projeto roda **containers Linux**. No Windows isso só funciona
com Docker (que usa WSL2 por baixo). Não existe versão "nativa" Windows do app.

---

## 2. Histórico deste projeto

| Quando | Máquina | Situação |
|---|---|---|
| até 04/10/2026 | Zorin OS (Linux), `/home/wilson/WBC-NOMAD` | Código completo. **Instalação nunca executada** (Docker faltava e `sudo` pedia senha). Repo pessoal `wwbcinformatica-gif/WBC-NOMAD` sincronizado com o upstream. |
| 06/10/2026 | Windows, `G:\WBC-NOMAD` | Usuário rodou no Zorin e **não gostou** → decidiu trazer para o Windows. |

### O que ficou registrado no `status.md` da máquina Linux
- Docker ausente, Docker Compose v2 ausente, `/opt/project-nomad` nunca criado
- Nenhum recurso (ZIM/mapas) e nenhum modelo Ollama baixados
- Driver NVIDIA quebrado — **não bloqueava** o NOMAD (o instalador só avisa)
- Próximo passo deles era: `printf 'y\ny\n' | sudo bash install/install_nomad.sh`

Ou seja: mesmo no Linux o NOMAD **nunca chegou a subir**. A instalação do
Windows não está "perdendo" nada que já existisse.

---

## 3. Estado atual de `G:\WBC-NOMAD`

| Item | Situação |
|---|---|
| Código-fonte | ✅ completo, 659 arquivos, v1.35.0 |
| **É um repo git?** | ❌ **Não** — não tem `.git`, é uma cópia solta |
| `admin/` | ✅ app AdonisJS (sem `node_modules` — só `package.json`) |
| `install/` | ✅ template do compose + scripts `.sh` + 2 ZIMs de teste (~4,5 MB) |
| **Docker** | ❌ **não instalado** |
| **WSL** | ❌ **não instalado** |
| Porta 8080 (painel) | ✅ livre |
| Porta 9999 (Dozzle) | ✅ livre |
| Disco | ✅ `G:` com **1.648 GB** livres |

---

## 4. O que foi criado nesta sessão

### 4.1 `docker-compose.yml` (arquivo novo, na raiz)

Gerado a partir do template oficial `install\management_compose.yaml`,
com os 6 placeholders `replaceme` preenchidos:

| Variável | Valor colocado |
|---|---|
| `APP_KEY` | 32 caracteres hexadecimais aleatórios (mínimo exigido: 16, senão o admin não sobe) |
| `URL` | `http://localhost:8080` |
| `DB_PASSWORD` | 48 caracteres hexadecimais aleatórios |
| `MYSQL_PASSWORD` | igual ao `DB_PASSWORD` (tem que bater) |
| `MYSQL_ROOT_PASSWORD` | `DB_PASSWORD` + `_root` |
| 1 `replaceme` restante | está **num comentário** — é só documentação, não afeta nada |

> ⚠️ **As senhas não estão escritas neste manual de propósito.**
> Elas estão apenas em `docker-compose.yml`.

**Serviços que esse arquivo sobe:**

| Container | Porta | Imagem |
|---|---|---|
| `nomad_admin` | 8080 | `ghcr.io/crosstalk-solutions/project-nomad:latest` |
| `nomad_dozzle` | 9999 | `amir20/dozzle:v10.0` |
| `nomad_mysql` | — | `mysql:8.0` |
| `nomad_redis` | — | `redis:7-alpine` |
| `nomad_updater` | — | sidecar updater |
| `nomad_disk_collector` | — | sidecar disco |

> ⚠️ **Esse arquivo não pode ser commitado.** O `.gitignore` já o exclui de
> propósito (linhas 36–43), porque contém senhas reais e a `APP_KEY`.
> O único compose que pertence ao git é o template `install/management_compose.yaml`.

---

### 4.2 `start.bat` (arquivo novo, na raiz)

**3.731 bytes, ASCII puro** (sem acentos/emoji — para não quebrar no `cmd`).

**Menu:**

```
============================================
       Project NOMAD - Windows
============================================

  [1] Iniciar NOMAD          docker compose up -d + abre o painel
  [2] Parar NOMAD            docker compose stop
  [3] Status dos containers  docker compose ps
  [4] Logs do painel         logs -f do admin (Ctrl+C volta)
  [5] Abrir painel           http://localhost:8080
  [6] Sair
```

**Verificações que ele faz antes de qualquer coisa** (nesta ordem):

1. `docker` existe no PATH?
2. o daemon do Docker responde (`docker info`)?
3. o plugin **Compose v2** existe? (o v1 não serve)
4. `docker-compose.yml` existe na pasta?

Cada falha mostra uma mensagem clara com o que fazer e volta ao menu.

**Teste executado:** o caminho "Docker ausente" foi rodado e funcionou:

```
[ERRO] Docker nao encontrado nesta maquina.

O Project NOMAD roda em containers. Sem Docker ele nao sobe.

Instale o Docker Desktop - ele usa o WSL2 no Windows:
       https://www.docker.com/products/docker-desktop/

Depois rode este arquivo de novo.
```

> ❌ **O `docker compose up -d` em si AINDA NÃO FOI TESTADO** — porque não há
> Docker nesta máquina. Esse é o próximo passo.

---

## 5. Próximo passo — instalar o Docker Desktop

Feito por você (instalação manual, requer admin).

1. Baixar: <https://www.docker.com/products/docker-desktop/>
2. Instalador usa **WSL2** — se pedir, reiniciar o PC
3. Abrir o Docker Desktop e esperar o ícone ficar **verde**
4. Conferir num prompt:
   ```bat
   docker --version
   docker compose version
   docker info
   ```

**Alternativa oficial do projeto:** o README aponta o guia **WSL2** para Windows
(<https://www.projectnomad.us/install/wsl2>) — Docker Engine dentro de uma
distro WSL2, que também funciona.

> O `start.bat` serve para as duas opções: ele só procura `docker` no PATH.

---

## 6. Como rodar depois que o Docker estiver instalado
O Windows PowerShell
Copyright (C) Microsoft Corporation. Todos os direitos reservados.

Instale o PowerShell mais recente para obter novos recursos e aprimoramentos! https://aka.ms/PSWindows

PS C:\WINDOWS\system32> wsl --install
Baixando: Subsistema do Windows para Linux 3.0.1
Instalando: Subsistema do Windows para Linux 3.0.1
Subsistema do Windows para Linux 3.0.1 foi instalado.
A operação foi concluída com êxito.
Baixando: Ubuntu
[==========================56,8%=                          ] 
Instalando Ubuntu
[==========================56,8%=                          ] 

quando terminar siga os paços abaixo

```
1. Duplo clique em  G:\WBC-NOMAD\start.bat
2. Escolha  [1] Iniciar NOMAD
3. Na PRIMEIRA vez demora — está baixando as imagens
4. O navegador abre em  http://localhost:8080
```

Equivalente manual:

```bat
docker compose -f G:\WBC-NOMAD\docker-compose.yml up -d
docker compose -f G:\WBC-NOMAD\docker-compose.yml ps
start http://localhost:8080
```

Parar:

```bat
docker compose -f G:\WBC-NOMAD\docker-compose.yml stop
```

---

## 7. Avisos e limitações

1. **Onde ficam os dados.** O compose monta `/opt/project-nomad/...`. Com o
   Docker Desktop + WSL2 esses caminhos vivem **dentro da VM/WSL (disco C:)**,
   não no `G:`.
   - Para mover (segundo o comentário do próprio compose):
     1. parar o NOMAD e **mover** os dados mantendo as subpastas (`zim`, `models`…)
     2. trocar o caminho da esquerda no volume
     3. deixar **idêntico** em `NOMAD_STORAGE_PATH` e no volume do `disk-collector`
   - Caminho é **sensível a maiúsculas/minúsculas** (`/mnt/Data` ≠ `/mnt/data`);
     divergência faz o Docker criar uma pasta vazia — é a causa clássica de
     "meu conteúdo sumiu".
2. **Sem autenticação, por design.** Não exponha numa rede sem proteção.
3. `pull_policy: always` em admin/updater/disk-collector → imagens novas a cada `up`.
4. Healthcheck do admin usa `curl` dentro da imagem (porta 8080, `/api/health`).
5. **Recursos e modelos: 0 baixados.** Depois que subir, usar o **Easy Setup**
   do painel para baixar ZIM/mapas/modelos.
6. RAM: o projeto em si roda em ~1 GB. IA (Ollama) é o que pesa — e nesta
   máquina a RAM é **7,9 GB**, então modelos grandes não são viáveis
   (mesmo limite que já foi encontrado no OpenCode: usar `qwen2.5-coder:7b`).

---

## 8. Decisão sobre repositório (em aberto)

**Pergunta:** criar um repo novo só para a versão Windows, para não mexer no
repo Linux?

**Recomendação: não criar repo novo — criar uma branch `windows` no repo atual.**

| | Repo novo (`WBC-NOMAD-Windows`) | Branch `windows` no repo atual |
|---|---|---|
| Protege o `main` do Linux | ✅ | ✅ |
| Update do upstream | ❌ portar para 2 repos | ✅ `git merge main` |
| `status.md` / `memoria.md` | ❌ duplica e diverge | ✅ um só |
| Risco de confundir qual é o certo | Alto | Baixo |

**Por quê:** a "versão Windows" não muda o código — roda **os mesmos containers
Linux** nas duas máquinas. O que muda é **só o jeito de ligar**
(`install_nomad.sh` no Linux × `start.bat` no Windows). São 2–3 arquivos, não um fork.

**Fatos que sustentam a recomendação:**
- `G:\WBC-NOMAD` **ainda não tem git** — hoje não existe risco de alterar nada
- o `.gitignore` já impede o `docker-compose.yml` de entrar no git
- o único artefato Windows que merece commit é o `start.bat` (+ um eventual `README-WINDOWS.md`)

**Quando decidir:**

```bat
cd G:\WBC-NOMAD
git init
git remote add origin https://github.com/wwbcinformatica-gif/WBC-NOMAD.git
git fetch origin
git checkout -b windows
git add start.bat manual.md
git commit -m "feat: start.bat e manual para Windows"
```

Se preferir o repo novo, funciona — mantenha o `upstream`
(`Crosstalk-Solutions/project-nomad`) como terceiro remoto para puxar releases.

---

## 9. Checklist

- [x] Código-fonte completo em `G:\WBC-NOMAD` (v1.35.0)
- [x] `docker-compose.yml` gerado com credenciais
- [x] `start.bat` criado e testado (caminho de erro)
- [x] Portas 8080 / 9999 livres
- [x] `manual.md` escrito
- [x] **Docker Desktop instalado** (4.94.0 · CLI 29.8.2 · Compose v5.5.1)
- [x] git inicializado — branch `windows`, remotes `origin` + `upstream`
- [x] **Features WSL2 ativadas** — `ativar-wsl2.bat`, DISM `exit 3010`
- [ ] **REINICIAR o Windows** ← *agora* (obrigatório; reiniciar só o Docker não basta)
- [ ] Conferir `SVM Mode` na BIOS (já deve estar `Enabled`)
- [ ] `docker info` respondendo + `start.bat` → `[1]`
- [ ] Painel aberto em `http://localhost:8080`
- [ ] Commit na branch `windows` (falta `user.name` / `user.email`)
- [ ] Push para `origin` (repo público, mas push exige credencial)

---

## 10. Referência rápida

| Item | Valor |
|---|---|
| Pasta do projeto | `G:\WBC-NOMAD` |
| Iniciador | `G:\WBC-NOMAD\start.bat` |
| Compose usado | `G:\WBC-NOMAD\docker-compose.yml` (local, fora do git) |
| Template oficial | `install\management_compose.yaml` (está no git) |
| Painel | `http://localhost:8080` |
| Logs (Dozzle) | `http://localhost:9999` |
| Caminho de dados | `/opt/project-nomad/` (dentro da VM do Docker) |
| Upstream | `Crosstalk-Solutions/project-nomad` |
| Repo pessoal | `wwbcinformatica-gif/WBC-NOMAD` |
| Guia Windows oficial | <https://www.projectnomad.us/install/wsl2> |
---

## 11. Diagnóstico: Docker instalado e o engine que não subia (06/10/2026)

### O que aconteceu

Docker Desktop **4.94.0** instalado pelo usuário, junto com CLI **29.8.2** e
Docker Compose **v5.5.1**. Porém:

```
docker info  →  Error response from daemon: Docker Desktop is unable to start
```

### Causa raiz (literal do log)

Arquivo: `%LOCALAPPDATA%\Docker\log\host\com.docker.backend.exe.log`

```
engine linux/wsl failed to start: checking preconditions: Virtual Machine Platform not enabled
no virtualization found
```

O próprio Docker Desktop também mostrou o diálogo:

> **Virtual Machine Platform not enabled**
> WSL requires the Virtual Machine Platform Windows feature. Enable it in
> administrator PowerShell:
> `Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform`

### Diagnóstico da máquina

| Item | Valor |
|---|---|
| Windows 11 Enterprise LTSC, build 26100 | ✅ |
| Processador AMD Ryzen 5 1400 | ✅ |
| `VirtualizationFirmwareEnabled` (BIOS) | ✅ **True** |
| SLAT | ✅ True |
| Backend do Docker (`vm.hypervisor.windows`) | `wsl2` |
| Hyper-V backend | ❌ indisponível (*per-user install*) |
| `HypervisorPresent` | ❌ False (esperado até ativar + reboot) |
| Feature `VirtualMachinePlatform` | ❌ estava desativada |
| Feature `Microsoft-Windows-Subsystem-Linux` | ❌ estava desativada |
| Sessão com admin | ❌ não |

**Conclusão:** a virtualização já está liberada na BIOS; o que faltava eram
**2 features do Windows**.

### Correção — `ativar-wsl2.bat`

Criado `G:\WBC-NOMAD\ativar-wsl2.bat`: se auto-eleva (prompt UAC), roda o DISM
para as 2 features, grava tudo em `G:\WBC-NOMAD\ativar-wsl2.log` e pede o reboot.

Equivalente manual, **prompt como administrador**:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All
```

ou

```bat
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

### Resultado obtido

```
A operação foi concluída com êxito.
VirtualMachinePlatform exit=3010
Microsoft-Windows-Subsystem-Linux exit=3010
```

> ⚠️ **`3010` não é erro**: significa *sucesso, reinício pendente*. O script
> foi corrigido para tratar 3010 como sucesso.

### O que fazer ao reiniciar

1. Na BIOS, procurar **`SVM Mode`** (AMD) → `Enabled`. O Windows já reporta
   virtualização ativa, então se já estiver `Enabled` **não mude nada**.
2. Salvar e sair da BIOS → deixar o Windows subir normalmente.
3. Conferir: `wsl --status` e `docker info`.
4. Abrir o Docker Desktop → esperar o ícone **verde**.
5. Rodar `G:\WBC-NOMAD\start.bat` → `[1]` → painel `http://localhost:8080`.
6. Para abrir em outra maquina -> http://192.168.100.91:8080


> Reiniciar só o Docker Desktop **não resolve** — o reboot do Windows é
> obrigatório para a feature entrar em vigor.

### Itens ainda pendentes

| Item | Situação |
|---|---|
| `docker compose up -d` | nunca executado |
| Painel `http://localhost:8080` | nunca aberto |
| Recursos (ZIM/mapas) e modelos Ollama | 0 baixados |
| Commit na branch `windows` | falta `user.name` / `user.email` |
| Push | repo é público, mas push exige credencial |
---

## 12. Correção no Windows: `rslave` no `disk-collector` (06/10/2026)

### O erro

Com a stack já subindo (5 de 6 containers OK):

```
Error response from daemon: path / is mounted on / but it is not a shared or slave mount
```

O container `nomad_disk_collector` ficava em `Created` e não iniciava.

### Causa

O template oficial (Linux) usa, em `install\management_compose.yaml` linha 131:

```yaml
disk-collector:
  volumes:
    - /:/host:ro,rslave   # Read-only view of host FS with rslave propagation
```

`rslave` é **bind propagation**: pede que a origem (`/`) seja um mount
`shared` ou `slave`, para que os submounts de `/sys` e `/proc` apareçam no
container. No **Docker Desktop com backend WSL2**, a raiz `/` da VM é mount
**`private`**, então o daemon recusa a criação. No Linux nativo funciona; no
Windows, não.

### Correção aplicada em `G:\WBC-NOMAD\docker-compose.yml`

```yaml
disk-collector:
  volumes:
      # WBC/NOMAD-Windows: era "ro,rslave". O Docker Desktop com backend WSL2 tem a raiz como mount
      # PRIVATE, entao o daemon recusava com:
      #   path / is mounted on / but it is not a shared or slave mount
      # Mantido apenas ":ro" (somente leitura) - o coletor funciona, apenas nao ve submounts de /sys e /proc.
      - /:/host:ro  # Read-only view of host FS
      - /opt/project-nomad/storage:/storage
```

Resultado: `Container nomad_disk_collector Started` + log
`disk-collector sidecar starting... Created initial placeholder`.

### O que se perde

Somente a visibilidade dos submounts de `/sys` e `/proc`. O uso de disco
exibido na UI continua funcionando — nada de segurança foi afrouxada (o
volume continua `ro`, somente leitura).

> ⚠️ **`docker-compose.yml` não está no git** (contém senhas — `.gitignore`
> linhas 36-43). Se você regerar o arquivo a partir de
> `install\management_compose.yaml`, **reaplique esta correção** ou o
> `disk-collector` volta a falhar.

### Verificação final (06/10/2026)

```
NAMES                  STATUS                   PORTS
nomad_admin            Up (healthy)             0.0.0.0:8080->8080/tcp
nomad_mysql            Up (healthy)             3306/tcp
nomad_redis            Up (healthy)             6379/tcp
nomad_updater          Up
nomad_dozzle           Up                       0.0.0.0:9999->8080/tcp
nomad_disk_collector   Up

http://localhost:8080  ->  HTTP 200 (3.541 bytes)
docker system df       ->  6 imagens, 4,22 GB
```

### Avisos para o uso diário

| Tema | Detalhe |
|---|---|
| **RAM** | 7,9 GB no total; VM limitada a 3,79 GB; NOMAD usa ~1,15 GB. Nunca rode Ollama com modelo carregado junto com o NOMAD. Use `ollama stop` para liberar. |
| **Dados** | Ficam em `C:\Users\User\AppData\Local\Docker\wsl\disk\docker_data.vhdx` (5,67 GB) — **não em `G:`**. Para mover: Docker Desktop → Settings → Resources → Advanced → Disk image location. |
| **Ligar/desligar** | `start.bat` → `[1]` / `[2]`. O Docker Desktop precisa estar aberto (ícone verde). |
| **Logs** | `http://localhost:9999` (Dozzle) ou `start.bat` → `[4]`. |

### Checklist final

- [x] Docker Desktop instalado (4.94.0 · CLI 29.8.2 · Compose v5.5.1)
- [x] Features WSL2 ativadas (`ativar-wsl2.bat`, DISM `exit 3010`)
- [x] Windows reiniciado → engine `wsl2` ligando
- [x] BIOS `SVM Mode` = Enabled (virtualização já estava ativa)
- [x] `docker info` respondendo
- [x] **6/6 containers no ar**
- [x] **Painel `http://localhost:8080` → HTTP 200**
- [x] Correção `rslave` aplicada e documentada
- [ ] Recursos (ZIM/mapas) e modelos Ollama baixados
- [ ] Commit na branch `windows` (falta `user.name` / `user.email`)
- [ ] Push para `origin` (repo público, mas push exige credencial)
---

## 13. O bug que derrubou o painel: ENOSPC no tacho de 1,9 GB (06/10/2026)

### Sintoma

O painel passou a mostrar:

```
An internal error occurred. Please try again or check the console for details. Network Error
```

### Diagnóstico

No log do `nomad_admin`:

```
Error: ENOSPC: no space left on device, write
```

e no `nomad_redis`:

```
Write error while saving DB to the disk(rdbSaveRio): No space left on device
```

`nomad_admin` entrou em **crash loop (24 reinícios)**; como a API caía, o
front devolvia "Network Error".

### Causa raiz

O template Linux aponta **todos** os dados para `/opt/project-nomad/...`:

```yaml
admin:        /opt/project-nomad/storage:/app/storage
mysql:        /opt/project-nomad/mysql:/var/lib/mysql
redis:        /opt/project-nomad/redis:/data
updater:      /opt/project-nomad:/opt/project-nomad
disk-collector: /opt/project-nomad/storage:/storage
```

No **Docker Desktop com backend WSL2**, qualquer caminho fora de
`/var/lib/docker` cai no **rootfs overlay da VM**, cujo *upperdir* é um
**tmpfs (disco em RAM) de 1,9 GB**:

```
none      1.9G  1.9G  12.8M   99%  /run          ← tacho cheio
/dev/sdf  1006.9G  5.4G  950.2G   1%  /var/lib     ← disco real, IGNORADO
```

Ou seja: **MySQL + storage viviam na RAM num tacho de 1,9 GB**. O primeiro
download maior encheu o tacho → `ENOSPC` → Redis parou de persistir → admin
morreu em loop. Efeito colateral pior: **esse dado se perde em todo restart
da VM.**

Sintomas observados:
- arquivos `.zim.tmp` de **0 bytes** na pasta `zim` (escrita falhou)
- todos os mounts `df` apontavam para `overlay 1.9G 100%`
- o disco real (`/dev/sdf`) com **950 GB livres** e nada usando

### Correção — mover para o disco real

**1. Parar a stack** (para cópia consistente):
```bat
docker compose stop
```

**2. Copiar os dados** para `/var/lib/nomad` (fica em `/var/lib` = `/dev/sdf`
= `docker_data.vhdx`, filesystem ext4 nativo, persistente):
```bat
docker run --rm --entrypoint sh -v /opt/project-nomad:/src:ro -v /var/lib/nomad:/dst mysql:8.0 -c "cp -a /src/. /dst/"
```
Resultado: `mysql 190 MB · redis 8 KB · storage 1,7 GB`.

**3. Trocar os caminhos no `docker-compose.yml`** — **7 ocorrências**:
```
/opt/project-nomad  →  /var/lib/nomad
```
(aparece em admin, `NOMAD_STORAGE_PATH`, mysql, redis, updater — com dois na
linha do updater — e disk-collector)

**4. Recriar a stack:**
```bat
docker compose up -d
```

**5. Limpar o tacho antigo:**
```bat
docker run --rm --entrypoint sh -v /opt/project-nomad:/old mysql:8.0 -c "rm -rf /old/*"
```

### Resultado

| Métrica | Antes | Depois |
|---|---|---|
| Filesystem dos dados | `overlay 1.9G` **100%** (RAM) | `/dev/sdf 1006.9G` **1%** (disco) |
| Espaço livre | **0 bytes** | **948,3 GB** |
| `/run` (tacho de RAM) | 1,9 GB cheio | **476 KB (0%)** → +1,9 GB de RAM |
| `nomad_admin` | 24 reinícios, crash loop | **healthy, 0 reinícios** |
| Painel | Network Error | **HTTP 200** |
| Logs `ENOSPC` | inundando | **nenhum** |

Verificação:
```
/  /var/lib/nomad/mysql   -> /var/lib/mysql
   /var/lib/nomad/storage -> /app/storage
   /var/lib/nomad/redis   -> /data
df /storage → /dev/sdf  1006.9G  7.4G  948.3G  1%
```

### Lições

- **Nunca deixe dados de serviço em caminho "solto" no Docker Desktop/WSL2** —
  fora de `/var/lib/docker` ou de uma pasta do Windows, cai no tmpfs de 1,9 GB.
- **`ENOSPC` em container = olhar `df` de cada mount**, não só do disco do
  Windows (o `C:` estava com 341 GB livres o tempo todo).
- O erro "Network Error" genérico do painel pode ser **o backend morrendo** —
  `docker logs nomad_admin` é o primeiro lugar a olhar.
- Depois desta correção o dado fica **dentro de `docker_data.vhdx` no `C:`**,
  invisível no Explorer. Para relocate posterior: template → seção
  "RELOCATING STORAGE" (trocar os mesmos 3 pontos).

---

## 14. Mover o disco do Docker para o `G:` — ✅ CONCLUÍDO (06/10/2026, 19:17)

### O problema

| Unidade | Modelo | Tamanho | Livre |
|---|---|---|---|
| `C:` | Windows M.2 | 476 GB | **128 GB** |
| `G:` | WDC 2 TB 3,5" (SATA) | 1.863 GB | **1.393 GB** |

O disco de dados do Docker em `C:\Users\User\AppData\Local\Docker\wsl\disk\docker_data.vhdx`
crescia sem parar (chegou a **198,84 GB**) e ameaçava apertar o `C:`.
Meta: transferi-lo para o `G:`.

### Etapa 1 — cópia: CONCLUÍDA E VERIFICADA ✅

```powershell
robocopy "$env:LOCALAPPDATA\Docker\wsl" "G:\Local\Docker\Wsl\DockerDesktopWSL" /E /J /R:2 /W:5 /NP /NFL /NDL
```

- `/J` = E/S **sem buffer** (obrigatório para VHDX de 198 GB)
- ~39 min a ~85 MB/s
- Verificação byte a byte: `213467004928` bytes dos dois lados → **IDÊNTICO**
- `main\ext4.vhdx` (100 MB) copiado à parte, porque o robocopy foi interrompido
  antes dele — **atenção:** um robocopy interrompido no meio de um arquivo **não
  retoma**, ele recompia o arquivo inteiro na próxima execução. Melhor copiar
  só a pasta que falta.

### Etapa 2 — mover de verdade: 3 tentativas, todas falharam

#### ❌ Tentativa A — *junction* no lugar da pasta

```powershell
Rename-Item ...\Docker\wsl wsl.old
New-Item -ItemType Junction ...\Docker\wsl -Target 'G:\Local\Docker\Wsl\DockerDesktopWSL'
```

A junction **funciona para leitura e escrita normais**, mas o WSL **recusa**
montar um VHDX através dela:

```
Falha ao anexar o disco '\\?\C:\...\wsl\main\ext4.vhdx' ao WSL2:
O caminho não pode ser atravessado porque contém um ponto de montagem não confiável.
Código de erro: Wsl/Service/CreateInstance/MountDisk/0x800701c0
```

**Conclusão: junction/symlink não servem para o disco do WSL.** O caminho
precisa ser real.

#### ❌ Tentativa B — gravar `vm.resources.wslDataFolder` nas settings

A chave aparece no log do backend e não existia em nenhum arquivo (Docker só
persiste valores diferentes do padrão). Gravada à mão em
`%APPDATA%\Docker\settings-store.json`:

```json
"vm.resources.wslDataFolder": "G:\\Local\\Docker\\Wsl\\DockerDesktopWSL"
```

O backend **leu** a chave (aparece no log) mas **reverteu para o default 1 s
depois**. Efeito colateral grave — o log:

```
[wslmigrate] neither WSL2 data distro nor disk exist. Looking at WSL2MonoDistro flag
[wslmigrate] provisioning the WSL2 engine using a data disk
[wsl-bootstrap] detected no file system. Formatting     ← DISCO NOVO FORMATADO
```

Como a pasta default não existia mais, o Docker **formatou um disco vazio de
1,6 GB** e subiu sem nenhum container.

**Conclusão (o erro era meu): o settings-store ACEITA edição manual, só que com
a chave errada.** `vm.resources.wslDataFolder` é só o nome **interno/IPC** que
aparece no log — ao gravar esse nome o backend loga e ignora:

```
[settingsstore][W] unknown settings found: {"vm.resources.wslDataFolder":"..."}
```

A chave que vai no `settings-store.json` é **`CustomWslDistroDir`** — foi ela
que o Docker gravou sozinho ao concluir a migração:

```json
"CustomWslDistroDir": "G:\\Local\\Docker\\Wsl\\DockerDesktopWSL"
```

Isso também explica por que a **GUI insistia em duplicar o nome** (ver Etapa 4).

#### ❌ Tentativa C — GUI do Docker Desktop (falhou antes, no dia)

Settings → Resources → Advanced → *Disk image location*. O fluxo oficial faz
`robocopy` e **depois** grava a setting. Nas duas execuções anteriores (05:11 e
05:23) o backend morreu logo após o robocopy:

```
[Docker Desktop.exe] backend process exited
[Docker Desktop.exe][E] backend process exited: exit status 0x40010004
```

e a setting **nunca persistiu** → voltou pro `C:`. A suspeita é RAM no talo
(máquina com ~1 GB livre durante a cópia).

### Etapa 3 — recuperação (foi o que restaurou a stack)

```powershell
# 1. fechar Docker Desktop + wsl --shutdown
# 2. descartar o disco formatado à toa
Rename-Item ...\Docker\wsl wsl_fresco          # era o disco vazio de 1,6 GB
Rename-Item ...\Docker\wsl.old wsl             # ORIGINAL de 198,9 GB
# 3. restaurar as settings do backup
Copy-Item settings-store.json.bak_* settings-store.json
# 4. subir de novo
```

Resultado: **23 containers + painel HTTP 200 + engine v29.8.2** ✅

### ✅ Etapa 4 — como terminou de verdade (migração CONCLUÍDA)

A cópia manual da Etapa 1 estava **desatualizada** (o disco continuava sendo
escrito), então a GUI ia recopiar tudo do mesmo jeito. Sequência final,
**18:46 → 19:23**:

**1. Tirar do caminho a cópia antiga** — foi o que resolveu o "bug" do Browse.
`G:\Local\Docker\Wsl\DockerDesktopWSL` foi renomeada para
`G:\Local\Docker\backup_copia_1749`, deixando `Wsl` **vazia**:

> O diálogo **abria já dentro dessa pasta e pré-selecionava `DockerDesktopWSL`**,
> e o Docker **acrescenta `\DockerDesktopWSL`** ao que está selecionado → o campo
> saía **sempre duplicado** (`...\DockerDesktopWSL\DockerDesktopWSL`), por mais
> vezes que se tentasse. Com `Wsl` vazia, o campo `Pasta:` passou a mostrar `Wsl`
> e o caminho final ficou `G:\Local\Docker\Wsl\DockerDesktopWSL`. **Não é bug do
> Docker — é pasta pré-selecionada.**

**2. Apply & restart (18:46:21)** — o log do fluxo oficial:

    [appmanager] moving WSL data from "<HOME>\AppData\Local\Docker\wsl"
                 to "G:\Local\Docker\Wsl\DockerDesktopWSL"
    [appmanager] unregistering docker-desktop
    [appmanager] Data is on a different drive: hard copying ... docker_data.vhdx
    [appmanager] Copying disk image with: robocopy.exe /MOV /J /NFL /NDL /NJH /NP /R:0

- **`/MOV` = MOVE** (copia e **apaga a origem**) — por isso o `C:` só foi
  liberado no fim.
- **26 min** a ~111 MB/s (medindo `WriteTransferCount` do processo `robocopy`).
- O robocopy **pré-aloca** o tamanho todo no destino de cara: o arquivo já
  aparece com 198,85 GB **logo aos 10 s**. O progresso real é o I/O, não o
  tamanho do arquivo.

**3. `Failed to apply settings` (18:51) — NÃO era falha.** É o diálogo do GUI
estourando o tempo de 5 min. O robocopy seguiu normal. **Não interromper.**

**4. Depois do robocopy:** 19:17 ele sai → 19:18:21 o Docker **recria**
`main\ext4.vhdx` (96 MB, o SO da VM — ele desregistra a distro durante o move)
→ 19:22:29 engine → 19:22:33 23 containers → 19:23:20 painel HTTP 200.

**Resultado final:**

| Métrica | Antes | Depois |
|---|---|---|
| Disco dos dados | `C:\Users\User\AppData\Local\Docker\wsl` | **`G:\Local\Docker\Wsl\DockerDesktopWSL`** |
| `docker_data.vhdx` | 198,85 GB em `C:` | **198,85 GB em `G:`** (escrita ativa) |
| **`C:` livre** | 131,5 GB | **327,9 GB (+196,4 GB)** |
| `G:` livre | 1.393 GB | 1.194 GB |
| Containers | 23 | **23** — todos `healthy` |
| Painel `:8080` | HTTP 200 | **HTTP 200** |
| `/app/storage` | 197 GB usados | **197 GB usados / 760 GB livres (21%)** |
| Fila downloads | 0 / 0 | **0 waiting / 0 failed** |

Persistida em `%APPDATA%\Docker\settings-store.json`:

```json
"CustomWslDistroDir": "G:\\Local\\Docker\\Wsl\\DockerDesktopWSL"
```

Backup `G:\Local\Docker\backup_copia_1749` (198,9 GB) mantido durante a
validação e **apagado em 19:35** — `G:` voltou a 1393 GB livres.

### Resumo do procedimento (repetível)

1. Parar de usar o `C:` — deixar a pasta de destino **vazia** (sem subpasta com
   o mesmo nome que o Docker acrescenta)
2. Docker Desktop → Settings → Resources → Advanced → *Disk image location* →
   **Browse** → entrar na pasta **mãe** → clicar em área vazia até o campo
   `Pasta:` mostrar o **nome da pasta mãe** → `Selecionar pasta`
3. Conferir que o campo final tem **`DockerDesktopWSL` UMA vez só**
4. **Apply & restart** → esperar (`/MOV` = 26 min para 198 GB) → **ignorar**
   `Failed to apply settings`
5. Validar: `C:\...\Docker\wsl` sumido, disco em `G:` gravando, 23 containers,
   painel 200, `df /app/storage` com os dados
6. Só então apagar o backup

### Revertendo (voltar pro `C:`)

Parar o Docker, copiar `G:\...\DockerDesktopWSL` de volta para
`C:\Users\User\AppData\Local\Docker\wsl` e trocar `CustomWslDistroDir` pelo
caminho do `C:` (ou remover a chave para voltar ao default).

### O que NÃO fazer

| Ação | Por quê |
|---|---|
| Junction/symlink na pasta `wsl` | `0x800701c0` — WSL não atravessa mount point |
| Gravar `vm.resources.wslDataFolder` no settings | é o nome **IPC**; o do arquivo é **`CustomWslDistroDir`** → senão `unknown settings` e é ignorado |
| Deixar subpasta em `...\Wsl\` antes de abrir o Browse | o Browse **pré-seleciona** e o Docker **acrescenta** `\DockerDesktopWSL` → caminho duplicado |
| Interromper no `Failed to apply settings` | é timeout do GUI (5 min); o robocopy continua — abortar mata a migração |
| Apagar `backup_copia_1749` antes de validar | única cópia de 198 GB fora do disco ativo |

---

## 15. `localhost` morto pelo `wslrelay` + rede da VM (06/10/2026)

### Sintoma

O painel dava `Impossível conectar-se ao servidor remoto` / timeout, mas
`docker ps` funcionava e o container respondia a si mesmo:

```
docker exec nomad_admin node -e "fetch('http://127.0.0.1:8080/api/health')..."
→ HTTP 200
```

### Causa

```
127.0.0.1  → HTTP 200  (235 ms)   ✅  ← com.docker.backend.exe (0.0.0.0:8080)
[::1]      → TIMEOUT   (20 s)     ❌  ← wslrelay.exe (ESTADO MORTO)
localhost  → TIMEOUT   (20 s)     ❌  ← Windows tenta IPv6 primeiro
```

Havia **dois listeners** na porta: o do Docker (funcionava) e o do
`wslrelay.exe` do WSL (`[::1]:8080`), que aceitava o TCP e **nunca respondia**.
O `localhost` do Windows resolve para `::1` primeiro → caía no relay morto e o
PowerShell não faz fallback.

### Correção

```powershell
Stop-Process -Name wslrelay -Force
```

O processo **não volta** até o próximo `wsl --shutdown`. Na sequência:

```
localhost  → HTTP 200  (8 s)   [::1] → HTTP 200   127.0.0.1 → HTTP 200
```

**Sempre testar com `127.0.0.1` antes de concluir que o painel caiu.**

### Rede da VM — episódio recorrente

Três vezes no mesmo dia o backend logou:

```
connect tcp 192.168.65.7:2376: no route to host
```

e a VM ficou inalcançável (`docker version` e `wsl -d docker-desktop` ambos em
timeout, `Get-NetRoute -DestinationPrefix '192.168.65.0/24'` → **nenhuma rota**).
Conserto: **`wsl --shutdown` + relançar o Docker Desktop limpo**.

- Lançar `Docker Desktop.exe` direto **falha** (`[F] no argument received`)
- Jeito certo: `Get-StartApps` → `Docker.DockerForWindows.Settings` →
  `Start-Process explorer.exe -ArgumentList "shell:AppsFolder\<AppID>"`
- Gatilho provável: RAM no talo (máquina com ~1 GB livre, vmmem em 3,5/3,79 GB)
  enquanto Ollama rodava a 240% de CPU no embedding

### Downloads — retomados

DNS de dentro do container estava quebrado (`getaddrinfo EAI_AGAIN
lb.download.kiwix.org`). Depois do restart limpo:

- `lb.download.kiwix.org → 51.159.97.236` ✅
- `fetch(https://lb.download.kiwix.org/) → HTTP 200` ✅
- fila `downloads`: **failed 0 · active 0 · waiting 0** → 46 ZIMs concluídos
- fila `file-embeddings`: **4 jobs falhos limpos + `POST /api/rag/sync`
  enfileirou 37 arquivos** (falhavam com *"Ollama is not installed"*)

### GPU

Confirmada funcionando no container:

```
sched_reserve: CUDA0 compute buffer size = 92.03 MiB
[GpuPassthroughRemediationProvider] Ollama is using a GPU backend — no action needed.
```

`nomad_ollama` com `DeviceRequests: driver=nvidia, capabilities=gpu`,
modelo `nomic-embed-text:v1.5` (274 MB).

---

## 16. Problemas conhecidos e soluções (comentados)

> **Esta é a primeira seção a olhar quando algo falhar.**
> Cada item traz **sintoma** (o que você vê), **causa** (por quê) e **solução**
> (o que fazer). Os comandos estão no §18 (runbook do admin).
> Itens marcados com 🆕 são os mais recentes (06/10/2026, período da noite).

### 16.1 Tabela rápida

| # | Problema | Sintoma na tela / terminal | Solução |
|---|---|---|---|
| 1 | Docker não sobe | ícone parado, engine não responde | §11 + `ativar-wsl2.bat` (exit 3010 = ok, só falta reboot) |
| 2 | `rslave` inválido | `invalid mode: /:/host:ro,rslave` | tirar o `,rslave` do `disk-collector` (§12) |
| 3 | ENOSPC no tacho de 1,9 GB | painel morre, `no space left on device` | storage em `/var/lib/nomad/storage`, fora do overlay (§13) |
| 4 | Disco do Docker no `C:` | `C:` cheio | migrar pro `G:` (§14) — ✅ já feito |
| 5 | `localhost` não responde | navegador trava, container `healthy` | matar `wslrelay`; testar **sempre** com `127.0.0.1` (§15) |
| 6 | Rede da VM morta | `no route to host 192.168.65.7:2376` | fechar Docker + `wsl --shutdown` + relançar (§15) |
| 7 | DNS quebrado no container | `getaddrinfo EAI_AGAIN` em downloads | restart limpo do Docker Desktop (§15) |
| 8 | IA não responde | *"Ollama is not installed"* | `nomad_ollama` precisa de GPU; 1–3 min p/ `healthy` |
| 9 | GPU não usada | Ollama em CPU puro | `DeviceRequests: driver=nvidia` no compose + reiniciar o container |
| 10 | Máquina lenta | RAM ~1 GB livre de 7,9 GB | `docker desktop stop` libera ~3 GB; Ollama a 240% CPU satura |
| 11 🆕 | **API do Docker travada** | `docker ps` / `docker exec` **penduram** sem resposta; volta `500 Internal Server Error` no pipe | **fechar Docker + `wsl --shutdown` + relançar pelo AppID** (§18.4) |
| 12 🆕 | **`nomad_admin` unhealthy** | `connect ECONNREFUSED <ip-antigo>:6379` no log | admin guardou o **IP antigo do Redis**; reiniciar o `nomad_admin` (§18.5) |
| 13 🆕 | **Content Explorer dá 500** | *"Request failed with status code 500"* em *Browse the Kiwix Library* | **consequência do #12** — consertar o Redis e recarregar a página |
| 14 🆕 | **`.zim.tmp` órfãos** | arquivos `0 bytes` ocupando nome em `/app/storage/zim/` | download abortou; apagar os `.tmp` de 0 byte (§18.6) |
| 15 🆕 | Upload de ZIM grande pelo navegador | upload de 19 GB trava/estoura | **não usar** o uploader p/ arquivos grandes — copiar direto no volume (§17.3) |
| 16 🆕 | Download de ZIM lento | começa rápido (~50 MB/s) e cai p/ ~1,5 MB/s | limite **por conexão** do CDN; deixar rodar com `curl -C -` (retomável) |
| 17 🆕 | **Ollama caiu pra CPU** | admin: *"NVIDIA GPU expected but Ollama reported a CPU-only backend"*; ollama: *"GPU discovery watchdog timed out"* | `docker restart nomad_ollama` (§16.8) — a `nvidia-smi` **continua funcionando**, o defeito é só na descoberta |
| 18 🆕 | **Duas stacks compose** | `docker compose ls` mostra só 6 containers, mas existem 23 | os outros vêm do projeto **`project-nomad-managed`**, criado pelo próprio NOMAD (§18.8) |

### 16.2 🆕 API do Docker travada — o pior de todos (06/10, 21:14)

**Sintoma.** `docker ps`, `docker exec` e `docker version` **penduram para sempre**
(nenhum retorno, mesmo com 60–90 s de paciência). O `docker desktop status`
ainda responde `running`, o que engana. Nos logs aparece:

```
request returned 500 Internal Server Error for API route and version
http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/v1.56/exec/...
```

**Causa.** O pipe nomeado `dockerDesktopLinuxEngine` entre o CLI do Windows e a
engine do WSL ficou bloqueado. **As containers podem continuar de pé** — portas
TCP aceitam conexão, mas o `docker exec` para dentro delas não funciona mais.

**Diagnóstico em 10 s** (§18.3): `docker ps` trava = é isso.

**Solução.**

```powershell
docker desktop stop --timeout 120   # se travar aqui, é sinal de que já era
wsl --shutdown
# relançar pelo AppID (o .exe direto FALHA, ver §18.4)
```

Na prática: `stop` levou ~45 s, `wsl --shutdown` 11 s, sem processos sobrando,
e ao relançar a engine subiu na **2ª tentativa** e os 23 containers voltaram na
**1ª**. Total: **~4 min**.

**Por que aconteceu.** NÃO está provado que tenha sido o `docker exec -d` /
`nohup ... &` que eu tentei para baixar o ZIM. O sintoma **já tinha aparecido
antes**, no segundo `docker exec` de uma mesma linha de comando (voltou o 500).
Padrão recorrente desta máquina: **RAM no talo** (ficou com 1,3 GB livre de
7,9 GB = 83,5% ocupada) é o gatilho mais provável.

### 16.3 🆕 `ECONNREFUSED` no Redis = IP antigo na cache (06/10, 21:20)

**Sintoma.** Log do `nomad_admin` cheio de:

```
{"level":50,"err":{"message":"connect ECONNREFUSED 172.18.0.18:6379"},
 "msg":"Shared Redis connection error"}
[ error ] [system] Worker error: connect ECONNREFUSED 172.18.0.18:6379
[ioredis] Unhandled error event: ...
```

e o container fica `health=unhealthy`.

**Causa.** O `nomad_admin` subiu **antes** do Redis, resolveu `redis` para
`172.18.0.18` e **cacheou** o IP. Quando o Redis subiu, a rede do compose lhe deu
`172.18.0.20`. O admin continua falando com o endereço velho → `ECONNREFUSED`.
É o erro clássico de **ordem de subida** após um restart brusco.

**Conferir em um comando:**

```powershell
docker inspect nomad_redis nomad_admin --format '{{.Name}} -> {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}| {{.State.Health.Status}}'
# /nomad_redis -> 172.18.0.20 | healthy
# /nomad_admin -> 172.18.0.21 | unhealthy   ← e queria falar com 172.18.0.18
```

**Solução.** `docker restart nomad_admin` — ao subir de novo ele resolve o
DNS e ganha o IP certo.

> ⚠️ **ATENÇÃO — ordem importa.** O processo `curl` do download da Wikipédia PT
> roda **dentro do `nomad_admin`**. Reiniciar o container **mata o download**.
> Fazer **só depois** que o `.zim` estiver completo (o arquivo fica no volume,
> então nada se perde — mas o download recomeça do zero, a menos que se use
> `curl -C -` para retomar do `.part`).

### 16.4 🆕 Content Explorer devolve 500 (06/10, 20:26)

**Sintoma.** `Settings → Content Explorer → Browse the Kiwix Library` fica em
*Loading...* e estoura dois avisos:

> *An internal error occurred. Please try again or check the console for
> details. Request failed with status code 500*

**Causa.** NÃO é problema da internet nem do Kiwix. É o backend `nomad_admin`
falhando ao servir a API — na prática, o **#12 (Redis com IP antigo)**.

**Solução.** Consertar o Redis (§18.5) e recarregar a página (F5).

**Enquanto isso não estiver resolvido**, o caminho alternativo é o
**Content Manager** (`Settings → Content Manager`), que lê os ZIMs **já
presentes** no volume e não depende dessa API remota.

### 16.5 🆕 `.zim.tmp` de 0 byte no volume

**Sintoma.** `ls /app/storage/zim` mostra coisas como:

```
0  libretexts.org_en_chem_2025-01.zim.tmp
0  wikibooks_en_all_maxi_2026-04.zim.tmp
295157760  wikipedia_en_medicine_maxi_2026-04.zim.tmp
```

**Causa.** Download interrompido (queda de rede, restart da stack). O NOMAD
usa o sufixo `.tmp` durante o download e renomeia ao fim.

**Por que incomoda.** Ocupam nome de arquivo e, se o NOMAD reenfileirar o
mesmo item, ele pode achar que já existe. Os de **0 byte** são puro lixo.

**Solução.** Apagar só os de 0 byte; os que têm tamanho valem a pena manter
para retomar:

```powershell
docker exec nomad_admin sh -c 'find /app/storage/zim -name "*.tmp" -size 0 -delete'
docker exec nomad_admin sh -c 'ls -l /app/storage/zim/*.tmp 2>/dev/null || echo "nenhum .tmp restante"'
```

### 16.6 🆕 Download de ZIM lento / retomável

**Sintoma.** Começa voando (~50 MB/s) e **cai para ~1,5 MB/s**, dando um ETA
de horas para um arquivo de 19 GB.

**Causa.** Limite **por conexão** do CDN do Kiwix (`download.kiwix.org`).
Não é disco nem RAM da máquina (a VM fica com 0% de CPU durante o download).

**O que fazer.** **Deixar rodar.** O `curl -C -` retoma do ponto onde parou,
então um corte de energia ou um restart não desperdiça o que já baixou:

```powershell
# acompanhar
docker exec nomad_admin sh -c 'ls -l /app/storage/zim/*.part'
# conferir se ainda está andando (duas leituras, 10 s de intervalo)
```

**Cuidado (regra de ouro):** nunca reiniciar `nomad_admin` com um `.part` em
andamento — mataria o `curl` (ver §16.3).

### 16.7 Sintomas que NÃO são defeito

| Sintoma | Por quê |
|---|---|
| `nomad_ollama` e `nomad_stirling_pdf` levam 1–3 min para `healthy` | healthcheck demorado — **não é falha** |
| `main\ext4.vhdx` (96 MB) aparecer/desaparecer no `G:` | distro é recriada no `wsl --shutdown`; os dados reais estão em `docker_data.vhdx` |
| exit `3010` no DISM | **sucesso** + reboot pendente (§11) |
| `wikipedia_en_medicine_maxi_...zim.tmp` com 295 MB | download parcial que vale a pena retomar |

### 16.8 🆕 Ollama volta a rodar em CPU depois de um restart brusco (06/10, 21:31)

**Sintoma.** Duas faces do mesmo problema:

```
# no nomad_admin (a cada ~45 s)
{"level":40,"msg":"NVIDIA GPU expected but Ollama reported a CPU-only backend at startup"}

# no nomad_ollama
level=WARN source=runner.go:584 msg="llama-server GPU discovery watchdog timed out"
    OLLAMA_LIBRARY_PATH="[/usr/lib/ollama /usr/lib/ollama/cuda_v12]"
    error="context deadline exceeded"
level=INFO msg="failure during llama-server GPU discovery"
```

**Diagnóstico — o que engana.** A GPU **está passada normalmente**. Confirme
antes de pensar em driver:

```powershell
docker exec nomad_ollama nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv
# NVIDIA GeForce RTX 3060, 615 MiB, 12288 MiB    ← já era isso, mesmo com o erro
```

Ou seja: **não é problema de driver nem do `DeviceRequests`.** É o *watchdog*
de descoberta do Ollama **estourando o tempo limite** enquanto a máquina estava
sob carga (RAM com **1,2 GB livre de 7,9 GB = 85% ocupada**). O Ollama tenta
`cuda_v12`, dá timeout, tenta `cuda_v13`, dá timeout de novo, e conclui
"CPU-only".

**Solução.** Reiniciar **só** o container do Ollama (seguro — ele não hospeda
outros downloads):

```powershell
docker restart nomad_ollama
# esperar ~45 s
```

**Prova de que funcionou:**

```
compute=8.6 name=CUDA0 description="NVIDIA GeForce RTX 3060"
libdirs=ollama,cuda_v13 driver=13.4 pci_id=0000:07:00.0
```

```powershell
curl.exe -s http://127.0.0.1:11434/api/tags      # http=200, nomic-embed-text:v1.5
docker logs --since 10m nomad_admin | Select-String 'CPU-only'   # deve vir vazio
```

> 📌 **Regra geral desta máquina:** quase todo problema "estranho" aqui tem a
> **RAM no talo** como gatilho. Antes de culpar o Docker ou a GPU, olhe
> `Get-CimInstance Win32_OperatingSystem` e veja quantos GB estão livres.

---

## 17. Guia do usuário (quem só usa o NOMAD)

> Você **não precisa** de terminal, Docker nem SSH. Tudo acontece no navegador.

### 17.1 Endereços

| Quero... | Vou em |
|---|---|
| Painel principal | `http://127.0.0.1:8080` |
| Ler ZIMs (Wikipédia, etc.) | `http://127.0.0.1:8090` |
| CyberChef (analisar dados) | `http://127.0.0.1:8100` |
| FlatNotes (anotações) | `http://127.0.0.1:8200` |
| Kolibri (cursos) | `http://127.0.0.1:8310` |
| Filebrowser (arquivos) | `http://127.0.0.1:8410` |
| Ver logs (só admin) | `http://127.0.0.1:9999` |

> Use **sempre `127.0.0.1`**, nunca `localhost` — ver aviso 5 abaixo.

### 17.2 Como abrir conteúdo

1. Abra `http://127.0.0.1:8080` e faça login.
2. `Content Manager` → a lista mostra os ZIMs já disponíveis, com tamanho.
3. Clique no título para abrir no Kiwix, ou vá em `Content Explorer` para
   procurar conteúdo novo.

### 17.3 Como adicionar conteúdo novo

**Arquivo pequeno (até ~2 GB):** `Content Manager → Drop files here or
browse files`. Escolha o arquivo `.zim` e aguarde.

**Arquivo grande (Wikipédia PT = 19 GB):** **não use o uploader.** A própria
página avisa:

> *Larger files should be copied directly to the storage volume.*

Nesses casos, **peça ao administrador** para colocar o arquivo direto no volume
(`/app/storage/zim/`). É instantâneo (não há cópia) e não passa pelo navegador.

> 📌 Se o painel mostrar *"The Kiwix application is not installed. Please
> install it to view downloaded ZIM files"* — é só **aviso**. Os arquivos
> estão no lugar e o servidor do Kiwix (porta 8090) os serve normalmente.

### 17.4 O que fazer se "não carrega"

| Você vê | Faça |
|---|---|
| Página não abre / fica carregando | Esperar **5 min** — o servidor pode estar subindo |
| Página não abre e já esperou | Testar com `127.0.0.1` em vez de `localhost` |
| Algo específico deu **500** | Recarregar (F5). Se persistir, ver §16.4 e avisar o admin |
| Tudo parou de repente | Provavelmente o Docker foi reiniciado. Esperar ~4 min e tentar de novo |
| Uma página em branco | Testar outra porta (8090/8100). Se as outras abrem, o problema é daquela ferramenta |

### 17.5 O que NÃO fazer

- ❌ Não apagar arquivos dentro de `/app/storage` pelo Filebrowser sem saber.
- ❌ Não fechar o Docker Desktop sem combinar — derruba as 23 ferramentas.
- ❌ Não instalar modelos de IA pela mão: são gigantes e a máquina tem
  **7,9 GB de RAM** no total.
- ❌ Não expor o painel numa rede sem senha: **não tem autenticação por
  design** nas portas internas.

---

## 18. Runbook do administrador

> Tudo aqui é executável no PowerShell. **Recarregue o PATH primeiro** — a
> sessão do agente nasce com PATH velho:
>
> ```powershell
> $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
> ```

### 18.1 Ligar / parar

```powershell
# LIGAR tudo (dia a dia — clique duplo no arquivo)
G:\WBC-NOMAD\iniciar-nomad.bat

# ou na mão
docker desktop start --timeout 300

# GERENCIAR (menu: iniciar/parar/status/logs)
G:\WBC-NOMAD\start.bat

# DESLIGAR (libera ~3 GB de RAM)
docker desktop stop
```

`AutoStart` está **`false`** de propósito: o Docker consome ~3 GB dos 7,9 GB e
esse `C:` é para outros projetos. Para mudar: Settings → General →
*Start Docker Desktop when you sign in*.

### 18.2 Diagnóstico rápido (2 min)

```powershell
# 1. engine responde?
docker version --format '{{.Server.Version}}'

# 2. quantos containers e quem está doente?
docker ps --format '{{.Names}}|{{.Status}}'
docker ps -f health=unstarting --format '{{.Names}}'

# 3. portas (sem usar docker — útil quando a API está travada)
foreach ($p in 8080,8090,9999,6333,11434,8100) {
  curl.exe -s -o NUL -w "$p -> %{http_code} (%{time_total}s)`n" --max-time 20 "http://127.0.0.1:$p"
}

# 4. espaço (NUNCA olhar via Filebrowser: o caminho é outro)
docker exec nomad_admin df -h /app/storage

# 5. log do backend (aqui mora a causa de quase tudo)
docker logs --tail 80 nomad_admin
```

**Interpretação das portas:**

| 8080 | significado |
|---|---|
| `000` em ~0,003 s | conexão **recusada** → container/app ainda não escuta (aguardar) |
| `000` em ~2 s | **proxy do Docker** não alcança a container → reiniciar Docker |
| `000` em 30–90 s | app **pendurado** dentro da container |
| `302` | **OK** (redireciona para o login) · `200` = OK |

### 18.3 Como saber se a API do Docker está travada

```powershell
# rode num job com timeout, senão o shell trava junto
$job = Start-Job { docker ps --format '{{.Names}}|{{.Status}}' 2>&1 | Out-String }
if (Wait-Job $job -Timeout 30) { Receive-Job $job } else { 'TRAVADO — ver §18.4'; Stop-Job $job }
Remove-Job $job -Force
```

Se travar 2 vezes seguidas, **não tente mais nada** — vá direto para §18.4.

### 18.4 Recuperação de emergência (API travada) — o que salvara a noite

```powershell
# 1. parar (usa a API do Desktop, separada da engine — funciona mesmo travado)
docker desktop stop --timeout 120

# 2. derrubar a VM por completo
wsl --shutdown

# 3. conferir que NÃO sobrou nada
Get-Process | Where-Object { $_.Name -match '^docker$|^com\.docker|^Docker Desktop$' }

# 4. relançar PELO APPID (o .exe direto falha com "[F] no argument received")
$app = Get-StartApps | Where-Object { $_.AppID -match 'Docker\.DockerForWindows' } | Select-Object -First 1
Start-Process explorer.exe -ArgumentList "shell:AppsFolder\$($app.AppID)"

# 5. esperar engine e containers
docker version --format '{{.Server.Version}}'
docker ps -q | Measure-Object | Select-Object -ExpandProperty Count   # esperar 23
```

**Tempos reais medidos:** stop ~45 s · shutdown 11 s · engine na 2ª tentativa ·
23 containers na 1ª · painel voltando em ~4 min.

> ⚠️ **Não matar o `wslrelay` como primeiro recurso.** Ele conserta `localhost`,
> mas **não** conserta a API. E depois de matá-lo, teste só com `127.0.0.1`.

### 18.5 Consertar o Redis / Content Explorer 500

**Só executar com nenhum download em andamento** (ver §16.3):

```powershell
# 1. garantir que NENHUM .part está sendo baixado
docker exec nomad_admin sh -c 'ls -l /app/storage/zim/*.part 2>/dev/null || echo "nenhum download ativo"'

# 2. confirmar o diagnóstico
docker inspect nomad_redis nomad_admin --format '{{.Name}} -> {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}| {{.State.Health.Status}}'

# 3. reiniciar o admin (ele volta a resolver o DNS do redis)
docker restart nomad_admin

# 4. esperar healthy (pode levar 1–3 min)
docker ps -f name=nomad_admin --format '{{.Status}}'

# 5. verificar
curl.exe -s -o NUL -w "%{http_code}`n" --max-time 30 http://127.0.0.1:8080   # 302
docker logs --tail 30 nomad_admin | Select-String -Pattern 'ECONNREFUSED'      # deve sumir
```

Depois, recarregar `Settings → Content Explorer` (F5).

### 18.6 Limpeza de `.tmp` órfãos

```powershell
docker exec nomad_admin sh -c 'find /app/storage/zim -name "*.tmp" -size 0 -delete'
docker exec nomad_admin sh -c 'ls -l /app/storage/zim/*.tmp 2>/dev/null || echo "nenhum .tmp restante"'
docker exec nomad_admin sh -c 'du -sh /app/storage/zim'
```

### 18.7 Onde estão os dados (não mexer sem ler)

| O quê | Onde |
|---|---|
| Storage (ZIMs, models, notes) | `G:\Local\Docker\Wsl\DockerDesktopWSL\disk\docker_data.vhdx` → dentro da VM: `/var/lib/nomad/storage` |
| ZIMs | `/var/lib/nomad/storage/zim` (dentro do `nomad_admin`: `/app/storage/zim`) |
| `docker-compose.yml` | `G:\WBC-NOMAD\docker-compose.yml` — **fora do git** (tem senhas) |
| Settings do Docker | `%APPDATA%\Docker\settings-store.json` → `CustomWslDistroDir` = `G:\Local\Docker\Wsl\DockerDesktopWSL` |
| Espaço | medir com `docker exec nomad_admin df -h /app/storage` — **nunca** pelo Filebrowser |

**Nunca voltar dados para `/opt/project-nomad`** — é tmpfs (RAM) e estoura.

### 18.8 A stack é DE DOIS PROJETOS compose (não só o seu)

`docker compose ls --all` mostra **só 6 containers** — e é verdade:

```
NAME                STATUS         CONFIG FILES
project-nomad       running(6)     G:\WBC-NOMAD\docker-compose.yml
```

**Por quê? Existem dois projetos:**

| Projeto | Quem cria | Containers |
|---|---|---|
| `project-nomad` | **o seu arquivo** `G:\WBC-NOMAD\docker-compose.yml` | `admin`, `dozzle`, `mysql`, `redis`, `updater`, `disk-collector`, `nomad-update-shared` |
| `project-nomad-managed` | **o próprio `nomad_admin`**, em tempo de execução | os outros 17: `ollama`, `kiwix_server`, `jellyfin`, `cyberchef`, `flatnotes`, `kolibri`, `stirling_pdf`, `qdrant`, `vaultwarden`… |

Comprovação:

```powershell
docker inspect nomad_ollama --format '{{json .Config.Labels}}'
# com.docker.compose.project = project-nomad-managed
# io.project-nomad.managed    = true
```

**Consequências práticas:**

1. **`ollama` NÃO está no seu `docker-compose.yml`** — não perca tempo procurando.
   O comentário no topo do `admin` já avisa: *"the admin inspects this mount and
   points every child app (Kiwix, Ollama, etc.) at the same host location
   automatically"*.
2. Configurações das ferramentas (GPU, volumes, portas) são **geridas pelo
   painel do NOMAD**, não editando o YAML.
3. `docker compose up -d` recria **só os 6** do seu arquivo. Os 17 *managed* o
   NOMAD recria sozinho quando ele sobe.
4. Para mudar como o Ollama roda: **painel → Settings**, não o compose.

> ⚠️ Isso explica por que `docker compose restart` **não** reinicia o Ollama.
> Para o caso da GPU (§16.8), use `docker restart nomad_ollama`.

### 18.9 Checklist antes de considerar "pronto"

- [ ] `docker version` responde sem travar
- [ ] 23 containers, 0 `unhealthy` (o `admin` precisa sair de `unhealthy`)
- [ ] `http://127.0.0.1:8080` → `302`/`200`
- [ ] `docker logs nomad_admin` sem `ECONNREFUSED`
- [ ] Content Explorer carrega (sem 500)
- [ ] `df -h /app/storage` com folga
- [ ] nenhum `.tmp` de 0 byte
- [ ] `status.md` e `memoria.md` atualizados
- [ ] commit feito na branch `windows`

---

## 19. Como subir o NOMAD — Linux e Windows

> O **mesmo projeto** roda nos dois sistemas. Muda o *jeito de subir* e onde
> ficam os dados. Esta seção cobre as duas vias lado a lado.

### 19.1 O que é igual nos dois

| Item | Valor |
|---|---|
| Pré-requisito | Docker **+ plugin Compose v2** (o v1 não serve) |
| Configuração | `docker-compose.yml` — contém **senhas**, logo **fica fora do git** (`.gitignore` linhas 36–43) |
| Painel (Command Center) | `http://localhost:8080` |
| Containers | 23 = 6 do seu compose + 17 gerenciados pelo próprio NOMAD (§18.8) |
| Conteúdo | um diretório único com ZIMs, modelos de IA e notas |
| Desinstalar | script oficial `uninstall_nomad.sh` (Linux); no Windows, apagar o disco |

### 19.2 LINUX — caminho oficial do upstream

**Requisitos** (o instalador aborta se falhar): Debian/Ubuntu-based, x86_64,
bash, sudo. **NVIDIA é opcional** — o instalador só avisa, nunca aborta.

#### Instalação rápida (uma linha, como no `README.md`)

```bash
sudo apt-get update && \
sudo apt-get install -y curl && \
curl -fsSL https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/install_nomad.sh \
  -o install_nomad.sh && \
sudo bash install_nomad.sh
```

#### A partir deste repositório (reproduzível, com histórico)

```bash
git clone https://github.com/wwbcinformatica-gif/WBC-NOMAD.git
cd WBC-NOMAD
sudo bash install/install_nomad.sh

# sem interação (as 2 perguntas já respondidas):
printf 'y\ny\n' | sudo bash install/install_nomad.sh
```

#### Os 2 prompts — e são os únicos do script

| # | Pergunta | Sem resposta |
|---|---|---|
| 1 | `Are you sure you want to continue? (y/N):` | `exit 0` — cancela tudo |
| 2 | `I have read and accept License Agreement & Terms of Use (y/N)?` | `exit 1` — aborta |

#### O que o instalador faz, em ordem

```
check_is_debian_based / check_is_x86_64 / check_is_bash / check_has_sudo
ensure_dependencies_installed      -> curl, gpg
get_install_confirmation          -> PROMPT 1
accept_terms                      -> PROMPT 2
ensure_docker_installed           -> get.docker.com + systemctl start docker
check_docker_compose              -> exige plugin v2
setup_nvidia_container_toolkit    -> so avisa, nunca aborta
get_local_ip
create_nomad_directory            -> /opt/project-nomad
download_helper_scripts           -> start/stop/update
download_management_compose_file  -> docker-compose.yml
start_management_containers
verify_gpu_setup
```

#### Depois de instalado — atalhos em `/opt/project-nomad`

```bash
sudo bash /opt/project-nomad/start_nomad.sh     # subir tudo
sudo bash /opt/project-nomad/stop_nomad.sh      # parar tudo
sudo bash /opt/project-nomad/update_nomad.sh    # atualizar Command Center + deps
```

- Painel: `http://localhost:8080` ou `http://<IP_DA_MAQUINA>:8080`
- **Dados:** `/opt/project-nomad` — é *bind mount* direto do host, você enxerga
  os arquivos com `ls` normalmente
- **Desinstalar:**

  ```bash
  curl -fsSL https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/uninstall_nomad.sh \
    -o uninstall_nomad.sh && sudo bash uninstall_nomad.sh
  ```

> ⚠️ `update_nomad.sh` atualiza **só** o Command Center e suas dependências
> (mysql, redis…). As aplicações instaláveis (Kiwix, Ollama, Jellyfin…) se
> atualizam pela **interface** do Command Center, não por esse script.

### 19.3 WINDOWS — esta máquina (`G:\WBC-NOMAD`)

**Requisitos:** Windows 10/11 x64 · WSL2 · **Docker Desktop** (instalado e
gerenciado pelo próprio usuário — §5).

#### Subir — clique duplo

| Arquivo | Função |
|---|---|
| `iniciar-nomad.bat` | **LIGAR TUDO** — Docker Desktop → espera a engine → espera os 23 containers → confere o painel → abre o navegador |
| `start.bat` | **GERENCIAR** — menu com status, logs, subir/parar a stack |
| `ativar-wsl2.bat` | Só na primeira vez, se o WSL2 estiver inativo (exit `3010` = sucesso + reboot pendente) |

#### Desligar

```powershell
docker desktop stop --timeout 120
```

#### O que é específico do Windows

| Item | Valor nesta máquina |
|---|---|
| Docker Desktop | 4.94.0 · CLI 29.8.2 · Compose v5.5.1 · WSL 3.0.1.0 |
| Disco do Docker | `G:\Local\Docker\Wsl\DockerDesktopWSL\disk\docker_data.vhdx` (`CustomWslDistroDir`) |
| Storage | **dentro do vhdx** → `/var/lib/nomad/storage` no host, `/app/storage` dentro do `nomad_admin` |
| AutoStart | `false` — a máquina tem 7,9 GB de RAM (§5) |
| Como testar o painel | **sempre** `127.0.0.1` — o `localhost` pode estar morto pelo `wslrelay` (§15) |
| Diagnóstico | mesmo do Linux, **mas sempre com `Start-Job` + timeout** — `docker exec` solto trava o shell (§18.3) |

> 🚫 **Nunca** jogue dados em `/opt/project-nomad` no Windows: é `tmpfs`
> (memória RAM) e o espaço simplesmente desaparece. Meça o uso real com
> `docker exec nomad_admin df -h /app/storage`.

### 19.4 Comparativo lado a lado

| | **Linux** | **Windows** |
|---|---|---|
| Docker | Docker Engine + plugin Compose | Docker Desktop + WSL2 |
| Instalar | `sudo bash install/install_nomad.sh` | `ativar-wsl2.bat` + Docker Desktop à mão |
| Subir | `sudo bash /opt/project-nomad/start_nomad.sh` | duplo clique em `iniciar-nomad.bat` |
| Parar | `sudo bash /opt/project-nomad/stop_nomad.sh` | `docker desktop stop --timeout 120` |
| Atualizar | `sudo bash /opt/project-nomad/update_nomad.sh` | `git pull` + `docker compose up -d` |
| Storage | `/opt/project-nomad` no **host** | dentro do **vhdx**, exposto só via `docker exec` |
| GPU | `nvidia-container-toolkit` | `DeviceRequests: nvidia` no Docker Desktop |
| Sistema de arquivos | ext4 nativo | 9P do WSL2 — **muito lento com montanhas de arquivos pequenos** |
| Scripts extras | `install/*.sh` | `*.bat` (ASCII puro + CRLF) |

### 19.5 Atualizar em cada sistema

**Linux**

```bash
sudo bash /opt/project-nomad/update_nomad.sh   # Command Center + deps
# aplicações instaláveis: pela interface do Command Center
```

**Windows**

```powershell
git pull
docker compose up -d        # recria SÓ os 6 containers do seu YAML (§18.8)
```

> ⚠️ `docker compose up -d` **não** toca nos 17 containers *managed*
> (Ollama, Kiwix, Jellyfin…). Esses o `nomad_admin` recria sozinho quando sobe.

### 19.6 Passar de um sistema para o outro

O repositório é o mesmo; o que muda é o caminho dos dados.

1. **Código:** `git clone` na Linux, `git pull` na Windows. Os `.bat` não
   atrapalham no Linux (só não são executáveis) e os `.sh` não atrapalham no Windows.
2. **Configuração:** o `docker-compose.yml` **não viaja pelo git** por conter
   senhas — copie à parte. Na Linux ele é gerado pelo instalador a partir do
   `install/management_compose.yaml`; na Windows ele já está em `G:\WBC-NOMAD\`.
3. **Dados:** não migram sozinhos.
   - **Windows → Linux:**

     ```bash
     docker cp nomad_admin:/app/storage/. /opt/project-nomad/storage/
     ```

   - **Linux → Windows:** copie de `/opt/project-nomad/storage` para o
     container com `docker cp` (caminho inverso).
4. **Documentação** (`manual.md`, `status.md`, `memoria.md`) é texto puro e vai
   junto no git nos dois lados.

> 📌 A **branch `windows`** deste repositório é a que carrega os `.bat` e toda a
> migração para o Windows. O upstream `Crosstalk-Solutions/project-nomad`
> (branch `main`) é o caminho Linux. Para aproveitar melhorias do upstream:
> `git fetch upstream` e depois `git merge upstream/main`.