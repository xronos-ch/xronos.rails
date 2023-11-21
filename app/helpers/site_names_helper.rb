module SiteNamesHelper
  def languages
    I18nData
      .languages("EN")
      .transform_values { |val|
        val.split(";")[0]
      }
      .invert
  end

  def language_badge(lang)
    content_tag :span, 
      title: I18nData.languages("EN")[lang],
      class: "badge text-bg-info text-uppercase" do
      lang
    end
  end
end
