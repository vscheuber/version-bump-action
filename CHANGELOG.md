# Changelog

## Unreleased

### Changed
- Updated version base resolution for no-tag repositories to bootstrap from valid `package.json` version first, then fallback to `0.0.0`.
- Retained fail-fast behavior for shallow checkouts and improved logs to show base source selection.

## [v1.0.9] - 2026-08-02

### Added
- Improved error handling for shallow repositories in version computation, enhancing reliability in environments with limited repository history. (commit 2cc396f)

### Changed
- Updated README to include prerequisites and error handling guidance for shallow checkouts, providing developers with clearer setup instructions. (commit 8b5610c)
- Enabled fetching tags during checkout in the release workflow, ensuring accurate version tagging in CI/CD processes. (commit 9271109)

## [v1.0.8] - 2026-08-02

### Changed
- Internal pipeline update release. This release updates CI/CD or release automation under `.github/` without changing functional behavior.

## [v1.0.7] - 2026-08-01

### Changed
- Cosmetic version update release. This release records a version or release-state change without additional functional code changes.

## [v1.0.6] - 2026-08-01

### Changed
- Enhanced version computation logic to improve handling of prereleases. This update refines how version numbers are calculated, ensuring more accurate semantic versioning in line with the SemVer specification. Developers using this library should notice improved version handling, particularly in projects utilizing prerelease tags.

## [v1.0.5] - 2026-08-01

### Changed
- Enhanced version computation logic to improve handling of prereleases. This update refines how version numbers are calculated, ensuring more accurate semantic versioning in line with the SemVer specification. Developers using this library should notice improved version handling, particularly in projects utilizing prerelease tags.

## [v1.0.5-1] - 2026-08-01

### Changed
- Enhanced version computation logic to improve handling of prereleases. This change refines how version numbers are calculated, ensuring more accurate semantic versioning in line with the SemVer specification. Developers using this library should notice improved version handling, particularly in projects utilizing prerelease tags.

## [v1.0.4] - 2026-08-01

### Changed
- Updated the release workflow to use the manifest version update action instead of inline package version updates. This change streamlines the version bump process, ensuring consistency across releases.

## [v1.0.4-1] - 2026-08-01

### Changed
- Updated the release workflow to use the manifest version update action instead of inline package version updates. This change streamlines the version bump process, ensuring consistency across releases.

## [v1.0.3] - 2026-08-01

### Fixed
- Improved prerelease logic to prioritize the latest stable tag for versioning, ensuring more accurate version calculations in CI/CD workflows. (#221a8d9)

## [v1.0.2] - 2026-08-01

### Added
- Enhanced version computation logic to prioritize stable tags and update the `package.json` version accordingly, ensuring more reliable versioning for projects using this action. (#a9c387b)
- Introduced logic to update major and minor action tags during the release process, providing more flexibility in version management. (#c79c056)

### Documentation
- Updated README.md to clarify version computation details and enhance input/output descriptions, improving user understanding of the library's functionality. (81cf513)

## [v1.0.1-2] - 2026-08-01

### Added
- Enhanced version computation logic to prioritize stable tags and update the `package.json` version accordingly. This ensures more reliable versioning for projects using this action. (#a9c387b)
- Introduced logic to update major and minor action tags during the release process, providing more flexibility in version management. (#c79c056)

## [v1.0.1] - 2026-07-29

### Added
- Logic to update major and minor action tags during release, ensuring that users can reference the latest stable version using these tags for easier integration and version management (c79c056).

## [v1.0.1] - 2026-07-29

### Added
- Introduced the initial version bump action with continuous integration (CI) and release workflows, enabling automated version management.

### Fixed
- Renamed the action to 'Semantic Release Version Action' to enhance clarity and ease of identification.

## [v1.0.1-1] - 2026-07-29

### Added
- Initial version bump action with CI and release workflows.

### Fixed
- Updated action name to 'Semantic Release Version Action' for better clarity and identification.

