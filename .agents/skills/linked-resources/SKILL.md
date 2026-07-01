---
name: linked-resources
description: Work with the LinkedResource model, the LinkedResource::Source registry, the Linkable concern, and the BatchMatchableToWikidata concern in XRONOS. Use when adding new linked data sources (Pleiades, Vici.org, OpenContext, iDAI, etc.), working with the curation dashboard, refactoring the linked_resources form, or attaching the linkable macro to a new model.
license: MIT
metadata:
  domain: xronos
  layer: model
---

## What I do
- Document the polymorphic `LinkedResource` model and its `linked_resources` table
- Document the `LinkedResource::Source` registry and the per-source configuration pattern
- Document the `Linkable` concern and the `linkable_to` macro
- Document the `BatchMatchableToWikidata` concern as the canonical pattern for SPARQL-based enrichment
- Flag the async-enrichment principle: XRONOS never blocks user-facing actions on external services

## When to use me
Use this when:
- Adding a new linked-data source (Pleiades, Vici.org, OpenContext, iDAI, etc.)
- Wiring the linkable macro into a new model (C14, Context, …)
- Refactoring the linked_resources form to be source-selectable
- Writing or debugging a rake task / background job that enriches records from an external API
- Debugging the curation dashboard nav, badges, or per-source scopes

## The architecture, in three pieces

```
                ┌────────────────────────┐
                │  LinkedResource::Source │  ← per-source config (PORO)
                │  (registry PORO)        │     id_pattern, url_template, …
                └────────────┬───────────┘
                             │  looked up by name
                             ▼
┌────────────────────┐  has_many  ┌──────────────────┐
│ Host model (Site)  │ ◄────────── │ LinkedResource   │  ← single table,
│                    │  polymorphic│                  │     polymorphic
│ include Linkable   │             │  external_id     │
│ linkable_to :foo   │             │  source          │
│                    │             │  status          │  (pending/approved)
└────────────────────┘             └──────────────────┘
         │
         │  include
         ▼
   ┌─────────────────────────────────┐
   │  BatchMatchableToWikidata       │  ← optional concern
   │  (and future BatchMatchableTo…) │     for SPARQL/API enrichment
   └─────────────────────────────────┘
```

The three pieces are independent:
- `LinkedResource` is the storage model — doesn't know about specific sources.
- `LinkedResource::Source` is the registry — knows per-source config, doesn't know about models.
- `Linkable` is the per-host concern — generates per-source methods, looks up sources by name.

## Data model

`LinkedResource` is a **polymorphic** join to any model. The `linkable_type` / `linkable_id` columns store the parent. The class column (`source`) and the id column (`external_id`) identify the linked-data entity.

| Column | Type | Notes |
|---|---|---|
| `linkable_type` | string | e.g. `"Site"` |
| `linkable_id` | bigint | parent's id |
| `source` | string | must match a registered `LinkedResource::Source#name` (validated) |
| `external_id` | string | the source's id, stored as-is (e.g. `"Q123456"` for Wikidata) |
| `status` | string | `"pending"` (default) or `"approved"` |
| `data` | jsonb | optional metadata cached from the source (label, description, …) |

**Source id is stored and printed as-is.** Do not prefix/suffix at display time; validate the full format via `LinkedResource::Source#id_pattern`.

## Naming conventions

Per AGENTS.md:

| Layer | Where | Example |
|---|---|---|
| Per-source registry PORO | `app/models/<model>/source.rb` (nested) | `LinkedResource::Source` |
| Per-source concern | `app/models/concerns/batch_matchable_to_<source>.rb` | `BatchMatchableToWikidata` |
| Host concern | `app/models/concerns/linkable.rb` | `Linkable` |

A new source typically needs only the registry entry. The `Linkable` macro picks it up automatically — no per-source methods to write. A matching concern (`BatchMatchableToPleiades`, etc.) is only needed if the source has an enrichment flow that warrants its own SPARQL/API logic.

## The registry: `LinkedResource::Source`

A PORO nested under `LinkedResource` (per the PORO-under-AR convention). Holds the per-source configuration.

**Each known source is a separate file** at `app/models/linked_resource/sources/<key>.rb`, defining a module `LinkedResource::Sources::<KeyCamelized>` that exposes an `ATTRIBUTES` constant (a frozen hash) **and calls `Source.register` at the bottom** to register itself when Zeitwerk loads the file. The `LinkedResource` model keeps a `KNOWN_SOURCES` whitelist that triggers the load (via `const_get`) and then asserts each source actually registered — so a missing or misbehaving source module fails loudly at class-load time rather than silently at use-time. The class body re-evaluates on every Zeitwerk reload, so the registry is repopulated in development without a separate `to_prepare` / `after_initialize` hook.

Pleiades (no brand logo) is a representative example:

```ruby
# app/models/linked_resource/sources/pleiades.rb
class LinkedResource
  module Sources
    module Pleiades
      ATTRIBUTES = {
        name: "Pleiades",
        url_template: "https://pleiades.stoa.org/places/%<id>s",
        id_pattern: /\A\d+\z/,
        has_logo: false,
        description: "Pleiades place resource"
      }.freeze

      LinkedResource::Source.register(:pleiades, **ATTRIBUTES)
    end
  end
end
```

```ruby
# app/models/linked_resource.rb
class LinkedResource < ApplicationRecord
  KNOWN_SOURCES = %i[wikidata pleiades].freeze
  KNOWN_SOURCES.each do |key|
    Sources.const_get(key.to_s.camelize)
    next if Source.known?(key.to_s)

    raise "Known source :#{key} is not registered. Check that " \
      "app/models/linked_resource/sources/#{key}.rb defines module " \
      "LinkedResource::Sources::#{key.to_s.camelize} and calls " \
      "LinkedResource::Source.register(#{key.inspect}, **ATTRIBUTES)."
  end
  # ...
end
```

`id_prefix` is **not** a thing — ids are stored as the user sees them. The `url_template` interpolates the full id via `%<id>s` (or `%{id}`, both work via `Kernel#format`).

**Registry API** (in `app/models/linked_resource/source.rb`):
- `LinkedResource::Source.register(:key, **attrs)` — register
- `LinkedResource::Source.find(name_or_key)` — by `"Pleiades"` (name) or `:pleiades` (key); returns `nil` if unknown
- `LinkedResource::Source.known?(name)` — boolean
- `LinkedResource::Source.all` — array of all registered
- `LinkedResource::Source.reset!` — for tests
- Instance: `source.url_for(id)`, `source.valid_id?(id)`, `source.has_logo?` (true by default; false for sources that fall back to a letter icon — see "Icons" below)

## Icons: logo SVG or letter fallback

The icon for a source is rendered by the `linked_resource_icon(source_name)` helper in `app/helpers/linked_resources_helper.rb`. Two paths:

- **Has a logo SVG** (`has_logo: true`, the default): the source's `icon` attribute is a SimpleIcons slug, and the helper renders `simple_icon(slug)`, which embeds the SVG at `app/assets/images/simple_icons/<slug>.svg`. Example: Wikidata → `simple_icon "wikidata"`.
- **No logo** (`has_logo: false`): the helper falls back to a Bootstrap Icons letter-circle built from the first letter of the source's name — `bs_icon "#{name.first.downcase}-circle"`. Example: Pleiades → `bs_icon "p-circle"`. The Bootstrap Icons `*-circle` alphabet is available for every letter, so the fallback works for any future source without a brand logo (Pleiades, Vici.org, OpenContext, iDAI, …).

## The `Linkable` concern

`Linkable` is mixed into any model that can have linked resources. The `linkable_to` macro generates per-source shortcut methods from the registry.

```ruby
class Site < ApplicationRecord
  has_many :linked_resources, as: :linkable, dependent: :destroy

  include Linkable
  linkable_to :wikidata          # one line per source
end
```

`linkable_to :wikidata` generates:
- `Site#wikidata_link` — reader for the LinkedResource
- `Site#missing_wikidata_link?` / `Site#pending_wikidata_link?` — predicates
- `Site.missing_wikidata_link` / `Site.pending_wikidata_link` — scopes
- Registers both issue symbols in `Site.linked_resource_issues` (the class-level array)

Adding Pleiades is a one-liner (`linkable_to :pleiades`); all the per-source methods appear automatically.

## ⛔ The async enrichment principle (CRITICAL)

**XRONOS must never be blocked by, or made reliant on, an external request.** External services (Wikidata, Pleiades, Geocoder, GBIF, Wikipedia, Nominatim, …) are **enrichment layers**. They add value; they must never gate a user action.

Three concrete rules:

1. **Enrichment produces pending records, not synchronous data.** The site show page never makes a SPARQL call. `BatchMatchableToWikidata.wikidata_match_candidates_batch` creates `LinkedResource` records with `status: "pending"` and stores the suggestion in `data`. The user (curator) reviews and approves later. The page is fast and works offline.

2. **Heavy enrichment runs in background jobs.** `Site::FetchDescriptionJob` pre-warms the `Site::Description` cache so the first request to the lazy turbo-frame hits a warm cache. Cache TTL is 7 days. Never call a Wikimedia / Wikidata / GBIF / Geocoder API synchronously from a controller action.

3. **Errors are silent, not fatal.** A SPARQL timeout, a GBIF 500, a Geocoder failure — all return empty / null. The user sees a record with no enrichment, not a 500 page. `BatchMatchableToWikidata` rescues `Net::OpenTimeout`, `Net::ReadTimeout`, `SocketError` and returns an empty hash.

When writing any new external-service integration:
- Ask: "what happens to the user if this endpoint is down for a week?" If the answer is "they can't use the app", you have a problem.
- Wrap every HTTP call in a rescue returning a safe default.
- Set a short timeout (≤ 5s) so a slow service doesn't hold up a worker.
- Use `Rails.cache` to memoize external responses; default TTL ≥ 1 day.
- If a record needs to be enriched on user-visible display, do it once at save and store the result. Never fetch on every request.

## Adding a new source: worked example (Pleiades)

Most sources need only steps 1–2. Add a concern only if you need SPARQL/API enrichment.

1. **Create a source module** at `app/models/linked_resource/sources/<key>.rb` (e.g. `pleiades.rb`). The filename is the source key in lowercase; the module name is the camelized form. The module exposes an `ATTRIBUTES` hash and **calls `Source.register` at the bottom** to register itself when loaded. Set `has_logo: false` if the source has no brand logo (see "Icons" above); set `icon: "<simpleicons-slug>"` (and `has_logo: true`, the default) if it does.

   ```ruby
   # app/models/linked_resource/sources/pleiades.rb
   class LinkedResource
     module Sources
       module Pleiades
         ATTRIBUTES = {
           name: "Pleiades",
           url_template: "https://pleiades.stoa.org/places/%<id>s",
           id_pattern: /\A\d+\z/,
           has_logo: false,
           description: "Pleiades place resource"
         }.freeze

         LinkedResource::Source.register(:pleiades, **ATTRIBUTES)
       end
     end
   end
   ```
2. **Add the key** to `LinkedResource::KNOWN_SOURCES` in `app/models/linked_resource.rb`. The model iterates this list to trigger each source's load and then asserts the registration actually happened. Forgetting the `Source.register` call (or getting the key wrong) will raise a loud error at class-load time, not at use-time.
3. **Add `linkable_to :pleiades`** to the host model (e.g. `Site`). This generates `pleiades_link`, `missing_pleiades_link?`, `pending_pleiades_link?`, the corresponding scopes, and registers the issue symbols so the per-site view and curation dashboard auto-populate.
4. **If the source has a logo** (the default path), add the SimpleIcons SVG at `app/assets/images/simple_icons/<key>.svg` (lowercase key). If `has_logo: false`, the `linked_resource_icon` helper falls back to a Bootstrap letter-circle — no asset to add.
5. **Test it** — `test/models/linked_resource/source_test.rb` for the registry (including `id_pattern` boundary cases and `has_logo?` for both states), `test/models/concerns/linkable_test.rb` for the macro on the new source. The site page's "Add {source} link" button and the missing/pending badges appear automatically; no view changes needed.

## The curation dashboard — Wikidata-only by design

The `LinkedResources::SitesController` dashboard (mounted at `/linked_resources/sites/:issue`) is currently Wikidata-only. Adding per-source dashboards is a separate decision; the data is already there (`Site.linked_resource_issues` is the array of every registered source's issue symbols). Talk to the user before exposing per-source views — they may want a per-source nav, a combined view, or neither.

## The `BatchMatchableToWikidata` pattern (template for new enrichments)

If a new source has an enrichment flow (e.g. matching C14s to Pleiades, finding Vici.org references by name), model it on `BatchMatchableToWikidata`:

- New concern `app/models/concerns/batch_matchable_to_<source>.rb`
- Class methods: `<source>_match_candidates_batch(records)` and helpers
- Constants: `USER_AGENT` (use `Xronos::USER_AGENT`), `<SOURCE>_<THING>_WIKIDATA_ID` (or similar)
- The `execute_*_request` method sets short timeouts (≤ 5s) and rescues network errors
- The match candidates method **only creates pending records** — never updates existing ones, never makes blocking writes the user is waiting on
- Models include the concern: `include BatchMatchableToPleiades` and add `linkable_to :pleiades`

## Common pitfalls
- Do not synchronously call external services in controllers or views.
- Do not block user-visible pages on external response time. If a controller or view needs enriched data, pre-warm it in a job.
- Do not prefix or strip the source id at display time. Store and print the full id (e.g. `Q123456`).
- Do not add per-source methods to the host model by hand. Use `linkable_to :source` so the macro generates them.
- Do not create a `WikidataLink`, `PleiadesLink`, etc. model. Use the polymorphic `LinkedResource` with `source: "Pleiades"`.
- Do not store ontology URLs in columns. The source registry is the single source of truth for URL templates.
- Do not `find_or_create_by!` a `LinkedResource` on the user's hot path. It's fine in a job; it's not fine in a controller.
- Do not use the `wikidata_link_attributes` strong-params key. There is no `WikidataLink` model.

## File map
- `app/models/linked_resource.rb` — the polymorphic model (also registers `KNOWN_SOURCES` in its class body)
- `app/models/linked_resource/source.rb` — the registry PORO
- `app/models/linked_resource/sources/` — one file per known source, each defining a module under `LinkedResource::Sources::<KeyCamelized>` with an `ATTRIBUTES` constant
- `app/models/concerns/linkable.rb` — the `linkable_to` macro
- `app/models/concerns/batch_matchable_to_wikidata.rb` — SPARQL enrichment for Wikidata
- `app/models/site/description.rb` — lazy Wikipedia + Wikimedia images, cached 7 days
- `app/jobs/site/fetch_description_job.rb` — pre-warms the description cache
- `app/controllers/linked_resources_controller.rb` — CRUD
- `app/controllers/linked_resources/sites_controller.rb` — curation dashboard
- `app/views/linked_resources/` — CRUD and curation views
- `app/helpers/linked_resources_helper.rb` — `linked_resource_icon` (logo SVG or letter-circle fallback), `linked_resource_badge` (issue badge)
- `lib/xronos.rb` — `Xronos::USER_AGENT`, `Xronos::CONTACT_EMAIL`
- `test/models/linked_resource_test.rb`
- `test/models/linked_resource/source_test.rb`
- `test/models/concerns/linkable_test.rb`
- `test/models/site/description_test.rb`
- `test/jobs/site/fetch_description_job_test.rb`
- `test/controllers/linked_resources_controller_test.rb`

## Maintaining this skill
If you add a new source, refactor `LinkedResource` or `LinkedResource::Source`, change the `linkable_to` macro, or add a new `BatchMatchableTo*` concern, **update this skill file** so future agents use the correct patterns. The async-enrichment principle is non-negotiable — if you're tempted to relax it, talk to the user first.
