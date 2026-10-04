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

# Runs the compute script with an explicit base version and asserts output
# lines. Usage: run_case <release-type> <current-version> <prerelease-id> \
#   [expected-line ...]
run_case() {
  local release_type="$1"
  local current_version="$2"
  local prerelease_id="$3"
  shift 3
  : > "$out"
  RELEASE_TYPE="$release_type" CURRENT_VERSION="$current_version" \
    PRERELEASE_IDENTIFIER="$prerelease_id" GITHUB_OUTPUT="$out" \
    bash "$SCRIPT_PATH" > /dev/null
  local expected
  for expected in "$@"; do
    assert_line "$out" "$expected"
  done
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

# --- premajor and regression matrix (explicit current-version) ---

# premajor from a stable base starts the next major prerelease train.
run_case 'premajor' '4.18.0' '' \
  'base=4.18.0' \
  'newVersion=5.0.0-1' \
  'newTag=v5.0.0-1' \
  'preRelease=true' \
  'publishTag=next' \
  'action_release_type=prerelease'

# premajor on an active premajor train continues via numeric suffix.
run_case 'premajor' '5.0.0-1' '' \
  'newVersion=5.0.0-2' \
  'newTag=v5.0.0-2' \
  'preRelease=true' \
  'publishTag=next'

# prerelease on the same base is unchanged (existing behavior).
run_case 'prerelease' '5.0.0-1' '' \
  'newVersion=5.0.0-2' \
  'newTag=v5.0.0-2' \
  'preRelease=true' \
  'publishTag=next'

# prerelease from a stable base is unchanged (existing behavior).
run_case 'prerelease' '4.18.0' '' \
  'newVersion=4.18.1-1' \
  'newTag=v4.18.1-1' \
  'preRelease=true' \
  'publishTag=next'

# major from a stable base is unchanged (existing behavior).
run_case 'major' '4.18.0' '' \
  'newVersion=5.0.0' \
  'newTag=v5.0.0' \
  'preRelease=false' \
  'publishTag=latest' \
  'action_release_type=full'

# premajor honors PRERELEASE_IDENTIFIER on a fresh train.
run_case 'premajor' '4.18.0' 'rc' \
  'newVersion=5.0.0-rc.1' \
  'newTag=v5.0.0-rc.1' \
  'preRelease=true' \
  'publishTag=next'

# premajor continues a labeled premajor train by incrementing the number.
run_case 'premajor' '5.0.0-rc.1' '' \
  'newVersion=5.0.0-rc.2' \
  'newTag=v5.0.0-rc.2'

# premajor on a bare-label suffix continues as label.N.
run_case 'premajor' '5.0.0-beta' '' \
  'newVersion=5.0.0-beta.1' \
  'newTag=v5.0.0-beta.1'

# Invalid release type fails with the updated message.
invalid_out="$workspace/invalid.txt"
: > "$invalid_out"
if RELEASE_TYPE='banana' GITHUB_OUTPUT="$invalid_out" bash "$SCRIPT_PATH" > "$invalid_out" 2>&1; then
  echo "Expected invalid release type 'banana' to exit nonzero"
  exit 1
fi
assert_line "$invalid_out" 'release-type must be one of: prerelease, premajor, patch, minor, major'

# patch on a prerelease base promotes the stable core (existing behavior).
run_case 'patch' '1.2.3-rc.1' '' \
  'newVersion=1.2.3' \
  'newTag=v1.2.3' \
  'preRelease=false' \
  'publishTag=latest'

# premajor does not continue an unrelated prerelease train (base is not X.0.0).
run_case 'premajor' '4.19.0-2' '' \
  'newVersion=5.0.0-1' \
  'newTag=v5.0.0-1'

echo "All compute-version tests passed"
