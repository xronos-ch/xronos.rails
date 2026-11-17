# frozen_string_literal: true

require 'bibtex'

namespace :xronos do
  namespace :import do
    desc 'Import RDCA (Radiocarbon Databank for Chinese Archaeology)'
    task 'rdca', %i[version dir source_url] => :environment do |_t, args|
      version, dir, source_url = Xronos::ImportRunner.parse_args!(args)

      source = Source.register!(
        name: 'RDCA',
        version: version,
        path: dir,
        source_url: source_url,
        license: 'CC-BY 4.0',
        notes: 'Radiocarbon Databank for Chinese Archaeology (7083 C14 dates). XLSX with 5 regional sheets.'
      )

      admin_user_id = ENV.fetch('ADMIN_USER_ID') do
        abort 'ADMIN_USER_ID must be set'
      end

      revision_comment = "Imported from Radiocarbon Databank for Chinese Archaeology #{version} (<#{source_url}>)"

      PaperTrail.request(whodunnit: admin_user_id) do
        runner = Xronos::ImportRunner.new(source, csv_dir: dir)

        # Helper to treat "-" as nil (dataset-specific)
        cell_or_dash = lambda { |row, column|
          val = runner.cell(row, column)
          val == '-' ? nil : val
        }

        # Helper to resolve citation abbreviations
        resolve_ref = lambda { |abbrev, ref_index, ref_aliases|
          return nil if abbrev.nil? || abbrev == 'This study.'

          resolved_abbrev = ref_aliases.fetch(abbrev, abbrev)
          reference = ref_index[resolved_abbrev]
          raise "Unresolvable citation: #{abbrev.inspect} (tried #{resolved_abbrev.inspect})" unless reference

          reference
        }

        # Helper to parse reference abbreviations into BibTeX fields
        inst_keywords = /Institute|Laboratory|Museum|University|Panel|Group|Project|CASS|XICRA|YPICRA|GPICRA|XUARM|Commission|CAQR/i
        year_re = /,\s*(\d{4}[a-z]?)\s/
        year_etal_re = /et al\.\s+(\d{4}[a-z]?)\s/

        parse_ref_abbrev = lambda { |abbrev|
          return nil unless abbrev

          clean = abbrev.gsub(/<[^>]+>/, '').strip.gsub("\u00A0", ' ')

          year_match = clean.match(year_re)
          if year_match
            author_str = clean[0...year_match.begin(0)].strip
            year = year_match[1]
            venue = clean[year_match.end(1)..].strip
          else
            etal_match = clean.match(year_etal_re)
            return nil unless etal_match

            year_start = clean.index(etal_match[1])
            author_str = clean[0...year_start].sub(/,\s*$/, '').strip
            year = etal_match[1]
            venue = clean[year_start + etal_match[1].length..].strip
          end

          venue = venue.sub(/\A[a-z]\s*/, '') if year =~ /\d[a-z]$/

          names = if author_str =~ /et al\./i
                    [author_str.sub(/\s*et al\.?\s*$/, '').strip]
                  elsif author_str.match?(/&/) || author_str.match?(/\band\b/)
                    parts = author_str.split(/\s*&\s*|\s+and\s+/)
                    parts.any? { |p| p.match?(inst_keywords) } ? [author_str] : parts.map(&:strip)
                  else
                    [author_str]
                  end

          bibtex_authors = names.map do |str|
            str = str.strip
            if str.match?(/\A[A-Z]{2,}/)
              "{#{str}}"
            else
              m = str.match(/\A([A-ZÀ-ž][a-zà-ž''-]+)\s+([A-Z]+)\z/)
              if m
                initials = m[2].chars.map { |c| "#{c}." }.join(' ')
                "#{m[1]}, #{initials}"
              else
                "{#{str}}"
              end
            end
          end.join(' and ')

          { author: bibtex_authors, year: year, venue: venue }
        }

        begin
          runner.describe!(whodunnit: admin_user_id, revision_comment: revision_comment)
          runner.suppress_merges!

          # Phase 0: Source reference
          source_ref = runner.import!(Reference,
                                      keys: { short_ref: 'RDCA' },
                                      attributes: {
                                        bibtex: <<~BIB.chomp
                                          @article{Qiu2025,
                                            author = {Qiu, Menghan and Du, Linyao and Staff, Richard and Yan, Ziyun and Yan, Tingting and Cao, Huihui and Gosden, Chris and Liu, Ruiliang and Dong, Guanghui},
                                            title = {Chronology of early China: A radiocarbon databank for Chinese archaeology},
                                            journal = {Scientific Data},
                                            year = {2025},
                                            volume = {12},
                                            pages = {1665},
                                            doi = {10.1038/s41597-025-05956-z}
                                          }
                                        BIB
                                      },
                                      revision_comment: revision_comment)
          source.update!(reference: source_ref)

          # Phase 1: References from "Data Source" sheet
          ref_index = {} # abbreviation -> Reference
          xlsx_file = 'Radiocarbon databank for Chinese archaeology v2023.4.xlsx'

          runner.xlsx(xlsx_file, sheets: 'Data Source') do |row|
            abbrev = cell_or_dash.call(row, 'Reference Abbreviation')
            skip_unless abbrev, 'missing reference abbreviation'
            skip_unless abbrev != 'This study.', 'skipping This study.'

            year = cell_or_dash.call(row, 'Year of Publication')
            doi = cell_or_dash.call(row, 'DOI')
            title_en = cell_or_dash.call(row, 'Title in English')
            title_zh = cell_or_dash.call(row, 'Title in Chinese')

            parsed = parse_ref_abbrev.call(abbrev)

            bibtex_lines = ["@misc{#{abbrev.gsub(/[^a-zA-Z0-9_]/, '_')},"]
            bibtex_lines << "  author = {#{parsed[:author]}}," if parsed && parsed[:author].present?
            if title_zh
              bibtex_lines << "  title = {#{title_zh}},"
              bibtex_lines << "  title-english = {#{title_en}}," if title_en
              bibtex_lines << '  language = {Chinese},'
            elsif title_en
              bibtex_lines << "  title = {#{title_en}},"
            end
            bibtex_lines << "  year = {#{year}}," if year
            bibtex_lines << "  doi = {#{doi}}," if doi
            bibtex_lines << '}'

            reference = runner.import!(Reference,
                                       keys: { short_ref: abbrev },
                                       attributes: { bibtex: bibtex_lines.join("\n") },
                                       revision_comment: revision_comment)
            ref_index[abbrev] = reference
          end

          # Phase 1.5: Create missing references that have no match in Data Source
          missing_refs = {
            'Fan W H., 1994  Archaeology' => { title: 'Fan W H., 1994 Archaeology', year: 1994 },
            'He YH et al., 2017 J Tibetol (藏学学刊)' => { title: 'He YH et al., 2017 J Tibetol', year: 2017 },
            'Panel of Xia-Shang-Zhou Chronology Project, 2000 Report of phased achievements of Xia-Shang-Zhou Chronology Project (1996-2000)' => {
              title: 'Report of phased achievements of Xia-Shang-Zhou Chronology Project (1996-2000)',
              year: 2000
            },
            'Shi JM et al., 2005 Res Soil Water Conserv (水土保持研究)' => {
              title: 'Shi JM et al., 2005 Res Soil Water Conserv',
              year: 2005
            },
            'Zhang R L et al., 1983 Archaeology' => { title: 'Zhang R L et al., 1983 Archaeology', year: 1983 },
            '2020 Acta Anthropol Sin (人类学学报)' => { title: 'Acta Anthropol Sin', year: 2020 },
            'Atahan et al., 2014 JAS' => { title: 'Atahan et al., 2014 JAS', year: 2014 },
            'Boaretto E et al., 2009 Proc Natl Acad Sci USA' => {
              title: 'Boaretto E et al., 2009 Proc Natl Acad Sci USA',
              year: 2009
            },
            'Wagner M et al., 2011 Proc Natl Acad Sci USA' => {
              title: 'Wagner M et al., 2011 Proc Natl Acad Sci USA',
              year: 2011
            },
            'Ma J et al., 2016 Cult Relic (文物)' => {
              title: 'Ma J et al., 2016 Cult Relic (文物)',
              year: 2016
            },
            'Sheng PF et al., 2020 Antiquity' => {
              title: 'Sheng PF et al., 2020 Antiquity',
              year: 2020
            },
            'Zhou Z, 2006 Cult Relic South China (南方考古)' => {
              title: 'Zhou Z, 2006 Cult Relic South China (南方考古)',
              year: 2006
            }
          }

          missing_refs.each do |abbrev, attrs|
            bibtex = "@misc{#{abbrev.gsub(/[^a-zA-Z0-9_]/,
                                          '_')},\n  title = {#{attrs[:title]}},\n  year = {#{attrs[:year]}}\n}"
            reference = runner.import!(Reference,
                                       keys: { short_ref: abbrev },
                                       attributes: { bibtex: bibtex },
                                       revision_comment: revision_comment)
            ref_index[abbrev] = reference
          end

          # Phase 2 & 3: Sites + C14 (single pass over 5 regional sheets)
          category_to_fc = {
            'Settlement' => 'settlement',
            'Cemetery' => 'burial',
            'Ancient city' => 'settlement',
            'Cave settlement' => 'settlement',
            'Rock-shelter settlement' => 'settlement',
            'Settlement cluster' => 'settlement',
            'Buddhist temple' => 'ritual_ceremonial',
            'Grottoes' => 'ritual_ceremonial',
            'Palace' => 'ritual_ceremonial',
            'Copper mine' => 'production',
            'Mine' => 'production'
          }

          era_abbreviations = {
            'PA' => 'Palaeolithic Age',
            'NA' => 'Neolithic Age',
            'CA' => 'Chalcolithic Age',
            'BA' => 'Bronze Age',
            'EIA' => 'Early Iron Age',
            'MA' => 'Metal Age'
          }

          # Reference aliases for typo corrections
          ref_aliases = {
            'Institute of Archaeology, CASS, 1992 Cult Relics Press (文物出版社)' => 'Institute of Archaeology, CASS, 1992 Cultural Relics Press (文物出版社)',
            'XICRA et al., 2020 Cultural Relic Press (文物出版社)' => 'XICRA et al., 2020 Cultural Relics Press (文物出版社)',
            'XICRA et al., 2020 Cult Relics Press (文物出版社)' => 'XICRA et al., 2020 Cultural Relics Press (文物出版社)',
            'Institute of Archaeology, CASS, 1992 Cultural Relic Press (文物出版社)' => 'Institute of Archaeology, CASS, 1992 Cultural Relics Press (文物出版社)',
            'Institute of Archaeology, CASS et al., 2014 Cult Relics Press (文物出版社)' => 'Institute of Archaeology, CASS et al., 2014 Cultural Relics Press (文物出版社)',
            'Tian D et al., 2022 Front Eco Evol' => 'Tian D et al., 2022 Front Ecol Evol',
            'XICRA, 2016 Sci Press (科学出版社)' => 'XICRA, 2016 Science Press (科学出版社)',
            'XICRA, 2013 Cult Relics Press (文物出版社)' => 'XICRA, 2013 Cultural Relics Press (文物出版社)',
            'XICRA et al., 2013 Cultural Relic Press (文物出版社)' => 'XICRA, 2013 Cultural Relics Press (文物出版社)',
            'Ma ZK et al., 2021 Quat Sci' => 'Ma ZK et al., 2021 Quat Sci (第四纪研究)',
            'Wang LJ et al., 2020 Holocene' => 'Wang LJ et al., 2021 Holocene',
            'XICRA, 2012 Cult Relics Press (文物出版社)' => 'XICRA, 2012 Cultural Relics Press (文物出版社)',
            'Yuan SX et al.1994 Cult Relics (文物)' => 'Yuan SX et al., 1994 Cult Relics (文物)',
            'He KY, 2011 Sichuan Cult Relic (四川文物)' => 'He KY, 2011 Sichuan Cult Relics (四川文物)',
            'Zhao JL et al., 2022 Archaeol Cult Relic (考古与文物)' => 'Zhao JL et al., 2022 Archaeol Cult Relics (考古与文物)',
            'Qiao H & Ma Q, 2022 Sichuan Cult Relic (四川文物)' => 'Qiao H & Ma Q, 2022 Sichuan Cult Relics (四川文物)',
            'Fan J et al., 2017 Relic and Museol (文博)' => 'Fan J et al., 2017 Relics and Museol (文博)',
            'Barton et al., 2007 Dev Quat Sci' => 'Barton L et al., 2007 Dev Quat Sci',
            'Rhode D et al., 2014 J Archeol Sci' => 'Rhode D et al., 2014 J Archaeol Sci',
            'Madsen DB et al., 2017 Archaeol Res Asia' => 'Madsen DB et al., 2017 Archeol Res Asia',
            'Qu et al., 2023 Herit Sci' => 'Qu YT et al., 2023 Herit Sci',
            'Aldenderfer M&Zhang YN, 2004 J World Prehist' => 'Aldenderfer M & Zhang YN, 2004 J World Prehist',
            'Yuan SX et al.1994 Cult Relic (文物)' => 'Yuan SX et al., 1994 Cult Relics (文物)',
            'YPICRA et al., 2010 Cult Relics Press (文物出版社)' => 'YPICRA et al., 2010 Cultural Relics Press (文物出版社)',
            'Zuo Z Q et al., 2017d Archaeol Discov Chengdu (成都考古发现2015)' => 'Zuo ZQ et al., 2017d Archaeol Discov Chengdu (成都考古发现2015)',
            'Zhao ZJ & Chen J, 2011 Cult Relic South China (南方考古)' => 'Zhao ZJ & Chen J, 2011 Cult Relics South China (南方考古)',
            'Zhong H et al., 2021 South Cult Relic (南方文物)' => 'Zhong H et al., 2021 South Cult Relics (南方文物)',
            'Liu XY et al., 2017 Plos ONE' => 'Liu XY et al., 2017 PLoS ONE',
            'Lee GA and Bestel S, 2007 Bull Indo-Pacific Prehist Assoc' => 'Lee GA and Bestel S, 2007 Bull Indo-Pacific Prehist',
            'Cheng ZJ et al., 2023 South Cult Relic (南方文物)' => 'Cheng ZJ et al., 2023 South Cult Relics (南方文物)',
            'Ding XF et al., 2013 Nucl Instrum Methods Phys Res B' => 'Ding XF et al., 2013 Nucl Instr Meth Phys Res B',
            'Zheng JF et al., 2023 North Cult Relic (北方文物)' => 'Zheng JF et al., 2023 North Cult Relics (北方文物)',
            'Shan SW, Yu XY. 2018 Archaeology (考古)' => 'Yu JJ et al., 2018 Archaeology (考古)',
            'He J & Cao DY, 2020 Cult Relic Centr China (中原文物)' => 'He J & Cao DY, 2020 Cult Relics Centr China (中原文物)',
            'Zhou Z, 2006 Cult Relic South China (南方考古)' => 'Zhou Z, 2006 Cult Relics South China (南方考古)',
            'Zhou Z, 2006 Cult Relic South China (南方文物)' => 'Zhou Z, 2006 Cult Relics South China (南方文物)',
            'Kan XH et al., 2010 Cult Relic (文物)' => 'Kan XH et al., 2010 Cult Relics (文物)',
            'Zhuang LN et al., 2018 Southeast Cult (东南文化)' => 'Huang DJ et al., 2023 Southeast Cult (东南文化)',
            'Hu YF et al., 2013 Southeast Cult (东南文化)' => 'Fu L et al., 2016 Southeast Cult (东南文化)',
            'Zheng XQ et al., 2021 Jianghan Archaeol (江汉考古)' => 'Tang LY et al., 2021 Jianghan Archaeol (江汉考古)',
            'Zhong ZB & Liu ZF, 2013 Cult Relic (文物）' => 'Zhong ZB & Liu ZF, 2013 Cult Relics (文物）',
            'Wu MY et al., 2016 Acta Anthropol Sin (人类学学报)' => 'Wu MY et al., 2016  Acta Anthropol Sin (人类学学报)',
            'Yang XY et al., 2018 Holocene' => 'Yang XY et al., 2017 Holocene',
            'Atahan P et al. 2014 J Archaeol Sci' => 'Atahan P et al., 2014 J Archaeol Sci',
            'Li XQ et al., 2007 Sci China Ser D' => 'Li XQ et al., 2007 Sci China Earth Sci'
          }

          data_sheets = ['Northwest', 'Southwest', 'Northern, NE', 'Yangtze Plain', 'Southeast']
          site_citation_tracker = {} # site_id -> Set of ref_ids already cited

          runner.xlsx(xlsx_file, sheets: data_sheets, header_row: 2) do |row|
            site_name = cell_or_dash.call(row, 'Site Name')
            skip_unless site_name, 'missing site name'
            skip_unless cell_or_dash.call(row, '14C age (BP)'), 'missing BP'
            skip_unless cell_or_dash.call(row, 'Uncertainty (yr)'), 'missing SD'
            skip_unless cell_or_dash.call(row, 'Lab Code'), 'missing lab code'

            # Site
            site = runner.import!(Site,
                                  keys: { name: site_name },
                                  attributes: {
                                    lat: cell_or_dash.call(row, 'Latitude (°N)')&.to_f,
                                    lng: cell_or_dash.call(row, 'Longitude (°E)')&.to_f,
                                    country_code: 'CN'
                                  },
                                  revision_comment: revision_comment)
            runner.cite_source!(site)

            # Alternate names: Byname
            byname = cell_or_dash.call(row, 'Byname')
            if byname
              byname.split(';').map(&:strip).reject(&:blank?).each do |alt_name|
                runner.import!(site.site_names,
                               keys: { name: alt_name, language: nil },
                               revision_comment: revision_comment)
              end
            end

            # Alternate names: Chinese Name
            chinese_name = cell_or_dash.call(row, 'Chinese Name')
            if chinese_name
              runner.import!(site.site_names,
                             keys: { name: chinese_name, language: 'zh' },
                             revision_comment: revision_comment)
            end

            # Category -> SiteType (original values)
            category = cell_or_dash.call(row, 'Category')
            if category
              category.split(';').map(&:strip).reject(&:blank?).each do |cat_name|
                site_type = runner.import!(SiteType, keys: { name: cat_name })
                site.site_types << site_type unless site.site_types.include?(site_type)

                # FunctionalClassification (mapped)
                fc_category = category_to_fc[cat_name]
                next unless fc_category

                fc_cat = FunctionalClassificationCategory.find_by(name: fc_category)
                next unless fc_cat

                runner.import!(FunctionalClassification,
                               keys: {
                                 assignable: site,
                                 functional_classification_category: fc_cat
                               },
                               attributes: { confidence: :unknown },
                               revision_comment: revision_comment)
              end
            end

            # Site citations (GI Source + Original Publication)
            site_citation_tracker[site.id] ||= Set.new
            ['GI Source', 'Original Publication'].each do |col|
              citation_str = cell_or_dash.call(row, col)
              next unless citation_str

              citation_str.split(';').map(&:strip).reject(&:blank?).each do |abbrev|
                reference = resolve_ref.call(abbrev, ref_index, ref_aliases)
                next unless reference
                next if site_citation_tracker[site.id].include?(reference.id)

                runner.import!(Citation, keys: { citing: site, reference: reference })
                site_citation_tracker[site.id].add(reference.id)
              end
            end

            # Context
            context_name = cell_or_dash.call(row, 'Archaeological Context')
            context = runner.import!(site.contexts,
                                     keys: { name: context_name },
                                     revision_comment: revision_comment)

            # Material
            material = nil
            material_name = cell_or_dash.call(row, 'Dating Material')
            material = runner.import!(Material, keys: { name: material_name }) if material_name

            # Taxon
            taxon = nil
            taxon_name = cell_or_dash.call(row, 'Species/Description')
            taxon = runner.import!(Taxon, keys: { name: taxon_name }) if taxon_name

            # Sample
            sample = runner.build_new!(context.samples,
                                       attributes: { material: material, taxon: taxon },
                                       revision_comment: revision_comment)

            # C14
            carbon_prop_raw = cell_or_dash.call(row, 'Carbon yield (%)')&.to_f
            carbon_prop = if carbon_prop_raw && carbon_prop_raw > 1
                            carbon_prop_raw / 100.0
                          else
                            carbon_prop_raw
                          end

            cn_ratio_raw = cell_or_dash.call(row, 'Collagen C/N ratio')&.to_f
            cn_ratio = cn_ratio_raw&.positive? ? cn_ratio_raw : nil

            c14 = runner.import!(sample.c14s,
                                 keys: { lab_identifier: cell_or_dash.call(row, 'Lab Code') },
                                 attributes: {
                                   bp: cell_or_dash.call(row, '14C age (BP)')&.to_i,
                                   std: cell_or_dash.call(row, 'Uncertainty (yr)')&.to_i,
                                   delta_c13: cell_or_dash.call(row, 'δ13C (‰)')&.to_f,
                                   method: cell_or_dash.call(row, 'Technique'),
                                   carbon_proportion: carbon_prop,
                                   carbon_nitrogen_ratio: cn_ratio
                                 },
                                  revision_comment: revision_comment)
            runner.cite_source!(c14)

            # C14 citations (Record Source + Original Publication)
            ['Record Source', 'Original Publication'].each do |col|
              citation_str = cell_or_dash.call(row, col)
              next unless citation_str

              citation_str.split(';').map(&:strip).reject(&:blank?).each do |abbrev|
                reference = resolve_ref.call(abbrev, ref_index, ref_aliases)
                next unless reference
                runner.import!(Citation, keys: { citing: c14, reference: reference })
              end
            end

            # Typo records: Era (split by ";")
            era = cell_or_dash.call(row, 'Era')
            if era
              era.split(';').map(&:strip).reject(&:blank?).each do |era_val|
                typo_name = era_abbreviations[era_val] || era_val
                typo = runner.import!(sample.typos,
                                      keys: { name: typo_name },
                                      revision_comment: revision_comment)
                runner.cite_source!(typo)

                # Typo citations (Record Source + Original Publication)
                ['Record Source', 'Original Publication'].each do |col|
                  citation_str = cell_or_dash.call(row, col)
                  next unless citation_str

                  citation_str.split(';').map(&:strip).reject(&:blank?).each do |abbrev|
                    reference = resolve_ref.call(abbrev, ref_index, ref_aliases)
                    next unless reference
                    runner.import!(Citation, keys: { citing: typo, reference: reference })
                  end
                end
              end
            end

            # Typo records: Cultural Association (split by ";")
            cultural = cell_or_dash.call(row, 'Cultural Association')
            if cultural
              cultural.split(';').map(&:strip).reject(&:blank?).each do |culture_name|
                typo = runner.import!(sample.typos,
                                      keys: { name: culture_name },
                                      revision_comment: revision_comment)
                runner.cite_source!(typo)

                # Typo citations (Record Source + Original Publication)
                ['Record Source', 'Original Publication'].each do |col|
                  citation_str = cell_or_dash.call(row, col)
                  next unless citation_str

                  citation_str.split(';').map(&:strip).reject(&:blank?).each do |abbrev|
                    reference = resolve_ref.call(abbrev, ref_index, ref_aliases)
                    next unless reference
                    runner.import!(Citation, keys: { citing: typo, reference: reference })
                  end
                end
              end
            end
          end

          runner.deduplicate_chrons!
          runner.succeed!
          runner.report!
        rescue StandardError => e
          runner.import_record.update!(error: "#{e.class}: #{e.message}")
          raise
        ensure
          runner.restore_merges!
        end
      end
    end
  end
end
