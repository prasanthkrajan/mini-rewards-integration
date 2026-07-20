class User < ApplicationRecord
  has_secure_password
  has_many :transactions

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :password, presence: true, length: { minimum: 6 }, unless: :persisted?

  def balance
    cached = Rails.cache.read("user:#{id}:balance")
    return cached if cached.present?

    calculate_and_cache_balance
  end

  def update_balance_cache
    calculate_and_cache_balance
  end

  private

  def calculate_and_cache_balance
    balance = transactions.sum(:points_delta).to_f.round.to_i
    Rails.cache.write("user:#{id}:balance", balance, expires_in: 1.hour)
    balance
  end
end
