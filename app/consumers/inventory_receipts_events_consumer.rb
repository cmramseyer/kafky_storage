require "json"

class InventoryReceiptsEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      process_message(message)
    end
  end

  private

  def process_message(message)
    payload = message.payload.is_a?(String) ? JSON.parse(message.payload) : message.payload
    validate_stock_added_event!(payload)

    data = payload.fetch("data")
    quantity = data.fetch("quantity").to_i
    raise ArgumentError, "Received stock quantity must be positive" unless quantity.positive?

    data.fetch("provider_order_id")

    inventory_item = InventoryItem.transaction do
      inventory_item = InventoryItem.lock.find_by!(product_sku: data.fetch("sku"))
      inventory_item.update!(available_quantity: inventory_item.available_quantity + quantity)
      InventoryStockUpdatedEvent.create!(inventory_item)
      inventory_item
    end
    InventoryItemBroadcaster.available_quantity_changed(inventory_item, direction: "increased")
  end

  def validate_stock_added_event!(payload)
    return if payload.fetch("event_type") == "inventory.stock_added" &&
              payload.fetch("source") == "kafky_providers" &&
              payload.fetch("event_version").to_i == 1

    raise ArgumentError,
          "Unsupported inventory.stock_added source=#{payload.fetch("source").inspect} event_version=#{payload.fetch("event_version").inspect}"
  end
end
