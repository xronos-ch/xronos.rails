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

  test 'invalid measurement preserves the selected context without exposing editable context fields' do
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

  test 'new dates on an existing unnamed context are not silently discarded or overwritten' do
    context = create(:context, site: @site, name: nil, approx_start_time: 5000)
    payload = form_params(context_name: '')
    payload[:c14][:sample_attributes][:context_attributes][:approx_start_time] = 4000

    assert_no_difference ['C14.count', 'Sample.count', 'Context.count'] do
      post c14s_path, params: payload, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_includes response.body, 'can only be blank once per site'
    assert_equal 5000, context.reload.approx_start_time
    assert_dom "input[name='c14[sample_attributes][context_attributes][approx_start_time]'][value='4000']"
  end

  private

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
