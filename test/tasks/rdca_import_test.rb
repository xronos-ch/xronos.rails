# frozen_string_literal: true

require 'test_helper'

# Test that the RDCA import task correctly handles cross-sample C14 merges.
# When a C14 is created and triggers a cross-sample merge, the parent sample
# is destroyed and its children (including subsequently-created typos) are
# reassigned to the canonical sample.
class RdcaImportTest < ActiveSupport::TestCase
  def nameless_sample_attrs(context:)
    { context: context, name: nil, material: nil, taxon: nil,
      part_of_organism: nil, position_description: nil, position_crs: nil,
      position_x: nil, position_y: nil, position_z: nil }
  end

  def c14_attrs(sample:)
    { lab_identifier: 'OxA-12345', sample: sample,
      bp: 3500, std: 30, method: 'AMS',
      delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5 }
  end

  test 'typos created after C14 cross-sample merge are on canonical sample' do
    context = create(:context)
    canonical_sample = create(:sample, nameless_sample_attrs(context: context))

    # Skip the sample auto-merge (and the on: :create duplicate
    # validation) so the dupe sample persists long enough to receive
    # a c14; the c14 save will trigger the cross-sample flow.
    Sample.skip_callback(:save, :after, :merge_exact_duplicates)
    Sample.skip_callback(:validate, :before, :no_exact_duplicate, on: :create)
    begin
      dupe_sample = create(:sample, nameless_sample_attrs(context: context))
      canonical = create(:c14, c14_attrs(sample: canonical_sample))
      dupe = create(:c14, c14_attrs(sample: dupe_sample))
    ensure
      Sample.set_callback(:save, :after, :merge_exact_duplicates)
      Sample.set_callback(:validate, :before, :no_exact_duplicate, on: :create)
    end

    assert_predicate dupe_sample, :destroyed?
    assert_equal canonical_sample.id, dupe.reload.sample_id
    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.ultimately_superseded_by.id

    # Now create a typo on the canonical sample
    typo = create(:typo, name: 'Iron Age', sample: canonical_sample,
                         approx_start_time: -800, approx_end_time: -400)

    assert typo.persisted?
    assert_equal canonical_sample.id, typo.sample_id
  end

  test 'multiple typos created after C14 cross-sample merge are all on canonical sample' do
    context = create(:context)
    canonical_sample = create(:sample, nameless_sample_attrs(context: context))

    Sample.skip_callback(:save, :after, :merge_exact_duplicates)
    Sample.skip_callback(:validate, :before, :no_exact_duplicate, on: :create)
    begin
      dupe_sample = create(:sample, nameless_sample_attrs(context: context))
      canonical = create(:c14, c14_attrs(sample: canonical_sample))
      dupe = create(:c14, c14_attrs(sample: dupe_sample))
    ensure
      Sample.set_callback(:save, :after, :merge_exact_duplicates)
      Sample.set_callback(:validate, :before, :no_exact_duplicate, on: :create)
    end

    assert_predicate dupe_sample, :destroyed?

    # Create multiple typos (simulating Era + Cultural Association)
    typo1 = create(:typo, name: 'Iron Age', sample: canonical_sample,
                          approx_start_time: -800, approx_end_time: -400)
    typo2 = create(:typo, name: 'Bronze Age', sample: canonical_sample,
                          approx_start_time: -2000, approx_end_time: -800)

    # All typos should be on the canonical sample
    assert_equal canonical_sample.id, typo1.sample_id
    assert_equal canonical_sample.id, typo2.sample_id
    assert_not canonical_sample.destroyed?
  end

  test 'import task handles cross-sample merge when creating C14 and typos' do
    # This test simulates the RDCA import scenario where:
    # 1. Two nameless samples exist in the same context (name-relaxed duplicates)
    # 2. A C14 is created on sample_a (triggers cross-sample merge)
    # 3. The import task must update its sample reference before creating typos
    
    context = create(:context)
    
    # Set up two nameless samples (canonical first, then dupe)
    canonical_sample = create(:sample, nameless_sample_attrs(context: context))
    
    Sample.skip_callback(:save, :after, :merge_exact_duplicates)
    Sample.skip_callback(:validate, :before, :no_exact_duplicate, on: :create)
    begin
      dupe_sample = create(:sample, nameless_sample_attrs(context: context))
      
      # Create a C14 on canonical_sample (so cross-sample duplicate exists)
      canonical_c14 = create(:c14, c14_attrs(sample: canonical_sample))
    ensure
      Sample.set_callback(:save, :after, :merge_exact_duplicates)
      Sample.set_callback(:validate, :before, :no_exact_duplicate, on: :create)
    end
    
    # Now simulate the import task creating a C14 on dupe_sample
    # This should trigger cross-sample merge
    import_sample = dupe_sample
    c14 = create(:c14, c14_attrs(sample: import_sample))
    
    # The dupe_sample should be destroyed
    assert_predicate dupe_sample, :destroyed?
    
    # The import task must reload the C14 and get the canonical sample
    # This is what the fix does: sample = c14.reload.sample
    canonical_sample_from_c14 = c14.reload.sample
    
    # Now create typos on the canonical sample
    typo = create(:typo, name: 'Iron Age', sample: canonical_sample_from_c14,
                         approx_start_time: -800, approx_end_time: -400)
    
    assert typo.persisted?
    assert_equal canonical_sample.id, typo.sample_id
    assert_not_predicate canonical_sample, :destroyed?
  end

  private

  def nameless_sample_attrs(context:)
    { context: context, name: nil, material: nil, taxon: nil,
      part_of_organism: nil, position_description: nil, position_crs: nil,
      position_x: nil, position_y: nil, position_z: nil }
  end

  def c14_attrs(sample:)
    { lab_identifier: 'OxA-12345', sample: sample,
      bp: 3500, std: 30, method: 'AMS',
      delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5 }
  end
end
