class AddSplashAttributionToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :splash_attribution, :string
  end
end
