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

repo2="$workspace/repo-fork-pr"
out2="$workspace/out2.txt"
event2="$workspace/event.json"
mkdir -p "$repo2"
cd "$repo2"

git init -b main >/dev/null
git config user.name 'Test User'
git config user.email 'test@example.com'

# Simulate a fork's divergent tag scheme (e.g. Trivir's v2.0.0-trivir.2)
# while package.json correctly reflects the upstream (rockcarver) version.
echo '{"name":"x","version":"4.6.0"}' > package.json
git add package.json
git commit -m 'init' >/dev/null
git tag v2.0.0-trivir.2

cat > "$event2" <<'EOF'
{
  "pull_request": {
    "head": { "repo": { "full_name": "trivir/frodo-cli" } },
    "base": { "repo": { "full_name": "rockcarver/frodo-cli" } }
  }
}
EOF

RELEASE_TYPE='prerelease' GITHUB_OUTPUT="$out2" GITHUB_EVENT_PATH="$event2" bash "$SCRIPT_PATH"

assert_line "$out2" 'base=4.6.0'
assert_line "$out2" 'base_source=package-json-fork-pr'
assert_line "$out2" 'newVersion=4.6.1-1'
assert_line "$out2" 'newTag=v4.6.1-1'

cd "$repo"

echo "All compute-version tests passed"
