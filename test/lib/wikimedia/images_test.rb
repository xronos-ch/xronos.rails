# frozen_string_literal: true

require 'test_helper'

class Wikimedia::ImagesTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  setup do
    Rails.cache.clear
  end

  test '.for returns an array of image hashes for an item with P18 claims' do
    img = ImageDouble.new(
      basename:  'Gobekli_Tepe_pillars',
      extension: 'jpg',
      thumb_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/Gobekli_Tepe_pillars.jpg/480px-Gobekli_Tepe_pillars.jpg',
      page_url:  'https://commons.wikimedia.org/wiki/File:Gobekli_Tepe_pillars.jpg'
    )
    item = ItemDouble.new('P18' => [img])

    Wikidata::Item.stub :find, item do
      result = Wikimedia::Images.for('Q123')
      assert_equal 1, result.length
      assert_equal 'Gobekli_Tepe_pillars', result.first[:basename]
      assert_equal 'jpg', result.first[:extension]
      assert_equal 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/Gobekli_Tepe_pillars.jpg/480px-Gobekli_Tepe_pillars.jpg',
        result.first[:thumb_url]
      assert_equal 'https://commons.wikimedia.org/wiki/File:Gobekli_Tepe_pillars.jpg', result.first[:page_url]
    end
  end

  test '.for returns up to MAX_IMAGES images' do
    images = Array.new(8) do |i|
      ImageDouble.new(
        basename:  "image_#{i}",
        extension: 'jpg',
        thumb_url: "https://example.org/#{i}",
        page_url:  "https://example.org/page/#{i}"
      )
    end
    item = ItemDouble.new('P18' => images)

    Wikidata::Item.stub :find, item do
      result = Wikimedia::Images.for('Q123')
      assert_equal 5, result.length
      assert_equal 'image_0', result.first[:basename]
      assert_equal 'image_4', result.last[:basename]
    end
  end

  test '.for returns [] when the item has no P18 claims' do
    item = ItemDouble.new({})

    Wikidata::Item.stub :find, item do
      assert_equal [], Wikimedia::Images.for('Q123')
    end
  end

  test '.for returns [] when the item does not exist' do
    Wikidata::Item.stub :find, nil do
      assert_equal [], Wikimedia::Images.for('Q99999999')
    end
  end

  test '.for returns [] for a blank QID' do
    assert_equal [], Wikimedia::Images.for('')
    assert_equal [], Wikimedia::Images.for(nil)
  end

  test '.for returns [] when Wikidata::Item.find raises' do
    Wikidata::Item.stub :find, ->(_) { raise 'boom' } do
      assert_equal [], Wikimedia::Images.for('Q123')
    end
  end

  test '.for caches responses' do
    img = ImageDouble.new(basename: 'x', extension: 'jpg',
      thumb_url: 'https://example.org/x', page_url: 'https://example.org/page/x')
    item = ItemDouble.new('P18' => [img])
    call_count = 0

    counter = lambda { |_qid|
      call_count += 1
      item
    }

    Wikidata::Item.stub :find, counter do
      Wikimedia::Images.for('Q123')
      Wikimedia::Images.for('Q123')
    end

    assert_equal 1, call_count
  end

  class ItemDouble
    def initialize(claims)
      @claims = claims
    end

    def properties(code)
      @claims[code] || []
    end
  end

  class ImageDouble
    attr_reader :basename, :extension, :thumb_url, :page_url

    def initialize(basename:, extension:, thumb_url:, page_url:)
      @basename = basename
      @extension = extension
      @thumb_url = thumb_url
      @page_url = page_url
    end

    def url(_size)
      @thumb_url
    end
  end
end
