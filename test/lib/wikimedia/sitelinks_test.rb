# frozen_string_literal: true

require 'test_helper'
require 'ostruct'

class Wikimedia::SitelinksTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  setup do
    Rails.cache.clear
  end

  test '.for returns a hash with the language Wikipedia and Commons titles' do
    item = OpenStruct.new(
      sitelinks: {
        'enwiki' => { 'title' => 'Göbekli Tepe' },
        'commonswiki' => { 'title' => 'Category:Göbekli Tepe' }
      }
    )

    Wikidata::Item.stub :find, item do
      result = Wikimedia::Sitelinks.for('Q123')
      assert_equal 'Göbekli Tepe', result[:lang_title]
      assert_equal 'Category:Göbekli Tepe', result[:commons_title]
    end
  end

  test '.for handles a Wikidata item with no Commons sitelink' do
    item = OpenStruct.new(
      sitelinks: { 'enwiki' => { 'title' => 'Site' } }
    )

    Wikidata::Item.stub :find, item do
      result = Wikimedia::Sitelinks.for('Q123')
      assert_equal 'Site', result[:lang_title]
      assert_nil result[:commons_title]
    end
  end

  test '.for handles a Wikidata item with no sitelinks at all' do
    item = OpenStruct.new(sitelinks: {})

    Wikidata::Item.stub :find, item do
      result = Wikimedia::Sitelinks.for('Q123')
      assert_nil result[:lang_title]
      assert_nil result[:commons_title]
    end
  end

  test '.for returns nil for a blank QID' do
    assert_nil Wikimedia::Sitelinks.for('')
    assert_nil Wikimedia::Sitelinks.for(nil)
  end

  test '.for returns nil when Wikidata::Item.find raises' do
    Wikidata::Item.stub :find, ->(_) { raise 'boom' } do
      assert_nil Wikimedia::Sitelinks.for('Q123')
    end
  end

  test '.for caches responses' do
    item = OpenStruct.new(sitelinks: { 'enwiki' => { 'title' => 'Site' } })
    call_count = 0

    counter = lambda { |_qid|
      call_count += 1
      item
    }

    Wikidata::Item.stub :find, counter do
      Wikimedia::Sitelinks.for('Q123')
      Wikimedia::Sitelinks.for('Q123')
    end

    assert_equal 1, call_count
  end

  test '.for returns nil when the Wikidata item does not exist' do
    Wikidata::Item.stub :find, nil do
      assert_nil Wikimedia::Sitelinks.for('Q99999999')
    end
  end

  test '.for does not raise NoMethodError when the Wikidata item does not exist' do
    Wikidata::Item.stub :find, nil do
      assert_nothing_raised do
        Wikimedia::Sitelinks.for('Q99999999')
      end
    end
  end
end
