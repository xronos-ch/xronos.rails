class Curate::ImportTable < ApplicationRecord
  before_create :default_values
  before_destroy :delete_file

  mount_uploader :file, ImportTableUploader
  belongs_to :user

  attr_reader :parsed
  attr_reader :parse_errors
  attr_reader :mapping

  default_scope { order(id: :desc) }

  def read_options=(value)
    if value[:headers].present?
      value[:headers] = ActiveRecord::Type::Boolean.new.deserialize(value[:headers])
    end

    if value[:na_values].present?
      value[:na_values] = value[:na_values].split(",")
    end

    value = value.compact_blank
    super(value)
  end

  def read_options
    return nil if self[:read_options].nil?
    ropts = self[:read_options]
    ropts = ropts.symbolize_keys
    if ropts[:na_values].present?
      ropts[:na_values] = ropts[:na_values].join(",")
    end
    return ropts
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

  def generate_mapping
    return nil if @parsed.blank?
    return nil if @parsed.headers.blank?
    @mapping = mapping_aliases.transform_values { |mod|
      mod.transform_values { |attr|
        guess_mapping(@parsed.headers, attr)
      }
    }
  end

  private

  def read_csv
    ropts = read_options.slice(:headers, :col_sep, :row_sep, :quote_char, :na_values)

    if ropts.fetch(:headers, {}) != true
      ropts = ropts.except(:headers)
      ncol = CSV.new(File.read(file.current_path), &ropts).first.count
      ropts[:headers] = Array(1..ncol)
    end

    if ropts.fetch(:row_sep, {}) == "auto"
      ropts[:row_sep] = :auto
    end

    if ropts.fetch(:na_values, {}).present?
      init_missing_converter(ropts[:na_values])
      ropts[:converters] = [:missing]
      ropts = ropts.except(:na_values)
    end

    begin
      csv = CSV.parse(File.read(file.current_path), **ropts)
    rescue CSV::MalformedCSVError => e
      @parse_errors = e
      return nil
    end

    return csv
  end

  def init_missing_converter(na_values)
    CSV::Converters[:missing] = lambda { |x|
      if x.nil?
        nil
      elsif na_values.include?(x)
        nil
      else
        x
      end
    }
  end

  def default_values
    self.imported_at ||= DateTime.now
    self.read_options ||= default_read_options
  end

  def default_read_options_csv
    {
      headers: true,
      col_sep: ",",
      row_sep: :auto,
      quote_char: '"',
      na_values: nil
    }
  end

  def guess_mapping(headers, aliases)
    headers.select { |header|
      aliases.include? comparable(header)
    }.first
  end

  def comparable(x)
    x
      .downcase
      .delete(" ")
      .delete("_")
      .delete("-")
      .delete(":")
      .delete(";")
  end

  def mapping_aliases
    aliases = {
      sites: {
        name: ["site name", "site", "name"],
        lat: ["lat", "latitude", "y", "y coord", "y coordinate"],
        lng: ["lng", "lon", "long", "longitude", "x", "x coord", "x coordinate"],
        country_code: ["country code", "country", "alpha2"],
        short_ref: ["source", "reference", "sources", "references", "ref", "refs", "citation", "citations"]
      },
      site_types: {
        name: ["site type", "type"],
        description: ["site type", "type"]
      },
      contexts: {
        name: ["context", "site context", "locus", "phase", "site phase", "phase code", "layer", "level"],
      },
      materials: {
        name: ["material", "sample material"]
      },
      taxons: {
        name: ["taxon", "species", "taxa", "sample taxon", "sample species", "sample taxa"]
      },
      samples: {
        position_description: ["sample", "sample location", "sample position", "position"],
        position_x: ["position x", "sample x"],
        position_y: ["position y", "sample y"],
        position_z: ["position z", "sample z", "depth", "sample depth", "elevation", "sample elevation"],
        position_crs: ["position crs"]
      },
      c14s: {
        lab_identifier: ["lab identifier", "lab code", "lab id", "lab number", "lab num", "lab no", "lab nr"],
        bp: ["bp", "cra", "age", "c14 age", "14c age", "c14 val", "c14", "14c", "uncal bp", "date", "r date"],
        std: ["std", "c14 std", "error", "c14 error", "sigma", "±", "1σ", "σ", "stdev"],
        delta_c13: ["d13c", "𝛿13c", "dc13", "𝛿c13", "delta c13", "c13", "c13 val", "13c", "13c val"],
        delta_c13_std: ["d13c std", "d13c error", "𝛿13c std", "c13 std", "c13 error", "13c std", "13c error", "𝛿13c error"],
        method: ["method", "dating method", "date method", "c14 method", "ams"],
        short_ref: ["source", "reference", "sources", "references", "ref", "refs", "citation", "citations"]
      },
      typos: {
        name: ["period", "periods", "typochronological unit", "typochronology"],
        short_ref: ["source", "reference", "sources", "references", "ref", "refs", "citation", "citations"]
      }
    }
    aliases.deep_transform_values { |a| comparable(a) }
  end
end
