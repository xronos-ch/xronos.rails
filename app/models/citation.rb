class Citation < ApplicationRecord

  belongs_to :citing, polymorphic: true
  belongs_to :reference

  acts_as_copy_target # enable CSV exports
end
