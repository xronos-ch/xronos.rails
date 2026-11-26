# frozen_string_literal: true

require 'test_helper'

class VersionsControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[index],
    requires_admin: false,
    statuses: {
      index: { not_signed_in: :success, signed_in: :success }
    }
  )

  test 'index includes both PaperTrail versions and SupersessionEvents' do
    with_versioning do
      site = build(:site)
      site.revision_comment = 'Created test site'
      site.save!
    end

    superseded = create(:site)
    canonical = create(:site)
    event = SupersessionEvent.create!(
      event_type: 'supersede',
      superseded: superseded,
      superseded_by: canonical,
      whodunnit_user: create(:user)
    )

    get versions_path

    assert_response :success
    assert_includes response.body, 'Created test site'
    assert_includes response.body, 'Superseded by'
    assert_dom "td time[datetime='#{event.created_at.iso8601}']"
    assert_dom "td", text: "Site:#{superseded.id}"
  end

  test 'index paginates mixed changelog entries' do
    site = create(:site)
    timestamp = Time.current.change(usec: 0)

    PaperTrail::Version.insert_all!(
      Array.new(20) do |i|
        {
          item_type: 'Site',
          item_id: site.id,
          event: 'update',
          revision_comment: format('Pagination example %02d', i),
          created_at: timestamp
        }
      end
    )

    SupersessionEvent.create!(
      event_type: 'supersede',
      superseded: create(:site),
      superseded_by: create(:site),
      whodunnit_user: create(:user),
      created_at: timestamp
    )

    get versions_path, params: { page: 1 }

    assert_response :success
    assert_includes response.body, 'Superseded by'
    assert_includes response.body, 'Pagination example 19'
    assert_not_includes response.body, 'Pagination example 00'

    get versions_path, params: { page: 2 }

    assert_response :success
    assert_includes response.body, 'Pagination example 00'
    assert_not_includes response.body, 'Pagination example 19'
    assert_not_includes response.body, 'Superseded by'
  end

  test 'index excludes versions of non-public record types' do
    with_versioning do
      site = build(:site)
      site.revision_comment = 'Public site revision'
      site.save!
    end

    PaperTrail::Version.insert_all!([{
      item_type: 'InternalRecord',
      item_id: 1,
      event: 'create',
      revision_comment: 'Private revision',
      created_at: Time.current
    }])

    get versions_path

    assert_response :success
    assert_includes response.body, 'Public site revision'
    assert_not_includes response.body, 'Private revision'
    assert_not_includes response.body, 'InternalRecord'

    get versions_path(format: :json)

    assert_response :success

    entries = JSON.parse(response.body)['changes']

    assert entries.any? { |entry| entry['comment'] == 'Public site revision' }
    assert_not entries.any? { |entry| entry['record_type'] == 'InternalRecord' }
    assert_not entries.any? { |entry| entry['comment'] == 'Private revision' }
  end

  test 'index renders historical versions of formerly versioned models' do
    taxon = create(:taxon)

    PaperTrail::Version.insert_all!([{
      item_type: 'Taxon',
      item_id: taxon.id,
      event: 'update',
      object_changes: {
        'name' => ['Old taxon name', 'Corrected taxon name']
      },
      revision_comment: 'Corrected taxon identification',
      created_at: Time.current
    }])

    get versions_path

    assert_response :success
    assert_includes response.body, 'Corrected taxon identification'
    assert_includes response.body, 'Old taxon name'
    assert_includes response.body, 'Corrected taxon name'
  end

  test 'filter form does not submit an unexpected commit parameter' do
    get versions_path

    assert_response :success
    assert_dom "form[action='#{versions_path}']"
    assert_dom "form[action='#{versions_path}'] [name='commit']", count: 0
  end

  test 'index filters by record type' do
    site = create(:site)
    reference = create(:reference)

    PaperTrail::Version.insert_all!([
      {
        item_type: 'Site',
        item_id: site.id,
        event: 'update',
        revision_comment: 'Site filter example',
        created_at: Time.current
      },
      {
        item_type: 'Reference',
        item_id: reference.id,
        event: 'update',
        revision_comment: 'Reference filter example',
        created_at: Time.current
      }
    ])

    get versions_path, params: { record_type: 'Site' }

    assert_response :success
    assert_includes response.body, 'Site filter example'
    assert_not_includes response.body, 'Reference filter example'
  end

  test 'index filters by event type across both changelog sources' do
    site = create(:site)

    PaperTrail::Version.insert_all!([{
      item_type: 'Site',
      item_id: site.id,
      event: 'update',
      revision_comment: 'Updated site example',
      created_at: Time.current
    }])

    SupersessionEvent.create!(
      event_type: 'supersede',
      superseded: site,
      superseded_by: create(:site),
      whodunnit_user: create(:user)
    )

    get versions_path, params: { event_type: 'supersede' }

    assert_response :success
    assert_includes response.body, 'Superseded by'
    assert_not_includes response.body, 'Updated site example'

    get versions_path, params: { event_type: 'update' }

    assert_response :success
    assert_includes response.body, 'Updated site example'
    assert_not_includes response.body, 'Superseded by'
  end

  test 'index filters by inclusive date range' do
    site = create(:site)

    PaperTrail::Version.insert_all!([
      {
        item_type: 'Site',
        item_id: site.id,
        event: 'update',
        revision_comment: 'Before date range',
        created_at: Time.zone.local(2026, 1, 9, 23, 59)
      },
      {
        item_type: 'Site',
        item_id: site.id,
        event: 'update',
        revision_comment: 'Within date range',
        created_at: Time.zone.local(2026, 1, 10, 23, 59)
      },
      {
        item_type: 'Site',
        item_id: site.id,
        event: 'update',
        revision_comment: 'After date range',
        created_at: Time.zone.local(2026, 1, 11)
      }
    ])

    get versions_path, params: {
      from: '2026-01-10',
      to: '2026-01-10'
    }

    assert_response :success
    assert_includes response.body, 'Within date range'
    assert_not_includes response.body, 'Before date range'
    assert_not_includes response.body, 'After date range'
  end

  test 'pagination retains selected filters' do
    with_versioning do
      create_list(:site, 25)
    end

    get versions_path, params: { record_type: 'Site' }

    assert_response :success
    assert_dom "a[href*='page=2'][href*='record_type=Site']"
  end

  test 'index exposes a public JSON changelog' do
    user = create(:user)
    site = create(:site)

    PaperTrail::Version.insert_all!([{
      item_type: 'Site',
      item_id: site.id,
      event: 'update',
      whodunnit: user.id.to_s,
      whodunnit_user_email: user.email,
      revision_comment: 'Corrected site name',
      object_changes: {
        'name' => ['Old name', 'New name']
      },
      created_at: Time.current
    }])

    get versions_path(format: :json),
        params: { record_type: 'Site', event_type: 'update' }

    assert_response :success
    assert_equal 'application/json', response.media_type

    data = JSON.parse(response.body)

    assert_equal 'Site', data['filters']['record_type']
    assert_equal 'update', data['filters']['event_type']

    entry = data['changes'].find do |change|
      change['comment'] == 'Corrected site name'
    end

    assert entry
    assert_equal 'version', entry['entry_type']
    assert_equal site.id, entry['record_id']
    assert_equal 'update', entry['event']
    assert_equal ['Old name', 'New name'], entry['changes']['name']
    assert_equal user.id, entry['contributor']['id']

    assert_not_includes response.body, user.email
  end

  test 'JSON changelog includes supersession events' do
    superseded = create(:site)
    canonical = create(:site)

    event = SupersessionEvent.create!(
      event_type: 'supersede',
      superseded: superseded,
      superseded_by: canonical,
      whodunnit_user: create(:user)
    )

    get versions_path(format: :json),
        params: { event_type: 'supersede' }

    assert_response :success

    data = JSON.parse(response.body)
    entry = data['changes'].find { |change| change['id'] == event.id }

    assert entry
    assert_equal 'supersession', entry['entry_type']
    assert_equal 'supersede', entry['event']
    assert_equal superseded.id, entry['record_id']
    assert_equal canonical.id, entry['superseded_by']['record_id']
    assert_equal 'Site', entry['superseded_by']['record_type']
  end

  test 'JSON changelog paginates entries in deterministic order' do
    site = create(:site)

    timestamp = Time.current.change(usec: 0)

    inserted = PaperTrail::Version.insert_all!(
      Array.new(1001) do
        {
          item_type: 'Site',
          item_id: site.id,
          event: 'update',
          created_at: timestamp
        }
      end,
      returning: %w[id]
    )

    filters = { record_type: 'Site', event_type: 'update' }

    get versions_path(format: :json), params: filters

    assert_response :success

    data = JSON.parse(response.body)

    assert_equal 1000, data['changes'].size
    assert_equal 1000, data['pagination']['per_page']
    assert_equal 1001, data['pagination']['total_count']
    assert_equal 2, data['pagination']['total_pages']
    assert_equal 2, data['pagination']['next_page']
    assert_nil data['pagination']['previous_page']

    get versions_path(format: :json), params: filters.merge(page: 2)

    assert_response :success

    second_page = JSON.parse(response.body)

    assert_equal 1, second_page['changes'].size
    assert_nil second_page['pagination']['next_page']
    assert_equal 1, second_page['pagination']['previous_page']

    expected_ids = inserted.rows.flatten.sort.reverse

    returned_ids = (
      data['changes'] + second_page['changes']
    ).map { |entry| entry['id'] }

    assert_equal expected_ids, returned_ids
  end

  test 'JSON changelog handles an empty result' do
    get versions_path(format: :json)

    assert_response :success

    data = JSON.parse(response.body)

    assert_empty data['changes']
  end

  test 'changelog responses discourage search engine indexing' do
    get versions_path

    assert_response :success
    assert_equal 'noindex, nofollow', response.headers['X-Robots-Tag']

    get versions_path(format: :json)

    assert_response :success
    assert_equal 'noindex, nofollow', response.headers['X-Robots-Tag']
  end

  test 'index rejects invalid request parameters' do
    [
      { record_type: 'User' },
      { event_type: 'invalid' },
      { from: 'not-a-date' },
      { from: '2026-02-01', to: '2026-01-01' },
      { unknown: 'value' },
      { page: '0' },
      { page: '-1' },
      { page: 'abc' },
      { page: '1.5' },
      { page: '99999999999999999999' }
    ].each do |parameters|
      get versions_path, params: parameters

      assert_response :bad_request, parameters.inspect
    end
  end

  test 'index returns not found for pages beyond the changelog' do
    get versions_path, params: { page: 2 }

    assert_response :not_found

    get versions_path(format: :json), params: { page: 2 }

    assert_response :not_found
  end

end
