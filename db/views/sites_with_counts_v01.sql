SELECT
  sites.*,
  COALESCE(c14_counts.c14s_count, 0) AS c14s_count,
  COALESCE(typo_counts.typos_count, 0) AS typos_count,
  COALESCE(ref_counts.references_count, 0) AS references_count
FROM sites
LEFT JOIN (
  SELECT contexts.site_id, COUNT(*) AS c14s_count
  FROM c14s
  JOIN samples ON samples.id = c14s.sample_id
  JOIN contexts ON contexts.id = samples.context_id
  GROUP BY contexts.site_id
) c14_counts ON c14_counts.site_id = sites.id
LEFT JOIN (
  SELECT contexts.site_id, COUNT(*) AS typos_count
  FROM typos
  JOIN samples ON samples.id = typos.sample_id
  JOIN contexts ON contexts.id = samples.context_id
  GROUP BY contexts.site_id
) typo_counts ON typo_counts.site_id = sites.id
LEFT JOIN (
  SELECT citing_id AS site_id, COUNT(*) AS references_count
  FROM citations
  WHERE citing_type = 'Site'
  GROUP BY citing_id
) ref_counts ON ref_counts.site_id = sites.id
