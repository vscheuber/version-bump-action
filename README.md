# version-bump-action

Compute the next semantic version and release tag from a release type.

This action only computes release metadata. It does not update `package.json` or create tags itself; the release workflow handles those steps.

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

Compatibility outputs are also provided: `normalized`, `tag`, `is_prerelease`.

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

- name: Use release metadata
  run: |
    echo "publish tag=${{ steps.version.outputs.publishTag }}"
    echo "base source=${{ steps.version.outputs.base_source }}"
```
