# Portable ~/.zshrc. Machine/company specifics go in ~/.zshrc.local (untracked).
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git)
[ -r "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim

# Homebrew (macOS Apple Silicon / Intel / Linuxbrew)
for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [ -x "$b" ] && eval "$("$b" shellenv)" && break
done

# nvm (optional)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
elif command -v brew >/dev/null 2>&1 && [ -s "$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]; then
  . "$(brew --prefix nvm)/nvm.sh"
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && . ~/.fzf.zsh
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh 2>/dev/null) 2>/dev/null

function createpatch() {
  local new_branch_name base_commit cherry_commits

  # Define ANSI Colors using Zsh's $'... ' quoting, which forces escape sequence interpretation
  local RESET=$'\e[0m'
  local BOLD_START=$'\e[1m'
  local BLUE=$'\e[34m'
  local YELLOW=$'\e[33m'
  local GREEN=$'\e[32m'
  local RED=$'\e[31m'

  echo "\n${BLUE}${BOLD_START}==========================================${RESET}"
  echo "${BLUE}${BOLD_START}--- 💡 Patch Creation Wizard Started ---${RESET}"
  echo "${BLUE}${BOLD_START}==========================================${RESET}"

  # 1. Prompt for the NEW feature branch name
  # vared still works for input, but the prompt string must use the escaped codes.
  vared -p " ${YELLOW}${BOLD_START}[1/4] New Feature Branch Name:${RESET} " new_branch_name
  if [[ -z "$new_branch_name" ]]; then
    echo "${RED}✘ ERROR: New branch name cannot be empty. Aborting.${RESET}"
    return 1
  fi

  # 2. Prompt for the specific commit hash
  vared -p " ${YELLOW}${BOLD_START}[2/4] Commit Hash to branch off of:${RESET} " base_commit
  if [[ -z "$base_commit" ]]; then
    echo "${RED}✘ ERROR: Commit hash cannot be empty. Aborting.${RESET}"
    return 1
  fi

  # 3. Prompt for commits to cherry-pick
  vared -p " ${YELLOW}${BOLD_START}[3/4] Commits to Cherry-Pick (space-separated SHAs):${RESET} " cherry_commits

  # --- Execution ---

  echo "\n${BLUE}--- Execution Phase ---${RESET}"

  # Step A: Fetch and Prepare
  echo "${GREEN}-->${RESET} Ensuring commit ${BLUE}${base_commit}${RESET} is available locally..."
  git fetch --all || { echo "${YELLOW}⚠️ WARNING: Could not fetch remote changes.${RESET}"; }

  # Step B: Create the new branch off the specific commit
  echo "${GREEN}-->${RESET} Creating new branch ${GREEN}'${new_branch_name}'${RESET} off of commit ${BLUE}${base_commit}${RESET}..."
  git checkout -b "${new_branch_name}" "${base_commit}" || { echo "${RED}✘ ERROR: Failed to create/checkout branch.${RESET}"; return 1; }
  echo "${GREEN}✔ SUCCESS: Checked out new branch '${new_branch_name}'${RESET}"


  # Step C: Cherry-pick the specified commits
  if [[ -n "$cherry_commits" ]]; then
    echo "\n${BLUE}--- Cherry-Picking Commits ---${RESET}"
    local commit_array=("${(@s/ /)cherry_commits}")
    for commit in "${commit_array[@]}"; do
      if [[ -n "$commit" ]]; then
        echo "${YELLOW}  -> Picking commit:${RESET} ${commit}"
        git cherry-pick "${commit}" || {
          echo "${RED}✘ ERROR: Cherry-picking failed on commit ${commit}. Resolve conflicts or abort.${RESET}";
          return 1;
        }
      fi
    done
    echo "${GREEN}✔ SUCCESS: Cherry-picking complete.${RESET}"
  else
    echo "${YELLOW}💡 Note: No additional commits specified for cherry-picking.${RESET}"
  fi

  # Step D: Ask about pushing
  local push_answer
  vared -p "\n ${YELLOW}${BOLD_START}[4/4] Push branch '${new_branch_name}' to remote (yes/no)?${RESET} " push_answer
  push_answer=${(L)push_answer}

  if [[ "$push_answer" == "yes" || "$push_answer" == "y" ]]; then
    echo "${GREEN}-->${RESET} Pushing branch to origin..."
    git push -u origin "${new_branch_name}" || { echo "${RED}✘ ERROR: Push failed. Check credentials/permissions.${RESET}"; return 1; }
    echo "${GREEN}🚀 SUCCESS: Push complete! Your branch is ready.${RESET}"
  else
    echo "${YELLOW}💡 Note: Branch created locally. Skipping push.${RESET}"
  fi

  echo "\n${BLUE}${BOLD_START}--- ✨ Workflow Complete on Branch: $(git branch --show-current) ---${RESET}"
}

# Machine-specific / company config (tokens, profiles, work helpers)
[ -f ~/.zshrc.local ] && . ~/.zshrc.local
