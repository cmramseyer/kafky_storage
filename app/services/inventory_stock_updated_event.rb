require "securerandom"

class InventoryStockUpdatedEvent
  def self.create!(inventory_item)
    event_id = SecureRandom.uuid

    OutboxEvent.create!(
      event_id: event_id,
      event_type: "inventory.stock_updated",
      aggregate_type: "InventoryItem",
      aggregate_id: inventory_item.id,
      payload: {
        event_id: event_id,
        event_type: "inventory.stock_updated",
        event_version: 1,
        source: "kafky_storage",
        occurred_at: Time.current.iso8601,
        data: {
          sku: inventory_item.product_sku,
          available_quantity: inventory_item.available_quantity
        }
      }
    )
  end
end
