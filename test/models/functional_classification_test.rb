require "test_helper"

class FunctionalClassificationTest < ActiveSupport::TestCase
  test "factory creates a valid classification" do
    classification = create(:functional_classification)

    assert classification.valid?
    assert_instance_of Context, classification.assignable
    assert classification.functional_classification_category.present?
  end

  test "requires confidence" do
    classification = build(:functional_classification, confidence: nil)

    assert_not classification.valid?
    assert_includes classification.errors[:confidence], "can't be blank"
  end

  test "does not allow duplicate category for same assignable" do
    assignable = create(:context)
    category = create(:functional_classification_category)

    create(
      :functional_classification,
      assignable: assignable,
      functional_classification_category: category
    )

    duplicate = build(
      :functional_classification,
      assignable: assignable,
      functional_classification_category: category
    )

    assert_not duplicate.valid?
    assert_includes(
      duplicate.errors[:functional_classification_category_id],
      "has already been assigned to this record"
    )
  end

  test "allows same category for different assignables" do
    category = create(:functional_classification_category)

    first = create(:functional_classification, functional_classification_category: category)
    second = build(:functional_classification, functional_classification_category: category)

    assert first.valid?
    assert second.valid?
  end
end