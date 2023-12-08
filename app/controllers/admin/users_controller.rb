class Admin::UsersController < AdminController
  include Pagy::Backend

  load_and_authorize_resource

  before_action :set_user, only: [:edit, :update, :destroy]
  before_action :add_users_breadcrumb

  # GET /admin/users
  def index
    @users = User.all
  end

  # GET /admin/users/new
  def new
    @user = Article.new
    @user.user = current_user

    breadcrumbs.add "New user"
  end

  # GET /admin/users/:id/edit
  def edit
    breadcrumbs.add @user.title
  end

  # POST /admin/users
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_users_url, status: :see_other, notice: "'#{@user.email}' created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/users/1
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to admin_users_url, status: :see_other, notice: "'Saved changes to '#{@user.email}'." }
        format.json { render :index, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/users/1
  def destroy
    deletedUser = @user.email
    @user.destroy
    respond_to do |format|
      format.html { redirect_to admin_users_url, status: :see_other, notice: "'#{deletedUser}' deleted." }
      format.json { head :no_content }
    end
  end

  private
    def add_users_breadcrumb
      breadcrumbs.add "Users", admin_users_path
    end

    def set_user
      @user = User.find(params[:id])
    end

    def user_parms
      params.require(:user).permit(
        :id
      )
    end
end
