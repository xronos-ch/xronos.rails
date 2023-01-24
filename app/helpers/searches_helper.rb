module SearchesHelper
  def random_search
    random = rand(PgSearch::Document.count)
    PgSearch::Document.offset(random).first.content
  end
end
