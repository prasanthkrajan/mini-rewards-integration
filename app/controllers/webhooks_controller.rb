class WebhooksController < ActionController::API
  def activity
    api_key = request.headers["Authorization"]&.sub(/^Bearer /, "")
    
    partner = Partner.authenticate_by_api_key(api_key)
    return render json: { error: "Unauthorized" }, status: 401 unless partner

    render json: { status: "received" }, status: 202
  end
end