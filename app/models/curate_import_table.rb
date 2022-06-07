class CurateImportTable < ApplicationRecord
  mount_uploader :file, CurateImportTableUploader

  belongs_to :user

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
      read_csv
    end
  end

  private

  def read_csv
    csv = CSV.parse(File.read(file.current_path), headers: true)
  end
end
