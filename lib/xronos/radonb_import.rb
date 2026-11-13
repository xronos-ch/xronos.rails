# frozen_string_literal: true

require 'bigdecimal'
require 'json'

module Xronos
  # Imports the plain TSV export and keeps its row-level provenance.
  class RadonbImport < ImportRunner # rubocop:disable Metrics/ClassLength
    FILENAME = 'radondaily.txt'
    PROVENANCE_PREFIX = 'RADONB import source '
    QUALIFIER_FIELDS = %w[SPECIES CULTURE PERIOD FEATURETYPE].freeze
    HEADERS = %w[
      ID LABNR C14AGE C14STD C13 MATERIAL SPECIES COUNTRY SITE CULTURE PERIOD
      FEATURETYPE FEATURE LATITUDE LONGITUDE REFERENCE
    ].freeze

    def run!
      @revision_comment = "Imported from #{@source.label} (<#{@source.source_url}>)"
      describe!(whodunnit: PaperTrail.request.whodunnit, revision_comment: @revision_comment)

      @source.with_lock(requires_new: true) do
        import_rows(read_rows)
        succeed!
      end

      report!
    rescue StandardError => e
      import_record.reload.update!(error: "#{e.class}: #{e.message}")
      raise
    end

    private

    def read_rows
      seen_ids = Set.new
      File.open(File.join(@csv_dir, FILENAME), 'r:bom|utf-8') do |file|
        header = file.gets&.chomp&.split("\t", -1)
        raise ArgumentError, "#{FILENAME}: unexpected header" unless header == HEADERS

        file.each_line.with_index(2).map { |line, number| parse_row(line, number, seen_ids) }
      end
    end

    def parse_row(line, number, seen_ids)
      # This export is plain TSV. Quotes inside fields are literal.
      fields = line.chomp.split("\t", -1)
      unless fields.size == HEADERS.size
        raise ArgumentError, "#{FILENAME}: expected #{HEADERS.size} fields at line #{number}"
      end

      row = HEADERS.zip(fields).to_h
      id = cell(row, 'ID')
      raise ArgumentError, "#{FILENAME}: invalid ID at line #{number}" unless id&.match?(/\A[0-9]+\z/)
      raise ArgumentError, "#{FILENAME}: duplicate ID #{id} at line #{number}" unless seen_ids.add?(id)

      row
    end

    def import_rows(rows)
      verify_versioning!
      @country_codes = {}
      site_coordinates = coordinates_by_site(rows)
      imported_ids = imported_source_ids

      with_merges_suppressed do
        process_enum(rows, title: FILENAME) { |row| import_row(row, imported_ids, site_coordinates) }
      end

      deduplicate_chrons!
    end

    def coordinates_by_site(rows)
      rows.each_with_object({}) do |row, index|
        key = site_key(row)
        pair = coordinates(row)
        next unless key.first && pair

        (index[key] ||= Set.new).add(pair)
      end
    end

    def import_row(row, imported_ids, site_coordinates)
      id = cell(row, 'ID')
      skip_unless !imported_ids.include?(id), 'already imported'

      bp = integer(cell(row, 'C14AGE'))
      std = integer(cell(row, 'C14STD'))
      skip_unless bp && std&.positive?, 'invalid BP or SD'

      site = import_site(row, site_coordinates)
      c14 = import_measurement(row, site, bp, std)

      cite_references!(c14, row)
    end

    def import_site(row, site_coordinates)
      key = site_key(row)
      name = key.first
      skip_unless name, 'missing site name'
      pair = coordinates(row)
      skip_unless pair, 'missing or invalid site coordinates'
      skip_unless site_coordinates.fetch(key).one?, 'conflicting site coordinates'

      code = country_code(text_cell(row, 'COUNTRY'))
      import!(Site, keys: { name: name },
                    attributes: { lat: pair.first, lng: pair.last, country_code: code },
                    revision_comment: @revision_comment)
    end

    def import_measurement(row, site, age, std)
      context = import!(site.contexts,
                        keys: { name: text_cell(row, 'FEATURE') },
                        revision_comment: @revision_comment)

      material_name = text_cell(row, 'MATERIAL')
      material = import!(Material, keys: { name: material_name }) if material_name
      sample = build_new!(context.samples, attributes: { material: material }, revision_comment: @revision_comment)
      import!(sample.c14s,
              keys: { lab_identifier: lab_identifier(row) },
              attributes: { bp: age, std: std, delta_c13: decimal(cell(row, 'C13'))&.to_f },
              revision_comment: measurement_revision_comment(row))
    end

    def cite_references!(c14, row)
      ensure_source_reference!
      cite_source!(c14)

      short_ref = text_cell(row, 'REFERENCE')
      return unless short_ref

      reference = import!(Reference, keys: { short_ref: short_ref }, revision_comment: @revision_comment)
      import!(Citation, keys: { citing: c14, reference: reference })
    end

    def ensure_source_reference!
      return if @source.reference_id?

      reference = import!(Reference, keys: { short_ref: @source.label }, revision_comment: @revision_comment)
      @source.update!(reference: reference)
    end

    def verify_versioning!
      return if PaperTrail.enabled? && PaperTrail.request.enabled? && PaperTrail.request.enabled_for_model?(C14)

      raise 'RADONB import requires PaperTrail for C14 provenance'
    end

    def source_prefix
      "#{PROVENANCE_PREFIX}#{@source.id}: "
    end

    def measurement_revision_comment(row)
      provenance = {
        id: cell(row, 'ID'),
        version: @source.version,
        reference: row.fetch('REFERENCE'),
        qualifiers: QUALIFIER_FIELDS.to_h { |field| [field, text_cell(row, field)] }.compact
      }
      "#{source_prefix}#{JSON.generate(provenance)}\n#{@revision_comment}"
    end

    def provenance_versions(prefix = PROVENANCE_PREFIX)
      PaperTrail::Version.where(item_type: 'C14', event: 'create')
                         .where('starts_with(revision_comment, ?)', prefix)
    end

    def imported_source_ids
      provenance_versions(source_prefix).pluck(:revision_comment)
                                        .to_set { |comment| parse_provenance(comment).fetch('id') }
    end

    def parse_provenance(comment)
      JSON.parse(comment.lines.first.partition(': ').last)
    end

    def site_key(row)
      country = text_cell(row, 'COUNTRY')
      [text_cell(row, 'SITE'), country_code(country) || country]
    end

    def country_code(country)
      return unless country

      return @country_codes[country] if @country_codes.key?(country)

      @country_codes[country] = if country == 'Republic of Serbia'
                                  'RS'
                                else
                                  ISO3166::Country[country]&.alpha2 ||
                                    ISO3166::Country.find_country_by_any_name(country)&.alpha2
                                end
    end

    def coordinates(row)
      lat = decimal(cell(row, 'LATITUDE'))
      lng = decimal(cell(row, 'LONGITUDE'))
      return unless lat && lng
      return if lat.zero? && lng.zero?

      coordinates = Coordinates.new(lng, lat)
      return unless coordinates.valid_latitude? && coordinates.valid_longitude?

      [lat, lng]
    end

    def text_cell(row, column)
      value = cell(row, column)
      value unless value&.match?(%r{\A(?:n\s*/\s*a|-)\z}i)
    end

    def lab_identifier(row)
      value = text_cell(row, 'LABNR')
      value unless value&.match?(%r{(?:\A|[-\s])n\s*/\s*a(?:\z|[-\s])}i)
    end

    def integer(value)
      return unless value&.match?(/\A[+-]?[0-9]+\z/)

      number = Integer(value, 10)
      number if number.between?(-2_147_483_648, 2_147_483_647)
    end

    def decimal(value)
      return unless value&.match?(/\A[+-]?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)\z/)

      BigDecimal(value)
    end
  end
end
