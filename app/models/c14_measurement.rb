class C14Measurement < ApplicationRecord
  validates :bp, :std, :cal_bp, :cal_std, presence: true
  #validates :method, inclusion: { in: %w(AMS conventional other unknown) }
end
