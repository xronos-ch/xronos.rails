require "open3"
require "json"

module CitationJs
  CONVERT_SCRIPT = <<~JS
    const Cite = require("citation-js")
    const format = process.argv[1]
    const input = process.argv[2]
    const cslItems = JSON.parse(input)
    const cite = new Cite(cslItems)
    process.stdout.write(cite.format(format))
  JS

  def self.convert(csl_items, format)
    return "" if csl_items.blank?

    stdout, stderr, status = Open3.capture3(
      { "NODE_PATH" => Rails.root.join("node_modules").to_s },
      "node", "-e", CONVERT_SCRIPT, format, csl_items.to_json
    )

    unless status.success?
      Rails.logger.error("[CitationJs] conversion failed (#{format}): #{stderr.strip}")
      return ""
    end

    stdout
  end
end
