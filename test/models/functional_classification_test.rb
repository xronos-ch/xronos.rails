# == Schema Information
#
# Table name: functional_classifications
# Database name: primary
#
#  id                                    :bigint           not null, primary key
#  assignable_type                       :string           not null
#  confidence                            :integer          default("possible"), not null
#  note                                  :text
#  source                                :string
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  assignable_id                         :bigint           not null
#  functional_classification_category_id :bigint           not null
#
# Indexes
#
#  idx_functional_classifications_unique_category           (assignable_type,assignable_id,functional_classification_category_id) UNIQUE
#  idx_on_functional_classification_category_id_0cc23f287f  (functional_classification_category_id)
#  index_functional_classifications_on_assignable           (assignable_type,assignable_id)
#
# Foreign Keys
#
#  fk_rails_...  (functional_classification_category_id => functional_classification_categories.id)
#
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
