namespace :cache do
  desc "Update sites with potential Wikidata matches in the cache"
  task update_sites_wikidata_match: :environment do
    puts "Starting cache update for potential Wikidata matches..."

    Site.find_in_batches(batch_size: 100) do |site_batch|
      site_batch.each_slice(25) do |site_chunk|
        begin
          # Extract site names for generating cache key
          site_names = site_chunk.map(&:name).compact.map(&:to_s)

          # Skip if the chunk is empty after sanitization
          next if site_names.empty?

          # Generate cache key for the chunk
          cache_key = Site.generate_cache_key(site_names)
          puts "Processing chunk with cache key: #{cache_key}"

          # Fetch Wikidata match candidates
          potential_matches = Site.wikidata_match_candidates_batch(site_chunk)

          # Write to cache
          Rails.cache.write(cache_key, potential_matches, expires_in: 24.hours)
        rescue => e
          puts "Failed to generate cache key for chunk: #{site_chunk.map(&:name).inspect}. Error: #{e.message}"
        end
      end
    end

    puts "Cache update complete."
  end
end