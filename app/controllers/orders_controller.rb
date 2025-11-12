# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item

  def index
    @order_address = OrderAddress.new
    # ここに「出品者は購入不可」「売却済みは不可」等のガードがあるなら、テスト条件と矛盾してないかも確認
  end

  def create
    @order_address = OrderAddress.new(order_params)

    if @order_address.valid?
      pay_item               # ↓テストでは無害化（次章）
      @order_address.save
      redirect_to root_path
    else
      # 失敗理由のログ（デバッグに有用）
      Rails.logger.info("[ORDER_ERRORS] #{@order_address.errors.full_messages.join(', ')}")
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_item
    @item = Item.find(params[:item_id])
  end

  def order_params
    params.require(:order_address).permit(
      :postal_code, :prefecture_id, :city, :block, :building, :phone_number, :token
    ).merge(user_id: current_user.id, item_id: @item.id)
  end

  def pay_item
    return if Rails.env.test?  # ← テストでは外部決済をスキップ
    Payjp.api_key = ENV['PAYJP_SECRET_KEY']
    Payjp::Charge.create(
      amount: @item.price,
      card:   order_params[:token],
      currency: 'jpy'
    )
  end
end
