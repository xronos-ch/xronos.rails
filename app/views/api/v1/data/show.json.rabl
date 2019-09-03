object @date
cache @date
attributes :id, :labnr

glue :c14_measurement do
  attributes :bp => :c14_measurement_bp
  attributes :std => :c14_measurement_std
  attributes :cal_bp => :c14_measurement_cal_bp
  attributes :cal_std => :c14_measurement_cal_std
  attributes :delta_c13 => :c14_measurement_delta_c13
end

glue :lab do
  attributes :name => :lab_name
end

glue :sample do
  glue :arch_object do
    glue :on_site_object_position do
      attributes :feature
    end
    glue :site_phase do
      attributes :name => :site_phase
      glue :site_type do
        attributes :name => :site_phase_type
      end
      glue :site do
        attributes :name => :site
        attributes :lat => :lat
        attributes :lng => :lng
      end
    end
  end
end
