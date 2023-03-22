class AddPublishedToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :publish, :boolean, default: false
  end
end
