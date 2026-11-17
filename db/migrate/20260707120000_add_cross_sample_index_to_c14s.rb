# frozen_string_literal: true

# Composite index that lets `Chron.cross_sample_pairs` (`app/models/chron.rb`)
# resolve the cross-sample candidate query in an index-only scan: the
# `lab_identifier` and `sample_id` predicates narrow to a small set, and
# the `created_at` ordering avoids a sort. The same index is reused by
# the per-row `find_cross_sample_chron_duplicate_sample` query in the
# `after_save :merge_cross_sample_duplicates` callback.
class AddCrossSampleIndexToC14s < ActiveRecord::Migration[8.0]
  def change
    add_index :c14s, %i[lab_identifier sample_id created_at],
              name: 'index_c14s_on_lab_identifier_sample_id_and_created_at'
  end
end
