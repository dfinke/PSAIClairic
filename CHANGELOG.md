# Changelog

## [Unreleased]

### Changed

- Sharpened receipt extraction instructions to preserve the full merchant name, exact item spelling, and every merchandise row without embedding sample answers.

### Added

- Bundled fictional `examples/receipt.png` with checkable totals; the image example defaults to this file.
- Receipt image example with local image paths, optional text context, ordered extraction, and usage documentation; included in module installation.

## [0.2.0] - 2026-10-20

### Added

- Optional `FieldOrder` on `ConvertFrom-ClairicAnswer`, preserving nulls and arrays while ordering projected properties.
- Appointment, list, estimate, and forecast examples covering all nine field types and every list item type.
- Example guide with checkable extraction targets and uncertainty guidance.
- MIT license and repository metadata.

### Changed

- Invoice example now pipes directly into `ConvertFrom-ClairicAnswer` and no longer declares an unused preview switch.
- README now includes installation, authentication, complete field coverage, and result interpretation.
- Local installer now targets PSAIClairic, copies manifest-listed files into a versioned current-user module directory, and supports `WhatIf` without mirroring or deleting destination files.
- Gallery helper now publishes PSAIClairic from the project manifest.

## [0.1.0] - 2026-10-20

### Added

- PowerShell 7.2+ module with `New-ClairicField`, `Invoke-Clairic`, and `ConvertFrom-ClairicAnswer`.
- Typed text, number, date, time, datetime, duration, list, estimate, and forecast fields.
- Cloudflare REST transport, environment credentials, local image encoding, reference dates, and optional quantiles.
- Request validation, credential-safe transport errors, truncation warnings, and local JSON request previews.
- Official input/output schemas, invoice example, and offline Pester tests.
