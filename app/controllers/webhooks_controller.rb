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

    render json: { status: "received" }, status: 202
  end
end