class AddRevisionCommentToVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :versions, :revision_comment, :text
  end
end
