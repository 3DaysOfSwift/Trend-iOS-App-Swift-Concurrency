# Weight history import

Settings → Import weight history and opening a supported document with Trend both
present a preview. Reading or cancelling never saves records. Confirming performs
one additive, serialized save and refreshes weight-derived screens.

## Supported files

- Weight Diary CSV: starts with `units,kg` or `units,lb` (also lbs).
  Metadata rows goal, height, birthdate and gender are ignored.
  Measurement rows contain date/time, weight, optional body fat, optional note.
  Body fat is not imported.
- Generic UTF-8 CSV: a header with `date,weight,unit,note`. Note is optional;
  columns can be reordered. Every row must specify kg or lb.
- Trend JSON weight-history exports.
- Trend version-1 recovery backups: **weight entries only**. Habits, selected
  habits, goal, unit preference and settings remain unchanged. Full recovery is
  still a separate workflow in Backups and recovery.

```csv
date,weight,unit,note
2026-09-13T13:33:39+07:00,70.8,kg,"After the gym"
2026-09-14,70.6,kg,""
```

Dates accept ISO 8601 timestamps, YYYY-MM-DD HH:mm:ss, or YYYY-MM-DD.
Unzoned dates use the device's current time zone, disclosed in the preview.
Date-only records use noon. Ambiguous slash dates are rejected, never guessed.
Quoted CSV fields may contain commas, doubled quotes and newlines.

## Merge and validation

Existing IDs win. A matching timestamp (to the nearest second) and weight (to
four decimal places in kilograms) is also considered a duplicate, even if the
note differs. Existing notes remain untouched. Duplicates within the file are
also skipped. Different readings on the same day remain separate entries.
The completion screen gives the actual added/skipped counts.

The merge reloads existing records inside WeightLogManager's operation gate and
rechecks duplicates there, so intervening edits and repeated imports are safe.
Records are published only after the save succeeds. Normal storage-change
observation schedules the existing backup checks; importing does not force an
iCloud synchronization or upload the original CSV.

Unsupported formats, unsupported backup versions and malformed records fail the
whole preview. Nothing is silently skipped except documented metadata and
duplicates. Limits: UTF-8, 20 MB, 50,000 source entries, finite weights above zero
and at most 1,000 kg, dates from 1900 through 3000. Historical measurements are
not rounded or clamped to the daily entry form's adult range.

## Extending and checking

WeightImportFileReader detects the file format; WeightCSVDecoder handles CSV
syntax and mappings. New exporters should get an explicit adapter and fixtures,
not guessed units or positional columns for unfamiliar formats.

WeightImportTests cover parsing, precision, notes, invalid rows, backups,
concurrent duplicate imports, failure preservation, confirmation and SwiftData
reopening. Set TREND_IMPORT_SAMPLE_PATH to a local Weight Diary CSV to run the
706-entry sample check; the user's file is not committed.

Device checks still required: open a CSV from Files/share sheet both with Trend
closed and already running; review/cancel; confirm; import again; relaunch and
verify history and unchanged habits. Also test Settings import from iCloud Drive.

