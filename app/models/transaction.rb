class Transaction < ApplicationRecord
  belongs_to :partner, optional: true
  belongs_to :user

  after_create :invalidate_user_balance_cache

  private

  def invalidate_user_balance_cache
    Rails.cache.delete("user:#{user_id}:balance")
  end
end
