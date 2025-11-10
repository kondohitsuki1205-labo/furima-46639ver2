class OrderAddress
  include ActiveModel::Model
  attr_accessor :user_id, :item_id, :postal_code, :prefecture_id, :city, :block, :building, :phone_number, :token

  with_options presence: true do
    validates :user_id, :item_id, :city, :block
    validates :postal_code,  format: { with: /\A\d{3}-\d{4}\z/ }
    validates :phone_number, format: { with: /\A\d{10,11}\z/ }
  end
  validates :prefecture_id, numericality: { other_than: 1 }

  def save
    order = Order.create!(user_id:, item_id:)
    Address.create!(
      order_id: order.id, postal_code:, prefecture_id:, city:, block:, building:, phone_number:
    )
  end
end