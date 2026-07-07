# frozen_string_literal: true

require 'test_helper'
require 'rake'

# End-to-end tests for the `xronos:deduplicate` rake task. These exercise
# the wiring between the rake entry point and the model's Mergeable
# callbacks; the per-model merge logic itself is covered in
# test/models/c14_test.rb and test/models/typo_test.rb.
class XronosDeduplicateTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('xronos:deduplicate')
    @dedupe_task = Rake::Task['xronos:deduplicate']
    @user        = create(:user, :admin)
    ENV['ADMIN_USER_ID'] = @user.id.to_s
    ENV['DRY_RUN']       = 'false'
  end

  teardown do
    ENV.delete('ADMIN_USER_ID')
    ENV.delete('DRY_RUN')
  end

  def invoke_dedupe(model_name)
    @dedupe_task.reenable
    @dedupe_task.invoke(model_name)
  end

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

  def typo_attrs(sample:)
    { name: 'Roman Iron Age', sample: sample,
      approx_start_time: -550, approx_end_time: -350 }
  end

  test 'C14: cross-sample pass runs even when strict duplicate scope is empty' do
    context = create(:context)
    canonical_sample = create(:sample, nameless_sample_attrs(context: context))

    # Skip auto-merge callbacks so the cross-sample duplicates can be set
    # up without the auto-merge pre-empting the rake task.
    Sample.skip_callback(:save, :after, :merge_exact_duplicates)
    C14.skip_callback(:save, :after, :merge_exact_duplicates)
    C14.skip_callback(:save, :after, :merge_cross_sample_duplicates)
    begin
      dupe_sample = create(:sample, nameless_sample_attrs(context: context))
      canonical   = create(:c14, c14_attrs(sample: canonical_sample))
      dupe        = create(:c14, c14_attrs(sample: dupe_sample))
    ensure
      C14.set_callback(:save, :after, :merge_cross_sample_duplicates)
      C14.set_callback(:save, :after, :merge_exact_duplicates)
      Sample.set_callback(:save, :after, :merge_exact_duplicates)
    end

    # Sanity: the strict scope is empty (the two C14s are in different
    # samples, so they are not strict duplicates) and nothing has been
    # merged yet via auto-merge.
    assert C14.duplicate_group_scope.empty?
    assert_not dupe.superseded?

    with_versioning do
      invoke_dedupe('C14')
    end

    dupe.reload
    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.ultimately_superseded_by.id
    # The cross-sample fallback destroyed the dupe sample.
    assert_nil Sample.find_by(id: dupe_sample.id)
  end

  test 'Typo: cross-sample pass runs even when strict duplicate scope is empty' do
    context = create(:context)
    canonical_sample = create(:sample, nameless_sample_attrs(context: context))

    Sample.skip_callback(:save, :after, :merge_exact_duplicates)
    Typo.skip_callback(:save, :after, :merge_exact_duplicates)
    Typo.skip_callback(:save, :after, :merge_cross_sample_duplicates)
    begin
      dupe_sample = create(:sample, nameless_sample_attrs(context: context))
      canonical   = create(:typo, typo_attrs(sample: canonical_sample))
      dupe        = create(:typo, typo_attrs(sample: dupe_sample))
    ensure
      Typo.set_callback(:save, :after, :merge_cross_sample_duplicates)
      Typo.set_callback(:save, :after, :merge_exact_duplicates)
      Sample.set_callback(:save, :after, :merge_exact_duplicates)
    end

    assert Typo.duplicate_group_scope.empty?
    assert_not dupe.superseded?

    with_versioning do
      invoke_dedupe('Typo')
    end

    dupe.reload
    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.ultimately_superseded_by.id
    assert_nil Sample.find_by(id: dupe_sample.id)
  end
end
