require 'test_helper'
require 'logger'


class C14MeasurementControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @c14_measurement = FactoryBot.create(:c14_measurement)
    @admin = FactoryBot.create(:user, :admin)
  end
  
  test "should update c14 Measurement" do
    sign_in @admin
    patch c14_measurement_url(@c14_measurement), params: { c14_measurement: { bp: 2000 } }
    assert_redirected_to c14_measurement_url(@c14_measurement)
  end
  
  test "should have a version" do
    sign_in @admin
    assert @c14_measurement.respond_to?(:version)
  end
  
  test "should have a higher version number after update" do
     with_versioning do
       sign_in @admin
       patch c14_measurement_url(@c14_measurement), params: { c14_measurement: { bp: 2001 } }
       previous_version = @c14_measurement.versions.length
       patch c14_measurement_url(@c14_measurement), params: { c14_measurement: { bp: 2002 } }
       @c14_measurement.reload
       assert_equal @c14_measurement.versions.length, previous_version + 1
     end
  end
end
