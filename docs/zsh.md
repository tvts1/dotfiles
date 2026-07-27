# Zsh

O módulo `zsh/` separa configuração interativa, ambiente e integrações:

```text
zsh/
├── .zprofile
├── .zshrc
└── .config/zsh/
    ├── aliases.zsh
    ├── environment.zsh
    ├── functions.zsh
    ├── integrations.zsh
    └── plugins.zsh
```

`.zprofile` carrega apenas o ambiente de login. `.zshrc` configura histórico,
completion, aliases, funções e integrações interativas.

## Integrações condicionais

- SDKMAN só é carregado quando `~/.sdkman/bin/sdkman-init.sh` existe.
- Volta só entra no `PATH` quando `~/.volta/bin` existe.
- Starship, zoxide e FZF só são inicializados quando seus comandos existem.
- Autosuggestions e syntax highlighting usam os caminhos do pacote Arch, com
  fallback seguro e sem erro quando ausentes.
- O arquivo de ambiente possui guarda de carga para não inicializar SDKMAN ou
  consultar o locale duas vezes em um shell de login interativo.

SDKMAN administra os caminhos de Java, Maven e Gradle. Volta administra Node,
npm, pnpm e ferramentas globais do ecossistema Node.

## Verificação

```bash
zsh -n zsh/.zshrc
zsh -n zsh/.zprofile
find zsh/.config/zsh -type f -name "*.zsh" -exec zsh -n {} \;
zsh -lic 'command -v sdk; command -v volta; command -v starship; command -v zoxide; command -v fzf'
```

O teste estrutural também carrega o ambiente duas vezes em uma `HOME`
temporária e confirma que ele permanece silencioso e idempotente.
