# STATUS — WBC NOMAD

> Snapshot do estado atual. Atualizado a cada sessão.
> Memória acumulada e histórico: [`memoria.md`](./memoria.md)

**Última atualização:** 2026-10-04 16:20 -03
**Máquina:** `qual-ano-do-ryzen-5-1400` (Ryzen 5 1400, RTX 3060)
**Usuário:** wilson
**Nome do projeto:** WBC NOMAD
**Versão do código:** 1.35.0

---

## Resumo

Código-fonte completo na máquina. **Instalação ainda não executada.**
Docker ausente, `/opt/project-nomad` inexistente, nenhum recurso baixado.

---

## Componentes

| Componente | Status | Detalhe |
|---|---|---|
| Código-fonte | ✅ OK | `/home/wilson/WBC-NOMAD` — 21 MB, ~700 arquivos |
| Versão | ✅ OK | 1.35.0 (igual à release upstream v1.35.0) |
| `git` | ✅ OK | 2.43.0, identidade `Wilson Barbosa Coimbra` |
| Workflows CI | ⏜ Excluídos | `.github/workflows/` no `.gitignore` — preservados em disco |
| Repo GitHub pessoal | ✅ Sincronizado | `wwbcinformatica-gif/WBC-NOMAD` — branch `main`, 2 commits |
| Docker | ❌ Falta | Não instalado, serviço `inactive` |
| Docker Compose v2 | ❌ Falta | Exige plugin v2 (não serve o v1) |
| `/opt/project-nomad/` | ❌ Falta | Nunca criado |
| Command Center | ⬜ Pendente | Containers não sobem |
| Painel web | ⬜ Pendente | Esperado em `http://localhost:8080` |
| Recursos (ZIM/mapas) | ⬜ Pendente | 0 baixados — 30 GB a 1 TB+ |
| Modelos Ollama | ⬜ Pendente | 0 baixados |
| Driver NVIDIA | ⚠️ Quebrado | Módulo não carregado (ver bloqueadores) |


---

## Bloqueadores

### 1. `sudo` exige senha
Não tenho como digitar senha. Comandos com `sudo` precisam ser executados
diretamente no terminal do usuário.

### 3. Driver NVIDIA não carregado
```
nvidia-smi → "couldn't communicate with the NVIDIA driver"
lsmod | grep nvidia → vazio
```
Apesar disso o módulo existe e está assinado:
- `/lib/modules/7.0.0-38-generic/updates/dkms/nvidia.ko.zst`
- DKMS `nvidia/580.178.04` instalado para 6.17.0-20 e 7.0.0-38
- SecureBoot ativo com MOK válido

O `lspci -k` não mostra driver vinculado à GA104 — nem o `nouveau`.
Suspeita: queda abrupta de energia deixou o módulo descarregado.
**Não bloqueia o NOMAD** — o instalador só avisa (`return 0`), nunca aborta.

```bash
sudo modprobe nvidia && nvidia-smi
```

---

## Próximos passos

### 1. Instalar o NOMAD (bloqueia todo o resto)
```bash
printf 'y\ny\n' | sudo bash /home/wilson/WBC-NOMAD/install/install_nomad.sh 2>&1 | tee ~/nomad-install.log
```
Responde automaticamente os 2 prompts (confirmação + aceite da licença Apache 2.0).
O log fica em `~/nomad-install.log` — importante porque o PC já desligou no meio
de um processo antes.

### 2. Sincronizar as atualizações de `status.md` / `memoria.md`
```bash
cd /home/wilson/WBC-NOMAD && git add -A && git commit -m "docs: atualiza status" && git push
```
O `credential.helper store` evita digitar o token a cada push.

### 3. Recuperar a GPU
```bash
sudo modprobe nvidia && nvidia-smi
```

### 4. Baixar os recursos
Abrir `http://localhost:8080` → Easy Setup → escolher o que baixar.
337 GB livres de 468 GB (25% usado) — suficiente, mas "baixar tudo" pode encher.

---

## Referência rápida

| Item | Valor |
|---|---|
| Código local | `/home/wilson/WBC-NOMAD` |
| Dir de instalação | `/opt/project-nomad` |
| Painel | `http://localhost:8080` |
| Upstream | `Crosstalk-Solutions/project-nomad` |
| Repo pessoal | `wwbcinformatica-gif/WBC-NOMAD` |
| Sessões anteriores | `~/PROJETO NOMAD 1.txt`, `~/PROJETO NOMAD 2.txt` |
| Log da instalação | `~/nomad-install.log` |
| Start / Stop | `/opt/project-nomad/start_nomad.sh` · `stop_nomad.sh` |
| Atualizar | `/opt/project-nomad/update_nomad.sh` |
