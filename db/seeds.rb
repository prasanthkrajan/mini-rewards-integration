puts "Seeding database..."

# ===== USERS =====
users_data = [
  { name: "Alice Johnson", email: "alice@example.com", password: "alice123" },
  { name: "Bob Smith", email: "bob@example.com", password: "bob123" },
  { name: "Carol White", email: "carol@example.com", password: "carol123" },
  { name: "David Brown", email: "david@example.com", password: "david123" }
]

users = {}
users_data.each do |data|
  user = User.find_or_create_by(email: data[:email]) do |u|
    u.name = data[:name]
    u.password = data[:password]
  end

  # Update password if user exists without password_digest (idempotency)
  if user.password_digest.blank?
    user.update!(password: data[:password])
  end

  users[data[:email]] = user
  puts "✓ User: #{user.email} (ID: #{user.id})"
end

# ===== PARTNERS =====
partner = Partner.find_or_create_by(name: "Demo Partner") do |p|
  p.api_key_digest = BCrypt::Password.create("demo_secret_key_123")
end
puts "✓ Partner: #{partner.name}"

# ===== REWARDS =====
rewards_data = [
  { name: "Free Coffee", description: "Get a free espresso at our cafe", points_required: 50 },
  { name: "$5 Discount", description: "Save $5 on your next purchase", points_required: 100 },
  { name: "Free Movie Ticket", description: "Enjoy a movie night on us", points_required: 150 },
  { name: "Premium Membership", description: "1 month of premium benefits", points_required: 200 }
]

rewards = {}
rewards_data.each do |data|
  reward = Reward.find_or_create_by(name: data[:name]) do |r|
    r.description = data[:description]
    r.points_required = data[:points_required]
    r.active = true
  end
  rewards[data[:name]] = reward
  puts "✓ Reward: #{reward.name} (#{reward.points_required} points)"
end

# ===== TRANSACTIONS (Credit Points to Users) =====
# Use unique external_id format: activity_<user_email>_<activity_type>_v1
# This ensures idempotency — same user/activity won't create duplicate transactions

transactions_to_create = [
  # Alice: signup (100 pts) + purchase (50 pts) = 150 total
  { user_email: "alice@example.com", activity_type: "signup", points_delta: 100, amount: nil, external_id: "activity_alice@example.com_signup_v1" },
  { user_email: "alice@example.com", activity_type: "purchase", points_delta: 50, amount: 50, external_id: "activity_alice@example.com_purchase_v1" },

  # Bob: signup (100 pts) + referral (50 pts) = 150 total
  { user_email: "bob@example.com", activity_type: "signup", points_delta: 100, amount: nil, external_id: "activity_bob@example.com_signup_v1" },
  { user_email: "bob@example.com", activity_type: "referral", points_delta: 50, amount: nil, external_id: "activity_bob@example.com_referral_v1" },

  # Carol: signup (100 pts) + two purchases (75 pts) = 175 total
  { user_email: "carol@example.com", activity_type: "signup", points_delta: 100, amount: nil, external_id: "activity_carol@example.com_signup_v1" },
  { user_email: "carol@example.com", activity_type: "purchase", points_delta: 50, amount: 50, external_id: "activity_carol@example.com_purchase_1_v1" },
  { user_email: "carol@example.com", activity_type: "purchase", points_delta: 25, amount: 25, external_id: "activity_carol@example.com_purchase_2_v1" },

  # David: signup (100 pts) only = 100 total
  { user_email: "david@example.com", activity_type: "signup", points_delta: 100, amount: nil, external_id: "activity_david@example.com_signup_v1" }
]

transactions_to_create.each do |tx_data|
  user = users[tx_data[:user_email]]

  # Check if transaction already exists (idempotency check)
  existing = Transaction.find_by(
    partner_id: partner.id,
    user_id: user.id,
    external_id: tx_data[:external_id]
  )

  if existing
    puts "  ✓ Transaction already exists: #{user.email} - #{tx_data[:activity_type]} (#{tx_data[:points_delta]} pts)"
  else
    Transaction.create!(
      partner_id: partner.id,
      user_id: user.id,
      activity_type: tx_data[:activity_type],
      points_delta: tx_data[:points_delta],
      amount: tx_data[:amount],
      external_id: tx_data[:external_id],
      kind: "earn"
    )
    puts "  ✓ Created transaction: #{user.email} - #{tx_data[:activity_type]} (#{tx_data[:points_delta]} pts)"
  end
end

# ===== SUMMARY =====
puts "\n" + "=" * 50
puts "Seed Summary:"
puts "=" * 50
users.each do |email, user|
  balance = user.balance
  puts "#{email}: #{balance} points"
end
puts "\nRewards available: #{rewards.length}"
puts "=" * 50
puts "✓ Seeding complete!"
