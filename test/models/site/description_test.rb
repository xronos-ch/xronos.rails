# frozen_string_literal: true

require 'test_helper'

class Site::DescriptionTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren,Metrics/ClassLength
  setup do
    Rails.cache.clear
    @site = FactoryBot.create(:site)
    @linked_resource = FactoryBot.create(:linked_resource,
                                         linkable: @site,
                                         source: 'Wikidata',
                                         external_id: 'Q123',
                                         status: 'approved')
    @sitelinks = { lang_title: 'Site', commons_title: 'Category:Site' }
    @extract = { title: 'Site', text: 'Lead.', url: 'https://en.wikipedia.org/wiki/Site' }
    @images = [
      { basename: 'Site_a', extension: 'jpg',
        thumb_url: 'https://example.org/a', page_url: 'https://example.org/page/a' },
      { basename: 'Site_b', extension: 'jpg',
        thumb_url: 'https://example.org/b', page_url: 'https://example.org/page/b' }
    ]
  end

  test 'cache_key includes the linked_resource id, updated_at and lang' do
    description = Site::Description.new(linked_resource: @linked_resource)
    assert_equal "site_description/#{@linked_resource.id}/#{@linked_resource.updated_at.to_i}/en",
      description.cache_key
  end

  test 'cache_key changes when the linked_resource is updated' do
    description = Site::Description.new(linked_resource: @linked_resource)
    key1 = description.cache_key

    travel_to 1.minute.from_now do
      @linked_resource.touch
      key2 = description.cache_key
      refute_equal key1, key2
    end
  end

  test 'cache_key reflects the chosen language' do
    en = Site::Description.new(linked_resource: @linked_resource, lang: 'en')
    de = Site::Description.new(linked_resource: @linked_resource, lang: 'de')
    refute_equal en.cache_key, de.cache_key
  end

  test 'cached? is false on a fresh model' do
    description = Site::Description.new(linked_resource: @linked_resource)
    refute description.cached?
  end

  test 'cached? is true after data has been read' do
    with_stubs do
      description = Site::Description.new(linked_resource: @linked_resource)
      description.data
      assert description.cached?
    end
  end

  test 'data includes the Wikipedia title, extract text and URL when a lang sitelink is present' do
    with_stubs do
      description = Site::Description.new(linked_resource: @linked_resource)
      assert_equal 'Site', description.data[:wikipedia_title]
      assert_equal 'Lead.', description.data[:wikipedia_extract_text]
      assert_equal 'https://en.wikipedia.org/wiki/Site', description.data[:wikipedia_url]
    end
  end

  test 'data has nil fields when the lang sitelink is absent' do
    Wikimedia::Sitelinks.stub(:for, { lang_title: nil }) do
      Wikimedia::Images.stub(:for, []) do
        description = Site::Description.new(linked_resource: @linked_resource)
        assert_nil description.data[:wikipedia_title]
        assert_nil description.data[:wikipedia_extract_text]
        assert_nil description.data[:wikipedia_url]
      end
    end
  end

  test 'data includes the images from Wikimedia::Images' do
    with_stubs do
      description = Site::Description.new(linked_resource: @linked_resource)
      assert_equal @images, description.data[:images]
    end
  end

  test 'data has an empty images array when Wikimedia::Images returns nothing' do
    Wikimedia::Sitelinks.stub(:for, @sitelinks) do
      Wikipedia::Article.stub(:summary, @extract) do
        Wikimedia::Images.stub(:for, []) do
          description = Site::Description.new(linked_resource: @linked_resource)
          assert_equal [], description.data[:images]
        end
      end
    end
  end

  test 'data includes a Commons category URL when a commonswiki sitelink is present' do
    with_stubs do
      description = Site::Description.new(linked_resource: @linked_resource)
      assert_equal 'https://commons.wikimedia.org/wiki/Category:Site',
        description.data[:commons_category_url]
    end
  end

  test 'data has a nil Commons category URL when no commonswiki sitelink is present' do
    Wikimedia::Sitelinks.stub(:for, { lang_title: 'Site', commons_title: nil }) do
      Wikipedia::Article.stub(:summary, @extract) do
        Wikimedia::Images.stub(:for, @images) do
          description = Site::Description.new(linked_resource: @linked_resource)
          assert_nil description.data[:commons_category_url]
        end
      end
    end
  end

  test 'data includes a human-readable Commons category title without the prefix' do
    Wikimedia::Sitelinks.stub(:for, { lang_title: 'Site', commons_title: 'Category:Göbekli Tepe' }) do
      Wikipedia::Article.stub(:summary, @extract) do
        Wikimedia::Images.stub(:for, @images) do
          description = Site::Description.new(linked_resource: @linked_resource)
          assert_equal 'Göbekli Tepe', description.data[:commons_category_title]
        end
      end
    end
  end

  test 'data has a nil Commons category title when no commonswiki sitelink is present' do
    Wikimedia::Sitelinks.stub(:for, { lang_title: 'Site', commons_title: nil }) do
      Wikipedia::Article.stub(:summary, @extract) do
        Wikimedia::Images.stub(:for, @images) do
          description = Site::Description.new(linked_resource: @linked_resource)
          assert_nil description.data[:commons_category_title]
        end
      end
    end
  end

  test 'data caches the combined result' do
    with_stubs do
      description = Site::Description.new(linked_resource: @linked_resource)
      first = description.data
      second = description.data
      assert_equal first, second
    end
  end

  test 'failed? is true when there is no Wikipedia text and no images' do
    Wikimedia::Sitelinks.stub(:for, { lang_title: nil }) do
      Wikipedia::Article.stub(:summary, nil) do
        Wikimedia::Images.stub(:for, []) do
          description = Site::Description.new(linked_resource: @linked_resource)
          assert description.failed?
        end
      end
    end
  end

  test 'failed? is false when only images are present' do
    Wikimedia::Sitelinks.stub(:for, { lang_title: nil, commons_title: 'Category:Site' }) do
      Wikipedia::Article.stub(:summary, nil) do
        Wikimedia::Images.stub(:for, @images) do
          description = Site::Description.new(linked_resource: @linked_resource)
          refute description.failed?
        end
      end
    end
  end

  test 'failed? is false when a Wikipedia text is present' do
    with_stubs do
      description = Site::Description.new(linked_resource: @linked_resource)
      refute description.failed?
    end
  end

  test 'lang changes the Wikipedia URL' do
    Wikimedia::Sitelinks.stub(:for, { lang_title: 'Site' }) do
      Wikipedia::Article.stub(:summary, { title: 'Site', text: 'Lead.', url: 'https://de.wikipedia.org/wiki/Site' }) do
        Wikimedia::Images.stub(:for, []) do
          description = Site::Description.new(linked_resource: @linked_resource, lang: 'de')
          assert_equal 'https://de.wikipedia.org/wiki/Site', description.data[:wikipedia_url]
        end
      end
    end
  end

  test 'fetched_at returns a Time recorded when the data was cached' do
    description = Site::Description.new(linked_resource: @linked_resource)
    before = Time.current

    with_stubs { description.data }

    after = Time.current

    assert_kind_of Time, description.fetched_at
    assert_operator description.fetched_at, :>=, before
    assert_operator description.fetched_at, :<=, after
  end

  test 'fetched_at is the same on subsequent reads within the cache window' do
    description = Site::Description.new(linked_resource: @linked_resource)

    with_stubs do
      description.data
      first = description.fetched_at

      travel_to 1.hour.from_now do
        assert_equal first, description.fetched_at
      end
    end
  end

  private

  def with_stubs
    Wikimedia::Sitelinks.stub(:for, @sitelinks) do
      Wikipedia::Article.stub(:summary, @extract) do
        Wikimedia::Images.stub(:for, @images) do
          yield
        end
      end
    end
  end
end
