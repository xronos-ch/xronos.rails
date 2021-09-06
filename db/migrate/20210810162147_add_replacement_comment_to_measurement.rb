class AddReplacementCommentToMeasurement < ActiveRecord::Migration[6.1]
  def change
    add_column :measurements, :replacement_comment, :text
  end
end
