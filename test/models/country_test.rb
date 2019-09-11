require 'test_helper'

class CountryTest < ActiveSupport::TestCase

  test "has a valid factory" do
    assert FactoryBot.build(:country).save
  end

  test "is invalid without a name" do
    assert_not FactoryBot.build(:country, name: nil).save
  end

  test "is invalid without a unique name" do
    FactoryBot.build(:country, name: "Test123").save
    assert_not FactoryBot.build(:country, name: "Test123").save
  end

end
