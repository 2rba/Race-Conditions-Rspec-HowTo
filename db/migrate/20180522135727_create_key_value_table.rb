class CreateKeyValueTable < ActiveRecord::Migration[5.2]
  def change
    create_table :key_values do |t|
      t.string :key
      t.integer :value
      t.timestamps
    end

    add_index :key_values, :key, unique: true
  end
end
