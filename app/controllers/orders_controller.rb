class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item
  before_action :redirect_if_self_item
  before_action :redirect_if_sold_out

  def index
    @order_address = OrderAddress.new
  end

  def create
    @order_address = OrderAddress.new(order_params)
    return render(:index, status: :unprocessable_entity) unless @order_address.valid?

    # 決済（失敗してもアラートは出さずフォーム再表示）
    begin
      pay_item
    rescue Payjp::AuthenticationError, Payjp::InvalidRequestError, Payjp::CardError
      @order_address.errors.add(:base, 'カードの認証/決済に失敗しました。')
      return render :index, status: :unprocessable_entity
    rescue => _
      @order_address.errors.add(:base, '決済でエラーが発生しました。')
      return render :index, status: :unprocessable_entity
    end

    # 保存（ユニーク制約などで失敗時もフォーム再表示）
    if @order_address.save
      redirect_to root_path
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_item
    @item = Item.find(params[:item_id])
  end

  def redirect_if_self_item
    redirect_to root_path if current_user == @item.user
  end

  def redirect_if_sold_out
    redirect_to root_path if @item.order.present?
  end

  def order_params
    params.require(:order_address).permit(
      :postal_code, :prefecture_id, :city, :block, :building, :phone_number, :token
    ).merge(user_id: current_user.id, item_id: @item.id)
  end

  def pay_item
    return if Rails.env.test? # テストでは外部決済しない
    Payjp.api_key = ENV['PAYJP_SECRET_KEY']
    Payjp::Charge.create(
      amount: @item.price,
      card:   order_params[:token],
      currency: 'jpy'
    )
  end
end
