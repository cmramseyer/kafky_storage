require "json"

class CatalogEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      process_message(message)
    end
  end

  private

  def process_message(message)
    payload = message.payload.is_a?(String) ? JSON.parse(message.payload) : message.payload
    return unless payload.fetch("event_type") == "product.created"

    validate_product_created_event!(payload)
    data = payload.fetch("data")

    InventoryItem.find_or_create_by!(product_sku: data.fetch("sku")) do |item|
      item.item_desc = data.fetch("product_desc")
    end
  end

  def validate_product_created_event!(payload)
    return if payload.fetch("source") == "kafky_prices" && payload.fetch("event_version").to_i == 1

    raise ArgumentError,
          "Unsupported product.created source=#{payload.fetch("source").inspect} event_version=#{payload.fetch("event_version").inspect}"
  end
end
