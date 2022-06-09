class Curate::ImportTable < ApplicationRecord
  before_create :default_values
  before_destroy :delete_file

  mount_uploader :file, ImportTableUploader
  belongs_to :user

  attr_reader :parse_errors
  attr_reader :parsed

  default_scope { order(id: :desc) }

  def read_options=(value)
    if value[:headers].present?
      value[:headers] = ActiveRecord::Type::Boolean.new.deserialize(value[:headers])
    end
    value = value.compact_blank
    super(value)
  end

  def read_options
    return nil if self[:read_options].nil?
    self[:read_options].symbolize_keys
      #.transform_values { |v| v.is_a?(String) ? v.undump : v }
  end

  def file_name
    file.identifier
  end

  def file_ext
    File.extname(file.current_path)
  end

  def file_type
    case file_ext
    when ".csv"
      "Comma-separated values (CSV)"
    end
  end

  def file_size
    File.size(file.current_path)
  end

  def read
    case file_ext
    when ".csv" 
      parsed = read_csv
    else
      parsed = nil
    end

    unless parsed.nil?
      @parsed = parsed
    end
  end

  def preview
    return nil if @parsed.nil?
    @parsed.to_a.drop(1)
  end

  def default_read_options(ext = file_ext)
    case ext
    when ".csv"
      default_read_options_csv
    else
      default_read_options_csv
    end
  end

  def delete_file
    File.delete(file.current_path)
  end

  def guess_mapping
    return nil if @parsed.blank?
    return nil if @parsed.headers.blank?
  end

  private

  def read_csv
    ropts = read_options.slice(:headers, :col_sep, :row_sep, :quote_char)

    if ropts.fetch(:headers, {}) != true
      ropts = ropts.except(:headers)
      ncol = CSV.new(File.read(file.current_path), &ropts).first.count
      ropts[:headers] = Array(1..ncol)
    end

    if ropts.fetch(:row_sep, {}) == "auto"
      ropts[:row_sep] = :auto
    end

    begin
      csv = CSV.parse(File.read(file.current_path), **ropts)
    rescue CSV::MalformedCSVError => e
      @parse_errors = e
      return nil
    end

    return csv
  end

  def default_values
    self.imported_at ||= DateTime.now
    self.read_options ||= default_read_options
    self.mapping ||= guess_mapping
  end

  def default_read_options_csv
    {
      headers: true,
      col_sep: ",",
      row_sep: :auto,
      quote_char: '"',
      na_values: ['""']
    }
  end
end
