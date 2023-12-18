class Admin::UsersController < AdminController
  include Pagy::Backend

  #load_and_authorize_resource

  before_action :set_user, only: [:edit, :update, :destroy]
  before_action :add_users_breadcrumb

  # GET /admin/users
  def index
    @users = User.all
  end

  # GET /admin/users/new
  def new
    @user = User.new
    breadcrumbs.add "New user"
  end

  # GET /admin/users/:id/edit
  def edit
    breadcrumbs.add @user.email
  end

  # POST /admin/users
  def create
    reset_password_now = user_params.fetch(:reset_password_now, false)
    @user = User.new(user_params.except(:reset_password_now))
    @user.passphrase = ENV["REGISTRATION_PASSPHRASE"]

    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_users_url, status: :see_other, notice: "'#{@user.email}' created." }
        format.json { render :show, status: :created, location: @user }
        @user.send_reset_password_instructions if reset_password_now
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/users/1
  def update
    @user.passphrase = ENV["REGISTRATION_PASSPHRASE"]

    reset_password_now = user_params.fetch(:reset_password_now, false)
    update_user_params = user_params.except(:reset_password_now)
    if user_params.fetch(:password, "").blank?
      update_user_params.delete(:password)
      update_user_params.delete(:password_confirmation)
    end

    respond_to do |format|
      if @user.update(update_user_params)
        format.html { redirect_to admin_users_url, status: :see_other, notice: "'Saved changes to '#{@user.email}'." }
        format.json { render :index, status: :ok, location: @user }
        @user.send_reset_password_instructions if reset_password_now
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

    def user_params
      params.require(:user).permit(
        :id,
        :email,
        :password,
        :password_confirmation,
        :admin,
        :reset_password_now
      )
    end
end
