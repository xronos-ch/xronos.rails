class AddPartOfOrganismToSamples < ActiveRecord::Migration[8.0]
  def change
    add_column :samples, :part_of_organism, :text
  end
end
