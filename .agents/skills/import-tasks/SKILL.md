---
name: import-tasks
description: Write xronos:import:* rake tasks using ImportRunner — import external datasets from CSV and BibTeX with provenance tracking and PaperTrail auditing.
license: MIT
---

## Contract

Import tasks are **create-only**. They never update existing records — any variation in source data produces a new record (matched across all keys + attributes). Duplicate resolution is handled separately.

## Workflow

### 1. Understand the source data
Inspect all files (CSV headers + sample rows, BibTeX keys, documentation). If a column's meaning is unclear, **ask the user**. If the data contains types that don't exist in XRONOS's model, **ask the user** whether to add them.

### 2. Flag unused columns
After mapping known columns to XRONOS models, list any unused columns to the user — they may contain overlooked data or be ignorable noise.

### 3. Guard defensively
- Use `cell(row, "Column")` for all CSV cell access (strips whitespace, returns `nil` for blanks).
- Skip rows missing critical fields with `skip_unless condition, "reason"` (counts and reports skipped rows).
- Use `&.to_i` / `&.to_f` for numeric conversions after `cell()`.
- Never use `find_by` + `update` — always use `import!`.

### 4. Write the rake task
Follow the skeleton below. Every task takes three required arguments: `[version, dir, source_url]`.

### 5. Cite the source
Create a bibliographic reference for the source dataset itself (Phase 0 in the skeleton, using BibTeX provided by the source authors). Store it on the `Source` record, then call `cite_source!(record)` after creating each citable record.

## Skeleton

```ruby
require "bibtex"  # if BibTeX files are used

namespace :xronos do
  namespace :import do
    desc "Import MyDataset"
    task "mydataset", [:version, :dir, :source_url] => :environment do |t, args|
      version, dir, source_url = Xronos::ImportRunner.parse_args!(args)

      source = Source.register(
        name: "MyDataset",
        version: version,
        path: dir,
        source_url: source_url,
        license: "CC-BY 4.0",
        notes: "MyDataset: description"
      )

      admin_user_id = ENV.fetch("XRONOS_ADMIN_USER") { abort "XRONOS_ADMIN_USER must be set" }
      revision_comment = "Imported from MyDataset #{version} <#{source_url}>"

      PaperTrail.request(whodunnit: admin_user_id) do
        runner = Xronos::ImportRunner.new(source, csv_dir: dir)

        begin
          runner.describe!(whodunnit: admin_user_id, revision_comment: revision_comment)

          # Phase 0: Source reference
          source_ref = runner.import!(Reference,
            keys: { short_ref: "MyDataset" },
            attributes: { bibtex: <<~BIB.chomp
              @article{Author2023,
                author = {Author, A. and Author, B.},
                title  = {Title},
                doi    = {10.xxxx/xxxxx}
              }
            BIB
            },
            revision_comment: revision_comment
          )
          source.update!(reference: source_ref)

          # === Import data phases here (use csv/process_enum with instance_exec blocks) ===

          runner.succeed!
          runner.report!
        rescue => e
          runner.import_record.update!(error: "#{e.class}: #{e.message}")
          raise
        end
      end
    end
  end
end
```

## API Reference

### Available inside blocks (`csv`, `process_enum`) via `instance_exec`

| Method | Purpose |
|--------|---------|
| `import!(scope, keys:, attributes: {}, revision_comment: nil)` | Create-only import; finds by merged keys+attributes, creates on miss |
| `cell(row, column)` | Sanitise CSV cell: strip whitespace, blank → `nil` |
| `skip_unless(condition, reason)` | Guard clause: `throw :skip_row` unless condition is truthy; counts skipped rows by `reason` in `records_skipped` |
| `cite_source!(citable)` | Link a citable record to the source's reference (must set `source.reference` first) |
| `import_record` | Current `Import` audit record |

### Called explicitly on `runner` (or `ImportRunner`) outside blocks

| Method | Purpose |
|--------|---------|
| `Xronos::ImportRunner.parse_args!(args)` | (class method) Extract `version, dir, source_url` from task args; aborts with usage on missing args or missing dir |
| `csv(filename, **csv_options, &block)` | Iterate CSV with progress bar; options forwarded to `CSV.foreach` |
| `process_enum(enumerable, title:, &block)` | Iterate any enumerable with progress bar |
| `describe!(whodunnit:, revision_comment:)` | Print pre-import options header |
| `report!` | Print post-import ASCII table of created records |
| `succeed!` | Mark import as successful, persist counters |

## Testing

Test `import!` directly via `ImportRunner`:

```ruby
test "creates records for attribute variations" do
  runner = Xronos::ImportRunner.new(source, csv_dir: tmpdir)

  a = runner.import!(Site, keys: { name: "Alpha" }, attributes: { lat: "10.5" })
  b = runner.import!(Site, keys: { name: "Alpha" }, attributes: { lat: "99.9" })

  assert_not_equal a.id, b.id
  assert_equal 2, runner.import_record.records_created["site"]
end

test "does not duplicate identical data" do
  runner = Xronos::ImportRunner.new(source, csv_dir: tmpdir)

  a = runner.import!(Site, keys: { name: "Alpha" }, attributes: { lat: "10.5" })
  b = runner.import!(Site, keys: { name: "Alpha" }, attributes: { lat: "10.5" })

  assert_equal a.id, b.id
  assert_equal 1, runner.import_record.records_created["site"]
end

test "skip_unless skips row and counts reason" do
  write_csv("samples.csv", [%w[Name BP], %w[Alpha 100], %w[Beta], %w[Gamma 200]])

  kept = []
  runner = Xronos::ImportRunner.new(source, csv_dir: tmpdir)
  runner.csv("samples.csv") do |row|
    skip_unless cell(row, "BP"), "missing BP"
    kept << cell(row, "Name")
  end

  assert_equal %w[Alpha Gamma], kept
  assert_equal 1, runner.import_record.records_skipped["missing BP"]
end
```

## Reference implementation

See `lib/tasks/import/14canarias.rake` for the canonical example.

## Maintaining this skill

If you add new shared helpers to `ImportRunner` or change the task skeleton convention, **update this skill file** so future agents use the correct patterns. The skill is the single source of truth for import task conventions.
