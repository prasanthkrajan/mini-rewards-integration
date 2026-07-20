class PartnerUserMapping < ApplicationRecord
  belongs_to :partner
  belongs_to :user
end
