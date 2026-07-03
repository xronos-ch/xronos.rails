# frozen_string_literal: true

require 'test_helper'

class LinkedResourcesControllerTest < ActionDispatch::IntegrationTest
  test 'unauthenticated users cannot create linked resources' do
    site = create(:site)

    assert_no_difference('LinkedResource.count') do
      post linked_resources_path, params: {
        linked_resource: {
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
