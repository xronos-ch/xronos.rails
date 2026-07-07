# frozen_string_literal: true

# Composite index for `Typo.cross_sample_pairs` (`app/models/chron.rb`,
# inherited from `Chron`). See `AddCrossSampleIndexToC14s` for the
# rationale; `name` here is the Typo equivalent of `lab_identifier`
# (the strict attr most likely to match a cross-sample duplicate).
class AddCrossSampleIndexToTypos < ActiveRecord::Migration[8.0]
  def change
    add_index :typos, %i[name sample_id created_at],
              name: 'index_typos_on_name_sample_id_and_created_at'
  end
end
