class WebhooksController < ActionController::API
  def activity
    render json: { status: "received" }, status: 202
  end
end