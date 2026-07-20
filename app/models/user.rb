class User < ApplicationRecord
  has_secure_password
  has_many :transactions

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :password, presence: true, length: { minimum: 6 }, unless: :persisted?

  def balance
    transactions.sum(:points_delta).to_i
  end
end
