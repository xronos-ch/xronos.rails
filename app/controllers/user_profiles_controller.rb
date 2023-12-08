class UserProfilesController < ApplicationController
  load_and_authorize_resource
  #layout "admin"
  before_action :set_user_profile, only: %i[ show edit update destroy ]

  include Pagy::Backend

  # GET /user_profiles or /user_profiles.json
  def index
    @user_profiles = UserProfile.all
  end

  # GET /contributors/1 or /contributors/1.json
  def show
    user = @user_profile.user
    @contribs = PaperTrail::Version
      .where(whodunnit_user_email: user.email)
      .reorder(created_at: :desc)

    respond_to do |format|
      format.html {
        @pagy, @contribs = pagy(@contribs)
      }
      format.json
    end
  end

  # GET /user_profiles/new
  def new
    @user_profile = UserProfile.new
  end

  # GET /user_profiles/1/edit
  def edit
  end

  # POST /user_profiles or /user_profiles.json
  def create
    # TODO: what if we're an admin trying to create a profile for another user?
    @user_profile.user = current_user

    respond_to do |format|
      if @user_profile.save
        format.html { redirect_to @user_profile, notice: "User profile updated." }
        format.json { render :show, status: :created, location: @user_profile }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_profiles/1 or /user_profiles/1.json
  def update
    respond_to do |format|
      if @user_profile.update(user_profile_params)
        format.html { redirect_to @user_profile, notice: "User profile updated." }
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
        :photo,
        :user_id
      )
    end

end
