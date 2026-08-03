#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/scripts/compute-version.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "compute-version script not found at $SCRIPT_PATH"
  exit 1
fi

workspace="$(mktemp -d "${TMPDIR:-/tmp}/version-bump-test.XXXXXX")"
trap 'rm -rf "$workspace"' EXIT

assert_line() {
  local file="$1"
  local expected="$2"
  if ! grep -q "^${expected}$" "$file"; then
    echo "Expected line not found: ${expected}"
    cat "$file"
    exit 1
  fi
}

repo="$workspace/repo"
out="$workspace/out.txt"
mkdir -p "$repo"
cd "$repo"

git init -b main >/dev/null
git config user.name 'Test User'
git config user.email 'test@example.com'

echo '{"name":"x","version":"1.0.1"}' > package.json
git add package.json
git commit -m 'init' >/dev/null

git tag v1.0.1
git tag v1.0.1-1

RELEASE_TYPE='patch' GITHUB_OUTPUT="$out" bash "$SCRIPT_PATH"

assert_line "$out" 'base=1.0.1'
assert_line "$out" 'base_source=latest-stable-tag'
assert_line "$out" 'base_ref=v1.0.1'
assert_line "$out" 'newVersion=1.0.2'
assert_line "$out" 'newTag=v1.0.2'

echo "All compute-version tests passed"
