class MeController < ActionController::API
  include UserAuthenticatable

  def balance
    render json: {
      balance: current_user.balance,
      user_id: current_user.id
    }, status: 200
  end
end
