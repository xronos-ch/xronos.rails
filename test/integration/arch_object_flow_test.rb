require 'test_helper'

class ArchObjectFlowTest < Capybara::Rails::TestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = FactoryBot.create(:user, :admin)
  end

  test 'creating a new arch_object (full info set)' do
    sign_in @admin
    visit arch_objects_path
    click_on "left_window_nav_general"

    click_on 'New Arch Object'

    # Samples > Measurements
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][labnr]', with: 'AAA-123'

    # Samples > Measurements > C14Measurement
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][bp]', with: 2345
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][std]', with: 12
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][cal_bp]', with: 2345
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][cal_std]', with: 12
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][delta_c13]', with: 30
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][delta_c13_std]', with: 10
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][method]', with: "AMS"

    # Samples > Measurements > C14Measurement > SourceDatabase
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][source_database_attributes][name]', with: "Testdatabase"
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][source_database_attributes][url]', with: "www.testdatabase.tw"
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][source_database_attributes][citation]', with: "Angelbrot/Zipperlein 1993"
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][c14_measurement_attributes][source_database_attributes][licence]', with: "CC0"

    # Samples > Measurements > Lab
    fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][lab_attributes][name]', with: "Black Mesa Research Facility"
    #fill_in 'arch_object[samples_attributes][0][measurements_attributes][0][lab_attributes][active]', with: true

    # Samples > Measurements > References
    # broken
    #click_on 'add reference'
    #first('input[id^="arch_object_samples_attributes_0_measurements_attributes_0_references_attributes_"][id$="_short_ref"]').set("Dirac 1981")
    #first('input[id^="arch_object_samples_attributes_0_measurements_attributes_0_references_attributes_"][id$="_bibtex"]').set("@book{dirac,
    #  title={The Principles of Quantum Mechanics},
    #  author={Paul Adrien Maurice Dirac},
    #  series={International series of monographs on physics},
    #  year={1981},
    #  publisher={Clarendon Press},
    #}")

    # Material
    fill_in 'arch_object[material_attributes][name]', with: "Plutonium"

    # Species
    fill_in "arch_object[species_attributes][name]", with: "Headcrab"

    # SitePhase
    fill_in "arch_object[site_phase_attributes][name]", with: "City 17 before Freeman"
    fill_in "arch_object[site_phase_attributes][approx_start_time]", with: 2500
    fill_in "arch_object[site_phase_attributes][approx_end_time]", with: 2000

    # SitePhase > Periods
    click_on 'add period'
    first('input[id^="arch_object_site_phase_attributes_periods_attributes"][id$="name"]').set("Opposing Force")
    first('input[id^="arch_object_site_phase_attributes_periods_attributes"][id$="approx_start_time"]').set(2400)
    first('input[id^="arch_object_site_phase_attributes_periods_attributes"][id$="approx_end_time"]').set(2100)

    # SitePhase > TypochronologicalUnits
    click_on 'add typochronological_unit'
    first('input[id^="arch_object_site_phase_attributes_typochronological_units_attributes"][id$="name"]').set("Blue Shift")
    first('input[id^="arch_object_site_phase_attributes_typochronological_units_attributes"][id$="approx_start_time"]').set(2400)
    first('input[id^="arch_object_site_phase_attributes_typochronological_units_attributes"][id$="approx_end_time"]').set(2200)

    # SitePhase > EcochronologicalUnits
    click_on 'add ecochronological_unit'
    first('input[id^="arch_object_site_phase_attributes_ecochronological_units_attributes"][id$="name"]').set("Decay")
    first('input[id^="arch_object_site_phase_attributes_ecochronological_units_attributes"][id$="approx_start_time"]').set(3000)
    first('input[id^="arch_object_site_phase_attributes_ecochronological_units_attributes"][id$="approx_end_time"]').set(1000)

    # SitePhase > SiteType
    fill_in "arch_object[site_phase_attributes][site_type_attributes][name]", with: "City"
    fill_in "arch_object[site_phase_attributes][site_type_attributes][description]", with: "Megacity of the 21st century AD"

    # SitePhase > Site
    fill_in "arch_object[site_phase_attributes][site_attributes][name]", with: "City 17"
    fill_in "arch_object[site_phase_attributes][site_attributes][lat]", with: 17
    fill_in "arch_object[site_phase_attributes][site_attributes][lng]", with: 17

    # SitePhase > Site > Country
    fill_in "arch_object[site_phase_attributes][site_attributes][country_attributes][name]", with: "Earth"

    # SitePhase > Site > FellPhases
    click_on 'add fell_phase'
    first('input[id^="arch_object_site_phase_attributes_site_attributes_fell_phases_attributes"][id$="name"]').set("A234-B76s")
    first('input[id^="arch_object_site_phase_attributes_site_attributes_fell_phases_attributes"][id$="start_time"]').set(2450)
    first('input[id^="arch_object_site_phase_attributes_site_attributes_fell_phases_attributes"][id$="end_time"]').set(2400)

    # SitePhase > Site > FellPhases > References
    # broken
    #click_on 'add reference'
    #fill_in 'arch_object[site_phase_attributes][site_attributes][fell_phases_attributes][1568364017591][references_attributes][1568364329345][short_ref]', with: "Dirac 1981"
    #fill_in 'arch_object[site_phase_attributes][site_attributes][fell_phases_attributes][1568364017591][references_attributes][1568364329345][bibtex]', with: "@book{dirac,
    #  title={The Principles of Quantum Mechanics},
    #  author={Paul Adrien Maurice Dirac},
    #  series={International series of monographs on physics},
    #  year={1981},
    #  publisher={Clarendon Press},
    #}"

    # OnSiteObjectPosition
    fill_in "arch_object[on_site_object_position_attributes][feature]", with: "Citadel"
    fill_in "arch_object[on_site_object_position_attributes][site_grid_square]", with: "A34"
    fill_in "arch_object[on_site_object_position_attributes][coord_reference_system]", with: "local"
    fill_in "arch_object[on_site_object_position_attributes][coord_X]", with: 117.83
    fill_in "arch_object[on_site_object_position_attributes][coord_Y]", with: 154.71
    fill_in "arch_object[on_site_object_position_attributes][coord_Z]", with: 99.39

    # OnSiteObjectPosition > FeatureType
    fill_in "arch_object[on_site_object_position_attributes][feature_type_attributes][name]", with: "Headquarter"
    fill_in "arch_object[on_site_object_position_attributes][feature_type_attributes][description]", with: "Where the Combine govern the Earth."

    # submit
    click_on 'Create Arch object'

    assert_current_path arch_object_path(ArchObject.last)
    assert has_content?('Arch object was successfully created.')
  end

end
