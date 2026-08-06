require "securerandom"

class InventoryLowStockEvent
  def self.create!(inventory_item)
    event_id = SecureRandom.uuid

    OutboxEvent.create!(
      event_id: event_id,
      event_type: "inventory.low_stock",
      aggregate_type: "InventoryItem",
      aggregate_id: inventory_item.id,
      payload: {
        event_id: event_id,
        event_type: "inventory.low_stock",
        event_version: 1,
        source: "kafky_storage",
        occurred_at: Time.current.iso8601,
        data: {
          product: {
            sku: inventory_item.product_sku,
            item_desc: inventory_item.item_desc,
            available_quantity: inventory_item.available_quantity,
            reorder_point: inventory_item.reorder_point
          }
        }
      }
    )
  end
end
