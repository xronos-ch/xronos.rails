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

  #
  # FunctionalClassification.reassign_all_to!
  #

  test 'reassign_all_to! moves classifications from one Site to another' do
    category   = create(:functional_classification_category)
    canonical  = create(:site)
    dupe       = create(:site)
    create(:functional_classification, assignable: dupe, functional_classification_category: category)

    result = FunctionalClassification.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 1, result[:reassigned]
    assert_equal 0, result[:destroyed_collisions]
    assert_equal 0, FunctionalClassification.where(assignable_type: 'Site', assignable_id: dupe.id).count
    assert_equal 1, FunctionalClassification.where(assignable_type: 'Site', assignable_id: canonical.id).count
  end

  test 'reassign_all_to! moves classifications from one Context to another' do
    category   = create(:functional_classification_category)
    canonical  = create(:context)
    dupe       = create(:context, site: canonical.site, name: 'Trench B')
    create(:functional_classification, assignable: dupe, functional_classification_category: category)

    result = FunctionalClassification.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 1, result[:reassigned]
    assert_equal 0, result[:destroyed_collisions]
    assert_equal 1, FunctionalClassification.where(assignable_type: 'Context', assignable_id: canonical.id).count
  end

  test 'reassign_all_to! destroys colliding categories' do
    category   = create(:functional_classification_category)
    canonical  = create(:site)
    dupe       = create(:site)
    create(:functional_classification, assignable: canonical, functional_classification_category: category)
    create(:functional_classification, assignable: dupe,      functional_classification_category: category)

    assert_difference 'FunctionalClassification.count', -1 do
      result = FunctionalClassification.reassign_all_to!(from: dupe, to: canonical)
      assert_equal 0, result[:reassigned]
      assert_equal 1, result[:destroyed_collisions]
    end
  end

  test 'reassign_all_to! mixes reassignment and destruction' do
    cat_a     = create(:functional_classification_category, name: 'settlement')
    cat_b     = create(:functional_classification_category, name: 'burial')
    canonical = create(:site)
    dupe      = create(:site)
    # cat_a is on the canonical -- dupe's cat_a is destroyed
    create(:functional_classification, assignable: canonical, functional_classification_category: cat_a)
    create(:functional_classification, assignable: dupe,      functional_classification_category: cat_a)
    # cat_b is unique to the dupe -- will be reassigned
    create(:functional_classification, assignable: dupe,      functional_classification_category: cat_b)

    result = FunctionalClassification.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 1, result[:reassigned]
    assert_equal 1, result[:destroyed_collisions]
    assert_equal 2, FunctionalClassification.where(assignable_type: 'Site', assignable_id: canonical.id).count
  end

  test 'reassign_all_to! is a no-op when there are no classifications' do
    canonical = create(:site)
    dupe      = create(:site)

    assert_no_difference 'FunctionalClassification.count' do
      result = FunctionalClassification.reassign_all_to!(from: dupe, to: canonical)
      assert_equal 0, result[:reassigned]
      assert_equal 0, result[:destroyed_collisions]
    end
  end

  test 'reassign_all_to! raises when from and to are different classes' do
    site    = create(:site)
    context = create(:context)

    assert_raises(ArgumentError) { FunctionalClassification.reassign_all_to!(from: site, to: context) }
  end

  test 'reassign_all_to! raises when to is not persisted' do
    site     = create(:site)
    new_site = Site.new

    assert_raises(ArgumentError) { FunctionalClassification.reassign_all_to!(from: site, to: new_site) }
  end

  test 'reassign_all_to! raises when from and to are the same record' do
    site = create(:site)

    assert_raises(ArgumentError) { FunctionalClassification.reassign_all_to!(from: site, to: site) }
  end
end
