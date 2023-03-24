module UserProfilesHelper
  def new_or_edit_profile_path(user_profile)
    user_profile ? edit_user_profile_path(user_profile) : new_user_profile_path(user_profile)
  end
end
