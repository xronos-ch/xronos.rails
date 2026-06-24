require "bibtex"

namespace :xronos do
  namespace :import do
    desc "Import 14Canarias dataset"
    task "14canarias", [:version, :dir, :source_url] => :environment do |t, args|
      version, dir, source_url = Xronos::ImportRunner.parse_args!(args)

      source = Source.register(
        name: "14Canarias",
        version: version,
        path: dir,
        source_url: source_url,
        license: "CC-BY 4.0",
        notes: "14Canarias: a radiocarbon database for the Canary Islands"
      )

      admin_user_id = ENV.fetch("ADMIN_USER_ID") do
        abort "ADMIN_USER_ID must be set"
      end

      revision_comment = "Imported from 14Canarias #{version} (<#{source_url}>)"

      PaperTrail.request(whodunnit: admin_user_id) do
        runner = Xronos::ImportRunner.new(source, csv_dir: dir)

        begin
          runner.describe!(whodunnit: admin_user_id, revision_comment: revision_comment)

          # Phase 0: Source reference
          source_ref = runner.import!(Reference,
            keys: { short_ref: "14Canarias" },
            attributes: {
              bibtex: <<~BIB.chomp
                @article{Morales2023,
                  author = {Morales, Jacob and Rodr{\'\i}guez, Amelia and Delgado, Tania},
                  title = {{14Canarias}: A radiocarbon database for the Canary Islands},
                  journal = {Journal of Open Archaeology Data},
                  year = {2023},
                  volume = {11},
                  pages = {1--7},
                  doi = {10.5334/joad.105}
                }
              BIB
            },
            revision_comment: revision_comment
          )
          source.update!(reference: source_ref)

          # Phase 1: Sites
          site_index = {}  # Id_site -> Site
          runner.csv("14CanariasSITE.csv") do |row|
            site_type = import!(SiteType, keys: { name: cell(row, "Tipo de yacimiento") })
            site = import!(Site,
              keys: { name: cell(row, "Yacimiento") },
              attributes: {
                lat: cell(row, "Latitud"),
                lng: cell(row, "Longitud"),
                country_code: "ES"
              },
              revision_comment: revision_comment
            )
            site.site_types << site_type unless site.site_types.include?(site_type)
            site_index[cell(row, "Id_site")] = site
          end

          # Phase 2: References
          bibtex_key_map = {}  # BibTeX key -> Reference
          bib = BibTeX.parse(File.read(File.join(dir, "14CanariasREF.bib")))
          runner.process_enum(bib.each_entry, title: "14CanariasREF.bib") do |entry|
            reference = import!(Reference,
              keys: { short_ref: entry.key },
              attributes: { bibtex: entry.to_s },
              revision_comment: revision_comment
            )
            bibtex_key_map[entry.key] = reference
          end

          # Phase 3: C14 data
          runner.csv("14CanariasDATA.csv", col_sep: ";", encoding: "utf-16le") do |row|
            skip_unless site_index[cell(row, "Id_site")], "unknown site"

            site = site_index[cell(row, "Id_site")]

            # Discard rows without BP or SD — scientifically worthless
            skip_unless cell(row, "BP") && cell(row, "SD"), "missing BP or SD"

            # Context
            context = import!(site.contexts,
              keys: { name: cell(row, "Contexto arqueologico") },
              revision_comment: revision_comment
            )

            # Material
            material = nil
            material_name = cell(row, "Material")
            if material_name
              material = import!(Material, keys: { name: material_name })
            end

            # Taxon
            taxon = nil
            taxon_name = cell(row, "Especie")
            if taxon_name
              taxon = import!(Taxon, keys: { name: taxon_name })
            end

            # Sample
            sample = import!(context.samples,
              keys: { material: material, taxon: taxon },
              revision_comment: revision_comment
            )

            # C14
            c14 = import!(sample.c14s,
              keys: { lab_identifier: cell(row, "IdMuestra") },
              attributes: {
                bp: cell(row, "BP")&.to_i,
                std: cell(row, "SD")&.to_i,
                delta_c13: cell(row, "Carbono_13")&.to_f,
                delta_15n: cell(row, "Nitrogeno_15")&.to_f,
                method: cell(row, "Tipo")
              },
              revision_comment: revision_comment
            )
            cite_source!(c14)

            # Citation
            bib_key = cell(row, "Bibliografía")
            if bib_key
              reference = bibtex_key_map[bib_key]
              if reference
                import!(Citation, keys: { citing: c14, reference: reference })
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

