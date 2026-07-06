# == Schema Information
#
# Table name: samples
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  name                 :string
#  part_of_organism     :text
#  position_crs         :text
#  position_description :text
#  position_x           :decimal(, )
#  position_y           :decimal(, )
#  position_z           :decimal(, )
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  context_id           :integer
#  material_id          :integer
#  taxon_id             :integer
#
# Indexes
#
#  index_samples_on_context_id    (context_id)
#  index_samples_on_material_id   (material_id)
#  index_samples_on_position_crs  (position_crs)
#  index_samples_on_taxon_id      (taxon_id)
#
require 'test_helper'

class SampleTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  test 'destroying a sample destroys its c14s' do
    sample = create(:sample)
    create_list(:c14, 2, sample: sample)

    assert_dependent_destroy(sample, :c14s, count: 2)
  end

  test 'destroying a sample destroys its typos' do
    sample = create(:sample)
    create_list(:typo, 2, sample: sample)

    assert_dependent_destroy(sample, :typos, count: 2)
  end

  test 'part_of_organism is stored as a free-text string' do
    sample = create(:sample, part_of_organism: 'maize cob')

    assert_equal 'maize cob', sample.reload.part_of_organism
  end

  test 'part_of_organism is nullable' do
    sample = create(:sample, part_of_organism: nil)

    assert_nil sample.reload.part_of_organism
  end

  test 'part_of_organism accepts any string, including values not in any vocabulary' do
    sample = build(:sample, part_of_organism: 'some free-text value (not a known term)')

    assert sample.valid?
  end

  test 'part_of_organism resolves to a controlled term when the value matches' do
    vocab = create(:controlled_vocabulary, name: 'part_of_organism')
    term  = create(:controlled_vocabulary_term, vocabulary: vocab, name: 'Cranium',
                                                ontology_name: 'UBERON', ontology_id: 'UBERON:0000029')
    sample = create(:sample, part_of_organism: 'Cranium')

    assert_equal 'Cranium', sample.reload.part_of_organism
    assert sample.part_of_organism_controlled?
    assert_equal term, sample.part_of_organism_term
  end

  test 'name is not constrained to be unique' do
    context = create(:context)
    create(:sample, context: context, name: 'Bone 1')

    duplicate = build(:sample, context: context, name: 'Bone 1')

    assert duplicate.valid?
  end

  test 'name is optional; multiple samples in the same context may have a nil name' do
    context = create(:context)
    create(:sample, context: context, name: nil)

    assert build(:sample, context: context, name: nil).valid?
  end

  test 'whitespace-only name is normalised to nil on save' do
    sample = build(:sample, name: '   ')

    assert sample.valid?
    assert_nil sample.name
  end

  #
  # Deduplication
  #

  def blank_attrs(context: nil, name: 'Bone 1')
    { context: context, name: name, material: nil, taxon: nil,
      part_of_organism: nil, position_description: nil, position_crs: nil,
      position_x: nil, position_y: nil, position_z: nil }
  end

  test 'auto-merges on create when all key attrs match' do
    context = create(:context)
    canonical = create(:sample, blank_attrs(context: context))
    dupe = create(:sample, blank_attrs(context: context))

    assert_predicate dupe, :destroyed?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'auto-merges on update when an update creates a duplicate' do
    context = create(:context)
    canonical = create(:sample, blank_attrs(context: context))
    other = create(:sample, blank_attrs(context: context, name: 'Bone 2'))

    other.update!(name: 'Bone 1')

    assert_predicate other, :destroyed?
    assert_equal canonical.id, other.merged_into_id
  end

  test 'does not auto-merge when a unique sample is created' do
    context = create(:context)
    create(:sample, blank_attrs(context: context, name: 'Bone 1'))
    other = create(:sample, blank_attrs(context: context, name: 'Bone 2'))

    assert_not other.destroyed?
    assert_nil other.merged_into_id
  end

  test 'does not auto-merge when name differs' do
    context = create(:context)
    create(:sample, blank_attrs(context: context, name: 'Bone 1'))
    other = create(:sample, blank_attrs(context: context, name: 'Bone 2'))

    assert_not other.destroyed?
    assert_nil other.merged_into_id
  end

  test 'does not auto-merge when context differs' do
    create(:sample, blank_attrs(context: create(:context), name: 'Bone 1'))
    other = create(:sample, blank_attrs(context: create(:context), name: 'Bone 1'))

    assert_not other.destroyed?
    assert_nil other.merged_into_id
  end

  test 'does not auto-merge when material is set on one side and nil on the other' do
    context = create(:context)
    material = create(:material)
    create(:sample, blank_attrs(context: context).merge(material: material))
    other = create(:sample, blank_attrs(context: context).merge(material: nil))

    # material has :nil_matches_nil, so nil == nil matches but nil != material
    assert_not other.destroyed?
    assert_nil other.merged_into_id
  end

  test 'auto-merges when material is nil on both sides (nil_matches_nil)' do
    context = create(:context)
    canonical = create(:sample, blank_attrs(context: context))
    dupe = create(:sample, blank_attrs(context: context))

    assert_predicate dupe, :destroyed?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'does not auto-merge when position_x is set on one side and nil on the other' do
    context = create(:context)
    create(:sample, blank_attrs(context: context).merge(position_x: 1.5))
    other = create(:sample, blank_attrs(context: context).merge(position_x: nil))

    assert_not other.destroyed?
    assert_nil other.merged_into_id
  end

  test 'reassigns c14s to the canonical sample on merge' do
    context = create(:context)
    canonical = create(:sample, blank_attrs(context: context))

    # Skip the auto-merge so we can attach a c14 to the dupe first
    # (the c14 factory validates the associated sample, which is
    # frozen after the dupe is hard-destroyed).
    Sample.skip_callback(:save, :after, :merge_exact_duplicates)
    begin
      dupe = create(:sample, blank_attrs(context: context))
      c14 = create(:c14, sample: dupe)
    ensure
      Sample.set_callback(:save, :after, :merge_exact_duplicates)
    end

    dupe.merge_exact_duplicates

    assert_equal canonical.id, c14.reload.sample_id
  end

  test 'reassigns typos to the canonical sample on merge' do
    context = create(:context)
    canonical = create(:sample, blank_attrs(context: context))
    dupe = create(:sample, blank_attrs(context: context))
    typo = create(:typo, sample: dupe)

    dupe.merge_exact_duplicates

    assert_equal canonical.id, typo.reload.sample_id
  end

  test 'hard-destroys the dupe (Sample is not Supersedable)' do
    context = create(:context)
    canonical = create(:sample, blank_attrs(context: context))
    dupe = create(:sample, blank_attrs(context: context))

    dupe.merge_exact_duplicates

    assert_predicate dupe, :destroyed?
    assert Sample.exists?(canonical.id)
  end

  #
  # name_relaxed_duplicate_of? (used by Chron's cross-sample merge)
  #

  test '#name_relaxed_duplicate_of? returns true when both names are nil and other attrs match' do
    context = create(:context)
    a = create(:sample, name: nil, context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)
    b = create(:sample, name: nil, context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)

    assert a.name_relaxed_duplicate_of?(b)
    assert b.name_relaxed_duplicate_of?(a)
  end

  test '#name_relaxed_duplicate_of? returns true when names match' do
    context = create(:context)
    a = create(:sample, name: 'Bone 1', context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)
    b = create(:sample, name: 'Bone 1', context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)

    assert a.name_relaxed_duplicate_of?(b)
  end

  test '#name_relaxed_duplicate_of? returns false when names differ' do
    context = create(:context)
    a = create(:sample, name: 'Bone 1', context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)
    b = create(:sample, name: 'Bone 2', context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)

    assert_not a.name_relaxed_duplicate_of?(b)
  end

  test '#name_relaxed_duplicate_of? returns false when one name is nil and the other is not' do
    context = create(:context)
    a = create(:sample, name: 'Bone 1', context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)
    b = create(:sample, name: nil, context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)

    assert_not a.name_relaxed_duplicate_of?(b)
    assert_not b.name_relaxed_duplicate_of?(a)
  end

  test '#name_relaxed_duplicate_of? returns false when contexts differ' do
    a = create(:sample, name: nil, context: create(:context), material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)
    b = create(:sample, name: nil, context: create(:context), material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)

    assert_not a.name_relaxed_duplicate_of?(b)
  end

  test '#name_relaxed_duplicate_of? returns false when one of the other attrs differs' do
    context = create(:context)
    a = create(:sample, name: nil, context: context, material: nil, taxon: nil,
                        part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)
    b = create(:sample, name: nil, context: context, material: create(:material),
                        taxon: nil, part_of_organism: nil, position_description: nil,
                        position_crs: nil, position_x: nil, position_y: nil,
                        position_z: nil)

    assert_not a.name_relaxed_duplicate_of?(b)
  end

  test '#name_relaxed_duplicate_of? returns false when compared with a non-Sample' do
    a = create(:sample, name: nil, context: create(:context))

    assert_not a.name_relaxed_duplicate_of?(nil)
    assert_not a.name_relaxed_duplicate_of?(a.context)
  end

  test '#name_relaxed_duplicate_of? returns false when compared with self' do
    a = create(:sample, name: nil, context: create(:context))

    assert_not a.name_relaxed_duplicate_of?(a)
  end
end
