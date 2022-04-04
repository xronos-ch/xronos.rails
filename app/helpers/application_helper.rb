module ApplicationHelper

  def to_dms(dd, axis)
    minutes = dd%1.0*60
    seconds = minutes%1.0*60
    suffix = case
             when (dd<0 && axis=="lon")
               "W"
             when (dd>=0 && axis=="lon")
               "E"
             when (dd<0 && axis=="lat")
               "S"
             when (dd>0 && axis=="lat")
               "N"
             else
               "Can not determine N/E/S/W"
             end

    return dd.abs.floor.to_s + "° " + minutes.floor.to_s + "' " + seconds.floor.to_s + '" ' + suffix
  end

  def javascript_exists?(script)
    script = "#{Rails.root}/app/javascript/packs/#{params[:controller]}.js"
    File.exists?(script) || File.exists?("#{script}.coffee") || File.exists?("#{script}.erb") 
  end

end


