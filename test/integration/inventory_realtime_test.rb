require "test_helper"

class InventoryRealtimeTest < ActionDispatch::IntegrationTest
  test "renders live inventory targets on the index and detail pages" do
    inventory_item = InventoryItem.create!(
      product_sku: "KEYBOARD-1",
      item_desc: "Keyboard",
      available_quantity: 10,
      reorder_point: 3
    )
    quantity_target = ActionView::RecordIdentifier.dom_id(inventory_item, :available_quantity)

    get inventory_items_path

    assert_response :success
    assert_select "turbo-cable-stream-source[signed-stream-name]", count: 1
    assert_select "#inventory_items"
    assert_select "span##{quantity_target}", text: "10"

    get inventory_item_path(inventory_item)

    assert_response :success
    assert_select "turbo-cable-stream-source[signed-stream-name]", count: 1
    assert_select "span##{quantity_target}", text: "10"
  end
end
