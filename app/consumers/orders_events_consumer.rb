require "json"

class OrdersEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      process_message(message)
    end
  end

  private

  def process_message(message)
    payload = message.payload.is_a?(String) ? JSON.parse(message.payload) : message.payload
    validate_order_created_event!(payload)

    payload.fetch("data").fetch("order").fetch("products").each do |product_payload|
      decrement_stock(product_payload)
    end
  end

  def decrement_stock(product_payload)
    sku = product_payload.fetch("sku")
    quantity = product_payload.fetch("quantity").to_i
    return unless quantity.positive?

    InventoryItem.transaction do
      inventory_item = InventoryItem.lock.find_by(product_sku: sku)
      return unless inventory_item
      return if quantity > inventory_item.available_quantity

      stock_before = inventory_item.available_quantity
      stock_after = stock_before - quantity

      inventory_item.update!(available_quantity: stock_after)
      InventoryStockUpdatedEvent.create!(inventory_item)
      InventoryLowStockEvent.create!(inventory_item) if stock_before > inventory_item.reorder_point &&
                                                       stock_after <= inventory_item.reorder_point
    end
  end

  def validate_order_created_event!(payload)
    return if payload.fetch("event_type") == "order.created" &&
              payload.fetch("source") == "kafky" &&
              payload.fetch("event_version").to_i == 1

    raise ArgumentError,
          "Unsupported order.created source=#{payload.fetch("source").inspect} event_version=#{payload.fetch("event_version").inspect}"
  end
end
