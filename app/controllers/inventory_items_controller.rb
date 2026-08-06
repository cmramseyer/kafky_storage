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
    if @inventory_item.update(inventory_item_params)
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
end
