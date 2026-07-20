require 'rails_helper'

RSpec.describe "Me (User)", type: :request do
  let(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "alice123") }
  let(:other_user) { User.create!(name: "Bob", email: "bob@example.com", password: "bob123") }
  let(:partner) { Partner.create!(name: "Partner A", api_key_digest: BCrypt::Password.create("secret")) }

  # Helper to authenticate as a user
  def auth_header_for(user)
    token = JwtService.encode(user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /api/me/balance" do
    context "with valid user authentication" do
      it "returns the user's total balance (sum of all transactions)" do
        # Create transactions for user
        Transaction.create!(
          partner_id: partner.id,
          user_id: user.id,
          activity_type: "signup",
          external_id: "evt_001",
          points_delta: 100,
          kind: "earn"
        )
        Transaction.create!(
          partner_id: partner.id,
          user_id: user.id,
          activity_type: "purchase",
          external_id: "evt_002",
          points_delta: 50,
          amount: 50,
          kind: "earn"
        )
        Transaction.create!(
          partner_id: partner.id,
          user_id: user.id,
          activity_type: "redeem",
          external_id: "evt_003",
          points_delta: -30,
          kind: "redeem"
        )

        get '/api/me/balance', headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        expect(response.parsed_body).to include(
          "balance" => 120,  # 100 + 50 - 30
          "user_id" => user.id
        )
      end

      it "returns 0 balance if user has no transactions" do
        get '/api/me/balance', headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        expect(response.parsed_body["balance"]).to eq(0)
      end

      it "only includes transactions for the authenticated user" do
        # Create transactions for different users
        Transaction.create!(
          partner_id: partner.id,
          user_id: user.id,
          activity_type: "signup",
          external_id: "evt_001",
          points_delta: 100,
          kind: "earn"
        )
        Transaction.create!(
          partner_id: partner.id,
          user_id: other_user.id,
          activity_type: "signup",
          external_id: "evt_002",
          points_delta: 100,
          kind: "earn"
        )

        get '/api/me/balance', headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        expect(response.parsed_body["balance"]).to eq(100)  # Only user's balance
      end
    end

    context "with missing authentication" do
      it "returns 401 Unauthorized" do
        get '/api/me/balance'

        expect(response).to have_http_status(401)
      end
    end

    context "with invalid authentication" do
      it "returns 401 Unauthorized" do
        get '/api/me/balance', headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(401)
      end
    end
  end
end
