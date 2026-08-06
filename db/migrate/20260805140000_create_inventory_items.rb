class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.string :product_sku, null: false
      t.text :item_desc, null: false
      t.integer :available_quantity, null: false, default: 0
      t.integer :reorder_point, null: false, default: 0

      t.timestamps
    end

    add_index :inventory_items, :product_sku, unique: true
  end
end
