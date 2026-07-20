require 'rails_helper'

RSpec.describe User do
  let(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "alice123") }
  let(:other_user) { User.create!(name: "Bob", email: "bob@example.com", password: "bob123") }
  let(:partner) { Partner.create!(name: "Partner A", api_key_digest: BCrypt::Password.create("secret")) }

  describe "#balance" do
    it "returns 0 for user with no transactions" do
      expect(user.balance).to eq(0)
    end

    it "returns the sum of all positive transactions" do
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
        kind: "earn"
      )

      expect(user.balance).to eq(150)
    end

    it "includes negative transactions in the sum" do
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
        activity_type: "redeem",
        external_id: "evt_002",
        points_delta: -30,
        kind: "redeem"
      )

      expect(user.balance).to eq(70)
    end

    it "only includes transactions for the specified user" do
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
        points_delta: 200,
        kind: "earn"
      )

      expect(user.balance).to eq(100)
    end

    it "includes transactions from multiple partners" do
      partner2 = Partner.create!(name: "Partner B", api_key_digest: BCrypt::Password.create("secret2"))

      Transaction.create!(
        partner_id: partner.id,
        user_id: user.id,
        activity_type: "signup",
        external_id: "evt_001",
        points_delta: 100,
        kind: "earn"
      )
      Transaction.create!(
        partner_id: partner2.id,
        user_id: user.id,
        activity_type: "signup",
        external_id: "evt_002",
        points_delta: 50,
        kind: "earn"
      )

      expect(user.balance).to eq(150)
    end
  end
end
