require "test_helper"

class InventoryReceiptsEventsConsumerTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "increases available quantity and broadcasts a green update" do
    inventory_item = InventoryItem.create!(
      product_sku: "KEYBOARD-1",
      item_desc: "Keyboard",
      available_quantity: 10,
      reorder_point: 3
    )

    streams = capture_turbo_stream_broadcasts("inventory_items") do
      process_message(inventory_item.product_sku, 4)
    end

    assert_equal 14, inventory_item.reload.available_quantity
    assert_equal "replace", streams.first["action"]
    assert_equal ActionView::RecordIdentifier.dom_id(inventory_item, :available_quantity), streams.first["target"]
    assert_includes streams.first.at("template").inner_html, "inventory-quantity-update--increased"
    assert_includes streams.first.at("template").inner_html, "14"
  end

  private

  def process_message(sku, quantity)
    payload = {
      event_type: "inventory.stock_added",
      event_version: 1,
      source: "kafky_providers",
      data: { sku: sku, quantity: quantity, provider_order_id: 1 }
    }
    message = Struct.new(:payload).new(payload.to_json)

    InventoryReceiptsEventsConsumer.new.send(:process_message, message)
  end
end
