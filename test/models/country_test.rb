require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  test "country has a valid factory" do
    assert FactoryBot.build(:country).save
  end
end
