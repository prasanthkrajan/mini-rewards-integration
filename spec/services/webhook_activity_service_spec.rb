require 'rails_helper'

RSpec.describe WebhookActivityService do
  let!(:partner) { Partner.create!(name: "Test Partner", api_key_digest: BCrypt::Password.create("test_key")) }
  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "test123") }

  describe ".process" do
    context "with valid flat activity (signup)" do
      let(:payload) do
        {
          activity_type: "signup",
          external_id: "evt_001",
          amount: nil
        }
      end

      it "creates a transaction with correct points_delta" do
        result = described_class.process(partner: partner, user: user, payload: payload)

        expect(result[:success]).to be true
        expect(result[:transaction]).to be_persisted
        expect(result[:transaction].points_delta).to eq(100)
        expect(result[:transaction].activity_type).to eq("signup")
        expect(result[:transaction].kind).to eq("earn")
        expect(result[:error]).to be_nil
      end

      it "stores the external_id for idempotency" do
        result = described_class.process(partner: partner, user: user, payload: payload)
        tx = result[:transaction]

        expect(tx.external_id).to eq("evt_001")
        expect(tx.partner_id).to eq(partner.id)
        expect(tx.user_id).to eq(user.id)
      end
    end

    context "with valid per-unit activity (purchase)" do
      let(:payload) do
        {
          activity_type: "purchase",
          external_id: "evt_002",
          amount: 50
        }
      end

      it "creates a transaction with correct points_delta" do
        result = described_class.process(partner: partner, user: user, payload: payload)

        expect(result[:success]).to be true
        expect(result[:transaction].points_delta).to eq(50)
        expect(result[:transaction].amount).to eq(50)
        expect(result[:transaction].activity_type).to eq("purchase")
      end

      it "calculates points correctly for different amounts" do
        amounts_and_points = [
          [10, 10],
          [50, 50],
          [100, 100],
          [0.5, 0]  # converted to int, so 0.5 rounds down
        ]

        amounts_and_points.each do |amount, expected_points|
          result = described_class.process(
            partner: partner,
            user: user,
            payload: payload.merge(amount: amount, external_id: "evt_#{amount}")
          )
          expect(result[:transaction].points_delta).to eq(expected_points)
        end
      end
    end

    context "with valid referral activity" do
      let(:payload) do
        {
          activity_type: "referral",
          external_id: "evt_003",
          amount: nil
        }
      end

      it "creates a transaction with 50 points" do
        result = described_class.process(partner: partner, user: user, payload: payload)

        expect(result[:success]).to be true
        expect(result[:transaction].points_delta).to eq(50)
        expect(result[:transaction].activity_type).to eq("referral")
      end
    end

    context "with idempotency (duplicate external_id)" do
      let(:payload) do
        {
          activity_type: "signup",
          external_id: "evt_001",
          amount: nil
        }
      end

      it "returns success on duplicate, but doesn't create a second transaction" do
        # First call
        result1 = described_class.process(partner: partner, user: user, payload: payload)
        expect(result1[:success]).to be true
        expect(Transaction.count).to eq(1)

        # Second call with same external_id
        result2 = described_class.process(partner: partner, user: user, payload: payload)
        expect(result2[:success]).to be true
        expect(result2[:idempotent]).to be true
        expect(result2[:transaction]).to be_nil
        expect(Transaction.count).to eq(1)
      end

      it "allows different users to have the same external_id from the same partner" do
        user2 = User.create!(name: "User 2", email: "user2@example.com", password: "user2123")

        # First user
        result1 = described_class.process(partner: partner, user: user, payload: payload)
        expect(result1[:success]).to be true

        # Second user with same external_id
        result2 = described_class.process(partner: partner, user: user2, payload: payload)
        expect(result2[:success]).to be true
        expect(result2[:idempotent]).to be false
        expect(Transaction.count).to eq(2)
      end
    end

    context "with invalid activity_type" do
      let(:payload) do
        {
          activity_type: "unknown_activity",
          external_id: "evt_004",
          amount: nil
        }
      end

      it "returns an error with 422 status" do
        result = described_class.process(partner: partner, user: user, payload: payload)

        expect(result[:success]).to be false
        expect(result[:error]).to include("unknown activity_type")
        expect(result[:status]).to eq(422)
        expect(result[:transaction]).to be_nil
        expect(Transaction.count).to eq(0)
      end
    end

    context "with missing activity_type" do
      let(:payload) do
        {
          activity_type: nil,
          external_id: "evt_005",
          amount: nil
        }
      end

      it "returns an error with 422 status" do
        result = described_class.process(partner: partner, user: user, payload: payload)

        expect(result[:success]).to be false
        expect(result[:error]).to include("activity_type is required")
        expect(result[:status]).to eq(422)
        expect(Transaction.count).to eq(0)
      end
    end

    context "with per-unit activity missing amount" do
      let(:payload) do
        {
          activity_type: "purchase",
          external_id: "evt_006",
          amount: nil
        }
      end

      it "returns an error with 422 status" do
        result = described_class.process(partner: partner, user: user, payload: payload)

        expect(result[:success]).to be false
        expect(result[:error]).to include("requires 'amount' field")
        expect(result[:status]).to eq(422)
        expect(Transaction.count).to eq(0)
      end
    end

    context "with missing external_id" do
      let(:payload) do
        {
          activity_type: "signup",
          external_id: nil,
          amount: nil
        }
      end

      it "returns an error with 422 status" do
        result = described_class.process(partner: partner, user: user, payload: payload)

        expect(result[:success]).to be false
        expect(result[:error]).to include("external_id is required")
        expect(result[:status]).to eq(422)
        expect(Transaction.count).to eq(0)
      end
    end

    context "with per-unit activity with zero amount" do
      let(:payload) do
        {
          activity_type: "purchase",
          external_id: "evt_007",
          amount: 0
        }
      end

      it "accepts zero amount and calculates 0 points" do
        result = described_class.process(partner: partner, user: user, payload: payload)

        expect(result[:success]).to be true
        expect(result[:transaction].points_delta).to eq(0)
        expect(result[:transaction].amount).to eq(0)
      end
    end
  end
end
