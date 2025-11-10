class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item
  before_action :block_mine_and_sold

  def index
    @order_address = OrderAddress.new
  end

  def create
    @order_address = OrderAddress.new(order_params)
    if @order_address.valid?
      # ★ 次コミットでPAY.JP課金を実装する（pay_item）
      @order_address.save
      redirect_to root_path
    else
      render :index, status: :unprocessable_entity
    end
  end

  private
  def set_item
    @item = Item.find(params[:item_id])
  end

  def block_mine_and_sold
    redirect_to root_path if current_user == @item.user || @item.order.present?
  end

  def order_params
    params.require(:order_address).permit(:postal_code, :prefecture_id, :city, :block, :building, :phone_number)
          .merge(user_id: current_user.id, item_id: @item.id, token: params[:token])
  end
end
