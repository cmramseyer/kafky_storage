require "securerandom"

class InventoryItemsController < ApplicationController
  before_action :set_inventory_item, only: %i[show edit update]

  def index
    @inventory_items = InventoryItem.order(:product_sku)
  end

  def show
  end

  def edit
  end

  def update
    @inventory_item.assign_attributes(inventory_item_params)

    if save_inventory_item_with_stock_event
      redirect_to @inventory_item, notice: "Inventory settings were updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_inventory_item
    @inventory_item = InventoryItem.find(params[:id])
  end

  def inventory_item_params
    params.require(:inventory_item).permit(:available_quantity, :reorder_point)
  end

  def save_inventory_item_with_stock_event
    stock_changed = @inventory_item.will_save_change_to_available_quantity?
    saved = false

    InventoryItem.transaction do
      saved = @inventory_item.save
      create_stock_updated_event if saved && stock_changed
    end

    saved
  end

  def create_stock_updated_event
    event_id = SecureRandom.uuid

    OutboxEvent.create!(
      event_id: event_id,
      event_type: "inventory.stock_updated",
      aggregate_type: "InventoryItem",
      aggregate_id: @inventory_item.id,
      payload: {
        event_id: event_id,
        event_type: "inventory.stock_updated",
        event_version: 1,
        source: "kafky_storage",
        occurred_at: Time.current.iso8601,
        data: {
          sku: @inventory_item.product_sku,
          available_quantity: @inventory_item.available_quantity
        }
      }
    )
  end
end
