require "test_helper"

class ContextDBTest < ActiveSupport::TestCase
  setup do
    @site = create(:site)
    @now  = Time.current
  end

  test "database enforces one NULL name per site" do
    Context.insert_all!([
      {
        site_id: @site.id,
        name: nil,
        created_at: @now,
        updated_at: @now
      }
    ])

    assert_raises ActiveRecord::RecordNotUnique do
      Context.insert_all!([
        {
          site_id: @site.id,
          name: nil,
          created_at: @now,
          updated_at: @now
        }
      ])
    end
  end

  test "database enforces unique name per site for non-NULL names" do
    Context.insert_all!([
      {
        site_id: @site.id,
        name: "Area 1",
        created_at: @now,
        updated_at: @now
      }
    ])

    assert_raises ActiveRecord::RecordNotUnique do
      Context.insert_all!([
        {
          site_id: @site.id,
          name: "Area 1",
          created_at: @now,
          updated_at: @now
        }
      ])
    end
  end

  test "database allows NULL names on different sites" do
    site2 = create(:site)

    assert_nothing_raised do
      Context.insert_all!([
        {
          site_id: @site.id,
          name: nil,
          created_at: @now,
          updated_at: @now
        },
        {
          site_id: site2.id,
          name: nil,
          created_at: @now,
          updated_at: @now
        }
      ])
    end
  end
end
