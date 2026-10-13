# How this setup works

## The model

`~/dotfiles` is a normal git clone. The installer makes the places where tools look for config into **symlinks** that
point back into the clone:

```
~/.config/nvim        -> ~/dotfiles/nvim
~/.config/alacritty   -> ~/dotfiles/alacritty
~/.tmux.conf          -> ~/dotfiles/tmux/.tmux.conf
~/.gitconfig          -> ~/dotfiles/git/.gitconfig     (--with-git)
~/.config/git/ignore  -> ~/dotfiles/git/ignore         (--with-git)
~/.zshrc              -> ~/dotfiles/zsh/.zshrc         (--with-zsh)
```

Editing `~/.tmux.conf` therefore edits `~/dotfiles/tmux/.tmux.conf`; `git status` in the repo shows it at once.
There is no sync step and nothing to copy back.

## What `install.sh` does, in order

1. **Detect the OS** (`uname`) and, on Linux, the package manager (apt, dnf or pacman).
2. **Install packages** (skip with `--no-packages`). macOS: Homebrew (installed if missing) + `Brewfile`.
   Linux: distro packages; if Neovim is older than 0.10 a current release is unpacked into `~/.local/opt/nvim`; the Nerd Font goes
   to `~/.local/share/fonts`.
3. **Clone plugin managers**: tpm (tmux) and, with `--with-zsh`, oh-my-zsh.
4. **Link configs.** For each target: already the right link -> nothing; something else exists -> moved to
   `~/.dotfiles-backup/<timestamp>/`; then the link is created. Alacritty's OS overlay is chosen by symlinking
   `alacritty/os.toml` to `alacritty.macos.toml` or `alacritty.linux.toml` (it is git-ignored; the shared
   `alacritty.toml` imports it).
5. **Sync plugins** (skip with `--no-plugins`): `nvim --headless "+Lazy! restore"` installs the exact versions in
   `nvim/lazy-lock.json`; tpm installs the tmux plugins.

It never deletes user files, and `--dry-run` prints every command without executing.

## Where things live

| Path | Purpose |
|---|---|
| `install.sh` | the one-command bootstrap |
| `nvim/` | LazyVim config; `lazy-lock.json` pins plugin versions for reproducibility |
| `alacritty/` | `alacritty.toml` (shared) + `alacritty.{macos,linux}.toml` (overlays) |
| `tmux/.tmux.conf` | tmux config (prefix `Ctrl-a`, catppuccin, sessionx, vim navigation) |
| `zsh/.zshrc`, `git/.gitconfig` | portable shell and git config; load `~/.zshrc.local` / `~/.gitconfig.local` |
| `Brewfile` | macOS packages |
| `scripts/check-secrets.sh` | scans for tokens and company-specific strings before you commit |

## Keeping company details out

The shared files contain nothing identifying. Work-specific settings (email, tokens, internal helpers, cloud profiles) go
into the untracked `*.local` files, which are listed in `.gitignore`. `scripts/check-secrets.sh` greps the tracked and
untracked-but-not-ignored files for token patterns and company strings; run it before each commit (or install it as a git
pre-commit hook: `ln -s ../../scripts/check-secrets.sh .git/hooks/pre-commit`).

## Common tasks

* **Add a nvim plugin:** drop a file in `nvim/lua/plugins/`, open nvim, then commit it and the updated `lazy-lock.json`.
* **New machine:** clone + `./install.sh`. Then create `~/.gitconfig.local` / `~/.zshrc.local` if needed.
* **Undo:** move the files from `~/.dotfiles-backup/<timestamp>/` back; delete the symlinks.
* **Symlinks unavailable:** `./install.sh --copy` (you then re-run it after changes).

## Platform notes

* macOS-only Alacritty settings (`buttonless` decorations, `blur`, `option_as_alt`) are in `alacritty.macos.toml`.
* On Debian/Ubuntu `fd` is installed as `fdfind`; the installer links it as `fd` in `~/.local/bin`.
* tmux plugins are fetched by tpm on first run; press `prefix + I` (Ctrl-a, Shift-i) if they are missing.
