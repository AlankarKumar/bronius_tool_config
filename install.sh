#!/usr/bin/env bash
# One-command bootstrap for macOS and Linux.
#
#   git clone https://github.com/AlankarKumar/bronius_tool_config.git ~/dotfiles
#   cd ~/dotfiles && ./install.sh
#
# Idempotent: safe to re-run. Existing files are moved to
# ~/.dotfiles-backup/<timestamp>/ before anything is linked; nothing is deleted.
set -u

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.dotfiles-backup/$STAMP"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

DRY=0; PLUGINS=1; PACKAGES=1; WITH_ZSH=0; WITH_GIT=0; COPY=0; FAILED=0

usage() {
  cat <<EOF
Usage: ./install.sh [options]
  --dry-run       show what would happen, change nothing
  --no-packages   skip installing system packages / fonts / neovim
  --no-plugins    skip downloading nvim/tmux plugins (faster; do it later)
  --with-zsh      also install oh-my-zsh and link the portable ~/.zshrc
  --with-git      also link the portable ~/.gitconfig (identity is kept in ~/.gitconfig.local)
  --copy          copy files instead of symlinking (for systems without symlink support)
  -h, --help      this help
Default links: nvim, alacritty, tmux. zsh and git are opt-in.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --no-packages) PACKAGES=0 ;;
    --no-plugins) PLUGINS=0 ;;
    --with-zsh) WITH_ZSH=1 ;;
    --with-git) WITH_GIT=1 ;;
    --copy) COPY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m%s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
# run: print in dry-run mode, otherwise execute. Failures are recorded, not fatal.
run() {
  if [ "$DRY" = 1 ]; then printf '   [dry-run] %s\n' "$*"; return 0; fi
  "$@" || { warn "failed: $*"; FAILED=1; return 1; }
}

# ---------- OS detection ----------
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM=macos ;;
  Linux)  PLATFORM=linux ;;
  *) echo "Unsupported OS: $OS (macOS and Linux only)" >&2; exit 1 ;;
esac
ARCH="$(uname -m)"
say "Platform: $PLATFORM ($ARCH)  dotfiles: $DOTFILES"
[ "$DRY" = 1 ] && say "DRY RUN: no changes will be made"

SUDO=""
if [ "$(id -u)" != 0 ] && have sudo; then SUDO="sudo"; fi

# ---------- packages ----------
install_packages_macos() {
  if ! have brew; then
    say "Installing Homebrew"
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [ -x "$b" ] && eval "$("$b" shellenv)" && break
    done
  fi
  have brew || { [ "$DRY" = 1 ] || warn "Homebrew not available; skipping packages"; return; }
  say "brew bundle"
  run brew bundle --file="$DOTFILES/Brewfile"
}

install_packages_linux() {
  local pkgs="git zsh tmux fzf zoxide ripgrep fd-find curl unzip tar"
  if have apt-get; then
    say "apt: installing packages"
    run $SUDO apt-get update
    run $SUDO apt-get install -y $pkgs neovim
    run $SUDO apt-get install -y alacritty || warn "alacritty not in apt repos; install it manually (https://alacritty.org)"
    # Debian/Ubuntu name the fd binary fdfind
    if [ "$DRY" = 0 ] && have fdfind && ! have fd; then
      mkdir -p "$HOME/.local/bin" && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
  elif have dnf; then
    say "dnf: installing packages"
    run $SUDO dnf install -y git zsh tmux fzf zoxide ripgrep fd-find curl unzip tar neovim alacritty
  elif have pacman; then
    say "pacman: installing packages"
    run $SUDO pacman -Sy --needed --noconfirm git zsh tmux fzf zoxide ripgrep fd curl unzip tar neovim alacritty
  else
    warn "No supported package manager (apt/dnf/pacman). Install manually: tmux neovim alacritty fzf zoxide ripgrep fd git zsh"
  fi
}

# LazyVim needs a recent Neovim; distro packages are often too old.
ensure_recent_nvim_linux() {
  local want_minor=10 minor=0
  if have nvim; then
    minor="$(nvim --version | head -1 | sed -E 's/^NVIM v[0-9]+\.([0-9]+).*/\1/')"
    case "$minor" in ''|*[!0-9]*) minor=0 ;; esac
  fi
  [ "$minor" -ge "$want_minor" ] && return 0
  local asset
  case "$ARCH" in
    x86_64|amd64)  asset="nvim-linux-x86_64.tar.gz" ;;
    aarch64|arm64) asset="nvim-linux-arm64.tar.gz" ;;
    *) warn "Neovim is older than 0.$want_minor and no prebuilt binary for $ARCH"; return ;;
  esac
  say "Installing recent Neovim ($asset) to ~/.local/opt"
  run mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  if [ "$DRY" = 1 ]; then return; fi
  local tmp; tmp="$(mktemp -d)"
  if curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/$asset" -o "$tmp/nvim.tgz" \
     && rm -rf "$HOME/.local/opt/nvim" && mkdir -p "$HOME/.local/opt/nvim" \
     && tar -xzf "$tmp/nvim.tgz" -C "$HOME/.local/opt/nvim" --strip-components=1; then
    ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    warn "Make sure ~/.local/bin is on your PATH (the bundled .zshrc does this)."
  else
    warn "Neovim download failed"; FAILED=1
  fi
  rm -rf "$tmp"
}

install_font_linux() {
  fc-list 2>/dev/null | grep -qi "FiraCode Nerd" && return 0
  say "Installing FiraCode Nerd Font to ~/.local/share/fonts"
  run mkdir -p "$HOME/.local/share/fonts"
  if [ "$DRY" = 1 ]; then return; fi
  local tmp; tmp="$(mktemp -d)"
  if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -o "$tmp/f.zip" \
     && unzip -oq "$tmp/f.zip" -d "$HOME/.local/share/fonts/FiraCodeNerd"; then
    have fc-cache && fc-cache -f >/dev/null 2>&1
  else
    warn "Font download failed; install 'FiraCode Nerd Font' manually"
  fi
  rm -rf "$tmp"
}

if [ "$PACKAGES" = 1 ]; then
  if [ "$PLATFORM" = macos ]; then
    install_packages_macos
  else
    install_packages_linux
    ensure_recent_nvim_linux
    install_font_linux
  fi
else
  say "Skipping packages (--no-packages)"
fi

# ---------- plugin managers ----------
clone_if_missing() { # url dest
  if [ -d "$2/.git" ]; then return 0; fi
  say "Cloning $1"
  run mkdir -p "$(dirname "$2")"
  run git clone --depth 1 "$1" "$2"
}
have git || warn "git not found; cannot bootstrap tpm / oh-my-zsh"
clone_if_missing https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
[ "$WITH_ZSH" = 1 ] && clone_if_missing https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"

# ---------- linking ----------
link() { # src dest
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then warn "missing in repo: $src"; return; fi
  if [ "$COPY" = 0 ] && [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "   ok      $dest"; return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local rel="${dest#$HOME/}"
    echo "   backup  $dest -> $BACKUP/$rel"
    run mkdir -p "$(dirname "$BACKUP/$rel")"
    run mv "$dest" "$BACKUP/$rel"
  fi
  run mkdir -p "$(dirname "$dest")"
  if [ "$COPY" = 1 ]; then
    echo "   copy    $src -> $dest"; run cp -R "$src" "$dest"
  else
    echo "   link    $dest -> $src"; run ln -s "$src" "$dest"
  fi
}

say "Linking configs"
# Alacritty: pick the OS-specific overlay imported by alacritty.toml
run ln -sfn "alacritty.$PLATFORM.toml" "$DOTFILES/alacritty/os.toml"
link "$DOTFILES/nvim"                "$CONFIG/nvim"
link "$DOTFILES/alacritty"           "$CONFIG/alacritty"
link "$DOTFILES/tmux/.tmux.conf"     "$HOME/.tmux.conf"

if [ "$WITH_GIT" = 1 ]; then
  # Keep the existing identity: seed ~/.gitconfig.local from the current file once.
  if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ] && [ ! -e "$HOME/.gitconfig.local" ]; then
    echo "   keep    existing ~/.gitconfig -> ~/.gitconfig.local (your identity stays on this machine)"
    run cp "$HOME/.gitconfig" "$HOME/.gitconfig.local"
  fi
  link "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"
  link "$DOTFILES/git/ignore"     "$CONFIG/git/ignore"
fi

if [ "$WITH_ZSH" = 1 ]; then
  link "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
  [ -e "$HOME/.zshrc.local" ] || echo "   note    put machine/company-specific shell config in ~/.zshrc.local"
fi

# ---------- post-install ----------
if [ "$PLUGINS" = 1 ] && have nvim; then
  say "Syncing Neovim plugins (lazy.nvim, pinned by lazy-lock.json); this can take a minute"
  run bash -c 'nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1'
fi
if [ "$PLUGINS" = 1 ] && [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
  say "Installing tmux plugins (tpm)"
  run bash -c '"$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1'
fi

echo
if [ "$FAILED" = 1 ]; then
  warn "Finished with warnings; review the messages above."
else
  say "Done."
fi
[ -d "$BACKUP" ] && echo "   Previous files saved in: $BACKUP"
cat <<EOF

Next steps:
  * Set your terminal font to "FiraCode Nerd Font" if icons look broken.
  * Open tmux and press prefix + I (Ctrl-a, then Shift-i) if plugins are missing.
  * Identity/secrets/company settings go in ~/.gitconfig.local and ~/.zshrc.local (never committed).
  * Before committing dotfile changes: scripts/check-secrets.sh
EOF
exit "$FAILED"
