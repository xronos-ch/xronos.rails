# frozen_string_literal: true

require 'test_helper'

class LodLinksControllerTest < ActionDispatch::IntegrationTest
  test 'unauthenticated users cannot create LOD links' do
    site = create(:site)

    assert_no_difference('LodLink.count') do
      post lod_links_path, params: {
        lod_link: {
          linkable_type: 'Site',
          linkable_id: site.id,
          source: 'Wikidata',
          external_id: 'Q123456789',
          status: 'pending'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end
end