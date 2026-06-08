# Admin command-line tasks

XRONOS includes several administrative command-line tasks for maintenance, cache updates, authority matching, and controlled deletion of records.

Run tasks from the application root with:

```bash
bin/rails <task>
```

In production Docker deployments, run commands inside the application container and set `RAILS_ENV=production` where needed.

Many destructive tasks default to dry-run mode. To actually modify or delete records, pass:

```bash
DRY_RUN=false
```

Use destructive tasks with care. Prefer running them first without `DRY_RUN=false` to inspect what would happen.

## Search and sitemap tasks

These tasks are provided by dependencies and are useful for operational maintenance.

### Rebuild PgSearch multisearch records

```bash
bin/rails pg_search:multisearch:rebuild[Model]
```

or, if a schema argument is needed:

```bash
bin/rails pg_search:multisearch:rebuild[Model,public]
```

Rebuilds PgSearch multisearch records for the given model.

### Refresh the sitemap

```bash
bin/rails sitemap:refresh
```

Generates sitemap files and pings search engines.

To generate sitemap files without pinging search engines:

```bash
bin/rails sitemap:refresh:no_ping
```

To remove generated sitemap files:

```bash
bin/rails sitemap:clean
```

## Cache tasks

### Update cached Wikidata match candidates for sites

```bash
bin/rails cache:update_sites_wikidata_match
```

Processes sites in batches and stores potential Wikidata match candidates in the Rails cache.

## Authority matching

### Match unknown taxons to GBIF

```bash
bin/rails xronos:taxons:match_unknown
```

By default, this is a dry run. To perform the matching:

```bash
DRY_RUN=false bin/rails xronos:taxons:match_unknown
```

The task processes taxons flagged as unknown and attempts exact matches against the GBIF Backbone Taxonomy.

## Data cleanup tasks

### Remove duplicate citations

```bash
DRY_RUN=true bin/rails xronos:citations:deduplicate
```

Runs citation deduplication in dry-run mode and reports duplicate citation groups.

To delete duplicates:

```bash
bin/rails xronos:citations:deduplicate
```

This task keeps the lowest citation ID per unique `citing_type`, `citing_id`, and `reference_id` combination and removes duplicate rows.

Note that this task treats the presence of `DRY_RUN` as dry-run mode. Unlike most other cleanup tasks, deleting duplicates is the default when `DRY_RUN` is not set.

### Destroy orphaned taxons

```bash
bin/rails xronos:taxons:destroy_orphans
```

By default, this is a dry run. To delete taxons not associated with any samples:

```bash
DRY_RUN=false bin/rails xronos:taxons:destroy_orphans
```

### Destroy orphaned materials

```bash
bin/rails xronos:materials:destroy_orphans
```

By default, this is a dry run. To delete materials not associated with any samples:

```bash
DRY_RUN=false bin/rails xronos:materials:destroy_orphans
```

### Destroy orphaned references

```bash
bin/rails xronos:references:destroy_orphans
```

This task requires an admin user ID for PaperTrail attribution:

```bash
ADMIN_USER_ID=1 bin/rails xronos:references:destroy_orphans
```

By default, this is a dry run. To delete references not cited by any records:

```bash
ADMIN_USER_ID=1 DRY_RUN=false bin/rails xronos:references:destroy_orphans
```

An optional revision comment can be provided:

```bash
ADMIN_USER_ID=1 DRY_RUN=false REVISION_COMMENT="Deleted uncited reference." bin/rails xronos:references:destroy_orphans
```

## Controlled record deletion

### Generic destroy task

```bash
MODEL=Site ID=123 ADMIN_USER_ID=1 bin/rails xronos:destroy
```

By default, this is a dry run. To actually destroy the record:

```bash
MODEL=Site ID=123 ADMIN_USER_ID=1 DRY_RUN=false bin/rails xronos:destroy
```

The task prints the dependent destroy tree before deleting anything. It also uses PaperTrail attribution via `ADMIN_USER_ID`.

Optional revision comment:

```bash
MODEL=Site ID=123 ADMIN_USER_ID=1 REVISION_COMMENT="Deleted duplicate site." DRY_RUN=false bin/rails xronos:destroy
```

### Destroy a site by ID

```bash
ID=123 ADMIN_USER_ID=1 bin/rails xronos:sites:destroy
```

To actually destroy the site:

```bash
ID=123 ADMIN_USER_ID=1 DRY_RUN=false bin/rails xronos:sites:destroy
```

This is a wrapper around `xronos:destroy` with `MODEL=Site`.

### Destroy a reference by ID

```bash
ID=123 ADMIN_USER_ID=1 bin/rails xronos:references:destroy
```

To actually destroy the reference:

```bash
ID=123 ADMIN_USER_ID=1 DRY_RUN=false bin/rails xronos:references:destroy
```

This is a wrapper around `xronos:destroy` with `MODEL=Reference`.

## Scheduled maintenance tasks

Some maintenance tasks are configured through `config/schedule.rb` and `whenever`.

Currently scheduled production jobs include:

```bash
bin/rails sitemap:refresh
bin/rails refreshers:data_views
bin/rails runner "Data.store_data_as_json"
```

These jobs require cron to be running in the production container. If scheduled jobs appear not to run, check both the installed crontab and the cron process.

```bash
crontab -l
ps aux | grep -E "cron|CRON"
```