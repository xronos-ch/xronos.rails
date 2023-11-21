class CreateSiteNames < ActiveRecord::Migration[7.0]
  def change
    create_table :site_names do |t|
      t.string :language
      t.string :name

      t.timestamps
    end

    add_reference :site_names, :site, foreign_key: true
  end
end
