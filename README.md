# version-bump-action

Compute a new semantic version and release tag from a release type.

## Inputs

- `release-type`: `prerelease | patch | minor | major` (default: `prerelease`)
- `current-version`: optional explicit base version, e.g. `1.2.3` or `v1.2.3`
- `prerelease-identifier`: optional prerelease label, e.g. `rc`
- `tag-prefix`: tag prefix (default: `v`)

## Outputs

- `newVersion`: computed semantic version
- `newTag`: computed release tag with prefix
- `preRelease`: `true` for prerelease versions
- `publishTag`: `next` for prerelease, `latest` otherwise

Compatibility outputs are also provided: `normalized`, `tag`, `is_prerelease`, `action_release_type`, `base`, `base_source`, `base_ref`.

## Example

```yaml
- name: Compute version
  id: version
  uses: vscheuber/version-bump-action@v1
  with:
    release-type: prerelease

- name: Show outputs
  run: |
    echo "version=${{ steps.version.outputs.newVersion }}"
    echo "tag=${{ steps.version.outputs.newTag }}"
```
