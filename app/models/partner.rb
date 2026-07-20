class Partner < ApplicationRecord
	has_many :transactions

  validates :name, presence: true, uniqueness: true
  validates :api_key_digest, presence: true, uniqueness: true
end
