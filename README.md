# version-bump-action

Compute the next semantic version and release tag from a release type.

This action only computes release metadata. It does not update `package.json` or create tags itself; the release workflow handles those steps.

## Prerequisites

This action derives versions from git tags unless you explicitly provide `current-version`. When `current-version` is not supplied, release workflows must fetch full history and tags before invoking the action.

Recommended checkout configuration:

```yaml
- uses: actions/checkout@v6
  with:
    fetch-depth: 0
    fetch-tags: true
```

If `current-version` is not supplied and the workflow uses a shallow checkout or does not fetch tags, the action now fails with guidance instead of falling back to weak sources such as `package.json` or `0.0.0`.

Bootstrap behavior:

- If checkout is non-shallow and no tags exist, the action first tries `package.json` version (when valid semver), then falls back to `0.0.0`.
- If checkout is shallow, the action fails with checkout guidance.

## Inputs

- `release-type`: `prerelease | patch | minor | major` (default: `prerelease`)
- `current-version`: optional explicit base version, e.g. `1.2.3`, `1.2.3-rc.1`, or `v1.2.3`
- `prerelease-identifier`: optional prerelease label, e.g. `rc`, `beta`, `alpha`
- `tag-prefix`: tag prefix (default: `v`)

## Outputs

- `newVersion`: computed semantic version
- `newTag`: computed release tag with prefix
- `preRelease`: `true` for prerelease versions
- `publishTag`: `next` for prerelease, `latest` otherwise
- `action_release_type`: `prerelease` or `full` for downstream changelog actions
- `base`: resolved base version without tag prefix
- `base_source`: how the base version was resolved
- `base_ref`: resolved base tag when available

When bootstrapping without tags, `base_source` is:

- `package-json-bootstrap` when a valid semver is found in `package.json`
- `default-bootstrap` when falling back to `0.0.0`

Compatibility outputs are also provided: `normalized`, `tag`, `is_prerelease`.

## Example

```yaml
- uses: actions/checkout@v6
  with:
    fetch-depth: 0
    fetch-tags: true

- name: Compute version
  id: version
  uses: vscheuber/version-bump-action@v1
  with:
    release-type: prerelease

- name: Show outputs
  run: |
    echo "version=${{ steps.version.outputs.newVersion }}"
    echo "tag=${{ steps.version.outputs.newTag }}"

- name: Use release metadata
  run: |
    echo "publish tag=${{ steps.version.outputs.publishTag }}"
    echo "base source=${{ steps.version.outputs.base_source }}"
```
