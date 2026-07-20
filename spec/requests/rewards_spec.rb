require 'rails_helper'

RSpec.describe "Rewards", type: :request do
  let!(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "alice123") }
  let!(:partner) { Partner.create!(name: "Partner A", api_key_digest: BCrypt::Password.create("secret")) }

  # Helper to authenticate as a user
  def auth_header_for(user)
    token = JwtService.encode(user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /api/rewards" do
    context "with valid authentication" do
      before do
        Reward.create!(name: "Free Coffee", description: "Get a free coffee", points_required: 100, active: true)
        Reward.create!(name: "50% Discount", description: "50% off", points_required: 50, active: true)
        Reward.create!(name: "Inactive Reward", description: "Not available", points_required: 25, active: false)
      end

      it "returns paginated active rewards" do
        get '/api/rewards', headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        body = response.parsed_body
        expect(body).to include("rewards", "pagination")
        expect(body["rewards"]).to be_an(Array)
        expect(body["rewards"].length).to eq(2)
      end

      it "returns reward details" do
        get '/api/rewards', headers: auth_header_for(user)

        body = response.parsed_body
        rewards = body["rewards"]
        coffee_reward = rewards.find { |r| r["name"] == "Free Coffee" }
        expect(coffee_reward).to include(
          "name" => "Free Coffee",
          "description" => "Get a free coffee",
          "points_required" => 100
        )
        expect(coffee_reward["id"]).to be_present
      end

      it "does not include inactive rewards" do
        get '/api/rewards', headers: auth_header_for(user)

        body = response.parsed_body
        rewards = body["rewards"]
        reward_names = rewards.map { |r| r["name"] }
        expect(reward_names).not_to include("Inactive Reward")
      end

      it "includes pagination info" do
        get '/api/rewards', headers: auth_header_for(user)

        body = response.parsed_body
        expect(body["pagination"]).to include(
          "page" => 1,
          "per_page" => 10,
          "total_count" => 2,
          "total_pages" => 1
        )
      end

      it "respects per_page parameter" do
        get '/api/rewards?per_page=1', headers: auth_header_for(user)

        body = response.parsed_body
        expect(body["rewards"].length).to eq(1)
        expect(body["pagination"]["per_page"]).to eq(1)
        expect(body["pagination"]["total_pages"]).to eq(2)
      end
    end

    context "with no active rewards" do
      it "returns empty rewards array with pagination" do
        get '/api/rewards', headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        body = response.parsed_body
        expect(body["rewards"]).to eq([])
        expect(body["pagination"]["total_count"]).to eq(0)
      end
    end

    context "without authentication" do
      it "returns 401 Unauthorized" do
        get '/api/rewards'

        expect(response).to have_http_status(401)
      end
    end
  end

  describe "POST /api/rewards/:reward_id/redeem" do
    let(:reward) { Reward.create!(name: "Free Coffee", description: "Get a free coffee", points_required: 100, active: true) }
    let(:inactive_reward) { Reward.create!(name: "Inactive Reward", description: "Not available", points_required: 50, active: false) }

    context "with valid redemption request" do
      before do
        # Credit user with points
        Transaction.create!(
          partner_id: partner.id,
          user_id: user.id,
          activity_type: "signup",
          external_id: "evt_001",
          points_delta: 200,
          kind: "earn"
        )
      end

      it "deducts points and creates a redeem transaction" do
        post "/api/rewards/#{reward.id}/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        expect(response.parsed_body).to include(
          "success" => true,
          "reward_id" => reward.id,
          "reward_name" => "Free Coffee",
          "points_spent" => 100,
          "new_balance" => 100,
          "transaction_id" => be_present
        )

        # Verify redeem transaction was created
        redeem_tx = Transaction.find_by(user_id: user.id, kind: "redeem")
        expect(redeem_tx).not_to be_nil
        expect(redeem_tx.points_delta).to eq(-100)
        expect(redeem_tx.activity_type).to eq("reward_redemption")
        expect(redeem_tx.partner_id).to be_nil
      end

      it "allows redeeming if balance >= points_required" do
        post "/api/rewards/#{reward.id}/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        expect(response.parsed_body["success"]).to be true
      end

      it "sets correct new_balance after redemption" do
        post "/api/rewards/#{reward.id}/redeem",
          headers: auth_header_for(user)

        expect(response.parsed_body["new_balance"]).to eq(100)
      end
    end

    context "with insufficient balance" do
      before do
        # Credit user with only 50 points
        Transaction.create!(
          partner_id: partner.id,
          user_id: user.id,
          activity_type: "signup",
          external_id: "evt_001",
          points_delta: 50,
          kind: "earn"
        )
      end

      it "returns 422 and does not create transaction" do
        post "/api/rewards/#{reward.id}/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(422)
        expect(response.parsed_body).to include("error")
        expect(response.parsed_body["error"]).to match(/insufficient balance|more points/i)

        # Verify no redeem transaction was created
        expect(Transaction.where(user_id: user.id, kind: "redeem").count).to eq(0)
      end
    end

    context "with inactive reward" do
      before do
        Transaction.create!(
          partner_id: partner.id,
          user_id: user.id,
          activity_type: "signup",
          external_id: "evt_001",
          points_delta: 200,
          kind: "earn"
        )
      end

      it "returns 422 with error message" do
        post "/api/rewards/#{inactive_reward.id}/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(422)
        expect(response.parsed_body).to include("error")
        expect(response.parsed_body["error"]).to match(/not available|inactive/i)

        # Verify no redeem transaction was created
        expect(Transaction.where(user_id: user.id, kind: "redeem").count).to eq(0)
      end
    end

    context "with reward not found" do
      before do
        Transaction.create!(
          partner_id: partner.id,
          user_id: user.id,
          activity_type: "signup",
          external_id: "evt_001",
          points_delta: 200,
          kind: "earn"
        )
      end

      it "returns 404" do
        post "/api/rewards/9999/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(404)
      end
    end

    context "with missing authentication" do
      it "returns 401 Unauthorized" do
        post "/api/rewards/#{reward.id}/redeem"

        expect(response).to have_http_status(401)
      end
    end

    context "with invalid authentication" do
      it "returns 401 Unauthorized" do
        post "/api/rewards/#{reward.id}/redeem",
          headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(401)
      end
    end

    context "with zero balance user" do
      it "returns 422 with insufficient balance error" do
        post "/api/rewards/#{reward.id}/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(422)
        expect(response.parsed_body["error"]).to match(/insufficient balance|more points/i)
      end
    end
  end
end
