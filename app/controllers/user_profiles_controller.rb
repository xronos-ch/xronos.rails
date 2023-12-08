class UserProfilesController < ApplicationController
  load_and_authorize_resource
  layout "admin"
  before_action :set_user_profile, only: %i[ show edit update destroy ]


  # GET /user_profiles or /user_profiles.json
  def index
    @user_profiles = UserProfile.all
  end

  # GET /user_profiles/1 or /user_profiles/1.json
  def show
  end

  # GET /user_profiles/new
  def new
    @user_profile = UserProfile.new
    @user_profile.user = current_user
  end

  # GET /user_profiles/1/edit
  def edit
  end

  # POST /user_profiles or /user_profiles.json
  def create
    user_params = user_profile_params.slice(:user_attributes)
    
    @user_profile = UserProfile.new(user_profile_params.except(:user_attributes))
    
    if current_user.admin?
      user_params = user_profile_params.slice(:user_attributes)
      @user = User.new(user_params[:user_attributes])
    else
      @user = current_user
    end
    
    @user_profile.user = @user

    respond_to do |format|
      if @user.save & @user_profile.save
        format.html { redirect_to @user_profile, notice: "User profile was successfully created." }
        format.json { render :show, status: :created, location: @user_profile }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_profiles/1 or /user_profiles/1.json
  def update
    user_params = user_profile_params.slice(:user_attributes)
    respond_to do |format|
      if @user_profile.update(user_profile_params.except(:user_attributes)) & @user_profile.user.update_with_password(user_params[:user_attributes])
        bypass_sign_in(@user_profile.user)
        format.html { redirect_to @user_profile, notice: "User profile was successfully updated." }
        format.json { render :show, status: :ok, location: @user_profile }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_profiles/1 or /user_profiles/1.json
  def destroy
    @user_profile.destroy
    respond_to do |format|
      format.html { redirect_to user_profiles_url, notice: "User profile was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_profile
      if params[:id]
        @user_profile = UserProfile.find(params[:id])
      else
        @user_profile = current_user.user_profile
      end
    end

    # Only allow a list of trusted parameters through.
    def user_profile_params
      params.fetch(:user_profile, {}).permit(
        :full_name,
        :public_email,
        :orcid,
        :url,
        :user_id
      )
    end
end
