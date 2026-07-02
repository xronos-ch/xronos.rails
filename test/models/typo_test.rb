# == Schema Information
#
# Table name: typos
# Database name: primary
#
#  id                :bigint           not null, primary key
#  approx_end_time   :integer
#  approx_start_time :integer
#  name              :string
#  superseded_by     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  parent_id         :integer
#  sample_id         :bigint
#
# Indexes
#
#  index_typos_on_name           (name)
#  index_typos_on_sample_id      (sample_id)
#  index_typos_on_superseded_by  (superseded_by)
#
require "test_helper"

class TypoTest < ActiveSupport::TestCase
  test "destroying a typo destroys its citations" do
    typo = create(:typo, :with_citations, citations_count: 2)
    assert_dependent_destroy(typo, :citations, count: 2)
  end

  test "parent and children associations work" do
    parent = create(:typo)
    child = create(:typo, parent: parent)

    assert_includes parent.children, child
    assert_equal parent, child.parent
  end
end
