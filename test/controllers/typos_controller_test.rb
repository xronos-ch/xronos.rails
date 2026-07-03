# frozen_string_literal: true

require 'test_helper'

class TyposControllerTest < ActionDispatch::IntegrationTest
  test 'unauthenticated users cannot create typos' do
    assert_no_difference('Typo.count') do
      post typos_path, params: {
        typo: {
          name: 'Unauthorized Typo'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end
end
