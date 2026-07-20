module Api
  class MeController < ActionController::API
    before_action :authenticate_user!

    def balance
      render json: {
        balance: current_user.balance,
        user_id: current_user.id
      }, status: 200
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
