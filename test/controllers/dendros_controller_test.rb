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

    get site_path(dendro.site)
    assert_response :success
    section = Nokogiri::HTML(response.body).at_css("#site-dendros")
    assert section&.at_css(%(a[href="#{dendro_path(dendro)}"]))
  end

  test "the series list directs contributors to a site before starting a new series" do
    sign_in create(:user)
    site = create(:site)

    get dendros_path
    assert_response :success
    assert Nokogiri::HTML(response.body).at_css(%(a[href="#{new_dendro_path}"]))

    get new_dendro_path
    assert_redirected_to sites_path

    get site_path(site)
    assert_response :success
    assert Nokogiri::HTML(response.body).at_css(%(a[href="#{new_dendro_path(site: site)}"]))

    get new_dendro_path(site: site)
    assert_response :success
    field = Nokogiri::HTML(response.body).at_css('input[name="dendro[sample_attributes][context_attributes][site_id]"]')
    assert_equal site.id.to_s, field&.[]("value")
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

  test "editing the series name preserves structured metadata" do
    sign_in create(:user, :admin)
    metadata = { object_dimensions: { "width_mm" => 42 }, wood_completeness: nil, parameters: {} }
    dendro = create(:dendro, **metadata)

    get edit_dendro_path(dendro)
    assert_response :success
    form = Nokogiri::HTML(response.body).at_css("form#dendroForm")
    assert form
    metadata.each_key do |field|
      assert_nil form.at_css(%([name="dendro[#{field}]"]))
      assert_nil form.at_css(%([name="dendro[#{field}_json]"]))
    end

    patch dendro_path(dendro), params: { dendro: { name: "Renamed series" } }

    assert_redirected_to dendro_path(dendro)
    assert_equal "Renamed series", dendro.reload.name
    assert_equal metadata.stringify_keys, dendro.attributes.slice(*metadata.keys.map(&:to_s))
  end

  test "an administrator can modify and delete a series" do
    sign_in create(:user, :admin)
    dendro = create(:dendro)

    get edit_dendro_path(dendro)
    assert_response :success

    patch dendro_path(dendro), params: { dendro: {
      name: "Updated series",
      sample_attributes: {
        id: dendro.sample.id,
        name: "Updated sample",
        part_of_organism: "Stem",
        context_attributes: { id: dendro.context.id, site_id: dendro.site.id }
      }
    } }
    assert_redirected_to dendro_path(dendro)
    assert_equal "Updated series", dendro.reload.name
    assert_equal "Updated sample", dendro.sample.name
    assert_equal "Stem", dendro.sample.part_of_organism

    assert_difference("Dendro.count", -1) { delete dendro_path(dendro) }
    assert_redirected_to dendros_path
  end
end
