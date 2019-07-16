class Measurement < ApplicationRecord
  belongs_to :sample
  belongs_to :lab
  actable

  def self.to_csv
    CSV.generate do |csv|
      csv << ["labnr", "site", "site_type", "lat", "lng", "country", "feature", "material", "species"]
      all.each do |item|
        csv << [item.labnr] + [item.site] + [item.site_type] +
            [item.lat] + [item.lng] + [item.country] + [item.feature] +
            [item.material] + [item.species]
      end
    end
  end

end
