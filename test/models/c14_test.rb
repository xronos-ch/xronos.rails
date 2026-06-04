require "test_helper"

class C14Test < ActiveSupport::TestCase

  test "destroying a c14 destroys its citations" do
    c14 = create(:c14, :with_citations, citations_count: 2)
    assert_dependent_destroy(c14, :citations, count: 2)
  end

end
