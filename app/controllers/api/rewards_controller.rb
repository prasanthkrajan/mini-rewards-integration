module Api
  class RewardsController < ActionController::API
    before_action :authenticate_user!

    def index
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 10).to_i
      per_page = [per_page, 100].min  # Cap at 100

      total_count = Reward.active.count
      rewards = Reward.active
                      .order(:id)
                      .limit(per_page)
                      .offset((page - 1) * per_page)
                      .map do |reward|
        {
          id: reward.id,
          name: reward.name,
          description: reward.description,
          points_required: reward.points_required.to_i
        }
      end

      render json: {
        rewards: rewards,
        pagination: {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page).ceil
        }
      }, status: 200
    end

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
      @current_user ||= User.find_by(id: user_id_from_jwt)
    end

    def authenticate_user!
      render json: { error: "Unauthorized" }, status: 401 unless current_user
    end

    def user_id_from_jwt
      token = request.headers["Authorization"]&.sub(/^Bearer /, "")
      return nil unless token.present?

      decoded = JwtService.decode(token)
      decoded["user_id"] if decoded
    end
  end
end
