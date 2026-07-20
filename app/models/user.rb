class User < ApplicationRecord
  has_many :transactions

  def balance
    transactions.sum(:points_delta).to_i
  end
end
