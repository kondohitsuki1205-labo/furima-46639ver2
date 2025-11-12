# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update]
  before_action :set_item,          only: [:show, :edit, :update]
  before_action :author_only,       only: [:edit, :update]

  def index
    @items = Item.includes(:order, image_attachment: :blob).order(created_at: :desc)
  end

  def show; end

  def new
    @item = Item.new
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to root_path
    else
      flash.now[:alert] = '入力内容を確認してください。'
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @item.update(item_params)
      redirect_to item_path(@item)
    else
      flash.now[:alert] = '入力内容を確認してください。'
      render :edit, status: :unprocessable_entity
    end
  end

  private
  def set_item
    @item = Item.find(params[:id])
  end

  # ← ここを“1つだけ”残す（出品者かつ未売却のみ可）
  def author_only
    redirect_to root_path unless current_user == @item.user && @item.order.blank?
  end

  def item_params
    params.require(:item).permit(
      :image, :name, :description, :category_id, :condition_id,
      :shipping_fee_id, :prefecture_id, :scheduled_delivery_id, :price
    ).merge(user_id: current_user.id)
  end
end
