class Partner < ApplicationRecord
	has_many :transactions

  validates :name, presence: true, uniqueness: true
  validates :api_key_digest, presence: true, uniqueness: true

  def self.authenticate_by_api_key(key)
	  all.find { |p| p.authenticate_api_key(key) }
	end

	def authenticate_api_key(key)
	  BCrypt::Password.new(api_key_digest) == key ? self : nil
	end
end
