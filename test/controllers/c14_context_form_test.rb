# frozen_string_literal: true

require 'test_helper'

class C14ContextFormTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.routes.eager_load!
    sign_in create(:user)
    @site = create(:site)
  end

  test 'new form submits the site with its nested context' do
    get new_c14_path(site: @site)

    assert_response :success
    assert_dom "input[type='hidden'][name='c14[sample_attributes][context_attributes][site_id]'][value='#{@site.id}']"
  end

  test 'a blank context name creates an unnamed context belonging to the site' do
    assert_difference ['C14.count', 'Sample.count', 'Context.count'], 1 do
      post c14s_path, params: form_params(context_name: '')
    end

    assert_response :redirect
    assert_equal @site, C14.last.site
    assert_nil C14.last.context.name
  end

  test 'a new context name creates the full hierarchy and returns to the originating page' do
    assert_difference ['C14.count', 'Sample.count', 'Context.count'], 1 do
      post c14s_path, params: form_params, headers: { 'HTTP_REFERER' => site_url(@site) }
    end

    assert_redirected_to site_url(@site)
    assert_equal @site, C14.last.site
    assert_equal 'Trench 1', C14.last.context.name
  end

  test 'missing context is rejected without persisting an orphan sample' do
    payload = form_params
    payload[:c14][:sample_attributes].delete(:context_attributes)

    assert_no_difference ['C14.count', 'Sample.count', 'Context.count'] do
      post c14s_path, params: payload
    end

    assert_response :unprocessable_entity
    assert_dom '#error_explanation', text: /Context must exist/i
  end

  test 'invalid modal submission shows errors and preserves entered fields' do
    payload = form_params
    payload[:c14][:bp] = ''

    assert_no_difference ['C14.count', 'Sample.count', 'Context.count'] do
      post c14s_path, params: payload, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_equal 'text/vnd.turbo-stream.html', response.media_type
    assert_includes response.body, 'Bp can&#39;t be blank'
    assert_includes response.body, 'Trench 1'
    assert_includes response.body, 'remoteModal-body'
  end

  test 'successful creation without a referring page has a local fallback' do
    post c14s_path, params: form_params

    assert_redirected_to c14_url(C14.last)
  end

  test 'missing site is shown as a nested validation error in the modal' do
    payload = form_params
    payload[:c14][:sample_attributes][:context_attributes].delete(:site_id)

    assert_no_difference ['C14.count', 'Sample.count', 'Context.count'] do
      post c14s_path, params: payload, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_includes response.body, 'Sample context site must exist'
    assert_includes response.body, 'Trench 1'
  end

  test 'duplicate context names show validation errors instead of silently failing' do
    context = create(:context, site: @site, name: 'Trench 1')

    assert_no_difference ['C14.count', 'Sample.count', 'Context.count'] do
      post c14s_path, params: form_params, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_includes response.body, 'has already been taken'
    assert_equal 'Trench 1', context.reload.name
  end

  test 'the same context name can be created at a different site' do
    create(:context, name: 'Trench 1')

    assert_difference 'Context.count', 1 do
      post c14s_path, params: form_params
    end

    assert_response :redirect
    assert_equal @site, C14.last.site
  end

  test 'an external referring page uses the local fallback' do
    post c14s_path, params: form_params, headers: { 'HTTP_REFERER' => 'https://example.org/' }

    assert_redirected_to c14_url(C14.last)
  end

  test 'an existing context can be selected without changing it' do
    context = create(:context, site: @site, name: 'Existing trench')
    payload = form_params
    payload[:c14][:sample_attributes][:context_id] = context.id

    assert_no_difference 'Context.count' do
      assert_difference ['C14.count', 'Sample.count'], 1 do
        post c14s_path, params: payload
      end
    end

    assert_redirected_to c14_url(C14.last)
    assert_equal context, C14.last.context
    assert_equal 'Existing trench', context.reload.name
  end

  test 'a blank context name reuses the sites unnamed context' do
    context = create(:context, site: @site, name: nil)

    assert_no_difference 'Context.count' do
      assert_difference ['C14.count', 'Sample.count'], 1 do
        post c14s_path, params: form_params(context_name: '  ')
      end
    end

    assert_response :redirect
    assert_equal context, C14.last.context
  end

  test 'return destination survives a validation error and a full page submission' do
    get new_c14_path(site: @site), headers: { 'HTTP_REFERER' => site_url(@site) }
    assert_dom "input[name='return_to'][value='#{site_url(@site)}']"

    payload = form_params.merge(return_to: site_url(@site))
    payload[:c14][:bp] = ''
    post c14s_path, params: payload, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_dom "input[name='return_to'][value='#{site_url(@site)}']"

    payload[:c14][:bp] = 4500
    post c14s_path, params: payload, headers: { 'HTTP_REFERER' => new_c14_url(site: @site) }
    assert_redirected_to site_url(@site)
  end

  test 'external return destinations are ignored' do
    payload = form_params.merge(return_to: 'https://example.org/')
    post c14s_path, params: payload, headers: { 'HTTP_REFERER' => 'https://example.org/' }
    assert_redirected_to c14_url(C14.last)
  end

  test 'invalid measurement preserves the selected context' do
    context = create(:context, site: @site)
    payload = form_params
    payload[:c14][:bp] = ''
    payload[:c14][:sample_attributes][:context_id] = context.id

    post c14s_path, params: payload, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_dom "select[name='context_choice'] option[selected][value='#{context.id}']"
    assert_equal context.name, context.reload.name
  end

  test 'successful modal submission redirects to its originating page' do
    post c14s_path, params: form_params.merge(return_to: site_url(@site)), as: :turbo_stream

    assert_redirected_to site_url(@site)
  end

  test 'an unnamed context at another site is not reused' do
    other_context = create(:context, name: nil)

    assert_difference 'Context.count', 1 do
      post c14s_path, params: form_params(context_name: '')
    end

    assert_response :redirect
    assert_equal @site, C14.last.site
    assert_not_equal other_context, C14.last.context
  end

  test 'ordinary users cannot change dates of an existing context during creation' do
    context = create(:context, site: @site, name: nil, approx_start_time: 5000)
    payload = form_params(context_name: '')
    payload[:c14][:sample_attributes][:context_attributes][:approx_start_time] = 4000

    assert_no_difference ['C14.count', 'Sample.count', 'Context.count'] do
      post c14s_path, params: payload
    end

    assert_response :not_found
    assert_equal 5000, context.reload.approx_start_time
  end

  test 'the default is NA and context dates are directly visible' do
    get new_c14_path(site: @site)

    assert_response :success
    assert_dom "#c14_context_choice option[selected][value='']", text: '<NA>'
    assert_dom 'details', count: 0
    assert_dom '#c14_context_help', count: 0
    assert_dom 'fieldset[hidden], fieldset[disabled]', count: 0
    assert_dom "input[name='c14[sample_attributes][context_attributes][approx_start_time]']"
  end

  test 'edit form selects the existing context and includes dates for other choices' do
    sign_in create(:user, :admin)
    c14 = create(:c14)
    other = create(:context, site: c14.site, approx_start_time: 4200, approx_end_time: 4100)

    get edit_c14_path(c14)

    assert_response :success
    assert_dom "#c14_context_choice option[selected][value='#{c14.context.id}']"
    selector = response.parsed_body.at_css('[data-context-choice-contexts-value]')
    data = JSON.parse(selector['data-context-choice-contexts-value'])
    assert_equal 4200, data[other.id.to_s]['startTime']
    assert_equal 4100, data[other.id.to_s]['endTime']
    assert_dom "input[name$='[approx_start_time]'][readonly]", count: 0
  end

  test 'existing context dates can be edited without renaming the context' do
    sign_in create(:user, :admin)
    c14 = create(:c14)
    name = c14.context.name
    payload = update_params(c14, context: c14.context, start_time: 5000, end_time: 4500)

    assert_no_difference 'Context.count' do
      patch c14_path(c14), params: payload
    end

    assert_redirected_to c14_url(c14)
    values = c14.reload.context.attributes.values_at('name', 'approx_start_time', 'approx_end_time')
    assert_equal [name, 5000, 4500], values
  end

  test 'switching contexts updates only the selected contexts dates' do
    sign_in create(:user, :admin)
    c14 = create(:c14)
    previous = c14.context
    previous.update!(approx_start_time: 6000, approx_end_time: 5500)
    selected = create(:context, site: c14.site, approx_start_time: 4200, approx_end_time: 4100)

    patch c14_path(c14), params: update_params(c14, context: selected, start_time: 4200, end_time: 4000)

    assert_redirected_to c14_url(c14)
    assert_equal selected, c14.reload.context
    assert_equal [6000, 5500], previous.reload.attributes.values_at('approx_start_time', 'approx_end_time')
    assert_equal [4200, 4000], selected.reload.attributes.values_at('approx_start_time', 'approx_end_time')
  end

  test 'invalid updates preserve context dates in the form without saving them' do
    sign_in create(:user, :admin)
    c14 = create(:c14)
    c14.context.update!(approx_start_time: 5000)
    payload = update_params(c14, context: c14.context, start_time: 4000, end_time: 3500)
    payload[:c14][:bp] = ''

    patch c14_path(c14), params: payload, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_includes response.body, 'remoteModal-body'
    assert_dom "input[name$='[approx_start_time]'][value='4000']"
    assert_dom "input[name$='[approx_end_time]'][value='3500']"
    assert_equal 5000, c14.context.reload.approx_start_time
  end

  test 'editing a date can create a new named context' do
    sign_in create(:user, :admin)
    c14 = create(:c14)
    previous = c14.context
    payload = update_params(c14, context: previous, start_time: 4200, end_time: 4100)
    payload[:c14][:sample_attributes][:context_id] = ''
    payload[:c14][:sample_attributes][:context_attributes][:name] = 'New trench'

    assert_difference 'Context.count', 1 do
      patch c14_path(c14), params: payload
    end

    assert_redirected_to c14_url(c14)
    assert_not_equal previous, c14.reload.context
    assert_equal 'New trench', c14.context.name
    assert_equal 4200, c14.context.approx_start_time
  end

  test 'editing a date can reuse the unnamed context and edit its dates' do
    sign_in create(:user, :admin)
    c14 = create(:c14)
    general = create(:context, site: c14.site, name: nil)
    payload = update_params(c14, context: general, start_time: 4200, end_time: 4100)
    payload[:c14][:sample_attributes][:context_id] = ''

    assert_no_difference 'Context.count' do
      patch c14_path(c14), params: payload
    end

    assert_redirected_to c14_url(c14)
    assert_equal general, c14.reload.context
    assert_equal 4200, general.reload.approx_start_time
  end

  test 'ordinary users see existing dates without editable controls' do
    create(:context, site: @site, name: nil, approx_start_time: 5000)
    get new_c14_path(site: @site)

    assert_response :success
    assert_dom "input[name$='[approx_start_time]'][value='5000'][readonly]"
  end

  test 'ordinary users can use an existing context with its unchanged dates' do
    context = create(:context, site: @site, approx_start_time: 5000)
    payload = form_params
    payload[:c14][:sample_attributes][:context_id] = context.id
    payload[:c14][:sample_attributes][:context_attributes][:approx_start_time] = '5000'

    post c14s_path, params: payload

    assert_redirected_to c14_url(C14.last)
    assert_equal context, C14.last.context
    assert_equal 5000, context.reload.approx_start_time
  end

  test 'admins can edit existing context dates while creating a radiocarbon date' do
    sign_in create(:user, :admin)
    context = create(:context, site: @site, approx_start_time: 5000)
    name = context.name
    payload = form_params
    payload[:c14][:sample_attributes][:context_id] = context.id
    payload[:c14][:sample_attributes][:context_attributes][:approx_start_time] = 4500

    assert_no_difference 'Context.count' do
      post c14s_path, params: payload
    end

    assert_redirected_to c14_url(C14.last)
    assert_equal context, C14.last.context
    assert_equal [name, 4500], context.reload.attributes.values_at('name', 'approx_start_time')
  end

  private

  def update_params(c14, context:, start_time:, end_time:)
    {
      c14: {
        sample_attributes: {
          id: c14.sample.id, context_id: context.id, context_attributes: {
            site_id: c14.site.id, name: '',
            approx_start_time: start_time, approx_end_time: end_time
          }
        }
      }
    }
  end

  def form_params(context_name: 'Trench 1')
    {
      c14: {
        lab_identifier: 'TEST-520', bp: 4500, std: 30,
        sample_attributes: {
          name: 'Sample 520',
          context_attributes: { name: context_name, site_id: @site.id }
        }
      }
    }
  end
end
