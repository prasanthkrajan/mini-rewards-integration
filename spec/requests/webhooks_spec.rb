require 'rails_helper'

RSpec.describe "Webhooks", type: :request do
  describe "POST /webhooks/activity" do
    let!(:partner) { Partner.create!(name: "Partner A", api_key_digest: BCrypt::Password.create("secret_key_123")) }
    let!(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "alice123") }
    let!(:partner_user_mapping) { PartnerUserMapping.create!(partner: partner, user: user, partner_user_id: "cust_123") }

    let(:valid_payload) do
      {
        partner_user_id: "cust_123",
        activity_type: "signup",
        external_id: "evt_001"
      }
    end

    context "with valid API key" do
      it "accepts the webhook and returns 202" do
        post '/webhooks/activity',
          params: valid_payload,
          headers: { "Authorization" => "Bearer secret_key_123" }

        expect(response).to have_http_status(202)
      end

      it "creates a transaction with correct points_delta for flat activity" do
        post '/webhooks/activity',
          params: valid_payload,
          headers: { "Authorization" => "Bearer secret_key_123" }

        expect(response).to have_http_status(202)
        tx = Transaction.last
        expect(tx.user_id).to eq(user.id)
        expect(tx.partner_id).to eq(partner.id)
        expect(tx.activity_type).to eq("signup")
        expect(tx.external_id).to eq("evt_001")
        expect(tx.points_delta).to eq(100)  # signup = 100 points (flat)
        expect(tx.kind).to eq("earn")
      end

      it "creates a transaction with correct points_delta for per-unit activity" do
        post '/webhooks/activity',
          params: valid_payload.merge(activity_type: "purchase", external_id: "evt_002", amount: 50),
          headers: { "Authorization" => "Bearer secret_key_123" }

        expect(response).to have_http_status(202)
        tx = Transaction.last
        expect(tx.activity_type).to eq("purchase")
        expect(tx.amount).to eq(50)
        expect(tx.points_delta).to eq(50)  # purchase = 1 point per $1 spent, so 50 * 1 = 50
        expect(tx.kind).to eq("earn")
      end

      it "handles duplicate external_id idempotently (returns 202, no duplicate transaction)" do
        # First request
        post '/webhooks/activity',
          params: valid_payload,
          headers: { "Authorization" => "Bearer secret_key_123" }
        expect(response).to have_http_status(202)
        expect(Transaction.count).to eq(1)

        # Second request with same external_id
        post '/webhooks/activity',
          params: valid_payload,
          headers: { "Authorization" => "Bearer secret_key_123" }
        expect(response).to have_http_status(202)
        expect(Transaction.count).to eq(1)  # No duplicate created
      end

      it "handles duplicate external_id from same partner but different user" do
        # Create another user with same partner
        user2 = User.create!(name: "Bob", email: "bob@example.com", password: "bob123")
        PartnerUserMapping.create!(partner: partner, user: user2, partner_user_id: "cust_456")

        # First request for user 1
        post '/webhooks/activity',
          params: valid_payload,
          headers: { "Authorization" => "Bearer secret_key_123" }
        expect(response).to have_http_status(202)

        # Second request for user 2 with same external_id (should succeed because it's a different user)
        post '/webhooks/activity',
          params: valid_payload.merge(partner_user_id: "cust_456"),
          headers: { "Authorization" => "Bearer secret_key_123" }
        expect(response).to have_http_status(202)
        expect(Transaction.count).to eq(2)  # Two different transactions
      end
    end

    context "with invalid API key" do
      it "returns 401 Unauthorized" do
        post '/webhooks/activity',
          params: valid_payload,
          headers: { "Authorization" => "Bearer wrong_key" }

        expect(response).to have_http_status(401)
      end
    end

    context "with missing API key" do
      it "returns 401 Unauthorized" do
        post '/webhooks/activity', params: valid_payload

        expect(response).to have_http_status(401)
      end
    end

    context "with unknown partner_user_id" do
      it "returns 404 Not Found" do
        post '/webhooks/activity',
          params: valid_payload.merge(partner_user_id: "unknown_user"),
          headers: { "Authorization" => "Bearer secret_key_123" }

        expect(response).to have_http_status(404)
      end
    end

    context "with invalid activity_type" do
      it "returns 422 with error message" do
        post '/webhooks/activity',
          params: valid_payload.merge(activity_type: "unknown_activity"),
          headers: { "Authorization" => "Bearer secret_key_123" }

        expect(response).to have_http_status(422)
        expect(response.parsed_body).to include("error")
      end
    end

    context "with per-unit activity missing amount" do
      it "returns 422 with error message" do
        post '/webhooks/activity',
          params: valid_payload.merge(activity_type: "purchase", external_id: "evt_003"),
          headers: { "Authorization" => "Bearer secret_key_123" }

        expect(response).to have_http_status(422)
        expect(response.parsed_body).to include("error")
      end
    end

    context "with missing external_id" do
      it "returns 422 with error message" do
        post '/webhooks/activity',
          params: valid_payload.except(:external_id),
          headers: { "Authorization" => "Bearer secret_key_123" }

        expect(response).to have_http_status(422)
        expect(response.parsed_body).to include("error")
      end
    end

    context "with referral activity" do
      it "creates a transaction with correct points_delta" do
        post '/webhooks/activity',
          params: valid_payload.merge(activity_type: "referral", external_id: "evt_004"),
          headers: { "Authorization" => "Bearer secret_key_123" }

        expect(response).to have_http_status(202)
        tx = Transaction.last
        expect(tx.activity_type).to eq("referral")
        expect(tx.points_delta).to eq(50)  # referral = 50 points (flat)
        expect(tx.kind).to eq("earn")
      end
    end
  end
end