# == Schema Information
#
# Table name: typos
# Database name: primary
#
#  id                :bigint           not null, primary key
#  approx_end_time   :integer
#  approx_start_time :integer
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  parent_id         :integer
#  sample_id         :bigint
#
# Indexes
#
#  index_typos_on_name       (name)
#  index_typos_on_sample_id  (sample_id)
#
require "test_helper"

class TypoTest < ActiveSupport::TestCase
  test "destroying a typo destroys its citations" do
    typo = create(:typo, :with_citations, citations_count: 2)
    assert_dependent_destroy(typo, :citations, count: 2)
  end
end
