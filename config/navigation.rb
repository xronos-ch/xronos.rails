# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  #navigation.renderer = Your::Custom::Renderer

  # Specify the class that will be applied to active navigation items. Defaults to 'selected' 
  #navigation.selected_class = 'selected'

  # Specify the class that will be applied to the current leaf of
  # active navigation items. Defaults to 'simple-navigation-active-leaf'
  #navigation.active_leaf_class = 'simple-navigation-active-leaf'

  # Specify if item keys are added to navigation items as id. Defaults to true
  #navigation.autogenerate_item_ids = true

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  #navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that
  # will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  #navigation.name_generator = Proc.new {|name, item| "<span>#{name}</span>"}

  # Specify if the auto highlight feature is turned on (globally, for the whole navigation). Defaults to true
  #navigation.auto_highlight = true
  
  # Specifies whether auto highlight should ignore query params and/or anchors when 
  # comparing the navigation items with the current URL. Defaults to true 
  #navigation.ignore_query_params_on_auto_highlight = true
  #navigation.ignore_anchors_on_auto_highlight = true
  
  # If this option is set to true, all item names will be considered as safe (passed through html_safe). Defaults to false.
  #navigation.consider_item_names_as_safe = false

  # Define the primary navigation
  navigation.items do |primary|
    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #           some special options that can be set:
    #           :if - Specifies a proc to call to determine if the item should
    #                 be rendered (e.g. <tt>if: -> { current_user.admin? }</tt>). The
    #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :unless - Specifies a proc to call to determine if the item should not
    #                     be rendered (e.g. <tt>unless: -> { current_user.admin? }</tt>). The
    #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :method - Specifies the http-method for the generated link - default is :get.
    #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
    #                            when the item should be highlighted, you can set a regexp which is matched
    #                            against the current URI.  You may also use a proc, or the symbol <tt>:subpath</tt>.
    #
    primary.item :data, 'data', root_path do |data|
      data.item :labs, 'labs', labs_path do |i|
        i.item :lab, 'new lab', new_lab_path
        i.item :lab, 'show lab', lambda {lab_path(@lab)}, :unless => lambda {@lab.nil?}
        i.item :lab, 'edit lab', lambda {edit_lab_path(@lab)}, :unless => lambda {@lab.nil?}
      end
      data.item :measurements, 'measurements', measurements_path do |i|
        i.item :measurement, 'new measurement', new_measurement_path
        i.item :measurement, 'show measurement', lambda {measurement_path(@measurement)}, :unless => lambda {@measurement.nil?}
        i.item :measurement, 'edit measurement', lambda {edit_measurement_path(@measurement)}, :unless => lambda {@measurement.nil?}
      end
      data.item :samples, 'samples', samples_path do |i|
        i.item :sample, 'new sample', new_sample_path
        i.item :sample, 'show sample', lambda {sample_path(@sample)}, :unless => lambda {@sample.nil?}
        i.item :sample, 'edit sample', lambda {edit_sample_path(@sample)}, :unless => lambda {@sample.nil?}
      end
      data.item :arch_objects, 'arch_objects', arch_objects_path do |i|
        i.item :arch_object, 'new arch_object', new_arch_object_path
        #i.item :arch_object, 'show arch_object', lambda {arch_object_path(@arch_object)}, :unless => lambda {@arch_object.nil?}
        #i.item :arch_object, 'edit arch_object', lambda {edit_arch_object_path(@arch_object)}, :unless => lambda {@arch_object.nil?}
      end
      data.item :references, 'references', references_path do |i|
        i.item :reference, 'new reference', new_reference_path
        i.item :reference, 'show reference', lambda {reference_path(@reference)}, :unless => lambda {@reference.nil?}
        i.item :reference, 'edit reference', lambda {edit_reference_path(@reference)}, :unless => lambda {@reference.nil?}
      end
      data.item :species, 'species', species_index_path do |i|
        i.item :species, 'new species', new_species_path
        i.item :species, 'show species', lambda {species_path(@species)}, :unless => lambda {@species.nil?}
        i.item :species, 'edit species', lambda {edit_species_path(@species)}, :unless => lambda {@species.nil?}
      end
      data.item :materials, 'materials', materials_path do |i|
        i.item :material, 'new material', new_material_path
        i.item :material, 'show material', lambda {material_path(@material)}, :unless => lambda {@material.nil?}
        i.item :material, 'edit material', lambda {edit_material_path(@material)}, :unless => lambda {@material.nil?}
      end
      data.item :feature_types, 'feature_types', feature_types_path do |i|
        i.item :feature_type, 'new feature_type', new_feature_type_path
        #i.item :feature_type, 'show feature_type', lambda {feature_type_path(@feature_type)}, :unless => lambda {@feature_type.nil?}
        #i.item :feature_type, 'edit feature_type', lambda {edit_feature_type_path(@feature_type)}, :unless => lambda {@feature_type.nil?}
      end
      data.item :on_site_object_positions, 'on_site_object_positions', on_site_object_positions_path do |i|
        i.item :on_site_object_position, 'new on_site_object_position', new_on_site_object_position_path
        i.item :on_site_object_position, 'show on_site_object_position', lambda {on_site_object_position_path(@on_site_object_position)}, :unless => lambda {@on_site_object_position.nil?}
        i.item :on_site_object_position, 'edit on_site_object_position', lambda {edit_on_site_object_position_path(@on_site_object_position)}, :unless => lambda {@on_site_object_position.nil?}
      end
      data.item :site_types, 'site_types', site_types_path do |i|
        i.item :site_type, 'new site_type', new_site_type_path
        i.item :site_type, 'show site_type', lambda {site_type_path(@site_type)}, :unless => lambda {@site_type.nil?}
        i.item :site_type, 'edit site_type', lambda {edit_site_type_path(@site_type)}, :unless => lambda {@site_type.nil?}
      end
      data.item :countries, 'countries', countries_path do |i|
        i.item :country, 'new country', new_country_path
        i.item :country, 'show country', lambda {country_path(@country)}, :unless => lambda {@country.nil?}
        i.item :country, 'edit country', lambda {edit_country_path(@country)}, :unless => lambda {@country.nil?}
      end
      data.item :periods, 'periods', periods_path do |i|
        i.item :period, 'new period', new_period_path
        i.item :period, 'show period', lambda {period_path(@period)}, :unless => lambda {@period.nil?}
        i.item :period, 'edit period', lambda {edit_period_path(@period)}, :unless => lambda {@period.nil?}
      end
      data.item :sites, 'sites', sites_path do |i|
        i.item :site, 'new site', new_site_path
        i.item :site, 'show site', lambda {site_path(@site)}, :unless => lambda {@site.nil?}
        i.item :site, 'edit site', lambda {edit_site_path(@site)}, :unless => lambda {@site.nil?}
      end
      data.item :typochronological_units, 'typochronological_units', typochronological_units_path do |i|
        i.item :typochronological_unit, 'new typochronological_unit', new_typochronological_unit_path
        i.item :typochronological_unit, 'show typochronological_unit', lambda {typochronological_unit_path(@typochronological_unit)}, :unless => lambda {@typochronological_unit.nil?}
        i.item :typochronological_unit, 'edit typochronological_unit', lambda {edit_typochronological_unit_path(@typochronological_unit)}, :unless => lambda {@typochronological_unit.nil?}
      end
      data.item :ecochronological_units, 'ecochronological_units', ecochronological_units_path do |i|
        i.item :ecochronological_unit, 'new ecochronological_unit', new_ecochronological_unit_path
        i.item :ecochronological_unit, 'show ecochronological_unit', lambda {ecochronological_unit_path(@ecochronological_unit)}, :unless => lambda {@ecochronological_unit.nil?}
        i.item :ecochronological_unit, 'edit ecochronological_unit', lambda {edit_ecochronological_unit_path(@ecochronological_unit)}, :unless => lambda {@ecochronological_unit.nil?}
      end
      data.item :site_phases, 'site_phases', site_phases_path do |i|
        i.item :site_phase, 'new site_phase', new_site_phase_path
        i.item :site_phase, 'show site_phase', lambda {site_phase_path(@site_phase)}, :unless => lambda {@site_phase.nil?}
        i.item :site_phase, 'edit site_phase', lambda {edit_site_phase_path(@site_phase)}, :unless => lambda {@site_phase.nil?}
      end
    end

		primary.item :api, 'api', api_path
		primary.item :about, 'about', about_path

    # Add an item which has a sub navigation (same params, but with block)
    #primary.item :key_2, 'name', url, options do |sub_nav|
      # Add an item to the sub navigation (same params again)
    #  sub_nav.item :key_2_1, 'name', url, options
    #end

    # You can also specify a condition-proc that needs to be fullfilled to display an item.
    # Conditions are part of the options. They are evaluated in the context of the views,
    # thus you can use all the methods and vars you have available in the views.
    #primary.item :key_3, 'Admin', url, class: 'special', if: -> { current_user.admin? }
    #primary.item :key_4, 'Account', url, unless: -> { logged_in? }

    # you can also specify html attributes to attach to this particular level
    # works for all levels of the menu
    #primary.dom_attributes = {id: 'menu-id', class: 'menu-class'}

    # You can turn off auto highlighting for a specific level
    #primary.auto_highlight = false
  end
end
