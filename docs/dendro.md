# Dendrochronological measurement series

A Dendro record describes one measurement series attached to an XRONOS sample. The sample links the series to its archaeological context and site.

## Series format

| Field | Meaning |
| --- | --- |
| `measurements` | A JSON array of objects with an integer `position` and a finite numeric or null `value`. Each position is unique within the series. |
| `is_anchored` | `true` for a calendar-dated series, `false` for a floating series, and `null` if the dating status is unknown. |
| `anchor_position`, `anchor_year` | The series position and corresponding calendar year of the anchor. Both are required for an anchored series. For floating series and series with unknown dating status both are null. |
| `measurement_variable` | `ring_width`, `earlywood_width`, or `latewood_width`. Use null if the variable is unknown. |
| `measurement_unit` | `mm` or `µm`. Use null if the unit is unknown. |

An omitted position leaves a gap in the series. A point with `value: null` records a known position with no value. A value of `0` is a recorded zero. Keep the original spacing between positions when preparing data for XRONOS.

For an anchored series, the calendar year at a position is `anchor_year + position - anchor_position`. Calendar years in exports use astronomical year numbering. Year `1` is 1 CE, year `0` is 1 BCE, and year `-1` is 2 BCE. The web interface displays BCE and CE labels. Calendar years are unavailable for floating series and series with unknown dating status.

### Anchored series

The following excerpt places position 2 in 1 CE. Position 1 therefore dates to 1 BCE.

```json
{
  "series_code": "EXAMPLE-ANCHORED",
  "is_anchored": true,
  "anchor_position": 2,
  "anchor_year": 1,
  "measurement_variable": "ring_width",
  "measurement_unit": "mm",
  "measurements": [
    { "position": 1, "value": 0.48 },
    { "position": 2, "value": 0.64 }
  ]
}
```

### Floating series

Position 2 is absent, position 3 has no recorded value, and position 4 has a recorded zero. If a calendar anchor is established later, the measurement positions stay the same.

```json
{
  "series_code": "EXAMPLE-FLOATING",
  "is_anchored": false,
  "anchor_position": null,
  "anchor_year": null,
  "measurement_variable": "ring_width",
  "measurement_unit": "µm",
  "measurements": [
    { "position": 1, "value": 480 },
    { "position": 3, "value": null },
    { "position": 4, "value": 0 }
  ]
}
```

## Exporting data

| Route | Export |
| --- | --- |
| `/dendros/:id.json` | One series, with its sample ID, dating status, anchor, measurement metadata, and measurement points. |
| `/dendros.json` or `/dendros.csv` | A collection of series. Collection CSVs contain one row per series, with the measurement points encoded as JSON in the `measurements` column. |
| `/dendros/:id/export_measurements_csv.csv` | One row per stored point, sorted by position. Columns are `position`, `calendar_year`, `value`, `measurement_variable`, and `measurement_unit`. |
| `/data.json?type=dendro` or `/data.csv?type=dendro` | Dendro series from the data browser. Use its Download menu to carry over the active filters. |

The single-series CSV leaves `calendar_year` blank when no calendar anchor is available and leaves `value` blank for a missing value. Measured zeroes appear as `0`. JSON exports include the anchor and relative positions so calendar years can be derived from them.
