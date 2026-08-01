# Changelog

## Unreleased

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

