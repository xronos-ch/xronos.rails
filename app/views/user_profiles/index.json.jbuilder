json.set! :data do
  json.array! @user_profiles do |user_profile|
    json.partial! 'user_profiles/user_profile', user_profile: user_profile
    json.url  "
              #{link_to 'Show', user_profile }
              #{link_to 'Edit', edit_user_profile_path(user_profile)}
              #{link_to 'Destroy', user_profile, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end