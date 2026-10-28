# PLAN: Citable Concern — BibTeX `urldate` Addition

**Branch:** `better-c14-show`
**Base:** `origin/master`
**Working tree:** clean (all work committed)

---

## 1. Feature Summary

XRONOS can now emit a citation for an individual scientific record. The `Citable`
model concern uses **CSL-JSON as the canonical machine-readable form**, with
adapters that render it as HTML (CiteProc/APA), BibTeX, YAML and RIS.

Author ordering rules (implemented in `Citable#citation_authors`):

1. The record **creator** is the first author — but only if they have a display name.
2. The **admin user** (`ENV["ADMIN_USER_ID"]`) is *always* the last author, even
   if they never edited the record.
3. Remaining contributors are sorted **alphabetically** in the middle.
4. Contributors without a display name are **excluded**.
5. If nobody qualifies, a literal **"XRONOS contributors"** is used.

---

## 2. Current State — Feature Is Complete

The citation feature is **fully implemented, tested, and committed**. The work
spans 8 commits on this branch:

```
17e6632d Fix Citable tests
2e086979 Downgrade ruby to 3.3.12
3aba4673 Rearrange calibration section of C14#show
7d23e721 Improve dropbox styling in record toolbar
81cacb0a Add C14 citation export
fad6715e Add citation to C14 show view
4051be12 Use CSL-format hash for citables internally
d5f8bd65 Add Citable concern
```

### What already exists

| Layer | File | Notes |
|---|---|---|
| Model concern | `app/models/concerns/citable.rb` | `Citable` — CSL-JSON core + format adapters |
| Model integration | `app/models/c14.rb` | `include Citable`; private `citation_title` (lines 136–140) |
| Model support | `app/models/user.rb` | `display_name`, `has_real_name?` |
| Controller concern | `app/controllers/concerns/citable_controller.rb` | `CitableController` — `respond_to` block + download options |
| Controller | `app/controllers/c14/citation_controller.rb` | `C14::CitationController` |
| Routing | `config/routes.rb` (line 29) | `resource :citation, only: :show, controller: "c14/citation"` |
| MIME types | `config/initializers/mime_types.rb` | `:bibtex` and `:ris` registered |
| Toolbar UI | `app/views/shared/_record_toolbar.html.erb` (lines 20–30) | "Cite" dropdown → BibTeX / CSL-JSON / YAML / RIS |
| Show view | `app/views/c14s/show.html.erb` (lines 132–138) | `<section id="c14-citation">` with `render_citation` |
| Tests | `test/models/concerns/citable_test.rb` | 15 tests, disposable `CitableTest::CitableModel` |
| Tests | `test/models/c14_test.rb` | 12 citation tests |
| Tests | `test/models/user_test.rb` | 7 tests for `display_name` / `has_real_name?` |
| Tests | `test/controllers/c14/citation_controller_test.rb` | 56 lines, controller coverage |
| CHANGELOG | `CHANGELOG` (top of file) | `[1.3.1.900] - unreleased` → "Added suggested citation for radiocarbon dates to show view / Exportable as BibTeX, CSL-JSON, YAML, RIS" |

### The one remaining change

`urldate=` in the BibTeX output.

**Two requests in the most recent user message are already satisfied — do not
re-implement them:**

- ✅ **`url=` instead of `howpublished=`** — `app/models/concerns/citable.rb` line 49
  already reads `bib.url = citation["URL"]`. There is no `howpublished` anywhere
  in the file.
- ✅ **Fallback author "XRONOS contributors"** — line 123 already reads
  `return [{ "literal" => "XRONOS contributors" }] if names.empty?`.

---

## 3. Task: Add `urldate` to the BibTeX output

**File to modify:** `app/models/concerns/citable.rb`
**Method:** `format_bibtex` (lines 42–61)

### Current code

```ruby
def format_bibtex
  bib = BibTeX::Entry.new
  bib.type      = :dataset
  bib.key       = citation["id"]
  bib.title     = citation["title"]
  bib.year      = citation.dig("issued", "date-parts", 0, 0)
  bib.publisher = citation["container-title"]
  bib.url       = citation["URL"]
  bib.author    = Array(citation["author"]).map { |a|
    if a["literal"]
      "{#{a["literal"]}}"
    else
      [a["given"], a["family"]].compact.join(" ")
    end
  }.join(" and ")
  bib.to_s
end
```

### Required changes

**Step 1** — insert one line after `bib.url = citation["URL"]` (line 49):

```ruby
  bib.urldate   = format_urldate_for_bibtex
```

**Step 2** — add a private helper. Place it after `format_bibtex` (i.e. after
line 61, before the `# CSL name entry` / `csl_name` region is fine) so the
private-methods block stays grouped:

```ruby
def format_urldate_for_bibtex
  parts = citation.dig("accessed", "date-parts", 0)
  return nil unless parts
  year, month, day = parts
  "#{year}-#{format('%02d', month)}-#{format('%02d', day)}"
end
```

### Notes / constraints

- The access date is already available. `citation_accessed` (line 164) returns
  the CSL shape `{ "date-parts" => [[y, m, d]] }` and `citation_access_date`
  (line 168) returns `Time.current`. **Reuse the existing `citation` hash** — do
  not add a second `Time.current` call, so `citation` and `format_bibtex` cannot
  disagree.
- `accessed` is already emitted in the CSL-JSON and consumed by `format_ris`
  (line 76). The RIS adapter writes it as `Y2  -`; the BibTeX adapter should
  write it as `urldate`.
- BibTeX's `urldate` is conventionally ISO 8601 (`YYYY-MM-DD`), which is what
  the helper above produces.
- The `bibtex-ruby` gem will serialise unknown fields as-is, so `urldate` needs
  no gem-side configuration.
- `AGENTS.md` style rules apply: `private` keyword on its own line, content
  **not** indented beneath it; order private methods by invocation flow; no
  comments unless asked.

---

## 4. Verification

1. **Targeted tests**
   ```bash
   bin/rails test test/models/c14_test.rb
   ```
   Expect 12 runs, 0 failures.

2. **Concern tests**
   ```bash
   bin/rails test test/models/concerns/citable_test.rb
   ```
   Expect 15 runs, 0 failures.

3. **Manual check**
   ```bash
   bin/rails runner "puts C14.first.format_bibtex"
   ```
   Expected output shape:
   ```bibtex
   @dataset{xronos_c14_1,
     title = {OxA-20596 (radiocarbon date)},
     year = {2025},
     publisher = {XRONOS: An Open Data Infrastructure for Archaeological Chronology},
     url = {http://localhost:3000/c14s/1},
     urldate = {2026-01-07},
     author = {XRONOS Core Team}
   }
   ```

4. **Add a regression test** (recommended) in `test/models/c14_test.rb`:
   ```ruby
   test "format_bibtex includes urldate" do
     c14 = create(:c14, lab_identifier: "OxA-12345")
     bib = c14.format_bibtex
     assert_includes bib, "urldate = {#{Time.current.strftime("%Y-%m-%d")}}"
   end
   ```

5. **Full suite**
   ```bash
   bin/rails test
   ```
   Expect 0 new failures. See §5 for the one known pre-existing failure.

6. **Lint**
   ```bash
   bundle exec rubocop app/models/concerns/citable.rb
   ```
   The project has ~6000 pre-existing rubocop offences (mostly
   `Style/StringLiterals`); only fix style in the lines you touch. Metrics
   warnings on `citation_authors` are already accepted in the codebase (compare
   `app/models/concerns/versioned.rb`).

---

## 5. Known Pre-existing Failure (NOT related to this task)

```
XronosDataControllerTest#test_data_index_applies_material_filter
  Expected response to be a <2XX: success>, but was a <500: Internal Server Error>
```

Cause: missing system library — `libboost_program_options.so.1.91.0: cannot open
shared object file`. This is an environment issue with the vendored
`calibrator` binary, not a code defect. Do not attempt to fix it as part of this
work.

---

## 6. Optional Follow-ups (out of scope for the `urldate` task)

Listed for context only — do not implement unless asked.

- **CHANGELOG** — the `urldate` addition changes exported BibTeX files, which is
  user-facing. The existing `1.3.1.900` entry already covers the feature; a
  sub-bullet such as `- BibTeX exports now include the access date (\`urldate\`)`
  would be appropriate if the maintainer wants the detail.
- **Extend `Citable` to other core models** — `Site`, `Sample` and `Context` are
  the obvious candidates. Each needs its own `citation_title` override and a
  matching `resource :citation` route plus controller (mirroring
  `C14::CitationController` and the `CitableController` concern).
- **`citable_record_path` / `citation_anchor`** in `CitableController` are
  already generic; they derive from `model_name.singular`, so extending to
  other models should not require changes there.

---

## 7. Files Reference

**Modify:**
- `app/models/concerns/citable.rb`

**Read-only references:**
- `app/models/c14.rb` — `include Citable`; `citation_title` override
- `app/controllers/concerns/citable_controller.rb` — `CitableController`
- `app/controllers/c14/citation_controller.rb` — `C14::CitationController`
- `app/views/shared/_record_toolbar.html.erb` — "Cite" dropdown
- `app/views/c14s/show.html.erb` — citation section (lines 132–138)
- `app/models/lab_id.rb` — `LabId` value object (`to_s` returns the full lab id)
- `app/models/user.rb` — `display_name`, `has_real_name?`
- `test/models/c14_test.rb`, `test/models/concerns/citable_test.rb`,
  `test/models/user_test.rb`,
  `test/controllers/c14/citation_controller_test.rb`
- `AGENTS.md` — project conventions
