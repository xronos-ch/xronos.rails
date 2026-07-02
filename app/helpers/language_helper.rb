##
# Helper methods for multilingual elements
module LanguageHelper

  ##
  # Known languages
  def languages
    I18nData
      .languages("EN")
      .transform_values { |val|
        val.split(";")[0]
      }
      .invert
  end

  ##
  # Generate badge for a language
  def language_badge(lang)
    content_tag :span, 
      title: I18nData.languages("EN")[lang],
      class: "badge text-bg-info text-uppercase" do
      lang
    end
  end

end
