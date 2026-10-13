#!/usr/bin/env bash
# Fails if tracked/staged content looks like a secret or company-specific detail.
# Usage: scripts/check-secrets.sh   (run before every commit)
set -u
cd "$(dirname "$0")/.."
PATTERN='ATATT[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY|(TOKEN|SECRET|PASSWORD|API_KEY)=["'"'"']?[A-Za-z0-9_./+-]{12,}|neimanmarcus|saks\.com|nmgcloud|AWS_PROFILE=|CLAUDE_CODE_USE_BEDROCK'
hits=$(git ls-files -z --cached --others --exclude-standard | xargs -0 grep -InE "$PATTERN" -- 2>/dev/null | grep -v '^scripts/check-secrets.sh:')
if [ -n "$hits" ]; then
  echo "Possible secrets / company-specific content found:" >&2
  echo "$hits" | sed -E 's/(=["'"'"']?)[A-Za-z0-9_.\/+-]{12,}/\1<redacted>/' >&2
  exit 1
fi
echo "check-secrets: clean"
