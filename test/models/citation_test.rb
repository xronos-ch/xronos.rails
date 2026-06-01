require "test_helper"

class CitationTest < ActiveSupport::TestCase
  test "does not allow duplicate citations for the same reference and citing record" do
    citation = create(:citation)

    duplicate = build(
      :citation,
      reference: citation.reference,
      citing: citation.citing
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reference], "has already been cited for this record"
  end

end
