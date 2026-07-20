class CreateRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :rewards do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :points_required, null: false, precision: 10, scale: 2
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :rewards, :name, unique: true
  end
end
