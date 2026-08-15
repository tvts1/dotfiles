# Dotfiles

Configuração pessoal e portátil para Arch Linux com Niri e Noctalia v5,
gerenciada por GNU Stow. O instalador prepara o desktop, cria backups de
conflitos e pode ser executado novamente sem substituir arquivos pessoais
silenciosamente.

## Ambiente

- Niri com scrollable tiling e Noctalia v5 nativo
- Kitty, Zsh, Starship, zoxide e FZF
- Neovim com LazyVim
- SDKMAN para Java e Maven
- Volta para Node.js, npm e pnpm
- Docker e Docker Compose
- Thunar, Firefox, PipeWire, NetworkManager e BlueZ
- GNOME Keyring como Secret Service para credenciais de aplicações
- greetd com tuigreet para login em `niri-session`

O Kitty usa o shell padrão da conta. O instalador configura o Zsh como shell
de login e mantém SDKMAN e Volta em módulos próprios da configuração do Zsh.

## Instalação

Execute como usuário normal em uma instalação Arch com rede e `sudo`
configurado:

```bash
git clone https://github.com/tvts1/dotfiles.git
cd dotfiles
./install.sh
```

Para instalar também Java/Maven via SDKMAN e Node/npm/pnpm via Volta:

```bash
./install.sh --with-dev-tools
```

O instalador usa Pacman, Paru e GNU Stow. Conflitos são movidos para
`~/.dotfiles-backup/<timestamp>/`. Ele habilita NetworkManager, Bluetooth,
Docker, o timer de TRIM e o greetd; não adiciona automaticamente o usuário ao
grupo `docker`. O greetd é apenas habilitado para o próximo boot e não é
iniciado sobre a sessão gráfica atual.

O pacote `xwayland-satellite` é detectado e integrado automaticamente pelo
Niri atual.

## Boot / Login

O login gráfico segue este fluxo, sem autologin e sem inicialização pelo Zsh:

```text
greetd → tuigreet → niri-session → Niri → Noctalia
```

O template versionado em `system/greetd/config.toml` é instalado por
`scripts/configure-greetd.sh`. O script resolve os caminhos de `tuigreet` e
`niri-session`, preserva uma configuração externa antes de substituí-la e
recusa continuar se GDM, SDDM, LightDM ou Ly estiver habilitado. O Noctalia é
iniciado diretamente pelo `spawn-at-startup` do Niri.

Os outros terminais virtuais continuam disponíveis. Se o login gráfico falhar,
use `Ctrl + Alt + F2`, autentique-se no TTY e verifique:

```bash
systemctl status greetd
journalctl -u greetd -b
niri-session
```

## Módulos Stow

```text
desktop  gtk  kitty  niri  noctalia  nvim  starship  thunar  zsh
```

O arquivo declarativo do Noctalia fica em
`~/.config/noctalia/config.toml`. Alterações feitas pela interface são gravadas
separadamente em `~/.local/state/noctalia/settings.toml` e têm precedência.

## Atalhos

| Atalho | Ação |
| --- | --- |
| `Super + T` | Kitty |
| `Super + E` | Thunar |
| `Super + B` | Firefox |
| `Super + Space` | Launcher do Noctalia |
| `Super + S` | Control Center do Noctalia |
| `Super + ,` | Configurações do Noctalia |
| `Alt + Tab` | Window switcher do Noctalia |
| `Super + X` | Menu de sessão do Noctalia |
| `Super + Shift + L` | Bloquear sessão |
| `Super + Q` | Fechar janela |
| `Super + O` | Overview do Niri |
| `Super + H/J/K/L` | Navegar entre colunas/janelas |
| `Super + Ctrl + H/J/K/L` | Mover colunas/janelas |
| `Super + U/I` | Workspace seguinte/anterior |
| `Super + R` | Alternar largura da coluna |
| `Super + F` | Maximizar coluna |
| `Super + V` | Alternar janela flutuante |
| `Print` | Capturar região com o Noctalia |
| `Ctrl + Print` | Capturar tela inteira com o Noctalia |
| `Alt + Print` | Capturar janela com o Niri |
| `Super + Shift + E` | Encerrar a sessão Niri com confirmação |

As teclas multimídia controlam volume e brilho via IPC do Noctalia. As teclas
de reprodução usam `playerctl`.

## Validação

```bash
./scripts/test-structure.sh
git diff --check
bash -n install.sh
find scripts -type f -name "*.sh" -exec bash -n {} \;
niri validate -c niri/.config/niri/config.kdl
noctalia config validate noctalia/.config/noctalia/config.toml
```

O menu de sessão/power permanece acessível pela interface do Noctalia e pelo
atalho `Super + X`. `Super + Escape` continua reservado ao controle nativo de
inibição de atalhos do Niri.

## Rollback do Stow

Antes de restaurar algo, revise os backups:

```bash
find ~/.dotfiles-backup -maxdepth 3 \( -type f -o -type l \)
```

Remova apenas os links do módulo desejado com `stow --delete`, usando este
repositório como `--dir` e a sua `HOME` como `--target`. Depois mova somente os
arquivos revisados do backup para seus destinos.

## Documentação

- [Zsh e integrações](docs/zsh.md)
- [Toolchain de desenvolvimento](docs/dev-toolchain.md)
- [Integração de wallpaper do Thunar](docs/thunar-wallpaper-plugin.md)
