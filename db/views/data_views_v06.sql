SELECT DISTINCT c14s.id,
    c14s.lab_identifier AS labnr,
    c14s.bp,
    c14s.std,
    c14s.cal_bp,
    c14s.cal_std,
    c14s.delta_c13,
    ''::text AS source_database,
    ''::text AS lab_name,
    materials.name AS material,
    taxons.name AS species,
    contexts.name AS feature,
    ( SELECT st.name
           FROM site_types st
             JOIN site_types_sites sts ON st.id = sts.site_type_id
             JOIN contexts ctx ON ctx.site_id = sts.site_id
             JOIN samples samp ON samp.context_id = ctx.id
          WHERE samp.id = samples.id AND st.name IS NOT NULL
         LIMIT 1) AS feature_type,
    sites.name AS site,
    sites.country_code AS country,
    sites.lat::text AS lat,
    sites.lng::text AS lng,
    ( SELECT st.name
           FROM site_types st
             JOIN site_types_sites sts ON st.id = sts.site_type_id
             JOIN contexts ctx ON ctx.site_id = sts.site_id
             JOIN samples samp ON samp.context_id = ctx.id
          WHERE samp.id = samples.id AND st.name IS NOT NULL
         LIMIT 1) AS site_type,
    COALESCE(( SELECT json_agg(json_build_object('periode', tp.name)) AS json_agg
           FROM typos tp
             JOIN samples sam ON tp.sample_id = sam.id
             JOIN contexts contexts_1 ON sam.context_id = contexts_1.id
             JOIN samples all_samples ON all_samples.context_id = contexts_1.id
          WHERE all_samples.id = samples.id), '[]'::json)::jsonb AS periods,
    COALESCE(( SELECT json_agg(json_build_object('typochronological_unit', tp.name)) AS json_agg
           FROM typos tp
             JOIN samples sam ON tp.sample_id = sam.id
             JOIN contexts contexts_1 ON sam.context_id = contexts_1.id
             JOIN samples all_samples ON all_samples.context_id = contexts_1.id
          WHERE all_samples.id = samples.id), '[]'::json)::jsonb AS typochronological_units,
    COALESCE(( SELECT json_agg(json_build_object('ecochronological_unit', tp.name)) AS json_agg
           FROM typos tp
             JOIN samples sam ON tp.sample_id = sam.id
             JOIN contexts contexts_1 ON sam.context_id = contexts_1.id
             JOIN samples all_samples ON all_samples.context_id = contexts_1.id
          WHERE all_samples.id = samples.id), '[]'::json)::jsonb AS ecochronological_units,
    COALESCE(( SELECT json_agg(json_build_object('reference', ref.short_ref)) AS json_agg
           FROM "references" ref
             JOIN citations cit ON ref.id = cit.reference_id
          WHERE cit.citing_type::text = 'C14'::text AND cit.citing_id = c14s.id), '[]'::json)::jsonb AS reference
   FROM c14s
     LEFT JOIN samples ON samples.id = c14s.sample_id
     LEFT JOIN materials ON materials.id = samples.material_id
     LEFT JOIN taxons ON taxons.id = samples.taxon_id
     LEFT JOIN contexts ON contexts.id = samples.context_id
     LEFT JOIN sites ON sites.id = contexts.site_id
     LEFT JOIN site_types_sites ON site_types_sites.site_id = sites.id
     LEFT JOIN site_types ON site_types_sites.site_type_id = site_types.id;