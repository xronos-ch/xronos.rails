---
name: controlled-vocabularies
description: Work with the ControlledVocabulary model family and the HasControlledTerms concern in XRONOS. Covers the strict-vs-fuzzy matching split, the variant thesaurus, normalization rules, and how to add new controlled-term-backed attributes. Use when adding, seeding, querying, or refactoring any controlled-vocabulary-backed attribute.
license: MIT
compatibility: opencode
metadata:
  domain: xronos
  layer: model
---

## What I do
- Document the ControlledVocabulary, ControlledVocabulary::Term, and ControlledVocabulary::Variant models
- Document the HasControlledTerms concern and its API
- Flag the strict-vs-fuzzy matching split and the normalization rules

## When to use me
Use this when:
- Adding a controlled-vocabulary-backed attribute to a model (e.g. `Sample#preservation_state`)
- Building a form that suggests canonical terms from a vocabulary
- Writing a rake task to seed terms from an external source
- Debugging why a value isn't matching (case, normalization, variant vs exact)

## The model family
- `ControlledVocabulary` — a named collection of terms. `self[name]` lookup.
- `ControlledVocabulary::Term` — a term within a vocabulary. Optional `ontology_name` + `ontology_id`; `ontology_url` is computed.
- `ControlledVocabulary::Variant` — a user-typed value mapped to a term. `value` stored verbatim; `normalized` is computed.
- `HasControlledTerms` (concern) — declarative API for adding controlled-term attributes to any model.

## The strict-vs-fuzzy split (do not mix)
- `ControlledVocabulary#match(input)` — **strict**, exact case-sensitive name match. Database use.
- `ControlledVocabulary#resolve_variant(input)` — **fuzzy**, case-insensitive match against the variant thesaurus. UI use.

The form composes: `vocab.resolve_variant(input) || vocab.match(input)`. Do not add fallbacks to `match`; if you need fuzzy, use `resolve_variant`.

## `HasControlledTerms` concern
```ruby
class Sample < ApplicationRecord
  include HasControlledTerms
  controlled_term :part_of_organism, vocabulary: "part_of_organism"
end
```

Per-attribute (no-arg) instance methods generated: `attribute_controlled?`, `attribute_vocabulary`, `attribute_term`, `attribute_ontologies`.

Parameterised: `controlled?(:attr)`, `vocabulary_for(:attr)`, `term_for(:attr)`, `ontologies_for(:attr)`, `resolve_variant_for(:attr, input)`.

Scopes: `Sample.controlled(:attr)` / `Sample.controlled_attr` and the `uncontrolled_*` pair. Backed by a single `EXISTS` / `NOT EXISTS`; **case-sensitive, does not consult variants**.

## Variant normalization
Single source of truth: `ControlledVocabulary::Variant.normalize_for_matching(value)`. Rule: `value.to_s.downcase.squish`.

Folds: case, leading/trailing whitespace, internal whitespace runs. Preserves: punctuation, hyphens, Unicode. The `value` column is never modified — only the `normalized` form is collapsed.

The `before_validation` callback on Variant and the needle computation in `resolve_variant` **must use the same rule** or matches silently break. There is a regression test for this.

## Adding a new controlled-term attribute
```ruby
# migration
add_column :samples, :preservation_state, :text

# model
controlled_term :preservation_state, vocabulary: "preservation_state"
```

**Do not** add a FK to `controlled_vocabulary_terms`, a scoped `belongs_to`, a validation that rejects non-vocabulary values, `accepts_nested_attributes_for`, `destroy_if_orphaned`, or a `HasIssues` entry for "missing". The database accepts any text; the vocabulary match is a runtime concern.

## Adding a new vocabulary
Create with `ControlledVocabulary.find_or_create_by!(name: "...")`. Add terms (set `ontology_name` + `ontology_id` together if referencing an external ontology). Upsert on `(ontology_name, ontology_id)`. To add a new external ontology, extend `ControlledVocabulary::Term::ONTOLOGY_URL_TEMPLATES` — never store URLs in columns (the registry is the single source of truth).

## Seeding from external sources
Use the `xronos:*` rake task pattern (see `lib/tasks/taxons.rake`, `materials.rake`): `DRY_RUN` env var (defaults true), `ProgressBar` from `ruby-progressbar`, `find_each` for batching, per-record rescue to log and continue. Make the task idempotent so re-running with the same source is a no-op.

## Common pitfalls
- Don't put a FK on the model. Import principle requires free-text acceptance.
- Don't validate against vocabulary membership.
- Don't add a scoped `belongs_to`.
- Don't introduce a third matching semantic — `match` is strict, `resolve_variant` is fuzzy.
- Don't break the normalization symmetry — both sides go through `normalize_for_matching`.
- Don't store the ontology URL — always derive from `ONTOLOGY_URL_TEMPLATES`.
- Don't use `find_or_create_by!` on a Term without setting `ontology_name` + `ontology_id` together, unless you mean to create a vocabulary-local term.

## File map
- `app/models/controlled_vocabulary.rb`
- `app/models/controlled_vocabulary/term.rb` — incl. `ONTOLOGY_URL_TEMPLATES`
- `app/models/controlled_vocabulary/variant.rb` — incl. `normalize_for_matching`
- `app/models/concerns/has_controlled_terms.rb`
- `test/models/controlled_vocabulary_test.rb`
- `test/models/controlled_vocabulary/term_test.rb`
- `test/models/controlled_vocabulary/variant_test.rb`
- `test/models/concerns/has_controlled_terms_test.rb`
