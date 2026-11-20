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

  test "a superseded series redirects to its canonical record" do
    canonical = create(:dendro)
    superseded = create(:dendro)
    superseded.merge_into!(canonical)

    get dendro_path(superseded)
    assert_response :moved_permanently
    assert_redirected_to dendro_path(canonical)

    get dendro_citation_path(superseded, format: :json)
    assert_response :success
    assert_equal "xronos_dendro_#{canonical.id}", JSON.parse(response.body).fetch("id")
  end

  test "a contributor cannot change an existing sample or context while creating a series" do
    sign_in create(:user)
    sample = create(:sample, name: "Original sample")
    context = sample.context

    [
      { name: "Overwritten sample" },
      { context_attributes: { id: context.id, name: "Overwritten context" } }
    ].each do |attributes|
      assert_no_difference("Dendro.count") do
        post dendros_path, params: { dendro: {
          name: "New series",
          series_code: "TEST001",
          sample_id: sample.id,
          sample_attributes: attributes.merge(id: sample.id)
        } }
      end
      assert_response :not_found
    end
    assert_equal "Original sample", sample.reload.name
    assert_not_equal "Overwritten context", context.reload.name
  end

  test "the site CSV only includes series from the selected site" do
    included = create(:dendro)
    excluded = create(:dendro)

    get dendros_path(format: :csv, site_id: included.site.id)

    assert_response :success
    assert_includes response.body, included.series_code
    assert_not_includes response.body, excluded.series_code
  end

  test "undated measurements export positions without inferring a calendar year or unit" do
    dendro = create(:dendro, measurements: [{ position: 1, value: 0.147 }])

    get export_measurements_csv_dendro_path(dendro, format: :csv)

    assert_response :success
    assert_equal [%w[position calendar_year value measurement_variable measurement_unit],
                  ["1", nil, "0.147", nil, nil]], CSV.parse(response.body)
  end

  test "structured measurement JSON can be updated without changing its values" do
    sign_in create(:user, :admin)
    dendro = create(:dendro)
    measurements = [{ "position" => 1, "value" => 0.147 }, { "position" => 2, "value" => nil },
                    { "position" => 4, "value" => 0 }]

    patch dendro_path(dendro, format: :json), params: { dendro: { measurements: measurements } }, as: :json

    assert_response :success
    assert_equal measurements, dendro.reload.measurements
  end

  test "anchored series use the same positions and calendar years in HTML, CSV and JSON" do
    dendro = create(:dendro, :anchored, anchor_position: 2, anchor_year: 1,
                   measurement_variable: "ring_width", measurement_unit: "mm",
                   measurements: [{ position: 1, value: 0.5 }, { position: 2, value: 0 }])

    get dendro_path(dendro)
    assert_response :success
    assert_includes response.body, "1 BCE"
    assert_includes response.body, "1 CE"
    assert_includes response.body, "Ring width (mm)"

    get export_measurements_csv_dendro_path(dendro, format: :csv)
    assert_response :success
    assert_equal [["1", "0", "0.5", "ring_width", "mm"], ["2", "1", "0", "ring_width", "mm"]],
                 CSV.parse(response.body).drop(1)

    get dendro_path(dendro, format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal [2, 1], json.values_at("anchor_position", "anchor_year")
    assert_equal dendro.measurements, json.fetch("measurements")
  end

  test "series sort by calendar start without treating floating positions as years" do
    later = create(:dendro, :anchored, anchor_year: 1200)
    earlier = create(:dendro, :anchored, anchor_year: 1300, anchor_position: 201)
    floating = create(:dendro, is_anchored: false)

    get dendros_path, params: { dendros_order_by: "calendar_start_year" }

    assert_response :success
    links = Nokogiri::HTML(response.body).css("#dendros-table tbody tr").map do |row|
      row.at_css("a[href^='/dendros/']")["href"]
    end
    assert_equal [earlier, later, floating].map { |series| dendro_path(series) }, links
  end

  test "malformed measurement JSON is rejected before it can break the display" do
    sign_in create(:user, :admin)
    dendro = create(:dendro)

    patch dendro_path(dendro, format: :json), params: { dendro: { measurements: "invalid" } }, as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body).key?("measurements")
    assert_kind_of Array, dendro.reload.measurements
  end

  test "curators can search and filter Dendro issues" do
    sign_in create(:user, :admin)
    included = create(:dendro, name: "Oak series", waney_edge: nil)
    excluded = create(:dendro, name: "Oak complete", waney_edge: true)

    get "#{issues_dendros_path}/missing_waney_edge_info", params: { search: "Oak" }

    assert_response :success
    assert_includes response.body, included.name
    assert_not_includes response.body, excluded.name
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

  test "details collapse measurements and populated structured metadata by default" do
    chronology = Chronology.create!(name: "Reference chronology", parameters: { sample_depth: 8 })
    dendro = create(:dendro, chronology: chronology, object_dimensions: { width_mm: 42 },
                   wood_completeness: { sapwood_rings: 0 }, parameters: { detrended: false })

    get dendro_path(dendro)

    assert_response :success
    page = Nokogiri::HTML(response.body)
    values = page.at_css("details#dendro-values")
    assert values.at_css("table tbody tr")
    assert_nil values["open"]
    assert page.at_css("#dendro-plot [data-controller=vega]")
    sections = page.css("#dendro-measurement details, #dendro-chronology details")
    assert_equal ["Object dimensions", "Additional wood completeness details",
                  "Series processing details", "Chronology processing details"],
                 (sections.map { |section| section.at_css("summary").text.strip })
    assert_empty(sections.select { |section| section.key?("open") })
    assert_equal %w[42 0 false 8], (sections.map { |section| section.at_css("dd").text.strip })
  end

  test "project details show only the supplied project fields" do
    dendro = create(:dendro, project_title: "Oak study", project_start_date: Date.new(2024, 1, 15))

    get dendro_path(dendro)

    assert_response :success
    page = Nokogiri::HTML(response.body)
    section = page.css("#dendro-measurement h5").find { |heading| heading.text == "Project Details" }.parent
    assert_equal ["Project title", "Project start date"], section.css("dt").map(&:text)
    assert_equal ["Oak study", "2024-01-15"], section.css("dd").map(&:text)
  end

  test "empty structured metadata and missing series values leave no disclosures" do
    dendro = create(:dendro, measurements: [], chronology: Chronology.create!(name: "Reference chronology"))

    get dendro_path(dendro)

    assert_response :success
    page = Nokogiri::HTML(response.body)
    assert_empty page.css("#dendro-values, #dendro-measurement details, #dendro-chronology details")
    assert_not_includes page.at_css("#dendro-measurement").text, "Project Details"
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

  test "an update to identical series data requires merge confirmation" do
    sign_in create(:user, :admin)
    canonical = create(:dendro, measurement_variable: "ring_width", measurement_unit: "mm")
    other = create(:dendro, sample: canonical.sample, series_code: canonical.series_code,
                   measurement_variable: "ring_width", measurement_unit: "mm",
                   measurements: [{ position: 1, value: 9 }])
    attributes = { measurements: canonical.measurements }
    patch dendro_path(other, format: :json), params: { dendro: attributes }, as: :json
    assert_response :conflict
    assert_not other.reload.superseded?
    patch dendro_path(other, format: :json), params: { dendro: attributes, confirm_merge: true }, as: :json
    assert_response :success
    assert_equal canonical, other.reload.ultimately_superseded_by
  end

end
