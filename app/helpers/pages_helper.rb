module PagesHelper
  def cached_site_count
    Rails.cache.fetch("stats/site_count", expires_in: 10.minutes) { Site.count }
  end

  def cached_c14_count
    Rails.cache.fetch("stats/c14_count", expires_in: 10.minutes) { C14.count }
  end

  def cached_typo_count
    Rails.cache.fetch("stats/typo_count", expires_in: 10.minutes) { Typo.count }
  end
end