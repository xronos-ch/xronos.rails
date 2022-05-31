object @date
cache @date

attributes :id

glue :c14_measurement do
  glue :source_database do
    attributes :name => :source_database
  end
end

attributes :labnr

glue :c14_measurement do
  attributes :bp => :bp
  attributes :std => :std
  attributes :cal_bp => :cal_bp
  attributes :cal_std => :cal_std
  attributes :delta_c13 => :delta_c13
end

glue :lab do
  attributes :name => :lab_name
end

glue :sample do
  glue :arch_object do
    glue :site_phase do
      glue :site do
        attributes :name => :site
      end
    end
    glue :site_phase do
      attributes :name => :site_phase
      glue :site_type do
        attributes :name => :site_type
      end
    end
    glue :on_site_object_position do
      attributes :feature => :feature
      glue :feature_type
        attributes :name => :feature_type
    end
    glue :site_phase do
      child :periods do
        attributes :name => :period
      end
      child :typochronological_units do
        attributes :name => :typochronological_unit
      end
      child :ecochronological_units do
        attributes :name => :ecochronological_unit
      end
    end
    glue :material do
      attributes :name => :material
    end
    glue :species do
      attributes :name => :species
    end
    glue :site_phase do
      glue :site do
        glue :country do
          attributes :name => :country
        end
        attributes :lat => :lat
        attributes :lng => :lng
      end
    end
  end
end

child :reference do
  attributes :short_ref => :references
end
