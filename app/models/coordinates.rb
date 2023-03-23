class Coordinates
  attr_reader :latitude, :longitude

  def initialize(lng, lat)
    @longitude = lng
    @latitude = lat
  end

  def x_bearing
    return nil if longitude.blank?
    longitude < 0 ? "W" : "E"
  end

  def y_bearing
    return nil if latitude.blank?
    latitude < 0 ? "S" : "N"
  end

  def valid_longitude?
    longitude >= -180 && longitude <= 180
  end

  def valid_latitude?
    latitude >= -90 && latitude <= 90
  end

  def invalid_longitude?
    not valid_longitude?
  end

  def invalid_latitude?
    not valid_latitude?
  end

  def to_s(format = "dd")
    case format
    when "dd"
      format_dd
    when "dms"
      format_dms
    end
  end

  protected

  def dd_to_dms(dd)
    deg = dd.abs.floor
    min = (dd.abs % 1 * 60).floor
    sec = (min % 1 * 60).round
    return deg, min, sec
  end

  def format_coordinate_dd(coord, bearing)
    return "" if coord.blank?
    "#{'%07.3f' % coord.abs}° #{bearing}"
  end

  def format_coordinate_dms(deg, min, sec, bearing)
    "#{'%03d' % deg}° #{'%02d' % min}\' #{'%02d' % sec}\" #{bearing}"
  end

  private

  def format_dd
    format_coordinate_dd(latitude, y_bearing) + 
      ", " + 
      format_coordinate_dd(longitude, x_bearing)
  end

  def format_dms
    format_coordinate_dms(*dd_to_dms(latitude), x_bearing) +
      ", " +
      format_coordinate_dms(*dd_to_dms(longitude), y_bearing)
  end

end
