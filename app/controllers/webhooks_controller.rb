class WebhooksController < ActionController::API
  def activity
    api_key = request.headers["Authorization"]&.sub(/^Bearer /, "")

    partner = Partner.authenticate_by_api_key(api_key)
    return render json: { error: "Unauthorized" }, status: 401 unless partner

    mapping = PartnerUserMapping.find_by(
      partner_id: partner.id,
      partner_user_id: params[:partner_user_id]
    )
    user = mapping&.user
    return render json: { error: "User not found" }, status: 404 unless user

    result = WebhookActivityService.process(
      partner: partner,
      user: user,
      payload: params.slice(:activity_type, :external_id, :amount)
    )

    if result[:success]
      render json: { status: "credited", transaction_id: result[:transaction]&.id }, status: 202
    else
      render json: { error: result[:error] }, status: result[:status]
    end
  end
end