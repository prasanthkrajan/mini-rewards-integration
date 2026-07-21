# Mini Rewards Integration

A Rails + PostgreSQL service demonstrating a light webhook-driven points management system

## System Requirements

- **Ruby**: 3.4.3 (see `.ruby-version`)
- **PostgreSQL**: 14+ (homebrew)
- **Bundler**: 2.6.7+ (comes with Ruby)

## Setup (Cold Clone)

### 1. Install dependencies

```bash
bundle install
```

If you hit a native-extension build error on `pg`:
```bash
bundle config set --local force_ruby_platform false
bundle lock --add-platform arm64-darwin-23  # (or your platform)
bundle install
```

### 2. Set up the database

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # Creates a stub user for testing
```

Verify Postgres is running: `psql -l` should list databases without error.

### 3. Start the server

```bash
bin/rails server
# Listens on http://localhost:3000
```

## Setup (Docker)

Alternatively, use Docker Compose to run the app with all dependencies in containers:

```bash
docker compose up
# Listens on http://localhost:3000
# PostgreSQL runs in the `db` service
```

The first time you run this, migrations and seeding happen automatically. On subsequent runs, the database persists in a Docker volume.

To run tests in Docker:
```bash
docker compose exec web bundle exec rspec
```

To access the Rails console:
```bash
docker compose exec web bundle exec rails console
```

To tear down and reset the database:
```bash
docker compose down -v  # -v removes volumes; next docker compose up re-seeds
```

## Running Tests

```bash
bundle exec rspec                 # Run full suite
bundle exec rspec spec/models     # Run model specs only
bundle exec rspec --format doc    # Verbose output
```

Tests use the `mini_rewards_integration_test` database (auto-populated from migrations).

## Testing Guide: Crediting Points for Development

### Quick Start

Credit a user with 100 points for a referral activity (for testing crediting and redemption):

**Using Rake Task (Recommended):**
```bash
bundle exec rake 'credit:referral[alice@example.com]'
```

(Note: Use quotes to escape the square brackets in zsh)

**Using Bash Script:**
```bash
chmod +x script/credit_referral.sh
./script/credit_referral.sh alice@example.com
```

Both scripts:
- Consume the webhook endpoint with proper authentication
- Create referral activity transactions
- Credit exactly 100 points
- Show updated user balance
- Work with any seeded user email
- Are idempotent (won't double-credit on repeated runs)

### Available Test Users (Seeded)

```
alice@example.com / alice123      → 150 points (pre-seeded)
bob@example.com / bob123          → 150 points (pre-seeded)
carol@example.com / carol123      → 175 points (pre-seeded)
david@example.com / david123      → 100 points (pre-seeded)
```

To create additional users:

```bash
rails console
User.create!(name: "Jane Doe", email: "jane@example.com", password: "password123")
```

### Testing Workflow

#### 1. Credit a User

```bash
bundle exec rake credit:referral["alice@example.com"]
```

Output:
```
Referral activity recorded successfully!

 Details:
   User: alice@example.com
   Points Earned: 100
   Activity Type: referral
   Transaction ID: 42
   External ID: ref_1726854123_5678

New Balance: 250 points
```

#### 2. Check Balance via API

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"alice123"}' \
  | jq -r '.token')

curl -s http://localhost:3000/api/me/balance \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### 3. Redeem a Reward

Login at `http://localhost:3000/login` and redeem from the dashboard.

#### 4. View Transaction History

In the dashboard, click the "History" tab to see all earn and redeem transactions.

### Idempotency

Running the credit command multiple times generates unique `external_id` values, so each run counts as a separate referral. The webhook endpoint prevents double-crediting via DB-enforced unique constraint on `(partner_id, user_id, external_id)`.

### Troubleshooting

**User not found error:**
```
User not found: unknown@example.com
   Available users:
     - alice@example.com
     - bob@example.com
```
Create the user first using Rails console (shown above).

**Connection refused error:**
Ensure Rails server is running with `bin/rails server`.

### Manual Webhook Testing

To manually test the webhook endpoint with curl:

```bash
curl -X POST http://localhost:3000/webhooks/activity \
  -H "Authorization: Bearer partner_a_secret_key_123" \
  -H "Content-Type: application/json" \
  -d '{
    "partner_user_id": "alice",
    "activity_type": "referral",
    "external_id": "ref_manual_001",
    "occurred_at": "2026-07-21T10:00:00Z"
  }'
```

Expected response:
```json
{
  "status": "credited",
  "transaction_id": 42
}
```

### Points Rules

Current hardcoded points rules for activities:

- `signup` → 100 points (flat)
- `referral` → 50 points (flat)
- `purchase` → 1 point per $1 (requires `amount` field)

