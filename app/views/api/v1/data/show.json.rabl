object @date => :measurement

attributes :id
attributes :lab_identifier => :labnr
attributes :bp => :bp
attributes :std => :std
attributes :cal_bp => :cal_bp
attributes :cal_std => :cal_std
attributes :delta_c13 => :delta_c13

glue :source_database do
  attributes :name => :source_database
end

glue :c14_lab do 
  attributes :name => :lab_name
end

glue :sample do
  glue :material do
    attributes :name => :material
  end
  glue :taxon do
    attributes :name => :species
  end
  glue :context do
    attributes :name => :feature
    node :feature_type do
      ""
    end
    glue :site do
      attributes :name => :site
      attributes :country_code => :country
      attributes :lat
      attributes :lng
      node :site_type do |site|
        site.site_types.first.name
      end
    end
    child :typos => :periods do
      attributes :name => :period
    end
    child :typos => :typochronological_units do
      attributes :name => :typochronological_unit
    end
    child :ecochronological_units do
      ""
    end
  end
end

child :references => :reference do
  attributes :short_ref => :references
end

