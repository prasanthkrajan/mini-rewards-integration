namespace :credit do
  desc "Credit a user with 100 points for a referral activity"
  task :referral, [:user_email] => :environment do |_t, args|
    user_email = args[:user_email] || ENV['USER_EMAIL'] || 'alice@example.com'
    host = ENV['HOST'] || 'localhost:3000'

    # Find or create test partner
    partner = Partner.find_or_create_by!(name: 'Test Partner') do |p|
      p.api_key_digest = BCrypt::Password.create('partner_a_secret_key_123')
    end

    # Find user by email
    user = User.find_by(email: user_email)
    unless user
      puts "User not found: #{user_email}"
      puts "   Available users:"
      User.pluck(:email).each { |email| puts "     - #{email}" }
      exit 1
    end

    # Create or update partner_user_mapping
    partner_user_id = user_email.split('@').first
    mapping = PartnerUserMapping.find_or_create_by!(
      partner: partner,
      partner_user_id: partner_user_id
    ) do |m|
      m.user = user
    end

    # Create referral transaction
    external_id = "ref_#{Time.current.to_i}_#{rand(1000..9999)}"

    begin
      transaction = Transaction.create!(
        partner_id: partner.id,
        user_id: user.id,
        activity_type: 'referral',
        external_id: external_id,
        points_delta: 100,
        kind: 'earn'
      )

      puts "Referral activity recorded successfully!"
      puts ""
      puts "Details:"
      puts "   User: #{user.email}"
      puts "   Points Earned: 100"
      puts "   Activity Type: referral"
      puts "   Transaction ID: #{transaction.id}"
      puts "   External ID: #{external_id}"
      puts ""

      # Show updated balance
      balance = user.balance
      puts "New Balance: #{balance} points"
    rescue ActiveRecord::RecordNotUnique
      puts "Transaction already exists with external_id: #{external_id}"
      puts "   (This is idempotent behavior - same event won't be double-credited)"
    rescue => e
      puts "Failed to create transaction: #{e.message}"
      exit 1
    end
  end
end
