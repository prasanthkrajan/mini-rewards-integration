class JwtService
  SECRET = Rails.application.secret_key_base

  def self.encode(user_id, exp = 24.hours.from_now)
    payload = {
      user_id: user_id,
      exp: exp.to_i
    }
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.decode(token)
    JWT.decode(token, SECRET, true, algorithm: 'HS256')[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    nil
  end
end
