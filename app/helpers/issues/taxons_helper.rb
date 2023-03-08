module Issues::TaxonsHelper
  # Possible values are documented at 
  # http://gbif.github.io/parsers/apidocs/org/gbif/api/model/checklistbank/NameUsageMatch.MatchType.html
  def colour_from_gbif_match_type(match_type)
    case match_type
    when "EXACT"
      "success"
    when "AGGREGATE"
      "warning"
    when "FUZZY"
      "warning"
    when "HIGHERRANK"
      "warning"
    when "NONE"
      "danger"
    else
      "danger"
    end
  end
end
