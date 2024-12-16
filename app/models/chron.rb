class Chron < ApplicationRecord
  self.abstract_class = true

  def self.fetch_c14
    C14
    .left_outer_joins(:c14_lab)
    .joins("LEFT OUTER JOIN cals on (cals.c14_age = c14s.bp AND cals.c14_error = c14s.std)")
      .left_outer_joins(sample: [
        :material,
        :taxon,
        context: [
          site: [
            :site_types
          ]
        ]
    ])
    .all.distinct
  end
  def self.fetch_dendro
    Dendro
    .left_outer_joins(sample: [
      :material,
      :taxon,
      context: [
        site: [
          :site_types
        ]
      ]
    ])
    .all.distinct
  end
end