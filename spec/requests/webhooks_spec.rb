require 'rails_helper'

RSpec.describe "Webhooks", type: :request do
  describe "POST /webhooks/activity" do
    let!(:partner) { Partner.create!(name: "Partner A", api_key_digest: BCrypt::Password.create("secret_key_123")) }
    let!(:user) { User.create!(name: "Alice", email: "alice@example.com") }
    let!(:partner_user_mapping) { PartnerUserMapping.create!(partner: partner, user: user, partner_user_id: "cust_123") }
    
    let(:valid_payload) do
      {
        partner_user_id: "cust_123",
        activity_type: "signup",
        external_id: "evt_001",
        occurred_at: Time.current.iso8601
      }
    end

    context "with valid API key" do
      it "accepts the webhook and returns 202" do
        post '/webhooks/activity',
          params: valid_payload,
          headers: { "Authorization" => "Bearer secret_key_123" }
        
        expect(response).to have_http_status(202)
        expect(response.parsed_body).to include("status" => "received")
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
  end
end