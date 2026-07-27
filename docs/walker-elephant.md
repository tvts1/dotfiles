# Walker And Elephant

Walker only renders the launcher UI. Application search comes from Elephant
providers. If Elephant is not running, or if the `desktopapplications` provider
is missing, Walker opens but returns `No Results` for entries such as `firefox`,
`kitty`, or `thunar`.

The supported provider listing command for the current Elephant CLI is:

```bash
elephant listproviders
```

Required providers:

- `desktopapplications`, from `elephant-desktopapplications`
- `providerlist`, from `elephant-providerlist`
- `runner`, from `elephant-runner`

Elephant service management is provided by Elephant itself:

```bash
elephant service enable
systemctl --user status elephant.service --no-pager
```

Hyprland asks the systemd user manager to start `elephant.service`, then starts
Walker once using `walker --gapplication-service`. Elephant still runs under
systemd supervision. `systemctl start` waits for the unit transition before the
Walker process is launched, avoiding a second direct Elephant process and the
startup race seen in sessions that do not activate `graphical-session.target`.
