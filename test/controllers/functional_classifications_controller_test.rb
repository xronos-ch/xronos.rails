# frozen_string_literal: true

require 'test_helper'

class FunctionalClassificationsControllerTest < ActionDispatch::IntegrationTest
  test 'unauthenticated users cannot create functional classifications' do
    context = create(:context)
    category = create(:functional_classification_category)

    assert_no_difference('FunctionalClassification.count') do
      post functional_classifications_path, params: {
        functional_classification: {
          assignable_type: 'Context',
          assignable_id: context.id,
          functional_classification_category_id: category.id,
          confidence: 'certain',
          source: 'manual',
          note: 'Unauthorized test'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end
end
