class AddPhysicalLocationRelationBetweenSitesAndCountries < ActiveRecord::Migration[5.2]
  def change
    create_table :physical_locations do |t|
      t.belongs_to :site, index: true
      t.belongs_to :country, index: true
      t.timestamps
    end
  end
end
