# XRONOS Rails Configuration

The XRONOS web application is the core component of XRONOS, a scientific open data infrastructure for archaeological chronology.
It is a tool primarily intended to be used by a small community of professional scientists.
Our design philosophy emphasises simplicitly, independence and long-term maintainability over cutting-edge or highly optimized frameworks.

## Tech Stack

- **Ruby** 3.3, **Rails** 8.0, **PostgreSQL**
- **Assets:** propshaft (for now)
- **Frontend:** Hotwire (Turbo 8 + Stimulus 3.x), Bootstrap 5
- **Testing:** Minitest + FactoryBot
- **Auth:** Devise
- **Background Jobs:** Solid Queue (database-backed, no Redis)
- **Caching:** Solid Cache
- **WebSockets:** Solid Cable
- **Deployment:** Docker via DockerHub

## Architecture

```
app/
  controllers/     # Thin. Only 7 REST actions. New resource for each state change.
  models/          # Rich. Business logic, concerns, associations, validations.
  models/concerns/ # Horizontal behavior: Versioned, Duplicable, Supersedable.
  views/           # ERB + Turbo Frames/Streams. No JS frameworks.
  javascript/      # Stimulus controllers. General purpose, not tied to business logic.
  jobs/            # Shallow. Call model methods, don't contain logic.
  mailers/         # Minimal. Bundle notifications, plain-text first.
  channels/        # ActionCable channels for real-time.
```

**No `app/services/`, `app/queries/`, `app/policies/`, `app/forms/` directories.** 
Business logic lives in models. 
Complex forms use standard Rails nested attributes.

## Core Philosophy

- **Vanilla Rails:** Rich domain models, thin controllers, avoid service objects (acceptable when justified, but not as default architecture)
- **Everything is CRUD:** State changes = new resources (`Superseded`, `Publication`)
- **State as records:** No boolean flags for business state -- use `has_one` state records
- **Rich models over services:** Business logic lives in models, organized via concerns
- **Concerns for organization:** Models compose behavior via focused concerns (`Versioned`, `Duplicable`)
- **No foreign key constraints:** Application enforces referential integrity
- **Shallow jobs:** `_later`/`_now` pattern; job calls model method, logic stays in model

## Key Commands

```bash
bin/setup                                    # Initial setup
bin/dev                                      # Start dev server
bin/rails test                               # Full test suite
bin/rails test test/models/card_test.rb      # Specific file
bin/rails test test/models/card_test.rb:14   # Specific line
bin/rails test:system                        # System tests (Capybara + Selenium)
bundle exec rubocop -a                       # Auto-fix Ruby style
bin/rails db:migrate                         # Run migrations
bin/rails db:reset                           # Drop, create, load schema + seeds
```

## Development Workflow

1. Write a failing Minitest test using factories
2. Implement minimal code to make it pass
3. Refactor while tests stay green
4. Stop to ask if the change is acceptable
5. If acceptable, suggest a brief CHANGELOG entry and commit message

Never commit or push changes yourself; that is the user's job.

## CHANGELOG

CHANGELOG contains a brief log of significant, user-facing changes. 
Ideally each line should be linked to at least one issue or pull request. 
Do not over-fill the CHANGELOG with details of internal API changes, code refactoring, etc. that has no discernable impact on users.

## Naming Conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Model | Singular PascalCase | `Site`, `SiteName` |
| Controller | Plural, nested by resource | `Articles::PublicationsController` |
| State Record | Noun describing state | `Supersession`, `Publication` |
| Concern | Adjective/-able | `Versioned`, `Duplicable`, `Supersedable` |
| Job | `Model::VerbJob` | `Event::RelayJob`, `Card::CleanupJob` |
| Test | `ModelTest` / `ControllerTest` | `SiteTest`, `Articles::PublicationsControllerTest` |

## Style Guide

- Guard clauses over complex conditionals
- Method ordering: class methods > public instance (`initialize` first) > private
- Order private methods by invocation flow (call order)
- Bang methods (`!`) only when a non-bang counterpart exists
- Newline under `private`/`protected` keyword; do not indent content under it
- Avoid service objects -- domain logic belongs in models with concerns (services acceptable when justified)
- **No premature abstraction:** Don't extract until complexity demands it. Three similar lines > wrong abstraction.
- **Explicit > implicit:** Clear service calls over hidden callbacks. Named methods over metaprogramming.

## Testing Conventions

- Test behaviour, not implementation
- Prefer integration-style model tests over excessive mocking
- Use system tests sparingly, for critical user flows
- Use FactoryBot to setup test data
- db:seed should only create real data needed in production
- Rake tasks for dummy data for sanity checking

## Migrations

- Keep migrations reversible
- Avoid destructive changes without backfill strategy
- Add indexes for foreign keys and frequent queries
- Never mix data migrations with schema changes unless necessary

## Data Model and Core Domain Logic

### Core Domain: “Chrons”

- Chrons are primary scientific records (e.g. `C14`, `Typo`, `Dendro`)
- They represent dated evidence of past human activity

### Core Association Chain

Structure:

Chron -> Sample -> Context -> Site

Rules:
- Each level is required (no orphaned core records)
- Associations are many-to-one (child belongs to parent)
- Always use ActiveRecord associations (no manual joins)

---

### Bibliographic Links

Structure:

Chron <-> Citation <-> Reference  
Site  <-> Citation <-> Reference

Rules:
- `Citation` is the only join model
- Do not link `Reference` directly to core models

---

### Core vs Peripheral Models

Core models (scientific data):

- Examples: `Chron`, `Sample`, `Context`, `Site`
- Must track all changes
- Must have stable permalinks
- Must support redirects on merge or move
- Must not be hard-deleted (unless explicitly approved)

Peripheral models (dependent scientific data):

- Examples: `SiteName`, `Taxon`, `Material`
- Only meaningful in relation to a core model
- Changes are tracked on the parent core record
- Can be deleted if not referenced

Non-scientific models:

- Examples: `UserProfile`, `Article`
- Not part of the scientific domain
- No change tracking required
- Standard CRUD lifecycle

---

### Data Integrity Rules

- Core hierarchy must remain intact: Chron -> Sample -> Context -> Site
- Do not duplicate scientific meaning across records
- Prefer association traversal over denormalisation
- All mutations to core data must be auditable

---

## UI Design

### Interface Layers

Layer 1: Public Interface

- Read-only access to scientific data
- Includes core records and associated data (citations, metadata)

Rules:
- No editing capabilities
- Stable URLs (permalinks)

---

Layer 2: Curation Interface (authenticated users)

- Used for editing and maintaining data

Includes:
- Create/update core and peripheral records
- Bulk editing
- Data quality workflows

Rules:
- All edits go through standard Rails forms
- Must preserve auditability of core data
- Prefer incremental updates over destructive changes

---

Layer 3: Admin Interface (admin users only)

- Project-level management

Includes:
- Destructive actions (delete, merge)
- User management
- System configuration

Rules:
- Destructive actions must be explicit and rare
- Must not be exposed in the curation interface

### Cross-Layer Rules

- Privilege order: Public < Curation < Admin
- Do not expose admin functionality in lower layers
- Controllers and routes must reflect layer boundaries
- Authentication and authorisation enforced per layer

## Other XRONOS Conventions

- User-facing models should have a self.label method for a human-friendly name
