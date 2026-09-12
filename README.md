# Dotfiles

Arch Linux x86_64 com Niri, Noctalia **v5 nativo**, Kitty, Fish, Starship,
asdf, Neovim/LazyVim, Thunar, Docker Engine e Compose. Um pacote Stow, `home`,
e um ponto de entrada, `install.sh`. O instalador pressupõe Arch já instalado:
não instala o sistema operacional, não particiona discos e não configura bootloader.

## Estrutura

```text
home/
├── .tool-versions
└── .config/
    ├── fish/config.fish
    ├── kitty/kitty.conf
    ├── niri/config.kdl
    ├── noctalia/config.toml
    ├── nvim/
    │   ├── init.lua, lazy-lock.json, lazyvim.json, stylua.toml
    │   └── lua/{config,plugins}/
    ├── Thunar/uca.xml
    ├── xfce4/xfconf/xfce-perchannel-xml/thunar.xml
    ├── gtk-3.0/settings.ini
    ├── gtk-4.0/settings.ini
    ├── mimeapps.list
    └── starship.toml
system/greetd/config.toml
packages.txt
install.sh
README.md
.gitignore
```

O conteúdo de LazyVim foi preservado, incluindo extras Angular, Java, YAML,
ESLint, Prettier, DAP, Spring Tools, indentação por linguagem, transparência e
atalhos locais. `lazy-lock.json` não foi regenerado. As adaptações Java ficam
no plugin existente, `lua/plugins/java.lua`.

## Instalação

Requer usuário normal, rede HTTPS, `sudo` configurado, pacman e repositórios
oficiais Arch. O destino é a HOME, com configuração em `~/.config`.
`XDG_CONFIG_HOME` diferente desse caminho é recusado; não há um segundo
mecanismo de implantação XDG. `ASDF_DATA_DIR` absoluto é respeitado.

Em uma HOME sem conflitos:

```bash
git clone https://github.com/tvts1/dotfiles.git
cd dotfiles
./install.sh --dry-run
./install.sh
# Opcional: runtimes e ferramentas de desenvolvimento
./install.sh --with-dev-tools
# Opcional: login e serviços, somente para o próximo boot
./install.sh --configure-system
# As opções podem ser combinadas
./install.sh --with-dev-tools --configure-system --dry-run
```

Use a revisão que contém `home/`. Na implementação isolada ainda sem commit,
revise e use a worktree indicada na seção de migração; o clone remoto não
recebe automaticamente estas alterações.

| Opção | Comportamento |
| --- | --- |
| Sem opções | Verifica conflitos, executa `pacman -Syu --needed`, prepara asdf/completion, simula Stow e aplica `home` |
| `--with-dev-tools` | Também instala somente versões ausentes declaradas em `home/.tool-versions` e gera shims |
| `--configure-system` | Configura greetd e habilita unidades existentes para o próximo boot |
| `--dry-run` | Verifica e mostra operações sem escrever, baixar, criar backups, executar sudo ou instalar runtimes |
| `--help` | Mostra ajuda |

O pacman exibe e confirma uma **atualização completa**, sem `--noconfirm`.
Não há atualização parcial, helper AUR ou troca automática do shell. As
reexecuções preservam instalações compatíveis; ainda consultam a atualização
completa do Arch. Fixar runtimes e revisões de plugins asdf não congela a
distribuição, o catálogo Mason nem as dependências internas dos plugins.

O instalador aborta diante de arquivos reais, links antigos e diretórios
ancestrais vinculados. Não usa `--adopt`, não move conflitos automaticamente e
não remove links genericamente. `--no-folding` mantém diretórios reais para
arquivos produzidos pelas aplicações. Falhas posteriores podem deixar etapas
anteriores concluídas: leia o diagnóstico e repita após corrigir a causa.

## asdf e versões

O gerenciador vem exclusivamente do [binário oficial asdf 0.20.0](https://github.com/asdf-vm/asdf/releases/tag/v0.20.0),
Linux amd64, instalado em `~/.local/bin/asdf`. O SHA-256 fixado no instalador
foi conferido com o `digest` do asset da [API da release](https://api.github.com/repos/asdf-vm/asdf/releases/tags/v0.20.0)
e com o arquivo baixado. Erro de checksum interrompe a instalação; não há
fallback. A seleção de arquitetura é intencionalmente limitada a x86_64.

Se asdf já existir, o instalador mostra caminho, versão e propriedade via
pacman. Reutiliza 0.20.0; versões diferentes exigem revisão manual. Não
sobrescreve executáveis existentes, inclusive os administrados pelo sistema.
A completion oficial é gerada na instalação, fora do pacote versionado;
conteúdo diferente ou symlink nesse destino exige resolução manual.

As versões exatas estão **somente em [home/.tool-versions](home/.tool-versions)**:
Temurin da linha 21, Maven, Node LTS 24 com seu npm e pnpm. Gradle é opcional;
os atalhos Java preferem `mvnw`/`gradlew` do projeto. Não habilite Corepack ou
instale outro pnpm global concorrente.

| Plugin | Origem verificada |
| --- | --- |
| Java | [halcyon/asdf-java](https://github.com/halcyon/asdf-java) |
| Maven | [halcyon/asdf-maven](https://github.com/halcyon/asdf-maven) |
| Node.js | [asdf-vm/asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs) |
| pnpm | [jonathanmorley/asdf-pnpm](https://github.com/jonathanmorley/asdf-pnpm) |

As revisões completas dos plugins estão no `install.sh` e definem o bootstrap
reproduzível de plugins ausentes. Um plugin existente com a mesma origem é
reutilizado na revisão atual e não é atualizado silenciosamente; o instalador
mostra URL e commit. Origens HTTPS, SSH e SCP do mesmo repositório GitHub são
tratadas como equivalentes. Outra origem, um caminho que não seja repositório
Git ou mudanças locais são reportados e interrompem a instalação. Para atualizar
um plugin existente, preserve mudanças locais e execute conscientemente
`asdf plugin update NOME REVISAO`.

O instalador lê o arquivo de versões por caminho absoluto e instala cada
par ferramenta/versão explicitamente, independentemente do diretório atual.
O plugin Node usa node-build; metadados internos podem ser atualizados pelo
próprio plugin, mas a versão Node solicitada permanece fixa.

Em Fish, para selecionar outra versão **num projeto**, substitua os marcadores:

```fish
cd /caminho/do/projeto
asdf list all java
asdf install java VERSAO_EXATA
asdf set java VERSAO_EXATA
asdf install nodejs VERSAO_EXATA
asdf set nodejs VERSAO_EXATA
asdf current
```

A `.tool-versions` mais próxima do diretório de trabalho prevalece sobre a
HOME. Versione-a no projeto. Para mudar o padrão da HOME, edite o arquivo
versionado e execute `./install.sh --with-dev-tools`; `asdf set -u` escreveria
através do symlink. Variáveis `ASDF_JAVA_VERSION`/`ASDF_NODEJS_VERSION` também
podem sobrepor a seleção: confira-as no diagnóstico.

## Fish, ações gráficas e Java

`config.fish` prepara EDITOR/VISUAL, `~/.local/bin`, shims prioritários e
JAVA_HOME antes do bloco interativo. Remove do PATH herdado as entradas dos
gerenciadores antigos, sem apagar suas instalações. Starship, zoxide, FZF,
aliases e integração oficial Java são condicionais. Fish já oferece sugestões
e realce; não há gerenciador de plugins. `extract`, aliases de eza/Neovim,
`rgrep`, `batcat` e `c` foram traduzidos. Opções específicas de histórico e
pilha de diretórios Zsh dão lugar ao comportamento nativo Fish.

O hook oficial Java atualiza JAVA_HOME no prompt. Uma resolução guardada também
ocorre no startup e nas mudanças de diretório, inclusive em `fish -c`.
Nenhuma versão Java fica hardcoded no shell. Se não houver Java selecionado e
instalado, JAVA_HOME herdado é limpo; a inicialização não interativa é silenciosa.

O Kitty continua usando o shell padrão da conta. A ação Thunar para projeto
usa `kitty --directory %f fish -c 'exec nvim .'`: o ambiente é preparado antes
do Neovim mesmo enquanto a conta ainda usa Zsh. `%f` é escapado pelo Thunar e
as três ações aceitam exatamente uma seleção; diretórios para terminal/editor
e imagens para wallpaper. Nenhum nome de arquivo é interpolado em código Fish.

Após `chsh` e novo login, o `niri-session` do Arch carrega o shell de login e
importa o ambiente para systemd/DBus. Não há inicialização de Niri no Fish nem
um arquivo de ambiente duplicado. Aplicações já abertas mantêm o ambiente
antigo até serem abertas novamente.

O [JDTLS exige Java 21 ou superior e Python 3.9+ no launcher](https://github.com/eclipse-jdtls/eclipse.jdt.ls).
Os bundles Spring usados atualmente têm class major 65, portanto também exigem
Java 21. O Neovim resolve o Java padrão da HOME por asdf, valida o major e passa
`--java-executable` somente ao JDTLS. Pode-se definir `JDTLS_JAVA_HOME` para um
JDK 21+ diferente. Essa escolha não muda o JAVA_HOME global do editor.

Para cada projeto, o plugin resolve asdf no diretório raiz, informa o JDK a
`java.configuration.runtimes` e passa JAVA_HOME aos terminais de build. Maven,
Gradle, wrappers e `pom.xml`/toolchains continuam responsáveis pelo target de
compilação. Um projeto Java 17 pode assim usar um JDTLS executando no Java 21.
Abra Neovim pela raiz do projeto para que Node e demais comandos também usem
a `.tool-versions` correta. Toolchains próprias Maven/Gradle podem prevalecer.

## Validar antes de trocar o shell

Após instalar, entre em `fish` e confira caminhos, seleção e versões:

```fish
type -a fish asdf java javac mvn node npm pnpm nvim
command -s asdf
asdf info
asdf current
asdf which java
asdf which node
asdf where java
printf '%s\n' $PATH
printf 'JAVA_HOME=%s\n' "$JAVA_HOME"
java -version
javac -version
mvn -version
node --version
npm --version
pnpm --version
fish -c 'command -s nvim; command -s node; command -s java; echo $JAVA_HOME'
```

Abra também um projeto pela ação do Thunar. Em Neovim:

```vim
:echo exepath('asdf')
:echo exepath('node')
:echo exepath('java')
:echo $JAVA_HOME
:checkhealth vim.lsp
:LspInfo
:Mason
:ConformInfo
```

Na primeira instalação, Lazy/Mason podem baixar plugins e servidores. Use
`:Lazy restore` para respeitar o lock existente; não use atualização global
como parte da migração. Mason deve disponibilizar JDTLS, java-debug-adapter,
java-test, vscode-spring-boot-tools, LemMinX e YAML, além das ferramentas dos
extras web. Reabra Neovim após instalar os bundles Spring/Java. O lock Lazy
não fixa os pacotes Mason; requisitos futuros devem ser revistos antes de
atualizá-los. A compatibilidade funcional completa precisa de um projeto real.

Só depois dos testes:

```bash
getent passwd "$(id -un)"
command -v fish
grep -Fx /usr/bin/fish /etc/shells
chsh -s /usr/bin/fish
```

Encerre a sessão e faça novo login. Mantenha `/usr/bin/zsh`, seus dotfiles e os
gerenciadores antigos para recuperação até validar terminal, ações gráficas,
Java/Spring, Angular e CLIs globais.

Antes de retirar Volta, inventarie `volta list all`, `type -a codex ng` e
`npm ls -g --depth=0` no ambiente antigo. Reinstale no Node asdf os pacotes e
versões realmente usados (inclusive a CLI com que trabalha); não copie
`node_modules`. Após instalações globais via npm, execute `asdf reshim nodejs`
e confira `type -a`/`asdf which` de cada comando. CLIs globais podem precisar de
reinstalação quando se troca a versão Node. Não remova Volta enquanto um comando
necessário ainda depender dele. A remoção de Volta, SDKMAN e Zsh é manual.

## Migração da estrutura anterior e rollback

A implementação foi criada a partir de `541c7d5` em:

```text
/home/tassio/Projects/dotfiles-fish-asdf
branch: refactor/simplify-fish-asdf
```

A árvore original `/home/tassio/Projects/dotfiles`, branch `main`, permanece
como origem dos links ativos e referência de rollback. Foram incorporadas as
mudanças locais de Niri (US/ANSI e Super+Space), do Neovim (lock, extras,
configurações e `java.lua` não rastreado), e o conteúdo útil de `docs/nvim-java.md`.
As mudanças locais do README e testes antigos foram consideradas na documentação
e validação novas; a infraestrutura antiga não foi copiada para `home`.

Revisão, sem migrar:

```bash
cd /home/tassio/Projects/dotfiles-fish-asdf
git status --short
git diff --stat
git diff --find-renames
git diff --check
./install.sh --dry-run --with-dev-tools
```

O último comando deve apontar os links antigos como conflitos. Isso é esperado.
Antes de ligar a configuração nova, escolha um local permanente para a worktree:
os symlinks dependerão dele. Não remova a árvore original nem a worktree após
aplicar Stow. Não rode o instalador antigo para preparar esta migração.

Faça a troca deliberadamente por TTY, após sair da sessão gráfica (Niri observa
arquivos em tempo real; Thunar/xfconf também podem persistir preferências).
Os comandos abaixo são Bash e **não foram executados no host nesta reescrita**:

```bash
old="$HOME/Projects/dotfiles"
new="$HOME/Projects/dotfiles-fish-asdf"
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
# Backup pontual: preserva links, arquivos locais e permissões.
# Inclua somente caminhos que existem; não copie a HOME inteira.
(cd "$HOME" && cp -a --parents .config/niri .config/nvim .config/kitty \
  .config/noctalia .config/Thunar .config/xfce4 .config/gtk-3.0 \
  .config/gtk-4.0 .config/starship.toml .config/mimeapps.list "$backup/")
# Se já existirem, preserve também .tool-versions e .config/fish.
# Guarde separadamente os overrides Noctalia; podem conter dados privados.
# Não apague nem importe esses arquivos indiscriminadamente para o Git.

stow --simulate --delete --no-folding --dir="$old" --target="$HOME" \
  desktop gtk kitty niri noctalia nvim starship thunar
stow --delete --no-folding --dir="$old" --target="$HOME" \
  desktop gtk kitty niri noctalia nvim starship thunar
# Zsh fica vinculado à árvore antiga como recuperação.
"$new/install.sh" --dry-run --with-dev-tools
# Resolva pontualmente os arquivos reais ainda indicados como conflitos:
# mova cada caminho revisado para $backup, preservando sua posição relativa.
"$new/install.sh" --with-dev-tools
```

A origem de cada link deve ser a árvore que o criou. Se os links vierem de
outro checkout, ajuste `old`; não suponha que `--restow home` retire links de
pacotes antigos. Se houver diretório ancestral symlink, registre seu destino,
remova-o pelo Stow de origem quando aplicável e preserve os arquivos externos
antes de recriar um diretório real. Não substitua toda `~/.config`.

Rollback dos links, também por TTY e com aplicações fechadas:

```bash
stow --simulate --delete --no-folding --dir="$new" --target="$HOME" home
stow --delete --no-folding --dir="$new" --target="$HOME" home
stow --simulate --no-folding --dir="$old" --target="$HOME" \
  desktop gtk kitty niri noctalia nvim starship thunar
stow --no-folding --dir="$old" --target="$HOME" \
  desktop gtk kitty niri noctalia nvim starship thunar
# Restaure apenas os arquivos locais que moveu, após conferir seus destinos.
# Se tiver feito chsh, volte ao shell registrado antes da migração:
chsh -s /usr/bin/zsh
```

Arquivos de runtime novos, completions e diretórios vazios podem permanecer;
não os remova por varredura genérica. O rollback Stow não desfaz atualização de
pacotes nem remove runtimes. Backups do greetd e o estado anterior dos serviços
precisam ser restaurados separadamente, se você usou `--configure-system`.

## Configuração, estado e cores

[Noctalia v5](https://docs.noctalia.dev/noctalia/configuration/) separa a base
versionada `~/.config/noctalia/config.toml` dos overrides da interface em
`~/.local/state/noctalia/settings.toml`, que prevalecem. Outros TOMLs deixados
no diretório de configuração também são carregados. Inspecione conflitos de
precedência antes de alterar a base. Não mantenha estado, credenciais, histórico
do clipboard ou caches no Git. Nada disso é apagado pelo instalador.

Tema escuro, paleta derivada do wallpaper, notificações, clipboard, screenshots,
lockscreen e idle (bloqueio aos 600 s, tela aos 660 s) foram mantidos. Templates
oficiais geram CSS GTK e `~/.config/kitty/themes/noctalia.conf`. Esses arquivos
pertencem ao runtime. O Kitty usa `globinclude`, válido também quando o arquivo
não existe: a primeira abertura usa suas cores padrão até o Noctalia gerar a
paleta. Fonte 12.5, padding 12, opacidade 0.92, cursor, scrollback e atalhos são
versionados. GTK conserva fontes e Papirus-Dark, com adw-gtk-theme instalado.

## Desktop, login e serviços

```text
greetd → tuigreet → niri-session → Niri → Noctalia
```

Não há autologin. Niri inicia Noctalia uma vez e mantém polkit-gnome como único
agente explícito; o agente do Noctalia fica desabilitado. GNOME Keyring fornece
Secret Service por ativação DBus. O instalador não modifica PAM; desbloqueio
automático do keyring no greetd depende da configuração PAM prévia. Uma
instalação nova pode pedir desbloqueio manual do cofre.

Portais GNOME/GTK, MIME, gvfs/MTP, thumbnails, arquivos compactados e Thunar-volman
foram preservados. O pacote Niri já fornece `niri-portals.conf`, incluindo Secret
Service via gnome-keyring; não é duplicado aqui. O MIME de diretórios e o handler
Claude existente foram preservados; o handler só funciona se essa aplicação
estiver instalada. Xwayland-satellite é integrado pelo Niri atual.

`--configure-system` verifica executáveis, a conta greeter, display managers
conhecidos ativos/habilitados e o alias `display-manager.service`. Se greetd
já tiver outra configuração, mostra o diff e exige confirmação em terminal;
cria backup datado ao lado do arquivo antes de substituir. Configurações via
symlink são recusadas. Uma configuração idêntica é reutilizada.

NetworkManager, Bluetooth, Docker, greetd e `fstrim.timer` são apenas habilitados
para o próximo boot. Não há `--now`, restart de rede/áudio/Docker nem início de
greetd sobre a sessão atual. TRIM segue o timer do sistema para dispositivos
que suportam discard. Antes de mudar serviços, registre `systemctl is-enabled`
e `systemctl is-active` para permitir rollback específico.

Docker Engine e Compose são preservados, sem Docker Desktop, `daemon.json`,
prune, mudanças de rede, armazenamento ou socket. Use `sudo docker ...` ou
avalie [modo rootless](https://docs.docker.com/engine/security/rootless/).
Participar do [grupo docker equivale a conceder privilégios de root](https://docs.docker.com/engine/install/linux-postinstall/);
se optar conscientemente, `sudo usermod -aG docker "$USER"` e novo login são
passos manuais. O instalador não altera grupos. Valide com
`docker compose version` e `sudo docker info` quando o daemon estiver ativo.

## Wallpaper do Thunar e recuperação do workaround antigo

A ação agora se chama **Set as wallpaper (Noctalia)** e chama o IPC v5
`noctalia msg wallpaper-set %f`. Isso identifica a ação correta, mas **não
remove a duplicação** com a ação nativa. A documentação e o código do
[plugin Thunar](https://github.com/xfce-mirror/thunar/blob/master/plugins/thunar-wallpaper/twp-provider.c)
não ofereceram uma opção runtime suportada para ocultá-lo individualmente;
a opção de compilação não justifica reconstruir o pacote nestes dotfiles.

O workaround antigo foi removido do repositório novo. Se já foi aplicado,
recupere manualmente, sem restaurar um `/etc/pacman.conf` antigo inteiro:

```bash
rg -n 'NoExtract|thunar-wallpaper-plugin' /etc/pacman.conf
ls -l /usr/lib/thunarx-3/thunar-wallpaper-plugin.so
ls -l /var/lib/dotfiles/thunar-wallpaper-plugin/
# Preserve a configuração atual antes da edição.
sudo cp -a /etc/pacman.conf "/etc/pacman.conf.backup-$(date +%Y%m%d-%H%M%S)"
sudoedit /etc/pacman.conf
# Retire apenas o token usr/lib/thunarx-3/thunar-wallpaper-plugin.so
# de NoExtract. Preserve os demais tokens/opções.
sudo pacman -Syu thunar
pacman -Qkk thunar
```

Prefira reinstalar a biblioteca da versão atual à cópia antiga guardada em
`/var/lib/dotfiles/thunar-wallpaper-plugin/`. Feche e reabra Thunar depois, no
momento escolhido por você. Na inspeção desta reescrita não foi encontrada a
entrada ativa NoExtract; a biblioteca nativa estava presente.

## Diagnóstico

- **Java/Node ainda no SDKMAN/Volta:** confira `type -a`, `asdf which`, `$PATH`,
  `JAVA_HOME`, variáveis `ASDF_*_VERSION` e `.tool-versions` do projeto. Use Fish
  novo; shells/processos antigos mantêm o ambiente herdado. Instale as versões
  pedidas antes de retirar os gerenciadores antigos.
- **Funciona no terminal, falha na GUI:** confira a ação Thunar com `fish -c`,
  abra pela raiz do projeto e consulte `exepath()`/JAVA_HOME no Neovim. Após
  trocar o shell, faça novo login para atualizar o ambiente Niri/systemd/DBus.
- **TOML Noctalia parece ignorado:** compare os overrides em `settings.toml` e
  outros TOMLs locais; preserve-os antes de mover qualquer arquivo. Valide a
  base com `noctalia config validate /caminho/novo/home/.config/noctalia/config.toml`.
- **Stow recusa:** use `readlink CAMINHO`, `namei -l CAMINHO` e a simulação com
  `--dir`/`--target` explícitos. Faça backup só do conflito identificado.
- **Login falha:** `Ctrl+Alt+F2`, login por TTY, `systemctl status greetd` e
  `journalctl -u greetd -b`. Confira `getent passwd "$USER"` e os executáveis do
  template. `niri-session` pode ser iniciado pelo TTY apenas sem sessão Niri
  concorrente. Restaure o backup datado do greetd e o shell anterior se preciso;
  não reinicie greetd sobre uma sessão gráfica em uso.

## Atalhos preservados

| Atalho | Ação |
| --- | --- |
| Super+T / E / B | Kitty / Thunar / Firefox |
| Super+Space | Launcher Noctalia mesmo sob inibição de atalhos |
| Super+S / Super+, | Control Center / configurações |
| Alt+Tab / Super+X | Window switcher / menu de sessão |
| Super+Shift+L | Bloquear |
| Super+Q / Super+O | Fechar / overview |
| Super+H/J/K/L ou setas | Navegar |
| Super+Ctrl+H/J/K/L ou setas | Mover |
| Super+U/I ou PageDown/PageUp | Workspaces; Ctrl move a coluna |
| Super+R / Shift+R | Próxima/anterior largura predefinida |
| Super+F / Shift+F | Maximizar coluna / fullscreen |
| Super+V / W / C | Flutuante / abas / centralizar |
| Print / Ctrl+Print / Alt+Print | Região Noctalia / tela Noctalia / janela Niri |
| Super+Escape | Inibição nativa de atalhos |
| Super+Shift+E / Ctrl+Alt+Delete | Sair com confirmação |
| Super+Shift+P | Desligar monitores |
| Teclas multimídia | Volume/brilho via Noctalia; reprodução via playerctl |
| Kitty F2 / Ctrl+Shift+T | Título da aba / nova aba no diretório |
| Kitty F7, depois S/O/P | Salvar / abrir / voltar sessão |
| Neovim Ctrl+S / Alt+Enter / Shift+F6 | Salvar / code action / renomear |
| F5 / F9 / F10 / F11 / Shift+F11 | Debug continuar / breakpoint / step over / into / out |
| `<leader>jr/jR/jt/jb/jc` | Spring Boot / perfil / testes / build / clean |
| `<leader>ju/jo` | Atualizar configuração Java / organizar imports |
| `<leader>tr/tt/tT` | Teste próximo / classe / seleção |

O teclado permanece US/ANSI com numlock, tap e scroll natural. Gaps, bordas,
proporções, regras e demais atalhos estão preservados no único `config.kdl`.
Nenhum monitor ou resolução foi fixado.

## Verificações da reescrita

Sem instalar pacotes ou executar a migração no host: `git diff --check`,
`bash -n`, parsing JSON/TOML/XML, compilação Lua com `loadfile()` e Neovim
`-u NONE`, `niri validate -c` e `noctalia config validate` com arquivo explícito.
Os validadores usaram HOME/XDG temporários; Noctalia não apresentou warnings.
O lock e as configurações reaproveitadas foram comparados com a árvore original.

Fish não estava instalado: o pacote oficial foi extraído em `/tmp`, sem pacman,
para `fish -n`, startup não interativo e PATH idempotente. Stow foi exercitado
em destinos temporários: vazio, reaplicação, arquivo real conflitante, link
antigo, ancestral symlink e preservação de arquivos alheios. Dry-run foi
exercitado nas quatro combinações de opções, comparando o destino antes/depois.
O fluxo padrão foi exercitado com asdf e Stow reais em HOME temporária e
substitutos inofensivos para sudo/pacman. Isso não equivale a uma instalação
completa de Arch ou dos runtimes.

ShellCheck não estava instalado. Não foram feitos teste visual do desktop,
login greetd, alteração de serviços, teste Docker, download dos runtimes,
atualização de plugins Lazy/Mason ou teste funcional Java/Angular completo.
Esses testes ficam para a migração manual e projetos reais.

Fontes oficiais consultadas em 11/09/2026: [asdf/Fish](https://asdf-vm.com/guide/getting-started.html),
[versões Node](https://nodejs.org/dist/index.json), [Temurin 21](https://github.com/adoptium/temurin21-binaries/releases),
[Maven](https://maven.apache.org/docs/history.html), [pnpm](https://github.com/pnpm/pnpm/releases),
[Niri](https://github.com/niri-wm/niri/wiki/Configuration:-Introduction),
[Noctalia IPC v5](https://docs.noctalia.dev/noctalia/ipc/),
[Kitty](https://sw.kovidgoyal.net/kitty/conf/),
[Thunar UCA](https://docs.xfce.org/xfce/thunar/custom-actions) e repositórios Arch.
Host: Niri 26.04, Noctalia `5.0.0_beta.8-1` (CLI v5.0.0), Neovim 0.12.4.
O catálogo online indicava Noctalia 5.1.0 e Fish 4.9.3 para instalação nova;
o pacman usa o catálogo atualizado no momento da instalação, dentro da geração
v5 verificada. O instalador recusa aplicar outra geração Noctalia.
