# frozen_string_literal: true

namespace :xronos do
  namespace :search do
    desc 'Remove search documents for superseded or missing records'
    task cleanup: :environment do
      removed = [Site, C14, Reference].sum do |model|
        documents = PgSearch::Document.where(searchable_type: model.name)
        documents.where.not(searchable_id: model.select(:id))
                 .or(documents.where(searchable_id: nil))
                 .delete_all
      end

      puts "Removed #{removed} stale search documents."
    end
  end
end
