require "test_helper"

class TypoTest < ActiveSupport::TestCase
  test "destroying a typo destroys its citations" do
    typo = create(:typo, :with_citations, citations_count: 2)
    assert_dependent_destroy(typo, :citations, count: 2)
  end
end
