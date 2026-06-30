# frozen_string_literal: true

require 'test_helper'

class Site::DescriptionTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren,Metrics/ClassLength
  setup do
    Rails.cache.clear
    @site = FactoryBot.create(:site)
    @lod_link = FactoryBot.create(:lod_link,
                                  linkable: @site,
                                  source: 'Wikidata',
                                  external_id: 123,
                                  status: 'approved')
  end

  test 'cache_key includes the lod_link id, updated_at and lang' do
    description = Site::Description.new(lod_link: @lod_link)
    assert_equal "site_description/#{@lod_link.id}/#{@lod_link.updated_at.to_i}/en",
      description.cache_key
  end

  test 'cache_key changes when the lod_link is updated' do
    description = Site::Description.new(lod_link: @lod_link)
    key1 = description.cache_key

    travel_to 1.minute.from_now do
      @lod_link.touch
      key2 = description.cache_key
      refute_equal key1, key2
    end
  end

  test 'cache_key reflects the chosen language' do
    en = Site::Description.new(lod_link: @lod_link, lang: 'en')
    de = Site::Description.new(lod_link: @lod_link, lang: 'de')
    refute_equal en.cache_key, de.cache_key
  end

  test 'cached? is false on a fresh model' do
    description = Site::Description.new(lod_link: @lod_link)
    refute description.cached?
  end

  test 'cached? is true after data has been read' do
    sitelinks = { lang_title: 'Site' }
    extract = { title: 'Site', text: 'Lead.', url: 'https://en.wikipedia.org/wiki/Site' }
    Wikimedia::Sitelinks.stub(:for, sitelinks) do
      Wikipedia::Article.stub(:summary, extract) do
        description = Site::Description.new(lod_link: @lod_link)
        description.data
        assert description.cached?
      end
    end
  end

  test 'data includes the Wikipedia title, extract text and URL when a lang sitelink is present' do
    sitelinks = { lang_title: 'Site' }
    extract = { title: 'Site', text: 'Lead.', url: 'https://en.wikipedia.org/wiki/Site' }
    Wikimedia::Sitelinks.stub(:for, sitelinks) do
      Wikipedia::Article.stub(:summary, extract) do
        description = Site::Description.new(lod_link: @lod_link)
        assert_equal 'Site', description.data[:wikipedia_title]
        assert_equal 'Lead.', description.data[:wikipedia_extract_text]
        assert_equal 'https://en.wikipedia.org/wiki/Site', description.data[:wikipedia_url]
      end
    end
  end

  test 'data has nil fields when the lang sitelink is absent' do
    sitelinks = { lang_title: nil }
    Wikimedia::Sitelinks.stub(:for, sitelinks) do
      description = Site::Description.new(lod_link: @lod_link)
      assert_nil description.data[:wikipedia_title]
      assert_nil description.data[:wikipedia_extract_text]
      assert_nil description.data[:wikipedia_url]
    end
  end

  test 'data caches the combined result' do
    sitelinks = { lang_title: 'Site' }
    extract = { title: 'Site', text: 'Lead.', url: 'https://en.wikipedia.org/wiki/Site' }
    Wikimedia::Sitelinks.stub(:for, sitelinks) do
      Wikipedia::Article.stub(:summary, extract) do
        description = Site::Description.new(lod_link: @lod_link)
        first = description.data
        second = description.data
        assert_equal first, second
      end
    end
  end

  test 'failed? is true when there is no Wikipedia text' do
    sitelinks = { lang_title: nil }
    extract = nil
    Wikimedia::Sitelinks.stub(:for, sitelinks) do
      Wikipedia::Article.stub(:summary, extract) do
        description = Site::Description.new(lod_link: @lod_link)
        assert description.failed?
      end
    end
  end

  test 'failed? is false when a Wikipedia text is present' do
    sitelinks = { lang_title: 'Site' }
    extract = { title: 'Site', text: 'Lead.', url: 'https://en.wikipedia.org/wiki/Site' }
    Wikimedia::Sitelinks.stub(:for, sitelinks) do
      Wikipedia::Article.stub(:summary, extract) do
        description = Site::Description.new(lod_link: @lod_link)
        refute description.failed?
      end
    end
  end

  test 'lang changes the Wikipedia URL' do
    sitelinks = { lang_title: 'Site' }
    extract = { title: 'Site', text: 'Lead.', url: 'https://de.wikipedia.org/wiki/Site' }
    Wikimedia::Sitelinks.stub(:for, sitelinks) do
      Wikipedia::Article.stub(:summary, extract) do
        description = Site::Description.new(lod_link: @lod_link, lang: 'de')
        assert_equal 'https://de.wikipedia.org/wiki/Site', description.data[:wikipedia_url]
      end
    end
  end

  test 'fetched_at returns a Time recorded when the data was cached' do
    description = Site::Description.new(lod_link: @lod_link)
    before = Time.current

    Wikimedia::Sitelinks.stub(:for, { lang_title: 'Site' }) do
      Wikipedia::Article.stub(:summary, { title: 'Site', text: 'Lead.', url: 'https://...' }) do
        description.data
      end
    end

    after = Time.current

    assert_kind_of Time, description.fetched_at
    assert_operator description.fetched_at, :>=, before
    assert_operator description.fetched_at, :<=, after
  end

  test 'fetched_at is the same on subsequent reads within the cache window' do
    description = Site::Description.new(lod_link: @lod_link)

    Wikimedia::Sitelinks.stub(:for, { lang_title: 'Site' }) do
      Wikipedia::Article.stub(:summary, { title: 'Site', text: 'Lead.', url: 'https://...' }) do
        description.data
        first = description.fetched_at

        travel_to 1.hour.from_now do
          assert_equal first, description.fetched_at
        end
      end
    end
  end
end
