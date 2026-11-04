# frozen_string_literal: true

require 'application_system_test_case'

class C14ContextFormSystemTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    # The shared integration-test teardown resets Capybara to another driver.
    self.class.driver.use
    login_as create(:user), scope: :user
    @context = create(:context, name: 'Existing trench')
    create(:c14, sample: create(:sample, context: @context))
  end

  teardown do
    Warden.test_reset!
  end

  test 'selecting a context, correcting an error and returning to the site' do
    visit site_path(@context.site)
    click_link 'Add radiocarbon date'
    assert_selector '#remoteModal.show'
    assert_selector '#remoteModal:focus'

    assert_selector '.ts-control .item', text: 'General site context'
    assert_no_selector 'input[name="c14[sample_attributes][context_attributes][id]"]', visible: :all
    find('[data-controller="context-choice"] .ts-control').click
    find('[data-controller="context-choice"] .ts-dropdown input.dropdown-input').send_keys('Existing')
    find('.ts-dropdown .option', text: 'Existing trench').click
    assert_selector 'fieldset[disabled]', visible: :hidden

    fill_in 'Lab identifier', with: 'SYSTEM-520'
    fill_in 'Sample name', with: 'Browser sample'
    fill_in 'Error', with: 30
    page.execute_script("document.getElementById('c14Form').noValidate = true")
    click_button 'Save'

    assert_selector '#error_explanation', text: /blank/
    assert_selector '.ts-control .item', text: 'Existing trench'
    assert_no_selector 'input[name="c14[sample_attributes][context_attributes][id]"]', visible: :all
    fill_in 'Age', with: 4500
    click_button 'Save'

    assert_no_selector '#remoteModal.show'
    assert_current_path site_path(@context.site)
    assert_equal @context, C14.find_by!(lab_identifier: 'SYSTEM-520').context
  end

  test 'the default creates or reuses the general site context without a selection' do
    visit site_path(@context.site)
    2.times do |index|
      click_link 'Add radiocarbon date'
      assert_selector '#remoteModal.show'
      assert_selector '#remoteModal:focus'
      assert_selector '.ts-control .item', text: 'General site context'
      fill_in 'Lab identifier', with: "DEFAULT-520-#{index}"
      fill_in 'Sample name', with: "Default sample #{index}"
      fill_in 'Age', with: 4500
      fill_in 'Error', with: 30
      click_button 'Save'
      assert_no_selector '#remoteModal.show'
      assert_text "DEFAULT-520-#{index}"
    end
    general = @context.site.contexts.where(name: nil)
    assert_equal 1, general.count
    context_ids = C14.where('lab_identifier LIKE ?', 'DEFAULT-520-%').map { |c14| c14.context.id }
    assert_equal [general.first.id], context_ids.uniq
  end

  test 'creating a context preserves its name and dates through an error' do
    visit site_path(@context.site)
    click_link 'Add radiocarbon date'
    assert_selector '#remoteModal:focus'
    find('[data-controller="context-choice"] .ts-control').click
    find('[data-controller="context-choice"] .ts-dropdown input.dropdown-input').send_keys('New trench')
    find('.ts-dropdown .create').click
    assert_selector '.ts-control .item', text: 'New trench'
    find('summary', text: 'More context details').click
    fill_in 'Dated from', with: 5000
    fill_in 'Dated to', with: 4000
    fill_in 'Lab identifier', with: 'NEW-520'
    fill_in 'Sample name', with: 'New sample'
    fill_in 'Error', with: 30
    page.execute_script("document.getElementById('c14Form').noValidate = true")
    click_button 'Save'
    assert_selector '#error_explanation'
    assert_selector '.ts-control .item', text: 'New trench'
    assert_field 'Dated from', with: '5000'
    fill_in 'Age', with: 4500
    click_button 'Save'
    assert_no_selector '#remoteModal.show'
    context = C14.find_by!(lab_identifier: 'NEW-520').context
    assert_equal 'New trench', context.name
    assert_equal 5000, context.approx_start_time
    assert_equal 4000, context.approx_end_time
  end
end
