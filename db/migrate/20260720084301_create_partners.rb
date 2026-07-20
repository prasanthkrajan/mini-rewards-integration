class CreatePartners < ActiveRecord::Migration[8.1]
  def change
    create_table :partners do |t|
      t.string :name, null: false
      t.string :api_key_digest, null: false
      t.timestamps
    end
    add_index :partners, :api_key_digest, unique: true
  end
end
