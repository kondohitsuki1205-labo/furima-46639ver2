# spec/requests/orders_spec.rb
require 'rails_helper'

RSpec.describe 'Orders', type: :request do
  let(:seller) { create(:user) }
  let(:user)   { create(:user) }                   # 購入者
  let(:item)   { create(:item, user: seller) }     # 出品者のアイテム（自分の出品物ではない）

  before { sign_in user }

  describe 'GET /items/:item_id/orders (index/new)' do
    it '200 を返す' do
      get item_orders_path(item)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /items/:item_id/orders (create)' do
    it '決済成功でリダイレクト' do
      post item_orders_path(item), params: {
        order_address: {
          postal_code: '123-4567',
          prefecture_id: 2,
          city: '横浜市緑区',
          block: '青山1-1-1',
          building: '',
          phone_number: '09012345678',
          token: 'tok_test_abc123' # ← これが strong params で許可されている必要あり
        }
      }
      expect(response).to have_http_status(:found) # 302
    end
  end
end
