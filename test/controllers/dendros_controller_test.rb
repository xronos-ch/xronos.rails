require "test_helper"

class DendrosControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "visitors can browse dendrochronological series" do
    dendro = create(:dendro)

    get dendros_path
    assert_response :success
    link = Nokogiri::HTML(response.body).at_css(%(a[href="#{dendro_path(dendro)}"]))
    assert_equal dendro.name, link&.text

    get dendro_path(dendro)
    assert_response :success
    assert_includes response.body, dendro.name
  end

  test "a signed-in contributor can add a series" do
    sign_in create(:user)
    sample = create(:sample)

    get new_dendro_path(site: sample.site)
    assert_response :success

    assert_difference("Dendro.count", 1) do
      post dendros_path, params: { dendro: {
        sample_id: sample.id, series_code: "TEST001", name: "Test series"
      } }
    end
    assert_redirected_to dendro_path(Dendro.find_by!(series_code: "TEST001"))
  end

  test "a contributor cannot modify or delete a series" do
    sign_in create(:user)
    dendro = create(:dendro, name: "Original series")

    patch dendro_path(dendro), params: { dendro: { name: "Changed series" } }
    assert_response :not_found
    assert_equal "Original series", dendro.reload.name

    assert_no_difference("Dendro.count") { delete dendro_path(dendro) }
    assert_response :not_found
  end

  test "an administrator can modify and delete a series" do
    sign_in create(:user, :admin)
    dendro = create(:dendro)

    get edit_dendro_path(dendro)
    assert_response :success

    patch dendro_path(dendro), params: { dendro: { name: "Updated series" } }
    assert_redirected_to dendro_path(dendro)
    assert_equal "Updated series", dendro.reload.name

    assert_difference("Dendro.count", -1) { delete dendro_path(dendro) }
    assert_redirected_to dendros_path
  end
end
