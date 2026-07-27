# Dotfiles

Configuração pessoal e portátil para Arch Linux com Hyprland, gerenciada por
GNU Stow. O instalador prepara o desktop, cria backups de conflitos e pode ser
executado novamente sem substituir arquivos pessoais silenciosamente.

## Ambiente suportado

- Arch Linux e Hyprland
- Zsh, Kitty e Starship
- Neovim com LazyVim
- Waybar, Walker e Elephant
- Thunar
- zoxide, FZF, SDKMAN e Volta

O Kitty não define um shell próprio: ele usa o shell padrão da conta. O
instalador configura o Zsh, mas não altera o shell de login do usuário.

## Pré-requisitos

Execute como usuário normal em uma instalação Arch com acesso à rede e `sudo`
configurado. `git` é necessário para clonar o repositório; o bootstrap garante
`git` e `base-devel` antes de instalar o restante.

## Instalação

```bash
git clone https://github.com/tvts1/dotfiles.git
cd dotfiles
./install.sh
```

Para incluir a toolchain opcional de Java e Node:

```bash
./install.sh --with-dev-tools
```

O instalador não remove arquivos pessoais, não muda o shell de login e registra
conflitos em `~/.dotfiles-backup/<timestamp>/`.

## Módulos

Os módulos aplicados pelo Stow são:

```text
desktop  gtk  hypr  kitty  nvim  starship  thunar  walker  waybar  zsh
```

Arquivos dependentes da máquina, como o wallpaper atual, o Hyprlock renderizado
e links do tema GTK 4, são gerados localmente e não são versionados.

## Validação

Os testes estruturais usam uma `HOME` temporária para simular o Stow e o
wallpaper:

```bash
./scripts/test-structure.sh
git diff --check
bash -n install.sh
find scripts -type f -name "*.sh" -exec bash -n {} \;
```

Quando `luac` estiver instalado:

```bash
find hypr nvim -type f -name "*.lua" -exec luac -p {} \;
```

Para verificar somente a integração Walker/Elephant:

```bash
bash scripts/configure-elephant.sh --check
elephant listproviders
systemctl --user status elephant.service --no-pager
```

## Rollback

Antes de restaurar algo, revise os backups:

```bash
find ~/.dotfiles-backup -maxdepth 3 -type f -o -type l
```

Remova apenas os links do módulo desejado com `stow --delete`, usando este
repositório como `--dir` e a sua `HOME` como `--target`. Depois, mova o arquivo
correspondente do backup para o caminho original. Não copie um diretório de
backup inteiro sem revisar o conteúdo.

## Documentação

- [Zsh e integrações](docs/zsh.md)
- [Toolchain de desenvolvimento](docs/dev-toolchain.md)
- [Walker e Elephant](docs/walker-elephant.md)
- [Integração de wallpaper do Thunar](docs/thunar-wallpaper-plugin.md)
