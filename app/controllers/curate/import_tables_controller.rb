class Curate::ImportTablesController < CurateController
  include Pagy::Backend

  load_and_authorize_resource

  def index
  end

  def show
    @parsed = @import_table.read
    unless @parsed.nil?
      @headers = @parsed.headers
      @preview = @parsed.to_a.drop(1)
      @pagy, @preview = pagy_array(@preview)
    end
  end

  def new
  end

  def edit
    @import_table.read
    unless @import_table.parsed.nil?
      @pagy, @preview = pagy_array(@import_table.preview)
    end
  end

  def create
    @import_table = Curate::ImportTable.new(import_table_params).tap do |it|
      it.user = current_user
    end

    respond_to do |format|
      if @import_table.save
        format.html { 
          redirect_to edit_curate_import_table_path(@import_table),
          notice: "File uploaded." 
        }
      else
        format.html { render :new }
      end
    end
  end

  def update
    respond_to do |format|
      if @import_table.update(import_table_params)
        format.html { redirect_to edit_curate_import_table_path(@import_table), notice: "Read options updated." }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @import_table.destroy
    respond_to do |format|
      format.html { redirect_to curate_import_tables_path, notice: "Imported table deleted." }
    end
  end

  private

  def import_table_params
    params.require(:curate_import_table).permit(
      :file,
      {read_options: [
        :headers,
        :col_sep,
        :row_sep,
        :quote_char,
        :na_values
      ]}
    )
  end
end
