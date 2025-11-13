class OrderAddress
  include ActiveModel::Model
  attr_accessor :postal_code, :prefecture_id, :city, :block, :building,
                :phone_number, :user_id, :item_id, :token

  with_options presence: true do
    validates :user_id, :item_id, :token
    validates :postal_code, :city, :block, :phone_number
  end
  validates :prefecture_id, numericality: { other_than: 1 }
  validates :postal_code,   format: { with: /\A\d{3}-\d{4}\z/ }
  validates :phone_number,  format: { with: /\A\d{10,11}\z/ }

  def save
    return false unless valid?
    ActiveRecord::Base.transaction do
      order = Order.create!(user_id: user_id, item_id: item_id)
      Address.create!(
        postal_code: postal_code, prefecture_id: prefecture_id, city: city,
        block: block, building: building, phone_number: phone_number, order_id: order.id
      )
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
