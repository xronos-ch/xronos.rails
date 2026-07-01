# frozen_string_literal: true

require 'test_helper'

class Wikipedia::ArticleTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
    setup do
      Rails.cache.clear
    end

    test '.summary returns a hash with text, title and url' do
      body = {
        query: {
          pages: {
            '123' => {
              pageid: 123,
              title: 'Göbekli Tepe',
              extract: "Göbekli Tepe is an archaeological site in Turkey.\n\nIt is known for its megalithic " \
              'structures.',
              fullurl: 'https://en.wikipedia.org/wiki/G%C3%B6bekli_Tepe'
            }
          }
        }
      }.to_json

      stub_request(:get, /en\.wikipedia\.org/).to_return(status: 200, body: body)

      result = Wikipedia::Article.summary('Göbekli Tepe')

      assert_equal 'Göbekli Tepe is an archaeological site in Turkey.', result[:text]
      assert_equal 'Göbekli Tepe', result[:title]
      assert_equal 'https://en.wikipedia.org/wiki/G%C3%B6bekli_Tepe', result[:url]
    end

    test '.summary limits the extract to the lead paragraph' do
      body = {
        query: {
          pages: {
            '1' => {
              title: 'Site',
              extract: "First paragraph here.\n\n==Section==\nMore text.",
              fullurl: 'https://en.wikipedia.org/wiki/Site'
            }
          }
        }
      }.to_json

      stub_request(:get, /en\.wikipedia\.org/).to_return(status: 200, body: body)

      result = Wikipedia::Article.summary('Site')

      assert_equal 'First paragraph here.', result[:text]
    end

    test '.summary returns nil for a blank title' do
      assert_nil Wikipedia::Article.summary('')
      assert_nil Wikipedia::Article.summary(nil)
    end

    test '.summary returns nil when the API errors' do
      stub_request(:get, /en\.wikipedia\.org/).to_return(status: 500)

      assert_nil Wikipedia::Article.summary('Site')
    end

    test '.summary returns nil on timeout' do
      stub_request(:get, /en\.wikipedia\.org/).to_timeout

      assert_nil Wikipedia::Article.summary('Site')
    end

    test '.summary caches responses' do
      body = {
        query: {
          pages: { '1' => { title: 'Site', extract: 'Lead.', fullurl: 'https://en.wikipedia.org/wiki/Site' } }
        }
      }.to_json

      stub_request(:get, /en\.wikipedia\.org/).to_return(status: 200, body: body)

      Wikipedia::Article.summary('Site')
      Wikipedia::Article.summary('Site')

      assert_requested :get, /en\.wikipedia\.org/, times: 1
    end

    test '.url returns the canonical article URL' do
      assert_equal 'https://en.wikipedia.org/wiki/Foo',
                   Wikipedia::Article.url('Foo', lang: 'en')
      assert_equal 'https://de.wikipedia.org/wiki/Foo',
                   Wikipedia::Article.url('Foo', lang: 'de')
    end

    test '.url encodes the title' do
      assert_equal 'https://en.wikipedia.org/wiki/G%C3%B6bekli%20Tepe',
                   Wikipedia::Article.url('Göbekli Tepe', lang: 'en')
    end
  end
