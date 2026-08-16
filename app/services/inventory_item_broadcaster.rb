class InventoryItemBroadcaster
  STREAM_NAME = "inventory_items"

  def self.created(inventory_item)
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM_NAME,
      target: "inventory_items",
      partial: "inventory_items/inventory_list",
      locals: {
        inventory_items: InventoryItem.order(:product_sku),
        highlight_inventory_item_id: inventory_item.id
      }
    )
  end

  def self.available_quantity_changed(inventory_item, direction:)
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM_NAME,
      target: ActionView::RecordIdentifier.dom_id(inventory_item, :available_quantity),
      partial: "inventory_items/available_quantity_update",
      locals: { inventory_item: inventory_item, direction: direction }
    )
  end
end
