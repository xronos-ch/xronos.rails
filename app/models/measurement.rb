class Measurement < ApplicationRecord
  belongs_to :sample
  belongs_to :lab
  actable

  def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |result|
        csv << result.attributes.values_at(*column_names)
      end
    end
  end

end
