# app/services/miaard/c14_collection_exporter.rb
# frozen_string_literal: true

module Miaard
  class C14CollectionExporter
    def initialize(c14s)
      @c14s = c14s
    end

    def as_json(*)
      {
        entries: c14s.map { |c14| C14Exporter.new(c14).as_json }
      }
    end

    private

    attr_reader :c14s
  end
end