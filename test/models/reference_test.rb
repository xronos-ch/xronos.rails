# == Schema Information
#
# Table name: references
# Database name: primary
#
#  id         :bigint           not null, primary key
#  bibtex     :text
#  short_ref  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_references_on_short_ref  (short_ref)
#
require "test_helper"

class ReferenceTest < ActiveSupport::TestCase
  test "destroying a reference destroys its citations" do
    reference = create(:reference)
    create_list(:citation, 2, reference: reference)

    assert_dependent_destroy(reference, :citations, count: 2)
  end
end
