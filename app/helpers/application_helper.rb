module ApplicationHelper

  def to_dms(dd)
    minutes = dd%1.0*60
    seconds = minutes%1.0*60
    return dd.floor.to_s + "°" + minutes.floor.to_s + "'" + seconds.floor.to_s + "''"
  end

  def javascript_exists?(script)
    script = "#{Rails.root}/app/javascript/packs/#{params[:controller]}.js"
    File.exists?(script) || File.exists?("#{script}.coffee") 
  end

end

