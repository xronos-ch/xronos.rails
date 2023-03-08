namespace :taxons do
  desc "Control all taxons (exact match to GBIF Backbone Taxonomy)"
  task recontrol: :environment do
    Taxon.find_each do |taxon|
      taxon.control
      taxon.save
    end
  end

end
