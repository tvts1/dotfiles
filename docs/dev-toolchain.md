# Optional Development Toolchain

The default installer does not install Java or Node tooling. Use:

```bash
./install.sh --with-dev-tools
```

or run the toolchain script directly:

```bash
bash scripts/install-dev-toolchain.sh
```

Installed components:

- SDKMAN in `$HOME/.sdkman`
- Java through SDKMAN
- Maven through SDKMAN
- Volta in `$HOME/.volta`
- Node through Volta
- npm bundled with Node
- pnpm through Volta native pnpm support

Supported options:

```bash
bash scripts/install-dev-toolchain.sh --check
bash scripts/install-dev-toolchain.sh --dry-run
bash scripts/install-dev-toolchain.sh --java VERSION
bash scripts/install-dev-toolchain.sh --maven VERSION
bash scripts/install-dev-toolchain.sh --node VERSION
bash scripts/install-dev-toolchain.sh --skip-java
bash scripts/install-dev-toolchain.sh --skip-node
```

Defaults:

- Empty `JAVA_VERSION` runs `sdk install java`, SDKMAN's latest stable default.
- Empty `MAVEN_VERSION` runs `sdk install maven`, SDKMAN's latest stable default.
- `NODE_VERSION=lts` runs `volta install node`, Volta's latest LTS default.

Zsh loads SDKMAN and Volta from
`zsh/.config/zsh/environment.zsh`. SDKMAN remains responsible for the Java,
Maven and Gradle paths; Volta remains responsible for Node, npm and pnpm. A new
Zsh login session should resolve:

```bash
zsh -lic 'command -v sdk; command -v java; command -v javac; command -v mvn; command -v gradle; command -v volta; command -v node; command -v npm; command -v pnpm'
```
