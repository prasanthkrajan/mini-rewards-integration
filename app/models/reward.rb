class Reward < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :points_required, presence: true, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }
end
