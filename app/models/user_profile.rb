# == Schema Information
#
# Table name: user_profiles
#
#  id           :bigint           not null, primary key
#  full_name    :string
#  orcid        :string
#  public_email :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserProfile < ApplicationRecord
  belongs_to :user
  
  accepts_nested_attributes_for :user
  
  validates :user_id, uniqueness: true, presence: true
  validates :full_name, presence: true
  validates :orcid, format: { 
    with: /\A(\d{4}-){3}\d{3}(\d|X)\z/, # https://gist.github.com/asencis/644f174855899b873131c2cabcebeb87
    message: "must be in the format xxxx-xxxx-xxxx-xxxx"
  }
  validates :public_email, format: { 
    with: Devise.email_regexp,
    message: "must be a valid email address"
  }
  validates :url, url: { allow_blank: true, public_suffix: true }
end
