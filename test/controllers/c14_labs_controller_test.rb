# frozen_string_literal: true

require 'test_helper'

class C14LabsControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  smoke_tests(
    param_key: :c14_lab,
    statuses: {
      index: { not_signed_in: :success, signed_in: :success },
      show: { not_signed_in: :success,  signed_in: :success },
      new: { not_signed_in: :not_found, signed_in: :success },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  test 'show hides the edit link from guests and regular users' do
    lab = create(:c14_lab)
    selector = "a[href='#{edit_c14_lab_path(lab)}']"

    get c14_lab_path(lab)
    assert_dom selector, count: 0

    sign_in create(:user)
    get c14_lab_path(lab)
    assert_dom selector, count: 0
  end

  test 'admins can open the edit dialog from the lab detail page' do
    lab = create(:c14_lab)
    sign_in create(:user, :admin)

    get c14_lab_path(lab)
    assert_dom "#c14Lab-header + .container a[href='#{edit_c14_lab_path(lab)}'][data-turbo-frame='remote_modal']"
    assert_dom "form[action='#{c14_lab_path(lab)}'] input[name='_method'][value='delete']", count: 0

    get edit_c14_lab_path(lab), headers: { 'Turbo-Frame' => 'remote_modal' }
    assert_dom 'turbo-frame#remote_modal form'
  end
end
