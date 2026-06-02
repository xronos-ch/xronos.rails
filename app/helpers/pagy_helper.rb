module PagyHelper
  def pagy_bootstrap_nav_tag(pagy)
    pagy.series_nav(
      :bootstrap,
      anchor_string: 'data-turbo-action="advance"'
    )
  end
end