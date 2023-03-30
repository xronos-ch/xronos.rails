class LabId
  attr_reader :lab_identifier, :lab_code, :lab_number

  PATTERN = '^([[:alpha:]\(\)\/]{1,8})[ -\u2010\u2013_#\.\+](\d*[A-Z]?)$'

  def initialize(lab_identifier)
    @lab_identifier = lab_identifier
    if lab_identifier.match?(PATTERN)
      @lab_code = lab_identifier[Regexp.new(PATTERN), 1]
      @lab_number = lab_identifier[Regexp.new(PATTERN), 2]
    end
  end

  def valid?
    @lab_identifier.match?(PATTERN)
  end

  def invalid?
    not valid?
  end

  def to_s
    return @lab_identifier unless @lab_code.present? and @lab_number.present?
    @lab_code + "-" + @lab_number
  end

  protected

  def extract_lab_code(lab_id)
  end

  def extract_lab_number(lab_id)
  end

end
