# frozen_string_literal: true

module Miaard
  class C14sController < ApplicationController
    load_and_authorize_resource class: "C14"

    def index
      c14s = C14
               .includes(sample: [:taxon, { context: :site }])
               .order(:id)

      c14s = c14s.where(c14_params) unless c14_params.blank?

      send_data(
        JSON.pretty_generate(Miaard::C14CollectionExporter.new(c14s).as_json),
        type: "application/json; charset=utf-8",
        filename: "xronos_c14s_miaard.json",
        disposition: "attachment"
      )
    end

    def show
      send_data(
        JSON.pretty_generate(Miaard::C14Exporter.new(@c14).as_json),
        type: "application/json; charset=utf-8",
        filename: "xronos_c14_#{@c14.id}_miaard.json",
        disposition: "attachment"
      )
    end

    private

    def c14_params
      params.fetch(:c14, {}).permit(
        :lab_identifier,
        :c14_lab_id,
        :bp,
        :std,
        :delta_c13,
        :delta_c13_std,
        :method,
        :sample_id
      )
    end
  end
end