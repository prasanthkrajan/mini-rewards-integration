module Api
  class MeController < ActionController::API
    before_action :authenticate_user!

    def balance
      render json: {
        balance: current_user.balance,
        user_id: current_user.id
      }, status: 200
    end

    def transactions
      page = (params[:page] || 1).to_i
      per_page = 10
      offset = (page - 1) * per_page

      query = current_user.transactions

      if params[:kind].present?
        query = query.where(kind: params[:kind])
      end

      total_count = query.count
      transactions = query.order(created_at: :desc)
                         .limit(per_page)
                         .offset(offset)

      render json: {
        transactions: transactions.map { |tx| transaction_json(tx) },
        pagination: {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page).ceil
        }
      }, status: 200
    end

    private

    def transaction_json(tx)
      {
        id: tx.id,
        kind: tx.kind,
        points_delta: tx.points_delta,
        activity_type: tx.activity_type,
        partner_id: tx.partner_id,
        external_id: tx.external_id,
        amount: tx.amount,
        created_at: tx.created_at.iso8601
      }
    end

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
