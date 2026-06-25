require 'test_helper'
require 'rake'

class Xronos::VocabulariesSeedTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  TASK_NAME = 'xronos:vocabularies:seed_part_of_organism'.freeze
  YAML_PATH = Rails.root.join('db/data/ontologies.yml').freeze

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?(TASK_NAME)
    Rake::Task[TASK_NAME].reenable
    @original_yaml = YAML_PATH.read
  end

  teardown do
    Rake::Task[TASK_NAME].reenable
    File.write(YAML_PATH, @original_yaml)
    ENV.delete('DRY_RUN')
    ControlledVocabulary::Variant.delete_all
    ControlledVocabulary::Term.delete_all
    ControlledVocabulary.delete_all
  end

  test 'rake task is registered' do
    assert Rake::Task.task_defined?(TASK_NAME)
  end

  test 'rake task in DRY_RUN mode does not write to the database' do
    ENV['DRY_RUN'] = 'true'
    vocab_count_before = ControlledVocabulary.count

    capture_stdout { invoke_task }

    assert_equal vocab_count_before, ControlledVocabulary.count
  end

  test 'rake task with DRY_RUN=false seeds the part_of_organism vocabulary' do
    ENV['DRY_RUN'] = 'false'

    capture_stdout { invoke_task }

    assert ControlledVocabulary.find_by(name: 'part_of_organism').present?
    assert ControlledVocabulary::Term.where(ontology_name: 'UBERON').any?
    assert ControlledVocabulary::Term.where(ontology_name: 'PO').any?
    assert ControlledVocabulary::Variant.count.positive?
    # Regression: description is populated from the parsed def
    assert ControlledVocabulary::Term.where.not(description: nil).count.positive?
  end

  test 'rake task is idempotent on a second run with the same source' do
    ENV['DRY_RUN'] = 'false'

    capture_stdout { invoke_task }
    after_first = ControlledVocabulary::Term.count
    assert after_first.positive?, 'first run should have inserted terms'

    capture_stdout do
      Rake::Task[TASK_NAME].reenable
      invoke_task
    end

    assert_equal after_first, ControlledVocabulary::Term.count
  end

  test 'rake task raises if the source file is missing' do
    File.write(YAML_PATH, { 'part_of_organism' => { 'uberon' => { 'path' => 'nope.obo' } } }.to_yaml)

    assert_raises(StandardError) do
      capture_stdout { invoke_task }
    end
  end

  test 'rake task raises if the SHA-256 mismatches' do
    bad_config = YAML.load(@original_yaml)
    bad_config['part_of_organism']['uberon']['sha256'] = 'deadbeef' * 8
    File.write(YAML_PATH, bad_config.to_yaml)

    assert_raises(StandardError) do
      capture_stdout { invoke_task }
    end
  end

  private

  def invoke_task
    Rake::Task[TASK_NAME].reenable
    Rake::Task[TASK_NAME].invoke
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end
end
