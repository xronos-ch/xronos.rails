class CreateSamples < ActiveRecord::Migration[5.2]
  def change
    create_table :samples do |t|
			
      t.timestamps
    end
  end
end
