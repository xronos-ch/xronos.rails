class SelectedMeasurementDatatable < AjaxDatatablesRails::ActiveRecord
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
      select: { source: "Measurement.id" },
      labnr: { source: "Measurement.labnr", cond: :like },
      bp: { source: "C14Measurement.bp", cond: :like },
      std: { source: "C14Measurement.std", cond: :like },
      cal_bp: { source: "C14Measurement.cal_bp", cond: :like },
      cal_std: { source: "C14Measurement.cal_std", cond: :like },
      site: { source: "Site.name", cond: :like },
      period: { source: "Period.name", cond: :like },
      material: { source: "Material.name", cond: :like },
    }
  end

  def data
    ## following still might cause trouble when relationships are NIL
    records.map do |record|
      {
        "arch_object_id": record.sample.arch_object.id,
        "measurement_id": record.id,
        "c14_measurement_id": record.c14_measurement_id,
        "select": "",
        "labnr": record.labnr,
        "bp": record.c14_measurement.bp,
        "std": record.c14_measurement.std,
        "cal_bp": record.c14_measurement.cal_bp,
        "cal_std": record.c14_measurement.cal_std,
	"site": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.site.present? ? link_to(record.sample.arch_object.site_phase.site.name, site_path(record.sample.arch_object.site_phase.site.id)) : '',
        "period": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.periods.present? ? record.sample.arch_object.site_phase.periods.map(&:name).join(" | ") : '',
        "material": record.sample.arch_object.material&.name
      }
    end
  end

  def get_raw_records
    return options[:selected_measurements]
  end

end
