# frozen_string_literal: true

module Api
  module V1
    class DendrosController < ApplicationController
      rescue_from ArgumentError, ActionController::UnpermittedParameters do |error|
        render json: { error: error.message }, status: :bad_request
      end
      rescue_from ActiveRecord::RecordNotFound do
        head :not_found
      end

      def index
        query = params.permit(:format, :page, :per_page, :q, :series_code, :sample_id, :site_id,
                              :measurement_variable, :measurement_unit, :is_anchored, :waney_edge,
                              :calendar_from, :calendar_to)
        page = positive_integer(query[:page].presence || '1', maximum: 2**31 - 1)
        per_page = [positive_integer(query[:per_page].presence || '25'), 100].min
        series = filtered_series(query)
        total = series.count
        records = series.reorder(:id).offset((page - 1) * per_page).limit(per_page)
                        .includes(sample: { context: :site })
        render json: {
          data: records.map { |record| serialize(record) },
          pagination: { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil }
        }
      end

      def show
        record = Dendro.unscoped.find(params[:id])
        canonical = record.ultimately_superseded_by
        if canonical != record
          redirect_to api_v1_dendro_path(canonical), status: :moved_permanently
        else
          render json: serialize(record)
        end
      end

      private

      def filtered_series(query)
        series = Dendro.in_calendar_range(from_year: query[:calendar_from], to_year: query[:calendar_to])
        series = series.search(query[:q]) if query[:q].present?
        series = series.where(series_code: query[:series_code]) if query[:series_code].present?
        if query[:sample_id].present?
          series = series.where(sample_id: positive_integer(query[:sample_id]))
        end
        if query[:site_id].present?
          contexts = Context.where(site_id: positive_integer(query[:site_id]))
          series = series.where(sample_id: Sample.where(context_id: contexts.select(:id)))
        end
        { measurement_variable: Dendro::MEASUREMENT_VARIABLES.keys, measurement_unit: Dendro::MEASUREMENT_UNITS,
          is_anchored: %w[true false], waney_edge: %w[true false] }.each do |field, allowed|
          next if query[field].blank?

          raise ArgumentError, "Invalid #{field}" unless allowed.include?(query[field])

          series = series.where(field => query[field])
        end
        series
      end

      def positive_integer(value, maximum: 2**63 - 1)
        number = Integer(value.to_s, 10)
        raise ArgumentError, 'Expected a positive integer' unless number.positive? && number <= maximum

        number
      rescue ArgumentError
        raise ArgumentError, 'Expected a positive integer'
      end

      def serialize(record)
        record.as_json(only: Dendro::EXPORT_COLUMNS).merge(
          'site_id' => record.site.id, 'context_id' => record.context.id,
          'calendar_start_year' => record.calendar_start_year, 'calendar_end_year' => record.calendar_end_year
        )
      end
    end
  end
end
