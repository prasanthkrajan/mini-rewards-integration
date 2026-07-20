class AddInventoryToRewards < ActiveRecord::Migration[8.1]
  def change
    add_column :rewards, :inventory, :integer
    add_column :rewards, :redeemed_count, :integer
    add_column :rewards, :expires_at, :datetime
  end
end
