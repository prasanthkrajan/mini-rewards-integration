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

  describe "GET /api/me/transactions" do
    context "with valid user authentication" do
      before do
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
          partner_id: nil,
          user_id: user.id,
          activity_type: "reward_redemption",
          external_id: "reward_1_1234567890",
          points_delta: -30,
          kind: "redeem"
        )
      end

      it "returns all transactions for the authenticated user" do
        get '/api/me/transactions', headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        body = response.parsed_body
        expect(body["transactions"]).to be_an(Array)
        expect(body["transactions"].length).to eq(3)
      end

      it "includes all transaction fields" do
        get '/api/me/transactions', headers: auth_header_for(user)

        body = response.parsed_body
        transaction = body["transactions"].first
        expect(transaction).to include(
          "id",
          "kind",
          "points_delta",
          "activity_type",
          "partner_id",
          "external_id",
          "amount",
          "created_at"
        )
      end

      it "returns transactions in reverse chronological order (newest first)" do
        get '/api/me/transactions', headers: auth_header_for(user)

        body = response.parsed_body
        transactions = body["transactions"]
        expect(transactions[0]["activity_type"]).to eq("reward_redemption")  # most recent
        expect(transactions[2]["activity_type"]).to eq("signup")  # oldest
      end

      it "includes pagination info" do
        get '/api/me/transactions', headers: auth_header_for(user)

        body = response.parsed_body
        expect(body["pagination"]).to include(
          "page" => 1,
          "per_page" => 10,
          "total_count" => 3,
          "total_pages" => 1
        )
      end

      it "filters by kind parameter (earn)" do
        get '/api/me/transactions?kind=earn', headers: auth_header_for(user)

        body = response.parsed_body
        expect(body["transactions"].length).to eq(2)
        expect(body["transactions"].all? { |t| t["kind"] == "earn" }).to be true
      end

      it "filters by kind parameter (redeem)" do
        get '/api/me/transactions?kind=redeem', headers: auth_header_for(user)

        body = response.parsed_body
        expect(body["transactions"].length).to eq(1)
        expect(body["transactions"][0]["kind"]).to eq("redeem")
      end

      it "handles pagination with page parameter" do
        # Create 15 transactions to test pagination (per_page = 10)
        15.times do |i|
          Transaction.create!(
            partner_id: partner.id,
            user_id: user.id,
            activity_type: "test",
            external_id: "evt_test_#{i}",
            points_delta: 10,
            kind: "earn"
          )
        end

        get '/api/me/transactions?page=1', headers: auth_header_for(user)
        page1 = response.parsed_body
        expect(page1["transactions"].length).to eq(10)
        expect(page1["pagination"]["page"]).to eq(1)
        expect(page1["pagination"]["total_pages"]).to eq(2)

        get '/api/me/transactions?page=2', headers: auth_header_for(user)
        page2 = response.parsed_body
        expect(page2["transactions"].length).to eq(8)  # 18 total - 10 on page 1 = 8 on page 2
        expect(page2["pagination"]["page"]).to eq(2)
      end

      it "only includes transactions for the authenticated user" do
        Transaction.create!(
          partner_id: partner.id,
          user_id: other_user.id,
          activity_type: "signup",
          external_id: "evt_other",
          points_delta: 100,
          kind: "earn"
        )

        get '/api/me/transactions', headers: auth_header_for(user)

        body = response.parsed_body
        expect(body["transactions"].length).to eq(3)  # Only user's 3 transactions
      end
    end

    context "with missing authentication" do
      it "returns 401 Unauthorized" do
        get '/api/me/transactions'

        expect(response).to have_http_status(401)
      end
    end

    context "with invalid authentication" do
      it "returns 401 Unauthorized" do
        get '/api/me/transactions', headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(401)
      end
    end

    context "with no transactions" do
      it "returns empty array with pagination info" do
        get '/api/me/transactions', headers: auth_header_for(user)

        body = response.parsed_body
        expect(body["transactions"]).to eq([])
        expect(body["pagination"]["total_count"]).to eq(0)
        expect(body["pagination"]["total_pages"]).to eq(0)
      end
    end
  end
end
