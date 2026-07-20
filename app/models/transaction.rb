class Transaction < ApplicationRecord
  belongs_to :partner, optional: true
  belongs_to :user
end
