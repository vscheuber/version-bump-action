#!/usr/bin/env bash
set -euo pipefail

release_type="${RELEASE_TYPE:-prerelease}"
current_input="${CURRENT_VERSION:-}"
prerelease_id="${PRERELEASE_IDENTIFIER:-}"
tag_prefix="${TAG_PREFIX:-v}"
semver_re='^([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z.-]+))?$'

semver_core_cmp() {
  local a="$1"
  local b="$2"
  if [[ "$a" == "$b" ]]; then
    echo 0
    return
  fi

  local max
  max="$(printf '%s\n%s\n' "$a" "$b" | sort -V | tail -n1)"
  if [[ "$max" == "$a" ]]; then
    echo 1
  else
    echo -1
  fi
}

case "$release_type" in
  prerelease|patch|minor|major) ;;
  *)
    echo "release-type must be one of: prerelease, patch, minor, major"
    exit 1
    ;;
esac

base_source=''
base_ref=''

if [[ -n "$current_input" ]]; then
  base_tag="$current_input"
  base_source='input'

  candidate1="$current_input"
  candidate2="${tag_prefix}${current_input#"${tag_prefix}"}"
  for c in "$candidate1" "$candidate2"; do
    if git rev-parse -q --verify "refs/tags/${c}" >/dev/null 2>&1; then
      base_ref="$c"
      break
    fi
  done
else
  if git rev-parse --is-shallow-repository >/dev/null 2>&1; then
    is_shallow_repo="$(git rev-parse --is-shallow-repository)"
  else
    is_shallow_repo='false'
  fi

  all_tags="$(git tag --sort=-v:refname 2>/dev/null || true)"
  latest_semver=''
  latest_stable=''

  while IFS= read -r tag; do
    [[ -z "$tag" ]] && continue
    stripped="${tag#"${tag_prefix}"}"
    if [[ "$stripped" =~ $semver_re ]]; then
      if [[ -z "$latest_semver" ]]; then
        latest_semver="$tag"
      fi
      pre_component="${BASH_REMATCH[5]:-}"
      if [[ -z "$pre_component" && -z "$latest_stable" ]]; then
        latest_stable="$tag"
      fi
      if [[ -n "$latest_semver" && -n "$latest_stable" ]]; then
        break
      fi
    fi
  done <<< "$all_tags"

  if [[ "$release_type" == "prerelease" ]]; then
    # For prereleases, continue an active prerelease train when that train is
    # ahead of the latest stable release (e.g., stable 1.0.7 + prerelease 1.0.8-1).
    # Otherwise, start a new prerelease train from the latest stable.
    if [[ -n "$latest_semver" ]]; then
      stripped_semver="${latest_semver#"${tag_prefix}"}"
      if [[ "$stripped_semver" =~ $semver_re ]]; then
        semver_core="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
        semver_pre="${BASH_REMATCH[5]:-}"

        if [[ -n "$semver_pre" ]]; then
          if [[ -n "$latest_stable" ]]; then
            stripped_stable="${latest_stable#"${tag_prefix}"}"
            if [[ "$stripped_stable" =~ $semver_re ]]; then
              stable_core="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
              cmp="$(semver_core_cmp "$semver_core" "$stable_core")"
              if [[ "$cmp" -gt 0 ]]; then
                base_tag="$latest_semver"
                base_source='latest-active-prerelease-tag'
                base_ref="$latest_semver"
              else
                base_tag="$latest_stable"
                base_source='latest-stable-tag'
                base_ref="$latest_stable"
              fi
            else
              base_tag="$latest_semver"
              base_source='latest-semver-tag'
              base_ref="$latest_semver"
            fi
          else
            base_tag="$latest_semver"
            base_source='latest-semver-tag'
            base_ref="$latest_semver"
          fi
        else
          base_tag="$latest_semver"
          base_source='latest-semver-tag'
          base_ref="$latest_semver"
        fi
      fi
    fi

    if [[ -z "${base_tag:-}" && -n "$latest_stable" ]]; then
      base_tag="$latest_stable"
      base_source='latest-stable-tag'
      base_ref="$latest_stable"
    fi
  else
    # For stable releases, prefer the latest stable tag to avoid reusing an existing stable version.
    if [[ -n "$latest_stable" ]]; then
      base_tag="$latest_stable"
      base_source='latest-stable-tag'
      base_ref="$latest_stable"
    elif [[ -n "$latest_semver" ]]; then
      base_tag="$latest_semver"
      base_source='latest-semver-tag'
      base_ref="$latest_semver"
    fi
  fi

  if [[ -z "${base_tag:-}" && -f package.json ]]; then
    pkg_version="$(node -p "require('./package.json').version" 2>/dev/null || true)"
    if [[ -n "$pkg_version" ]]; then
      base_tag="$pkg_version"
      base_source='package-json'
    fi
  fi

  if [[ -z "${base_tag:-}" ]]; then
    base_tag='0.0.0'
    base_source='default-bootstrap'
  fi

  if [[ "$base_source" == 'package-json' || "$base_source" == 'default-bootstrap' ]]; then
    echo "Unable to determine a reliable base version from git tags."
    if [[ "$is_shallow_repo" == 'true' ]]; then
      echo "Repository checkout is shallow."
    fi
    echo "Provide current-version explicitly or ensure the workflow checkout fetches full history and tags:"
    echo "  - uses: actions/checkout@v6"
    echo "    with:"
    echo "      fetch-depth: 0"
    echo "      fetch-tags: true"
    exit 1
  fi
fi

base="${base_tag#"${tag_prefix}"}"
if [[ ! "$base" =~ $semver_re ]]; then
  echo "Could not parse semver from '$base_tag'"
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
pre="${BASH_REMATCH[5]:-}"

stable_major="$major"
stable_minor="$minor"
stable_patch="$patch"

if [[ "$release_type" == "prerelease" ]]; then
  if [[ -n "$pre" ]]; then
    if [[ "$pre" =~ ^([0-9]+)$ ]]; then
      num="${BASH_REMATCH[1]}"
      next="${major}.${minor}.${patch}-$((num + 1))"
    elif [[ "$pre" =~ ^([A-Za-z0-9-]+)\.([0-9]+)$ ]]; then
      label="${BASH_REMATCH[1]}"
      num="${BASH_REMATCH[2]}"
      next="${major}.${minor}.${patch}-${label}.$((num + 1))"
    else
      if [[ -n "$prerelease_id" ]]; then
        next="${major}.${minor}.${patch}-${prerelease_id}.1"
      else
        next="${major}.${minor}.${patch}-1"
      fi
    fi
  else
    if [[ -n "$prerelease_id" ]]; then
      next="${major}.${minor}.$((patch + 1))-${prerelease_id}.1"
    else
      next="${major}.${minor}.$((patch + 1))-1"
    fi
  fi
  is_prerelease='true'
  action_release_type='prerelease'
  publish_tag='next'
elif [[ "$release_type" == "patch" ]]; then
  if [[ -n "$pre" ]]; then
    next="${stable_major}.${stable_minor}.${stable_patch}"
  else
    next="${major}.${minor}.$((patch + 1))"
  fi
  is_prerelease='false'
  action_release_type='full'
  publish_tag='latest'
elif [[ "$release_type" == "minor" ]]; then
  next="${stable_major}.$((stable_minor + 1)).0"
  is_prerelease='false'
  action_release_type='full'
  publish_tag='latest'
else
  next="$((stable_major + 1)).0.0"
  is_prerelease='false'
  action_release_type='full'
  publish_tag='latest'
fi

new_tag="${tag_prefix}${next}"

{
  echo "base=${base}"
  echo "base_source=${base_source}"
  echo "base_ref=${base_ref}"
  echo "release_type=${release_type}"
  echo "action_release_type=${action_release_type}"
  echo "newVersion=${next}"
  echo "newTag=${new_tag}"
  echo "preRelease=${is_prerelease}"
  echo "publishTag=${publish_tag}"
  echo "normalized=${next}"
  echo "tag=${new_tag}"
  echo "is_prerelease=${is_prerelease}"
} >> "$GITHUB_OUTPUT"
