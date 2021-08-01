class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  attr_accessor :passphrase
  validates :passphrase, format: { with: Regexp.new(ENV["REGISTRATION_PASSPHRASE"]) , message: "is wrong. Please contact ... to get a correct passphrase to register." }

end
