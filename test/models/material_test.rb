# == Schema Information
#
# Table name: materials
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_materials_on_name  (name)
#
require "test_helper"

class MaterialTest < ActiveSupport::TestCase
  #
  # VALIDATIONS
  #
  test "is invalid without a name" do
    material = Material.new(name: nil)
    assert_not material.valid?
  end

  #
  # destroy_if_orphaned
  #
  test "destroy_if_orphaned destroys material with no samples" do
    material = FactoryBot.create(:material)

    assert_difference("Material.count", -1) do
      material.destroy_if_orphaned
    end
  end

  test "destroy_if_orphaned does not destroy if samples exist" do
    material = FactoryBot.create(:material)
    FactoryBot.create(:sample, material: material)

    assert_no_difference("Material.count") do
      material.destroy_if_orphaned
    end
  end

  #
  # Deduplication
  #

  test "auto-merges on create when an exact duplicate exists" do
    canonical = FactoryBot.create(:material, name: "Charcoal")

    # Bypass `validate :no_exact_duplicate, on: :create` to exercise
    # the after_save merge path in isolation.
    dupe = FactoryBot.build(:material, name: "Charcoal")
    dupe.save(validate: false)

    assert_predicate dupe, :destroyed?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test "auto-merges on update when an update creates a duplicate" do
    canonical = FactoryBot.create(:material, name: "Charcoal")
    other = FactoryBot.create(:material, name: "Bone")

    other.update!(name: "Charcoal")

    assert_predicate other, :destroyed?
    assert_equal canonical.id, other.merged_into_id
  end

  test "does not auto-merge when a unique material is created" do
    FactoryBot.create(:material, name: "Charcoal")
    other = FactoryBot.create(:material, name: "Bone")

    assert_not other.destroyed?
    assert_nil other.merged_into_id
  end

  test "reassigns samples to the canonical material on merge" do
    canonical = FactoryBot.create(:material, name: "Charcoal")
    dupe = FactoryBot.build(:material, name: "Charcoal")
    dupe.save(validate: false)
    sample = FactoryBot.create(:sample, material: dupe)

    dupe.merge_exact_duplicates

    assert_equal canonical.id, sample.reload.material_id
  end

  test "destroys the dupe (not supersede) since Material is not Supersedable" do
    canonical = FactoryBot.create(:material, name: "Charcoal")
    dupe = FactoryBot.build(:material, name: "Charcoal")
    dupe.save(validate: false)

    assert_predicate dupe, :destroyed?
    # The dupe is hard-destroyed (not soft-deleted via Supersession) because
    # Material is not a Supersedable model. The canonical remains.
    assert Material.exists?(canonical.id)
  end
end
