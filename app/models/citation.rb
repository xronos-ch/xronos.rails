class Citation < ApplicationRecord

  belongs_to :citing, polymorphic: true
  belongs_to :reference

end
