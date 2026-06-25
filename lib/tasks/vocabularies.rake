require 'digest'
require 'open-uri'
require 'yaml'

require 'obo/parser'

namespace :xronos do
  namespace :vocabularies do
    ONTOLOGIES_CONFIG_PATH = Rails.root.join('db/data/ontologies.yml').freeze unless defined?(ONTOLOGIES_CONFIG_PATH)

    desc 'Fetch the source OBO files for our controlled vocabularies into db/data/ontologies/'
    task fetch: :environment do
      config = YAML.load_file(ONTOLOGIES_CONFIG_PATH)

      config.each do |vocabulary_name, sources|
        sources.each do |source_key, source|
          fetch_source(vocabulary_name, source_key, source)
        end
      end

      puts
      puts 'Done. Review git diff and commit db/data/ontologies/ + ontologies.yml.'
    end

    def fetch_source(vocabulary_name, source_key, source)
      source_url = source.fetch('source')
      dest_path  = Rails.root.join(source.fetch('path'))

      puts "== #{vocabulary_name} / #{source_key} =="
      puts "Source: #{source_url}"
      puts "Target: #{dest_path}"

      if dest_path.exist?
        cached_version = read_data_version(dest_path)
        if cached_version == source['version']
          puts "Local copy is up to date (#{cached_version}). Skipping."
          puts
          return
        end
        puts "Local copy is #{cached_version.inspect}; expected #{source['version'].inspect}; refreshing."
      end

      download = URI.open(source_url) # rubocop:disable Security/Open
      tmp_path = dest_path.to_path + '.tmp'
      File.binwrite(tmp_path, download.read)
      new_version = read_data_version(tmp_path)
      new_sha256  = Digest::SHA256.hexdigest(File.read(tmp_path))

      if source['version'] && new_version != source['version']
        abort("Fetched file data-version #{new_version.inspect} does not match ontologies.yml " \
              "version #{source['version'].inspect}. Update ontologies.yml or revisit the source URL.")
      end

      File.rename(tmp_path, dest_path)

      puts "Downloaded version: #{new_version}"
      puts "SHA-256:            #{new_sha256}"
      puts 'Update db/data/ontologies.yml if the version or sha256 differ from the committed values.'
      puts
    end

    def read_data_version(path)
      File.foreach(path).find { |l| l.start_with?('data-version:') }
          &.split(':', 2)&.last&.strip
    end

    desc 'Seed the part_of_organism controlled vocabulary from the vendored OBO files (DRY_RUN=true by default; pass DRY_RUN=false to mutate)'
    task seed_part_of_organism: :environment do
      dry_run = ENV['DRY_RUN'] != 'false'

      config = YAML.load_file(ONTOLOGIES_CONFIG_PATH)
      sources = config.fetch('part_of_organism')

      puts '== Seed part_of_organism vocabulary =='
      puts "Dry run: #{dry_run}"
      puts

      sources.each do |source_key, source|
        seed_source(source_key, source, dry_run: dry_run)
      end

      puts
      puts 'Done.'
    end

    def seed_source(source_key, source, dry_run:)
      ontology_name = source_key.upcase
      filter_method = :"#{source_key}_filter"

      unless ControlledVocabulary.respond_to?(filter_method)
        abort("No ControlledVocabulary.#{filter_method} predicate for ontology #{source_key.inspect}")
      end

      filter = ControlledVocabulary.public_send(filter_method)
      path = Rails.root.join(source.fetch('path'))
      verify_source!(source, path)

      puts "-- #{ontology_name} --"
      puts "File:   #{path}"
      puts "Source: #{source['source']}"
      puts "Version: #{source['version']}"
      puts

      plan = ControlledVocabulary.compute_seed_summary(
        vocabulary_name: 'part_of_organism',
        ontology_name:   ontology_name,
        obo_path:        path,
        filter:          filter
      )
      print_summary(source_key, plan.summary, dry_run: dry_run)

      return if dry_run

      ControlledVocabulary.apply_seed(
        vocabulary_name: 'part_of_organism',
        ontology_name:   ontology_name,
        terms:           plan.kept_terms
      )
    end

    def verify_source!(source, path)
      raise "Source file not found: #{path}" unless path.exist?

      actual_sha = Digest::SHA256.hexdigest(File.read(path))
      if source['sha256'] && actual_sha != source['sha256']
        raise "SHA-256 mismatch for #{path}: expected #{source['sha256']}, got #{actual_sha}"
      end

      actual_version = read_data_version(path)
      return unless source['version'] && actual_version != source['version']

      raise "data-version mismatch for #{path}: expected #{source['version']}, got #{actual_version}"
    end

    def print_summary(source_key, summary, dry_run:)
      mode = dry_run ? '[DRY RUN] ' : ''
      puts "#{mode}#{source_key}: kept #{summary[:kept]}, " \
           "inserted #{summary[:inserted]}, updated #{summary[:updated]}, " \
           "deleted #{summary[:deleted]}, variants rebuilt #{summary[:variants_rebuilt]}"
    end
  end
end
