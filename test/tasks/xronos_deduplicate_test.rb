# frozen_string_literal: true

require 'test_helper'
require 'rake'

# End-to-end tests for the `xronos:deduplicate` rake task. These exercise
# the wiring between the rake entry point and the model's Mergeable
# callbacks; the per-model merge logic itself is covered in
# test/models/c14_test.rb and test/models/typo_test.rb.
class XronosDeduplicateTaskTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
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
    original_stdout = $stdout
    $stdout = File.new(File::NULL, 'w')
    @dedupe_task.invoke(model_name)
  ensure
    $stdout = original_stdout
  end

  def invoke_model_task(task_name)
    @dedupe_task.reenable
    Rake::Task[task_name].reenable
    original_stdout = $stdout
    $stdout = File.new(File::NULL, 'w')
    Rake::Task[task_name].invoke
  ensure
    $stdout = original_stdout
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

  # Run `block` with the chron auto-merge callbacks disabled, so the
  # caller can set up cross-sample duplicates without the auto-merge
  # pre-empting the rake task. Pass the chron class to disable (C14
  # or Typo).
  def without_chron_auto_merge(chron_class, &block)
    chron_class.skip_callback(:save, :after, :merge_exact_duplicates)
    chron_class.skip_callback(:save, :after, :merge_cross_sample_duplicates)
    Sample.skip_callback(:save, :after, :merge_exact_duplicates)
    begin
      block.call
    ensure
      chron_class.set_callback(:save, :after, :merge_cross_sample_duplicates)
      chron_class.set_callback(:save, :after, :merge_exact_duplicates)
      Sample.set_callback(:save, :after, :merge_exact_duplicates)
    end
  end

  # Create three C14s in three different samples, all cross-sample
  # matches. Returns the three C14s in creation order. Used by the
  # `C14.cross_sample_pairs` tests.
  def create_three_cross_sample_c14s
    context = create(:context)
    sample_a = create(:sample, nameless_sample_attrs(context: context))
    sample_b = create(:sample, nameless_sample_attrs(context: context))
    sample_c = create(:sample, nameless_sample_attrs(context: context))

    without_chron_auto_merge(C14) do
      [create(:c14, c14_attrs(sample: sample_a)),
       create(:c14, c14_attrs(sample: sample_b)),
       create(:c14, c14_attrs(sample: sample_c))]
    end
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

  test 'C14.cross_sample_pairs returns each candidate pair once with the younger chron on the left' do
    chron_a, chron_b, chron_c = create_three_cross_sample_c14s

    pairs = C14.cross_sample_pairs

    # Three chrons in three different samples, all cross-sample matches.
    # The pairs are ordered (younger, older) in (created_at, id) order
    # to match `Mergeable#merge_with_duplicate`'s canonicality rule.
    chrons = [chron_a, chron_b, chron_c]
    expected_pairs = chrons.combination(2).map do |a, b|
      if a.created_at < b.created_at || (a.created_at == b.created_at && a.id < b.id)
        [b.id, a.id]
      else
        [a.id, b.id]
      end
    end

    assert_equal expected_pairs.sort, pairs.sort
  end

  test 'C14.cross_sample_pairs returns [] when there are no cross-sample candidates' do
    # Two chrons in the same sample are strict duplicates, not
    # cross-sample candidates.
    sample = create(:sample)
    create(:c14, c14_attrs(sample: sample))
    create(:c14, c14_attrs(sample: sample).merge(bp: 3501))

    assert_equal [], C14.cross_sample_pairs
  end

  test 'C14.cross_sample_pairs excludes pairs whose samples are not name-relaxed duplicates' do
    # Two C14s in different samples with the same chron attrs, but
    # the samples are in different contexts — the sample-side filter
    # (encoding `Sample#name_relaxed_duplicate_of?`) should exclude them.
    context_a = create(:context)
    context_b = create(:context)
    sample_a = create(:sample, nameless_sample_attrs(context: context_a))
    sample_b = create(:sample, nameless_sample_attrs(context: context_b))

    without_chron_auto_merge(C14) do
      create(:c14, c14_attrs(sample: sample_a))
      create(:c14, c14_attrs(sample: sample_b))
    end

    assert_equal [], C14.cross_sample_pairs
  end

  test 'model-specific deduplicate tasks delegate to shared task' do
    model_tasks = {
      'xronos:taxons:deduplicate' => :taxon,
      'xronos:c14s:deduplicate' => :c14,
      'xronos:citations:deduplicate' => :citation,
      'xronos:contexts:deduplicate' => :context,
      'xronos:materials:deduplicate' => :material,
      'xronos:references:deduplicate' => :reference,
      'xronos:samples:deduplicate' => :sample,
      'xronos:sites:deduplicate' => :site,
      'xronos:typos:deduplicate' => :typo
    }

    with_versioning do
      model_tasks.each do |task_name, factory_name|
        create(factory_name)
        assert_nothing_raised { invoke_model_task(task_name) }
        Rake::Task[task_name].reenable
        @dedupe_task.reenable
      end
    end
  end
end
