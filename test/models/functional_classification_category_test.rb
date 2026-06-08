# == Schema Information
#
# Table name: functional_classification_categories
# Database name: primary
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class FunctionalClassificationCategoryTest < ActiveSupport::TestCase
  test "factory creates a valid category" do
    category = create(:functional_classification_category)

    assert category.valid?
  end

  test "requires a name" do
    category = build(:functional_classification_category, name: nil)

    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "requires a unique name" do
    create(:functional_classification_category, name: "Settlement")
    duplicate = build(:functional_classification_category, name: "Settlement")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end
