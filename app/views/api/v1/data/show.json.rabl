object @date
cache @date
attributes :id, :labnr

child :c14_measurement do
  attributes :bp, :std, :cal_bp, :cal_std, :delta_c13
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
