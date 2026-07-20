class RewardsController < ActionController::API
  before_action :authenticate_user!

  def redeem
    reward = Reward.find_by(id: params[:reward_id])
    return render json: { error: "Reward not found" }, status: 404 unless reward

    result = RedemptionService.redeem(user: current_user, reward: reward)

    if result[:success]
      render json: result, status: 200
    else
      render json: { error: result[:error] }, status: result[:status]
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: user_id_from_token)
  end

  def authenticate_user!
    render json: { error: "Unauthorized" }, status: 401 unless current_user
  end

  def user_id_from_token
    token = request.headers["Authorization"]&.sub(/^Bearer /, "")
    match = token&.match(/^user_(\d+)$/)
    match[1].to_i if match
  end
end
