# bronius_tool_config

Portable dotfiles for **Alacritty, Neovim (LazyVim), tmux**, plus an optional portable zsh and git setup.
Works on macOS and Linux (apt, dnf, pacman). No company details or secrets are stored here.

## One command

```sh
git clone https://github.com/AlankarKumar/bronius_tool_config.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

That installs packages (Homebrew on macOS; apt/dnf/pacman on Linux), the FiraCode Nerd Font, tpm, links the
configs, and syncs the Neovim and tmux plugins. Re-running is safe.

| Option | Effect |
|---|---|
| `--dry-run` | print everything that would happen, change nothing (**use this first**) |
| `--no-packages` | skip system packages, fonts and Neovim install |
| `--no-plugins` | skip downloading nvim / tmux plugins |
| `--with-zsh` | also install oh-my-zsh and link the portable `~/.zshrc` |
| `--with-git` | also link the portable `~/.gitconfig` (your identity is preserved in `~/.gitconfig.local`) |
| `--copy` | copy instead of symlink |

Anything already in place is **moved, never deleted**, to `~/.dotfiles-backup/<timestamp>/`.

## Daily workflow

```sh
# edit the live files as usual (they ARE the repo files, via symlinks)
vim ~/.tmux.conf
cd ~/dotfiles
scripts/check-secrets.sh      # refuses tokens / company strings
git commit -am "tmux: ..." && git push
# on another machine
cd ~/dotfiles && git pull      # re-run ./install.sh only if new files or packages were added
```

Details: [docs/HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md).

## Machine-specific and company settings

Never commit them. Put them in untracked files that the shared configs load if present:

* `~/.zshrc.local` : tokens, work helpers, profiles, PATH tweaks
* `~/.gitconfig.local` : `user.name`, `user.email`, work includes

## Are symlinks a good idea? Alternatives

Symlinks are the oldest and most widely used dotfiles technique and are very stable on macOS and Linux. The tools involved
(nvim, tmux, alacritty, git, zsh) all follow them without trouble. Caveats: the repo must stay at a stable path,
Windows support is poor, and a tool that rewrites a file by delete-and-recreate (rare) can replace the link with a plain file.

| Approach | Good | Bad | Verdict |
|---|---|---|---|
| **Symlinks via a script (this repo)** | no dependencies, edits land in the repo instantly, easy to understand | you maintain the script | **Recommended now** |
| GNU Stow | same model, declarative, tiny | needs Perl + stow installed | good alternative; layout here is stow-friendly |
| chezmoi | per-OS/host templates, encrypted secrets, copy-based so no link breakage | extra binary, repo files are not the live files (`chezmoi edit/apply`) | upgrade path if you need per-host templating or secrets |
| yadm / bare git repo in `$HOME` | no linking at all | easy to commit junk or secrets; confusing on a work laptop | not recommended |
| Copy script (the old repo) | trivial | drift (it already happened) | rejected |

**Plan:** symlinks now; move to chezmoi only if you start needing per-machine templates or secret management.
