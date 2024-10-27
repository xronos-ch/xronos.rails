module LodsHelper
  def lod_label(lod)
    lod.to_s.upcase
  end

  def lod_description(lod)
    case lod
    # Sites
    when :missing_wikidata_link
      "No Wikidata Link has yet been provided"
    else
      ""
    end
  end

  def lod_badge(lod)
    content_tag :span, title: lod_description(lod), class: "badge text-bg-warning" do
      lod_label(lod)
    end
  end
end
