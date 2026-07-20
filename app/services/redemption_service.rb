class RedemptionService
  def self.redeem(user:, reward:)
    new.redeem(user: user, reward: reward)
  end

  def redeem(user:, reward:)
    return error_result("Reward is not available", 422) unless reward.active
    return error_result("Reward has expired", 422) if reward.expires_at && reward.expires_at < Time.current

    current_balance = user.balance
    return error_result("Insufficient balance", 422) if current_balance < reward.points_required

    begin
      reward.lock!

      if reward.inventory && reward.redeemed_count >= reward.inventory
        return error_result("Reward sold out", 422)
      end

      result = nil
      ActiveRecord::Base.transaction do
        reward.increment!(:redeemed_count) if reward.inventory

        transaction = Transaction.create!(
          user_id: user.id,
          partner_id: nil,
          activity_type: "reward_redemption",
          external_id: "reward_#{reward.id}_#{Time.current.to_i}",
          points_delta: -reward.points_required.to_i,
          kind: "redeem"
        )

        new_balance = current_balance - reward.points_required.to_i

        result = {
          success: true,
          reward_id: reward.id,
          reward_name: reward.name,
          points_spent: reward.points_required.to_i,
          new_balance: new_balance,
          transaction_id: transaction.id
        }
      end
      result
    rescue ActiveRecord::Deadlocked
      error_result("Reward unavailable, please try again", 503)
    rescue => e
      error_result("Failed to redeem reward: #{e.message}", 500)
    end
  end

  private

  def error_result(message, status)
    {
      success: false,
      error: message,
      status: status
    }
  end
end
