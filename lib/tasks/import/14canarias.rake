require "bibtex"

namespace :xronos do
  namespace :import do
    desc "Import 14Canarias dataset"
    task "14canarias", [:version, :dir] => :environment do |t, args|
      version = args[:version] || abort("Usage: bin/rails \"xronos:import:14canarias[version,dir]\" — provide a version (e.g. v2) and path to data directory")
      dir = args[:dir] || abort("Usage: bin/rails \"xronos:import:14canarias[version,dir]\" — provide a version (e.g. v2) and path to data directory")
      abort "Source directory not found: #{dir}" unless Dir.exist?(dir)

      source = Source.register(
        name: "14Canarias",
        version: version,
        path: dir,
        source_url: "https://doi.org/10.5334/joad.105",
        license: "CC-BY 4.0",
        notes: "14Canarias: a radiocarbon database for the Canary Islands"
      )

      admin_user_id = ENV.fetch("XRONOS_ADMIN_USER") do
        abort "XRONOS_ADMIN_USER must be set"
      end

      revision_comment =
        "Imported from 14Canarias #{version} <https://doi.org/10.5281/zenodo.7755694>"

      PaperTrail.request(whodunnit: admin_user_id) do
        runner = Xronos::ImportRunner.new(source, csv_dir: dir)

        begin
          runner.describe!(whodunnit: admin_user_id, revision_comment: revision_comment)

          # Phase 1: Sites
          site_index = {}  # Id_site -> Site
          runner.csv("14CanariasSITE.csv") do |row|
            site_type = SiteType.find_or_create_by!(name: cell(row, "Tipo de yacimiento"))
            site = Site.find_or_create_by!(name: cell(row, "Yacimiento")) do |s|
              s.lat = cell(row, "Latitud")
              s.lng = cell(row, "Longitud")
              s.country_code = "ES"
              s.revision_comment = revision_comment
            end
            site.site_types << site_type unless site.site_types.include?(site_type)
            site_index[cell(row, "Id_site")] = site
            runner.increment_created(:site) if site.previously_new_record?
          end

          # Phase 2: References
          bibtex_key_map = {}  # BibTeX key -> Reference
          bib = BibTeX.parse(File.read(File.join(dir, "14CanariasREF.bib")))
          runner.process_enum(bib.each_entry, title: "14CanariasREF.bib") do |entry|
            short_ref = entry.key
            reference = Reference.find_or_create_by!(short_ref: short_ref) do |r|
              r.bibtex = entry.to_s
              r.revision_comment = revision_comment
            end
            bibtex_key_map[entry.key] = reference
            runner.increment_created(:reference) if reference.previously_new_record?
          end

          # Phase 3: C14 data
          runner.csv("14CanariasDATA.csv", col_sep: ";", encoding: "utf-16le") do |row|
            site = site_index[cell(row, "Id_site")]
            unless site
              runner.import_record.update!(error: "Site not found for Id_site=#{cell(row, "Id_site")}")
              next
            end

            # Discard rows without BP or SD — scientifically worthless
            next unless cell(row, "BP") && cell(row, "SD")

            # Context
            context_name = cell(row, "Contexto arqueologico")
            context = site.contexts.find_or_create_by!(name: context_name) do |c|
              c.revision_comment = revision_comment
            end
            runner.increment_created(:context) if context.previously_new_record?

            # Material
            material_name = cell(row, "Material")
            material = nil
            if material_name
              material = Material.find_or_create_by!(name: material_name)
              runner.increment_created(:material) if material.previously_new_record?
            end

            # Taxon
            taxon_name = cell(row, "Especie")
            taxon = nil
            if taxon_name
              taxon = Taxon.find_or_create_by!(name: taxon_name)
              runner.increment_created(:taxon) if taxon.previously_new_record?
            end

            # Sample
            sample = context.samples.find_or_create_by!(material: material, taxon: taxon) do |s|
              s.revision_comment = revision_comment
            end
            runner.increment_created(:sample) if sample.previously_new_record?

            # C14
            lab_id = cell(row, "IdMuestra")
            c14 = sample.c14s.find_or_create_by!(lab_identifier: lab_id) do |c|
              c.bp = cell(row, "BP")&.to_i
              c.std = cell(row, "SD")&.to_i
              c.delta_c13 = cell(row, "Carbono_13")&.to_f
              c.delta_15n = cell(row, "Nitrogeno_15")&.to_f
              c.method = cell(row, "Tipo")
              c.revision_comment = revision_comment
            end
            runner.increment_created(:c14) if c14.previously_new_record?

            # Citation
            bib_key = cell(row, "Bibliografía")
            if bib_key
              reference = bibtex_key_map[bib_key]
              if reference
                Citation.find_or_create_by!(citing: c14, reference: reference)
              end
            end
          end

          runner.succeed!
          runner.report!
        rescue => e
          runner.import_record.update!(error: "#{e.class}: #{e.message}")
          raise
        end
      end
    end
  end
end

