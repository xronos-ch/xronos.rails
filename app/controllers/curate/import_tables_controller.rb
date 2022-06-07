class Curate::ImportTablesController < CurateController
  include Pagy::Backend

  def index
    @import_tables = CurateImportTable.all
  end

  def show
    @import_table = CurateImportTable.find(params[:id])
    @parsed = @import_table.read
    @headers = @parsed.headers
    @preview = @parsed.to_a.drop(1)
    @pagy, @preview = pagy_array(@preview)
  end

  def new
    @import_table = CurateImportTable.new
  end

  def edit
    @import_table = CurateImportTable.find(params[:id])
    @parsed = @import_table.read
    @headers = @parsed.headers
    @preview = @parsed.to_a.drop(1)
    @pagy, @preview = pagy_array(@preview)
  end

  def create
    @import_table = CurateImportTable.new(curate_import_table_params).tap do |it|
      it.user = current_user
    end

    respond_to do |format|
      if @import_table.save
        format.html { 
          redirect_to edit_curate_import_table_path(@import_table),
          notice: "File uploaded." 
        }
      else
        format.html { render :new, status: unprocessable_entity }
      end
    end
  end

  def update
  end

  def destroy
  end

  private

  def curate_import_table_params
    params.require(:curate_import_table).permit(:file)
  end
end
