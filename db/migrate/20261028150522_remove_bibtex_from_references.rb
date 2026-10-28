class RemoveBibtexFromReferences < ActiveRecord::Migration[8.0]
  def up
    remove_column :references, :bibtex, :text
  end

  def down
    add_column :references, :bibtex, :text

    Reference.find_each do |ref|
      next if ref.csl.blank?

      ref.update_columns(bibtex: ref.format_bibtex)
    rescue => e
      Rails.logger.warn("Failed to regenerate BibTeX for reference #{ref.id}: #{e.message}")
    end
  end
end
