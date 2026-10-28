admin_email = ENV["ADMIN_USER_EMAIL"]

admin = User.find_or_initialize_by(email: admin_email)

admin.assign_attributes(
  password: ENV["ADMIN_USER_PASSWORD"],
  password_confirmation: ENV["ADMIN_USER_PASSWORD"],
  admin: true,
  passphrase: ENV["REGISTRATION_PASSPHRASE"]
)

# Ensure profile exists. ADMIN_USER_NAME only initialises the name; later
# changes via the UI must stick.
admin.build_user_profile unless admin.user_profile
if admin.user_profile.full_name.blank? && ENV["ADMIN_USER_NAME"].present?
  admin.user_profile.full_name = ENV["ADMIN_USER_NAME"]
end

admin.save!

puts "Seeded default admin user: #{admin.id} <#{admin.email}>"
