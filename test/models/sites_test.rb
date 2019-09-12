require 'test_helper'

class SitesTest < ActiveSupport::TestCase

  test "has a valid factory" do
    assert FactoryBot.build(:site).save
  end

  test "is invalid without a name" do
    assert_not FactoryBot.build(:site, name: nil).save
  end

  test "is valid without a unique name" do
    FactoryBot.build(:site, name: "Test123").save
    assert FactoryBot.build(:site, name: "Test123").save
  end

end
