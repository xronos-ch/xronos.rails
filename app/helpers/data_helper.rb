module DataHelper
  def na_value
    '<abbr title="Unknown or missing value" class="initialism text-muted">NA</abbr>'.html_safe
  end
end
