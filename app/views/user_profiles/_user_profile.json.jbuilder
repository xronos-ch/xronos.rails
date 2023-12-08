json.extract! user_profile, :id, :user_id, :full_name, :orcid, :public_email, :url, :created_at, :updated_at
json.url user_profile_url(user_profile, format: :json)
