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
  belongs_to :user, required: true

  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize_to_fill: [180, 180]
  end
  
  validates :orcid, 
    format: { 
      with: /\A(\d{4}-){3}\d{3}(\d|X)\z/, # https://gist.github.com/asencis/644f174855899b873131c2cabcebeb87
      message: "must be in the format xxxx-xxxx-xxxx-xxxx"
    }, 
    allow_blank: true

  validates :public_email, 
    format: { 
      with: Devise.email_regexp,
      message: "must be a valid email address"
    }, 
    allow_blank: true

  validates :url, url: { allow_blank: true, public_suffix: true }

  validate :photo_not_too_big
  validate :variable_photo

  def variable_photo
    return unless photo.attached?
    unless ActiveStorage.variable_content_types.include?(photo.content_type)
      # Workaround for lack of proper validation of ActiveStorage attachments
      # See https://github.com/rails/rails/issues/31656
      photo.purge
      errors.add(:photo, "must be a supported file type")
    end
  end

  def photo_not_too_big
    return unless photo.attached?
    unless photo.blob.byte_size <= 5.megabyte
      # Workaround for lack of proper validation of ActiveStorage attachments
      # See https://github.com/rails/rails/issues/31656
      photo.purge
      errors.add(:photo, "must be less than 5 megabytes")
    end
  end

end
