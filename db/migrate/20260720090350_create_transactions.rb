class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :partner, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :points_delta, null: false
      t.decimal :amount
      t.string :kind, null: false
      t.string :external_id, null: false
      t.string :activity_type, null: false

      t.timestamps
    end
    add_index :transactions, [:partner_id, :user_id, :external_id], unique: true
  end
end
