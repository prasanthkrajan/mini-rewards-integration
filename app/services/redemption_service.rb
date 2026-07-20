class RedemptionService
  def self.redeem(user:, reward:)
    new.redeem(user: user, reward: reward)
  end

  def redeem(user:, reward:)
    return error_result("Reward is not available", 422) unless reward.active

    current_balance = user.balance
    return error_result("Insufficient balance", 422) if current_balance < reward.points_required

    begin
      transaction = Transaction.create!(
        user_id: user.id,
        partner_id: nil,
        activity_type: "reward_redemption",
        external_id: "reward_#{reward.id}_#{Time.current.to_i}",
        points_delta: -reward.points_required.to_i,
        kind: "redeem"
      )

      new_balance = current_balance - reward.points_required.to_i

      {
        success: true,
        reward_id: reward.id,
        reward_name: reward.name,
        points_spent: reward.points_required.to_i,
        new_balance: new_balance,
        transaction_id: transaction.id
      }
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
