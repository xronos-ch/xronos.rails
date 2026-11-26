class SearchesController < ApplicationController

  def index
    @results = PgSearch.multisearch(search_params[:q])

    @n_results = @results.count
    @n_sites = @results.where(searchable_type: "Site").count
    @n_c14s = @results.where(searchable_type: "C14").count
    @n_references = @results.where(searchable_type: "Reference").count

    type_param = search_params[:type]
    if type_param.present? && searchable_types.include?(type_param)
      @results = @results.where(searchable_type: type_param)
      @search_type = type_param
    end

    respond_to do |format|
      format.html {
        @results = @results.includes(:searchable)
        @pagy, @results = pagy(:offset, @results)
        @card_counts = load_card_details
      }
      format.json { 
        render json: @results.limit(500) 
      }
    end
  end

  private

  def load_card_details
    results = @results.filter_map(&:searchable).group_by(&:class)
    sites = results.fetch(Site, [])
    dates = results.fetch(C14, [])
    references = results.fetch(Reference, [])

    ActiveRecord::Associations::Preloader.new(records: dates, associations: { sample: { context: :site } }).call
    ActiveRecord::Associations::Preloader.new(records: sites + dates.filter_map(&:site), associations: :site_names).call
    ActiveRecord::Associations::Preloader.new(records: sites, associations: :site_types).call

    counts = {}
    if sites.any?
      site_scope = Site.where(id: sites.map(&:id))
      c14_counts = site_scope.joins(:c14s).group('sites.id').count
      typo_counts = site_scope.joins(:typos).group('sites.id').count
      reference_counts = site_scope.joins(:references).group('sites.id').count
      sites.each do |site|
        counts[site] = {
          c14s: c14_counts.fetch(site.id, 0),
          typos: typo_counts.fetch(site.id, 0),
          references: reference_counts.fetch(site.id, 0)
        }
      end
    end
    if dates.any?
      reference_counts = C14.where(id: dates.map(&:id)).joins(:references).group('c14s.id').count
      dates.each { |date| counts[date] = { references: reference_counts.fetch(date.id, 0) } }
    end
    if references.any?
      citation_counts = Citation.where(reference_id: references.map(&:id)).group(:reference_id).count
      references.each { |reference| counts[reference] = { citations: citation_counts.fetch(reference.id, 0) } }
    end
    counts
  end

  def search_params
    params.permit(:q, :type, :page, :format)
  end

  def searchable_types
    [ "Site", "C14", "Reference" ]
  end

end
