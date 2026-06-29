# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  admin                  :boolean          default(FALSE)
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "display_name returns the full name from the user profile" do
    user = create(:user)
    user.user_profile.update!(full_name: "Alice Smith")
    assert_equal "Alice Smith", user.display_name
  end

  test "display_name returns nil when the user has no profile" do
    user = create(:user)
    user.user_profile&.delete
    user.update!(user_profile: nil)
    assert_nil user.display_name
  end

  test "display_name returns nil when the profile has no full name" do
    user = create(:user)
    user.user_profile.update!(full_name: nil)
    assert_nil user.display_name
  end

  test "has_real_name? is true when the profile has a full name" do
    user = create(:user)
    user.user_profile.update!(full_name: "Alice Smith")
    assert_predicate user, :has_real_name?
  end

  test "has_real_name? is false when the user has no profile" do
    user = create(:user)
    user.user_profile&.delete
    user.update!(user_profile: nil)
    assert_not_predicate user, :has_real_name?
  end

  test "has_real_name? is false when the profile has no full name" do
    user = create(:user)
    user.user_profile.update!(full_name: nil)
    assert_not_predicate user, :has_real_name?
  end

  test "has_real_name? is false when the profile has a blank full name" do
    user = create(:user)
    user.user_profile.update!(full_name: "   ")
    assert_not_predicate user, :has_real_name?
  end
end
