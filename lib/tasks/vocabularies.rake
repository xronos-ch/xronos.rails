require 'digest'
require 'open-uri'

require Rails.root.join('db/data/sources')

namespace :xronos do
  namespace :vocabularies do
    desc 'Fetch the source OBO files for our controlled vocabularies into db/data/ontologies/'
    task fetch: :environment do
      SOURCES.each { |source| fetch_source(source) }
      puts
      puts 'Done. Review git diff and commit db/data/ontologies/.'
    end

    def fetch_source(source)
      dest_path = Rails.root.join(source.fetch(:path))
      url      = source.fetch(:url)

      puts "== #{source[:source_key]} =="
      puts "Source: #{url}"
      puts "Target: #{dest_path}"

      download = URI.open(url) # rubocop:disable Security/Open
      tmp_path = dest_path.to_path + '.tmp'
      File.binwrite(tmp_path, download.read)

      new_version = read_data_version(tmp_path)
      new_sha256  = Digest::SHA256.hexdigest(File.read(tmp_path))

      if dest_path.exist? && read_data_version(dest_path) == new_version
        File.unlink(tmp_path)
        puts "Local copy is up to date (#{new_version}). Skipping."
        puts
        return
      end

      File.rename(tmp_path, dest_path)
      puts "Downloaded version: #{new_version}"
      puts "SHA-256:            #{new_sha256}"
      puts
    end

    def read_data_version(path)
      File.foreach(path).find { |l| l.start_with?('data-version:') }
          &.split(':', 2)&.last&.strip
    end
  end
end
