require "test_helper"

class ReferenceTest < ActiveSupport::TestCase
  test "destroying a reference destroys its citations" do
    reference = create(:reference)
    create_list(:citation, 2, reference: reference)

    assert_dependent_destroy(reference, :citations, count: 2)
  end
end
