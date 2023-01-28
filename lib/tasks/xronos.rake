namespace :xronos do
  desc "Rebuild pg_search multisearch documents for all models"
  task rebuild_pg_search: :environment do
    unless Rails.application.config.cache_classes
      Rails.application.eager_load!
    end
    ApplicationRecord.descendants.each do |model_class|
      if model_class.respond_to?(:pg_search_multisearchable_options)
        puts "Rebuilding pg_search documents for #{model_class.model_name.plural}..."
        PgSearch::Multisearch.rebuild(model_class)
      end
    end
  end

end
