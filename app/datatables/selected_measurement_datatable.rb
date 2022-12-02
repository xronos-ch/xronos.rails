class SelectedMeasurementDatatable < AjaxDatatablesRails::ActiveRecord
  include DataHelper
  extend Forwardable

  def_delegators :@view, :link_to, :lab_path
  def_delegators :@view, :link_to, :site_path
  def_delegators :@view, :link_to, :site_phase_path
  def_delegators :@view, :link_to, :site_type_path
  def_delegators :@view, :link_to, :feature_type_path
  def_delegators :@view, :best_in_place

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      select: { source: "C14.id" },
      lab_identifier: { source: "C14.lab_identifier", cond: :like },
      site: { source: "Site.name", cond: :like },
      material: { source: "Material.name", cond: :like },
      taxon: { source: "Taxon.name", cond: :like },
      bp: { source: "C14.bp", cond: :like },
      std: { source: "C14.std", cond: :like },
      cal_bp: { source: "C14.cal_bp", cond: :like },
      cal_std: { source: "C14.cal_std", cond: :like },
      source_database: { source: "C14.source_database.name", cond: :like }
    }
  end

  def data
    ## following still might cause trouble when relationships are NIL
    records.map do |record|
      {
        "sample_id": record.sample.id,
        "c14_id": record.id,
        "select": "",
        "lab_identifier": link_to(record.lab_identifier, record),
        "site": link_to(record.sample.context.site.name, site_path(record.sample.context.site.id)),
        "material": record.sample.material.present? ? record.sample.material.name : na_value,
        "taxon": record.sample.taxon.present? ? record.sample.taxon.name : na_value,
        "bp": record.bp.present? ? record.bp : na_value,
        "std": record.std.present? ? record.std : na_value,
        "cal_bp": record.cal_bp.present? ? record.cal_bp : na_value,
        "cal_std": record.cal_std.present? ? record.cal_std : na_value,
        "source_database": record.source_database.present? ? record.source_database.name : na_value
      }
    end
  end

  def get_raw_records
    return options[:selected_measurements]
  end

end
