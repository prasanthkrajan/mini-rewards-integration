class Reward < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :points_required, presence: true, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [true, false] }
  validates :inventory, numericality: { greater_than: 0 }, allow_nil: true
  validates :redeemed_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }

  before_create :initialize_redeemed_count

  private

  def initialize_redeemed_count
    self.redeemed_count ||= 0 if inventory.present?
  end
end
