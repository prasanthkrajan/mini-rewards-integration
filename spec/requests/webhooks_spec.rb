require 'rails_helper'

RSpec.describe "Webhooks", type: :request do
  describe "POST /webhooks/activity" do
    let(:valid_payload) do
      {
        partner_user_id: "cust_123",
        activity_type: "signup",
        external_id: "evt_001",
        occurred_at: Time.current.iso8601
      }
    end

    it "accepts a valid activity webhook and returns 202" do
      post '/webhooks/activity', params: valid_payload
      
      expect(response).to have_http_status(202)
      expect(response.parsed_body).to include("status" => "received")
    end
  end
end