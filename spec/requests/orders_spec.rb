require 'rails_helper'

RSpec.describe 'Orders', type: :request do
  let(:seller) { create(:user) }
  let(:buyer)  { create(:user) }
  let(:item)   { create(:item, user: seller) }

  before do
    # Basic認証をテストで無効化
    allow_any_instance_of(ApplicationController)
      .to receive(:basic_auth_enabled?).and_return(false)
  end

  describe 'GET /items/:item_id/orders' do
    it 'ログイン済み & 未購入 & 他人の出品 → 200' do
      sign_in buyer
      get item_orders_path(item)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /items/:item_id/orders' do
    it '決済成功で302' do
      sign_in buyer
      post item_orders_path(item), params: {
        order_address: {
          postal_code: '123-4567', prefecture_id: 2, city: '横浜市緑区',
          block: '青山1-1-1', building: '', phone_number: '09012345678',
          token: 'tok_test_abc123'
        }
      }
      expect(response).to have_http_status(:found) # 302
    end
  end

  describe 'ガード動作' do
    it 'ログイン済み & 売却済み → 直リンクでもトップ' do
      create(:order, user: buyer, item: item) # 売却済みにする
      sign_in create(:user)                   # 第三者
      get item_orders_path(item)
      expect(response).to redirect_to(root_path)
    end

    it '未ログイン → ログインページへ' do
      get item_orders_path(item)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
