require "test_helper"

class CatalogEventsConsumerTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "creates an inventory item and broadcasts the highlighted list" do
    streams = capture_turbo_stream_broadcasts("inventory_items") do
      process_message(
        event_type: "product.created",
        source: "kafky_prices",
        data: { sku: "KEYBOARD-1", product_desc: "Keyboard" }
      )
    end

    inventory_item = InventoryItem.find_by!(product_sku: "KEYBOARD-1")

    assert_equal "Keyboard", inventory_item.item_desc
    assert_equal "replace", streams.first["action"]
    assert_equal "inventory_items", streams.first["target"]
    assert_includes streams.first.at("template").inner_html, "inventory-item-created"
    assert_includes streams.first.at("template").inner_html, "KEYBOARD-1"
  end

  test "does not broadcast when a retried event finds the inventory item" do
    InventoryItem.create!(product_sku: "KEYBOARD-1", item_desc: "Keyboard")

    assert_no_turbo_stream_broadcasts "inventory_items" do
      process_message(
        event_type: "product.created",
        source: "kafky_prices",
        data: { sku: "KEYBOARD-1", product_desc: "Keyboard" }
      )
    end
  end

  private

  def process_message(event_type:, source:, data:)
    payload = { event_type: event_type, event_version: 1, source: source, data: data }
    message = Struct.new(:payload).new(payload.to_json)

    CatalogEventsConsumer.new.send(:process_message, message)
  end
end
