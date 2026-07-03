# frozen_string_literal: true

require 'test_helper'

class C14sControllerTest < ActionDispatch::IntegrationTest
  test 'unauthenticated users cannot create c14 records' do
    sample = create(:sample)
    c14_lab = create(:c14_lab)

    assert_no_difference('C14.count') do
      post c14s_path, params: {
        c14: {
          sample_id: sample.id,
          c14_lab_id: c14_lab.id,
          lab_identifier: 'UNAUTH-1',
          bp: 4500,
          std: 30,
          method: 'AMS'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end
end