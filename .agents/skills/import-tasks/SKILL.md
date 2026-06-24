# Skill: XRONOS Import Tasks

Guide for writing `xronos:import:*` rake tasks using the `ImportRunner` framework.

## Core Contract

**Import tasks never update existing records.** They only create new records when no exact match (by all keys + attributes) exists. Any variation in the source data produces a new record — duplicate resolution is handled separately.

## Architecture

| Component | Role |
|-----------|------|
| `Source` | Provenance tracking (name, version, path, licence, URL, SHA256 file manifest). Register via `Source.register`. |
| `Import` | Audit log with per-model creation counters, success/failure status, error text. |
| `ImportRunner` | Orchestrator: progress bars, CSV/array iteration, record import, CLI output. |

## Workflow for Writing an Import Task

### 1. Understand the Source Data

- Inspect all source files: CSV headers, sample rows, BibTeX keys, any accompanying documentation.
- If a column's meaning is unclear, **ask the user** before deciding on a mapping.
- If the data contains a type that does not exist in XRONOS's data model (e.g. isotopic ratios, anthropological measurements), **ask the user** whether it should be added.

### 2. Identify Unused Columns

After mapping known columns to XRONOS models, flag any columns that were not used to the user — they may contain overlooked data or be ignorable noise.

### 3. Guard Against Bad Data

- Use `cell(row, "Column")` for all CSV cell access — it strips whitespace and returns `nil` for blanks.
- Skip rows missing critical fields with early guard clauses.
- Use `&.to_i` / `&.to_f` for numeric conversions after `cell()`.
- Use `find_or_initialize_by` (via `import!`) — never raw `find_by` or `update` calls.

### 4. Always Cite the Source

Every import must create a bibliographic reference for the source dataset itself and link it to all citable records (C14 measurements, etc.) via `cite_source!`. The BibTeX should be provided by the source authors — do not generate it yourself.

### 5. Create a Rake Task

Use the versioned [version, dir] argument pattern. Every run is explicit about where data lives.

### 6. Create a Bibliographic Reference for the Source

After registering the source, create the source's own reference from a BibTeX entry supplied by the source authors and store it on the Source:

```ruby
source_ref = runner.import!(Reference,
  keys: { short_ref: "SourceName" },
  attributes: { bibtex: <<~BIB.chomp
    @article{Author2023,
      author = {Author, A. and Author, B.},
      title  = {Title},
      ...
    }
  BIB
  },
  revision_comment: revision_comment
)
source.update!(reference: source_ref)
```

### 7. Link Citable Records to the Source

After creating each citable record (typically C14 measurements), call `cite_source!`:

```ruby
c14 = import!(sample.c14s, keys: { lab_identifier: ... }, attributes: { ... })
cite_source!(c14)
```

## Rake Task Skeleton

```ruby
require "bibtex"  # if BibTeX files are used

namespace :xronos do
  namespace :import do
    desc "Import MyDataset"
    task "mydataset", [:version, :dir, :source_url] => :environment do |t, args|
      version = args[:version] || abort("Usage: bin/rails \"xronos:import:mydataset[version,dir,source_url]\"")
      dir = args[:dir] || abort("Usage: bin/rails \"xronos:import:mydataset[version,dir,source_url]\"")
      source_url = args[:source_url] || abort("Usage: bin/rails \"xronos:import:mydataset[version,dir,source_url]\"")
      abort "Source directory not found: #{dir}" unless Dir.exist?(dir)

      source = Source.register(
        name: "MyDataset",
        version: version,
        path: dir,
        source_url: source_url,
        license: "CC-BY 4.0",
        notes: "MyDataset: description"
      )

      admin_user_id = ENV.fetch("ADMIN_USER_ID") { abort "ADMIN_USER_ID must be set" }

      revision_comment = "Imported from MyDataset #{version} <<#{source_url}>>"

      PaperTrail.request(whodunnit: admin_user_id) do
        runner = Xronos::ImportRunner.new(source, csv_dir: dir)

        begin
          runner.describe!(whodunnit: admin_user_id, revision_comment: revision_comment)

          # === Import phases here ===

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

## ImportRunner API

Available inside `csv` and `process_enum` blocks (via `instance_exec`):

### `csv(filename, **csv_options, &block)`

Iterates a CSV with a progress bar. Options passed to `CSV.foreach`.

```ruby
runner.csv("data.csv", col_sep: ";", encoding: "utf-16le") do |row|
  name = cell(row, "Name")
  import!(Site, keys: { name: name }, ...)
end
```

### `process_enum(enumerable, title:, &block)`

Progress bar for any enumerable (BibTeX entries, JSON arrays, etc.).

```ruby
bib = BibTeX.parse(File.read("refs.bib"))
runner.process_enum(bib.each_entry, title: "refs.bib") do |entry|
  import!(Reference, keys: { short_ref: entry.key }, attributes: { bibtex: entry.to_s })
end
```

### `import!(scope, keys:, attributes: {}, revision_comment: nil)`

Creates a record only when no exact match exists across the combined `keys` + `attributes`. Never modifies existing data. Sets `revision_comment` on models that include `Versioned`.

```ruby
# Simple lookup
import!(Material, keys: { name: "Wood" })

# With attributes
import!(Site,
  keys: { name: cell(row, "Name") },
  attributes: { lat: cell(row, "Lat")&.to_f, country_code: "ES" },
  revision_comment: revision_comment
)

# Association scope
import!(site.contexts, keys: { name: cell(row, "Context") },
  revision_comment: revision_comment)
```

### `cite_source!(citable)`

Links a citable record to the source's own bibliographic reference. The source must have its `source_reference` set beforehand. Safe to call multiple times.

```ruby
cite_source!(c14)
```

### `cell(row, column)`

Sanitises a CSV cell: strips whitespace, returns `nil` for blank/empty values.

```ruby
name = cell(row, "Name")    # "  Foo  " → "Foo"
bp   = cell(row, "BP")&.to_i  # "" → nil, "5000" → 5000
```

### `describe!(whodunnit:, revision_comment:)`

Prints an options header before the import begins.

### `report!`

Prints an ASCII table of created records after completion.

### `succeed!` / `import_record`

`succeed!` marks the Import as successful and persists counters. `import_record` returns the Import record for error logging.

## Testing

Test `import!` behaviour directly via `ImportRunner`:

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
```

## Reference Implementation

See `lib/tasks/import/14canarias.rake` for the canonical example.
