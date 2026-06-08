# == Schema Information
#
# Table name: citations
# Database name: primary
#
#  id           :bigint           not null, primary key
#  citing_type  :string
#  citing_id    :bigint
#  reference_id :bigint
#
# Indexes
#
#  index_citations_on_citing                (citing_type,citing_id)
#  index_citations_on_citing_and_reference  (citing_type,citing_id,reference_id) UNIQUE
#  index_citations_on_reference_id          (reference_id)
#
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

  test "destroying the last citation deletes its reference" do
    reference = create(:reference)
    citation  = create(:citation, reference: reference)

    assert_difference "Reference.count", -1 do
      citation.destroy
    end

    assert_nil Reference.find_by(id: reference.id),
      "Expected reference to be deleted when its last citation is destroyed"
  end

  test "destroying a citation does not delete a reference with remaining citations" do
    reference  = create(:reference)
    citation_1 = create(:citation, reference: reference)
    citation_2 = create(:citation, reference: reference)

    assert_difference "Citation.count", -1 do
      citation_1.destroy
    end

    assert Reference.exists?(reference.id),
      "Expected reference with remaining citations not to be deleted"

    assert_equal 1, reference.reload.citations.count
  end

end
