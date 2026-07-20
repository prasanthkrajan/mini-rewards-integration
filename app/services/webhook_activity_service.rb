class WebhookActivityService
  POINTS_RULES = {
    "signup" => 100,
    "purchase" => { points_per_unit: 1 },
    "referral" => 50
  }.freeze

  def self.process(partner:, user:, payload:)
    new.process(partner: partner, user: user, payload: payload)
  end

  def process(partner:, user:, payload:)
    activity_type = payload[:activity_type]
    external_id = payload[:external_id]
    amount = payload[:amount]

    validation_error = validate_payload(activity_type, external_id, amount)
    return error_result(validation_error, 422) if validation_error

    points_delta = calculate_points(activity_type, amount)

    begin
      transaction = Transaction.create!(
        partner_id: partner.id,
        user_id: user.id,
        activity_type: activity_type,
        external_id: external_id,
        points_delta: points_delta,
        amount: amount,
        kind: "earn"
      )
      success_result(transaction)
    rescue ActiveRecord::RecordNotUnique
      # Idempotent: already recorded, return 202
      success_result(nil, idempotent: true)
    end
  end

  private

  def validate_payload(activity_type, external_id, amount)
    return "activity_type is required" if activity_type.blank?
    return "external_id is required for idempotent processing" if external_id.blank?
    return "unknown activity_type: #{activity_type}" unless POINTS_RULES.key?(activity_type)

    rule = POINTS_RULES[activity_type]
    if rule.is_a?(Hash) && rule[:points_per_unit]
      return "activity_type '#{activity_type}' requires 'amount' field" if amount.blank?
    end

    nil
  end

  def calculate_points(activity_type, amount)
    rule = POINTS_RULES[activity_type]

    if rule.is_a?(Hash)
      # Per-unit rule
      (amount.to_d * rule[:points_per_unit]).to_i
    else
      # Flat rule
      rule
    end
  end

  def success_result(transaction, idempotent: false)
    {
      success: true,
      transaction: transaction,
      error: nil,
      idempotent: idempotent
    }
  end

  def error_result(error_message, status)
    {
      success: false,
      transaction: nil,
      error: error_message,
      status: status
    }
  end
end
