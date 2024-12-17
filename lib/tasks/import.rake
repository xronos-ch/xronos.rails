namespace :import do

  require "roo"

  admin_user_id = ENV["ADMIN_USER_ID"]

  desc "Import data from Wang et al. 2014"
  task wang_et_al_2014: :environment do
    dates_file = "db/import/wang_et_al_2014/1-s2.0-S0277379114001966-mmc3.xlsx"
    references_file = "db/import/wang_et_al_2014/wang_et_al_2014_references.csv"
    revision_comment = "Imported from Wang et al. (2014), <https://doi.org/10.1016/j.quascirev.2014.05.015>"

    wang_et_al_2014_bibtex = BibTeX.parse <<-END
@article{WangEtAl2014,
  title = {Prehistoric Demographic Fluctuations in {{China}} Inferred from Radiocarbon Data and Their Linkage with Climate Change over the Past 50,000 Years},
  author = {Wang, Can and Lu, Houyuan and Zhang, Jianping and Gu, Zhaoyan and He, Keyang},
  year = {2014},
  month = aug,
  journal = {Quaternary Science Reviews},
  volume = {98},
  pages = {45--59},
  issn = {0277-3791},
  doi = {10.1016/j.quascirev.2014.05.015},
  abstract = {Historic human--climate interactions have been of interest to scholars for a long time. However, exploring the long-term relation between prehistoric demography and climate change remains challenging because of the absence of an effective proxy for population reconstruction. Recently, the summed probability distribution of archaeological radiocarbon dates has been widely used as a proxy for human population levels, although researchers recognize that such usage must be cautious. This approach is rarely applied in China due to the lack of a comprehensive archaeological radiocarbon database, and thus the relation between human population and climate change in China remains ambiguous. Herein we systematically compile an archaeological 14C database (n~=~4656) for China for the first time. Using the summed probability distributions of the radiocarbon dates alongside high-resolution palaeoclimatic records, we show that: 1) the commencement of major population expansion in China was at 9~ka~cal~BP, occurring after the appearance of agriculture and associated with the early Holocene climate amelioration; 2) the major periods of small population size and population decline, i.e., 46--43~ka~cal~BP, 41--38~ka~cal~BP, 31--28.6~ka~cal~BP, 25--23.5~ka~cal~BP, 18--15.2~ka~cal~BP, and 13--11.4~ka~cal~BP, correspond well with the dating of abrupt cold events in the Last Glacial (LG) such as the Heinrich and Younger Dryas (YD) events, while the major periods of high-level population in the Holocene, i.e., 8.5--7~ka~cal~BP, 6.5--5~ka~cal~BP and 4.3--2.8~ka~cal~BP, occur at the same times as warm-moist conditions and Neolithic cultural prosperity, suggesting that abrupt cooling in the climate profoundly limited population size and that mild climate episodes spurred a growth in prehistoric populations and advances in human cultures; and 3) populations in different regions experience different growth trajectories and that their responses to climate change are varied, due to both regional environmental diversity and the attainment of different levels of adaptive strategies.}
}
    END

    PaperTrail.request(whodunnit: admin_user_id) do
      ActiveRecord::Base.transaction do

        wang_et_al_2014 = Reference.find_or_create_by!(
          short_ref: "Wang et al. 2014",
          bibtex: wang_et_al_2014_bibtex.to_s
        )

        # Import references as references (manually matched to citations)
        references = Roo::Spreadsheet.open(references_file)
          .parse(headers: true)

        references_progress = ProgressBar.create(
          title: "Importing references",
          total: references.count, 
          format: "%t: |%B| %c/%C (%E)"
        )

        bibliography = references.map { |reference|
          references_progress.increment

          # Correct punctuation in short refs
          short_ref = reference["Citation"]
            .sub(".", " ")
            .sub("&", " & ")
            .sub(",", ", ")
            .sub("et al", "et al.")
            .sub(",  ", ", ")

          # Generate better-than-nothing BibTeX
          bibtex = BibTeX::Entry.new(
            bibtex_type: :misc,
            bibtex_key: short_ref.remove(" ").remove(".").remove("&").remove(","),
            note: reference["Reference"]
          )

          ref = Reference.find_or_create_by!(bibtex: bibtex, short_ref: short_ref) do |reference|
            reference.revision_comment = revision_comment
          end

          [ reference["Citation"], ref ]
        }.to_h

        # Import dates as sites, contexts, samples, c14s, and typos
        dates = Roo::Spreadsheet.open(dates_file)
          .sheet("China")
          .parse(headers: true, clean: true)

        dates_progress = ProgressBar.create(
          title: "Importing dates",
          total: dates.count, 
          format: "%t: |%B| %c/%C (%E)"
        )

        dates.each do |date|
          dates_progress.increment

          if bibliography.has_key?(date["Data references"])
            references = [
              bibliography.fetch(date["Data references"]),
              wang_et_al_2014
            ]
          else
            references = [ wang_et_al_2014 ]
          end

          site_type = SiteType.find_or_create_by!(name: date["Site type"])

          site = Site.find_or_create_by!(
            country_code: "CN",
            lat: date["Latitude(N)"],
            lng: date["Longitude(E)"],
            name: date["Site name"],
          ) do |site|
            site.site_types = [ site_type ]
            site.references = references
            site.revision_comment = revision_comment
          end

          context = Context.find_or_create_by!(
            name: date["Context"] || "Unspecified", 
            site: site
          ) do |context|
            context.revision_comment = revision_comment
          end

          if date["Material dated"] == "Unknown"
            material = nil
          else
            material = Material.find_or_create_by!(name: date["Material dated"]) do |material|
              material.revision_comment = revision_comment
            end
          end

          sample = Sample.find_or_create_by!(
            position_description: date["Sample provenience"],
            context: context,
            material: material
          ) do |sample|
            sample.revision_comment = revision_comment
          end

          delta_c13 = date["<html><b>Delta</b><sup><b>13</b></sup><b>C</b><b>（‰）</b></html>"]
          delta_c13_std = nil
          if delta_c13.is_a?(String) and delta_c13.include?("±")
            delta_c13, delta_c13_std = delta_c13.split("±").map(&:to_i)
          else
            delta_c13 = delta_c13.to_i
          end

          c14 = C14.find_or_create_by!(
            bp: date["<html><sup><b>14</b></sup><b>C age(BP)</b></html>"],
            std: date["1σ"],
            delta_c13: delta_c13,
            delta_c13_std: delta_c13_std,
            lab_identifier: date["Lab code"],
            method: date["Method of Sample Analysis"],
            sample: sample
          ) do |c14|
            c14.references = references
            c14.revision_comment = revision_comment
          end

          unless date["Cultural affiliation"].blank?
            typo = Typo.find_or_create_by!(
              name: date["Cultural affiliation"],
              sample: sample
            ) do |typo|
              typo.references = references
              typo.revision_comment = revision_comment
            end
          end

        end

      end

    end

  end

end
