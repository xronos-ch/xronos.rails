module SearchesHelper
  def random_search
    random = rand(PgSearch::Document.count)
    random >= 1 ? PgSearch::Document.offset(random).first.content : "Site name, lab code, ..."
  end
end
