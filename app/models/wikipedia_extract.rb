class WikipediaExtract
  include ActiveModel::Conversion

  def initialize(title, lang = "en")
    @title = title
    @lang = lang
    opts = { prop: ["extracts", "fullurl"], exintro: true, explaintext: true } # return first extract, plain text
    @page = wikipedia_api(lang).find(title, opts)
  end

  def text
    @page.summary.split("\n", 2)[0]
  end

  def url
    "https://#{@lang}.wikipedia.org/wiki/#{ERB::Util.url_encode @title}"
  end

  protected

  def wikipedia_api(lang = "en")
    config = Wikipedia::Configuration.new(domain: "#{lang}.wikipedia.org")
    return Wikipedia::Client.new(config)
  end
end
