SELECT
  c14s.id,
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
  site_type_lateral.st_name AS feature_type,
  sites.name AS site,
  sites.country_code AS country,
  sites.lat::text AS lat,
  sites.lng::text AS lng,
  site_type_lateral.st_name AS site_type,
  COALESCE(typo_agg.periods, '[]'::json)::jsonb AS periods,
  COALESCE(typo_agg.typochronological_units, '[]'::json)::jsonb AS typochronological_units,
  COALESCE(typo_agg.ecochronological_units, '[]'::json)::jsonb AS ecochronological_units,
  COALESCE(ref_agg.reference, '[]'::json)::jsonb AS reference
FROM c14s
  LEFT JOIN samples ON samples.id = c14s.sample_id
  LEFT JOIN materials ON materials.id = samples.material_id
  LEFT JOIN taxons ON taxons.id = samples.taxon_id
  LEFT JOIN contexts ON contexts.id = samples.context_id
  LEFT JOIN sites ON sites.id = contexts.site_id
  LEFT JOIN LATERAL (
    SELECT st.name AS st_name
    FROM site_types st
    JOIN site_types_sites sts ON st.id = sts.site_type_id
    WHERE sts.site_id = sites.id AND st.name IS NOT NULL
    LIMIT 1
  ) site_type_lateral ON true
  LEFT JOIN LATERAL (
    SELECT
      json_agg(json_build_object('periode', tp.name)) AS periods,
      json_agg(json_build_object('typochronological_unit', tp.name)) AS typochronological_units,
      json_agg(json_build_object('ecochronological_unit', tp.name)) AS ecochronological_units
    FROM typos tp
    JOIN samples sam ON tp.sample_id = sam.id
    WHERE sam.context_id = samples.context_id
  ) typo_agg ON true
  LEFT JOIN LATERAL (
    SELECT json_agg(json_build_object('reference', ref.short_ref)) AS reference
    FROM "references" ref
    JOIN citations cit ON ref.id = cit.reference_id
    WHERE cit.citing_type = 'C14' AND cit.citing_id = c14s.id
  ) ref_agg ON true;
