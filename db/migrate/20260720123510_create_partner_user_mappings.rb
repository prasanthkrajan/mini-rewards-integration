class CreatePartnerUserMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :partner_user_mappings do |t|
      t.references :partner, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :partner_user_id, null: false

      t.timestamps
    end
    add_index :partner_user_mappings, [:partner_id, :partner_user_id], unique: true
  end
end
