# == Schema Information
#
# Table name: samples
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  position_crs         :text
#  position_description :text
#  position_x           :decimal(, )
#  position_y           :decimal(, )
#  position_z           :decimal(, )
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  context_id           :integer
#  material_id          :integer
#  taxon_id             :integer
#
# Indexes
#
#  index_samples_on_context_id    (context_id)
#  index_samples_on_material_id   (material_id)
#  index_samples_on_position_crs  (position_crs)
#  index_samples_on_taxon_id      (taxon_id)
#
require "test_helper"

class SampleTest < ActiveSupport::TestCase

  test "destroying a sample destroys its c14s" do
    sample = create(:sample)
    create_list(:c14, 2, sample: sample)

    assert_dependent_destroy(sample, :c14s, count: 2)
  end

  test "destroying a sample destroys its typos" do
    sample = create(:sample)
    create_list(:typo, 2, sample: sample)

    assert_dependent_destroy(sample, :typos, count: 2)
  end

end

