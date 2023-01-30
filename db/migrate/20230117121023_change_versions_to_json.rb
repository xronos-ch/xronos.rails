class ChangeVersionsToJson < ActiveRecord::Migration[6.1]
  def change
    # see https://github.com/paper-trail-gem/paper_trail/blob/f348708f15075f7597bd1a94ff94776b90979a96/CHANGELOG.md#1400-2022-11-26
    add_column :versions, :new_object, :jsonb
    add_column :versions, :new_object_changes, :jsonb

    PaperTrail::Version.where.not(object: nil).find_each do |version|
      version.update_column(:new_object, YAML.load(version.object))
      if version.object_changes
        version.update_column(
          :new_object_changes,
          YAML.load(version.object_changes)
        )
      end
    end

    remove_column :versions, :object_changes
    rename_column :versions, :new_object_changes, :object_changes
  end
end
