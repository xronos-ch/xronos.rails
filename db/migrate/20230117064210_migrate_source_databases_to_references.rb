class MigrateSourceDatabasesToReferences < ActiveRecord::Migration[6.1]
  # This IRREVERSIBLE migration transforms data from the deprecated 
  # source_databases table into references associated with the respective 
  # records.
  #
  # It also creates paper_trail 'create' versions for records previously 
  # imported directly into the database, noting the original source database. 
  # Unfortunately since only c14s had a source_database column, we can only do
  # this unambiguously for c14s.
  #
  # See https://github.com/xronos-ch/xronos.rails/issues/136 for rationale.
  def change
    # Make references from source_databases
    # - First ensuring pkey sequence is in sync
    # - Saving a temporary relation between source_databases and references (in both tables)
    # - Wrapping citation in dummy BibTeX so as to not break views
    execute %(ALTER TABLE "references" ADD COLUMN source_database_id INT;)
    execute %(SELECT setval('public.references_id_seq', (SELECT MAX(id) FROM "references")+1);)
    execute %(
      INSERT INTO "references"
        (short_ref, bibtex, created_at, updated_at, source_database_id)
      SELECT
        name AS short_ref,
        '@Misc{' || name || ', url = {' || url || '}, note = {' || citation || '} }' AS bibtex,
        created_at,
        updated_at,
        id AS source_database_id
      FROM source_databases;
    )
    execute %(ALTER TABLE source_databases ADD COLUMN reference_id INT;)
    execute %(
      UPDATE source_databases 
      SET reference_id = ref.id
      FROM "references" AS ref
      WHERE source_databases.id = ref.source_database_id
    )

    # Create citations to references for c14s
    execute %(
      INSERT INTO citations
        (reference_id, citing_type, citing_id)
      SELECT 
        source_databases.reference_id AS reference_id,
        'C14' AS citing_type,
        c14s.id AS citing_id
      FROM c14s, source_databases 
      WHERE source_databases.id = c14s.source_database_id;
    )

    # Create versions (event: create) for the initial import
    # - for models that has_paper_trail (c14s, c14_labs, typos, samples, materials, taxons, contexts, sites, site_types, references)
    # - With the same created_date as the record
    # - Linking to the import script (https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)
    #
    # For c14s:
    # - Noting the name of the source database
    # - Linking to the source database and c14bazAAR
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'C14' AS item_type,
        c14s.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        c14s.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from [', source_databases.name, '](', source_databases.url, ') via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM c14s, source_databases
      WHERE c14s.source_database_id = source_databases.id;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'C14Lab' AS item_type,
        c14_labs.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        c14_labs.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM c14_labs;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'Typo' AS item_type,
        typos.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        typos.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM typos;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'Sample' AS item_type,
        sAMPLES.ID as ITEM_ID,
        'create' AS event,
        3 AS whodunnit,
        samples.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM samples;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'Material' AS item_type,
        materials.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        materials.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM materials;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'Taxon' AS item_type,
        taxons.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        taxons.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM taxons;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'Context' AS item_type,
        contexts.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        contexts.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM contexts;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'Context' AS item_type,
        contexts.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        contexts.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM contexts;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'Site' AS item_type,
        sites.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        sites.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM sites;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'SiteType' AS item_type,
        site_types.id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        site_types.created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM site_types;
    )
    execute %(
      INSERT INTO versions
        (item_type, item_id, event, whodunnit, created_at, whodunnit_user_email, revision_comment)
      SELECT
        'Reference' AS item_type,
        "references".id AS item_id,
        'create' AS event,
        3 AS whodunnit,
        "references".created_at AS created_at,
        'admin@xronos.ch' AS whodunnit_user_email,
        CONCAT('Imported from source database via [c14bazAAR](https://github.com/xronos-ch/xronos-import/blob/eba0da90659b60fdcd698adc3e40e904e03e5a29/scripts/xronos_import_20220202.R)') AS revision_comment
      FROM "references";
    )
    
    # Drop temporary foreign key from references
    execute %(
      ALTER TABLE "references" DROP COLUMN source_database_id
    )

    # Drop source_database foreign keys
    remove_column :c14s, :source_database_id

    # Drop source_databases
    drop_table :source_databases
  end
end
