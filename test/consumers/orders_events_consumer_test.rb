require "test_helper"

class OrdersEventsConsumerTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "decreases available quantity and broadcasts a red update" do
    inventory_item = InventoryItem.create!(
      product_sku: "KEYBOARD-1",
      item_desc: "Keyboard",
      available_quantity: 10,
      reorder_point: 3
    )

    streams = capture_turbo_stream_broadcasts("inventory_items") do
      process_message(inventory_item.product_sku, 4)
    end

    assert_equal 6, inventory_item.reload.available_quantity
    assert_equal "replace", streams.first["action"]
    assert_equal ActionView::RecordIdentifier.dom_id(inventory_item, :available_quantity), streams.first["target"]
    assert_includes streams.first.at("template").inner_html, "inventory-quantity-update--decreased"
    assert_includes streams.first.at("template").inner_html, "6"
  end

  private

  def process_message(sku, quantity)
    payload = {
      event_type: "order.created",
      event_version: 1,
      source: "kafky",
      data: { order: { products: [ { sku: sku, quantity: quantity } ] } }
    }
    message = Struct.new(:payload).new(payload.to_json)

    OrdersEventsConsumer.new.send(:process_message, message)
  end
end
