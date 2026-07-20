require 'rails_helper'

RSpec.describe "Rewards", type: :request do
  let!(:user) { User.create!(name: "Alice", email: "alice@example.com") }
  let!(:partner) { Partner.create!(name: "Partner A", api_key_digest: BCrypt::Password.create("secret")) }

  # Helper to authenticate as a user
  def auth_header_for(user)
    { "Authorization" => "Bearer user_#{user.id}" }
  end

  describe "POST /rewards/:reward_id/redeem" do
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
        post "/rewards/#{reward.id}/redeem",
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
        post "/rewards/#{reward.id}/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(200)
        expect(response.parsed_body["success"]).to be true
      end

      it "sets correct new_balance after redemption" do
        post "/rewards/#{reward.id}/redeem",
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
        post "/rewards/#{reward.id}/redeem",
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
        post "/rewards/#{inactive_reward.id}/redeem",
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
        post "/rewards/9999/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(404)
      end
    end

    context "with missing authentication" do
      it "returns 401 Unauthorized" do
        post "/rewards/#{reward.id}/redeem"

        expect(response).to have_http_status(401)
      end
    end

    context "with invalid authentication" do
      it "returns 401 Unauthorized" do
        post "/rewards/#{reward.id}/redeem",
          headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(401)
      end
    end

    context "with zero balance user" do
      it "returns 422 with insufficient balance error" do
        post "/rewards/#{reward.id}/redeem",
          headers: auth_header_for(user)

        expect(response).to have_http_status(422)
        expect(response.parsed_body["error"]).to match(/insufficient balance|more points/i)
      end
    end
  end
end
