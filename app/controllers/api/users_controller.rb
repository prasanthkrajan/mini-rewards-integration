module Api
  class UsersController < ActionController::API
    def login
      email = params[:email]
      password = params[:password]

      return render json: { error: "Email and password are required" }, status: 400 unless email.present? && password.present?

      user = User.find_by(email: email)
      return render json: { error: "Invalid email or password" }, status: 401 unless user&.authenticate(password)

      token = JwtService.encode(user.id)
      render json: { token: token, user: { id: user.id, email: user.email, name: user.name } }, status: 200
    end
  end
end
