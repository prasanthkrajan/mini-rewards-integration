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

## Running Tests

```bash
bundle exec rspec                 # Run full suite
bundle exec rspec spec/models     # Run model specs only
bundle exec rspec --format doc    # Verbose output
```

Tests use the `mini_rewards_integration_test` database (auto-populated from migrations).

