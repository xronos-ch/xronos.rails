# == Schema Information
#
# Table name: materials
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_materials_on_name  (name)
#
class Material < ApplicationRecord
  default_scope { order(name: :asc) }

  include Versioned
  include Supersedable

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words

  has_many :samples, inverse_of: :material

  validates :name, presence: true
end
