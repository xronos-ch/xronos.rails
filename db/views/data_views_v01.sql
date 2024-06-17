SELECT 
  c14s.id as id,
  c14s.lab_identifier as labnr,
  c14s.bp as bp,
  c14s.std as std,
  c14s.cal_bp as cal_bp,
  c14s.cal_std as cal_std,
  c14s.delta_c13 as delta_c13,
  materials.name as material,
  taxons.name as species,
  contexts.name as feature,
  (
  SELECT st.name
  FROM site_types st
  JOIN site_types_sites sts ON st.id = sts.site_type_id
  JOIN contexts ctx ON ctx.site_id = sts.site_id
  JOIN samples samp ON samp.context_id = ctx.id
  WHERE samp.id = samples.id AND st.name IS NOT NULL LIMIT 1
  ) as feature_type,
  sites.name as site,
  sites.country_code as country,
  sites.lat::text as lat,
  sites.lng::text as lng,
  (
    SELECT st.name
    FROM site_types st
    JOIN site_types_sites sts ON st.id = sts.site_type_id
    JOIN contexts ctx ON ctx.site_id = sts.site_id
    JOIN samples samp ON samp.context_id = ctx.id
    WHERE samp.id = samples.id AND st.name IS NOT NULL LIMIT 1
  ) as site_type,
  (
    SELECT json_agg(json_build_object('periode', tp.name))
    FROM typos tp
    WHERE tp.sample_id = samples.id
  ) as periods,
  (
  SELECT json_agg(json_build_object('typochronological_unit', tp.name))
    FROM typos tp
    WHERE tp.sample_id = samples.id
  ) as typochronological_units,
  (
  SELECT json_agg(json_build_object('ecochronological_unit', tp.name))
    FROM typos tp
    WHERE tp.sample_id = samples.id
  ) as ecochronological_units,
  (
  SELECT json_agg(json_build_object('reference', ref.short_ref))
    FROM "references" ref
    JOIN citations cit ON ref.id = cit.reference_id
    WHERE cit.citing_type = 'C14' AND cit.citing_id = c14s.id
    ) as reference
FROM c14s
LEFT JOIN samples ON samples.id = c14s.sample_id
LEFT JOIN materials ON materials.id = samples.material_id
LEFT JOIN taxons ON taxons.id = samples.taxon_id
LEFT JOIN contexts ON contexts.id = samples.context_id
LEFT JOIN sites ON sites.id = contexts.site_id
LEFT JOIN site_types_sites ON site_types_sites.site_id = sites.id
LEFT JOIN site_types ON site_types_sites.site_type_id = site_types.id;