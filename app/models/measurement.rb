class Measurement < ApplicationRecord
  belongs_to :sample
  belongs_to :lab
  actable

  def self.to_csv
    CSV.generate do |csv|
      csv << ["labnr", "site", "site_type"]
      all.each do |item|
        csv << [item.labnr] + [item.site] + [item.site_type]
      end
    end
  end

end
