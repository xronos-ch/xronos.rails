class C14::LabIdentifier
  attr_reader :lab_code, :lab_number

  PATTERN = /^([[:alpha:]\(\)\/]{1,8})[ -\u2010\u2013_#\.\+](\d*[A-Z]?)$/

  def initialize(lab_identifier)
    @raw_lab_id = lab_identifier
    if lab_identifier.match?(PATTERN)
      @lab_code = lab_identifier[PATTERN, 1]
      @lab_number = lab_identifier[PATTERN, 2]
    end
  end

  def valid?
    @raw_lab_id.match?(PATTERN)
  end

  def to_s
    return @raw_lab_id unless @lab_code.present? and @lab_number.present?
    @lab_code + "-" + @lab_number
  end

  protected

  def extract_lab_code(lab_id)
  end

  def extract_lab_number(lab_id)
  end

end
