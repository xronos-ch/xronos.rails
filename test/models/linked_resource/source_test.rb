# frozen_string_literal: true

require 'test_helper'

class LinkedResource::SourceTest < ActiveSupport::TestCase
  setup do
    @test_source = LinkedResource::Source.register :source_test,
      name: "Source Test",
      url_template: "https://test.example/%{id}",
      id_pattern: /\A\d+\z/,
      icon: "test",
      description: "Test source"
  end

  teardown do
    LinkedResource::Source.registry.delete(:source_test)
  end

  # --- Registry ---

  test 'register returns a LinkedResource::Source' do
    assert_instance_of LinkedResource::Source, @test_source
  end

  test 'register stores the source under its key' do
    assert_equal @test_source, LinkedResource::Source.registry[:source_test]
  end

  test 'find returns a source by symbol key' do
    assert_equal @test_source, LinkedResource::Source.find(:source_test)
  end

  test 'find returns a source by name string' do
    assert_equal @test_source, LinkedResource::Source.find('Source Test')
  end

  test 'find returns nil for an unknown source' do
    assert_nil LinkedResource::Source.find(:nonexistent)
  end

  test 'known? returns true for a registered source' do
    assert LinkedResource::Source.known?('Source Test')
  end

  test 'known? returns false for an unregistered source' do
    refute LinkedResource::Source.known?('Nonexistent')
  end

  test 'all includes registered sources' do
    assert_includes LinkedResource::Source.all, @test_source
  end

  test 'reset! clears the registry' do
    original = LinkedResource::Source.registry.dup
    begin
      LinkedResource::Source.reset!
      refute LinkedResource::Source.known?('Source Test')
    ensure
      LinkedResource::Source.instance_variable_set(:@registry, original)
    end
  end

  # --- PORO methods ---

  test 'url_for interpolates the id into the template' do
    assert_equal 'https://test.example/42', @test_source.url_for(42)
  end

  test 'valid_id? accepts ids matching the pattern' do
    assert @test_source.valid_id?('42')
  end

  test 'valid_id? rejects ids not matching the pattern' do
    refute @test_source.valid_id?('abc')
  end

  test 'valid_id? returns true when no pattern is set' do
    source = LinkedResource::Source.new(key: :nopat, name: 'Nopat',
      url_template: 'https://nopat.example/%{id}')
    assert source.valid_id?('anything goes')
  end

  # --- Known sources ---

  test 'the Wikidata source module registers itself on load' do
    assert LinkedResource::Source.known?('Wikidata')
  end

  test 'known-source Wikidata has expected attributes' do
    wikidata = LinkedResource::Source.find('Wikidata')
    assert_equal 'https://www.wikidata.org/wiki/Q123', wikidata.url_for('Q123')
    assert wikidata.valid_id?('Q123')
    refute wikidata.valid_id?('123')
    refute wikidata.valid_id?('abc')
  end
end
