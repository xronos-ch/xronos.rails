class UserProfiles::PhotoController < ApplicationController
  skip_load_and_authorize_resource
  before_action :set_user_profile

  # DELETE /user_profiles/1/photo
  def destroy
    @user_profile.photo.purge
    respond_to do |format|
      format.html { redirect_to edit_user_profile_url(@user_profile), notice: "Profile photo removed." }
      format.json { head :no_content }
    end
  end

  private
    def set_user_profile
      @user_profile = UserProfile.find(params[:user_profile_id])
      authorize! :edit, @user_profile
    end

end
