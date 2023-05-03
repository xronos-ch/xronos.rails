class CreateArticles < ActiveRecord::Migration[6.1]
  def change
    create_table :articles do |t|
      t.integer :section, null: false, index: true
      t.string :slug, index: { unique: true }
      t.string :title
      t.references :user, index: true
      t.datetime :published_at
      t.text :body

      t.timestamps
    end
  end
end
