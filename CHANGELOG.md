# Changelog

## [0.2.0] - 2026-10-20

### Added

- Optional `FieldOrder` on `ConvertFrom-ClairicAnswer`, preserving nulls and arrays while ordering projected properties.
- Appointment, list, estimate, and forecast examples covering all nine field types and every list item type.
- Receipt image example with optional text context and a bundled fictional `receipt.png` with checkable totals.
- Example guide with expected facts, uncertainty guidance, and observed receipt image extraction errors.
- Transparent PSAIClairic logo and centered README header.
- MIT license and repository metadata.

### Changed

- Invoice example pipes directly into `ConvertFrom-ClairicAnswer` and no longer declares an unused preview switch.
- Receipt instructions request the complete merchant name, exact item spelling, and every merchandise row without embedding sample answers.
- README includes Gallery and source installation, authentication, all field types, and result interpretation.
- Local installer copies only manifest-listed package files into the current user's versioned PowerShell module directory. Git metadata, tests, publishing scripts, credentials, and the local video script are not copied.
- Gallery helper installs the package first, publishes the matching installed version by name, and excludes any installed files outside the manifest's package list.

## [0.1.0] - 2026-10-20

### Added

- PowerShell 7.2+ module with `New-ClairicField`, `Invoke-Clairic`, and `ConvertFrom-ClairicAnswer`.
- Typed text, number, date, time, datetime, duration, list, estimate, and forecast fields.
- Cloudflare REST transport, environment credentials, local image encoding, reference dates, and optional quantiles.
- Request validation, credential-safe transport errors, truncation warnings, and local JSON request previews.
- Official input/output schemas, invoice example, and offline Pester tests.
