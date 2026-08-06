class InventoryItem < ApplicationRecord
  validates :product_sku, :item_desc, presence: true
  validates :product_sku, uniqueness: true
  validates :available_quantity, :reorder_point,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
