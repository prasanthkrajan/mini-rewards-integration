require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "alice123") }

  describe "POST /login" do
    context "with valid credentials" do
      it "returns a JWT token" do
        post '/login', params: {
          email: "alice@example.com",
          password: "alice123"
        }

        expect(response).to have_http_status(200)
        body = response.parsed_body
        expect(body).to include("token")
        expect(body["token"]).to be_present
      end

      it "returns user information" do
        post '/login', params: {
          email: "alice@example.com",
          password: "alice123"
        }

        body = response.parsed_body
        expect(body["user"]).to include(
          "id" => user.id,
          "email" => "alice@example.com",
          "name" => "Alice"
        )
      end

      it "returns a valid JWT token that can be decoded" do
        post '/login', params: {
          email: "alice@example.com",
          password: "alice123"
        }

        token = response.parsed_body["token"]
        decoded = JwtService.decode(token)
        expect(decoded["user_id"]).to eq(user.id)
      end
    end

    context "with invalid email" do
      it "returns 401 Unauthorized" do
        post '/login', params: {
          email: "nonexistent@example.com",
          password: "alice123"
        }

        expect(response).to have_http_status(401)
        expect(response.parsed_body).to include("error" => "Invalid email or password")
      end
    end

    context "with invalid password" do
      it "returns 401 Unauthorized" do
        post '/login', params: {
          email: "alice@example.com",
          password: "wrongpassword"
        }

        expect(response).to have_http_status(401)
        expect(response.parsed_body).to include("error" => "Invalid email or password")
      end
    end

    context "with missing email" do
      it "returns 400 Bad Request" do
        post '/login', params: {
          password: "alice123"
        }

        expect(response).to have_http_status(400)
        expect(response.parsed_body).to include("error")
      end
    end

    context "with missing password" do
      it "returns 400 Bad Request" do
        post '/login', params: {
          email: "alice@example.com"
        }

        expect(response).to have_http_status(400)
        expect(response.parsed_body).to include("error")
      end
    end
  end

end
