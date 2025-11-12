require 'rails_helper'

RSpec.describe 'Orders', type: :request do
  let(:seller) { create(:user) }                      # 出品者
  let(:buyer)  { create(:user) }                      # 購入者
  let(:item)   { create(:item, user: seller) }        # 他人の出品物

  # Basic認証はテスト中は無効化
  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:basic_auth_enabled?).and_return(false)
  end

  describe 'GET /items/:item_id/orders (index/new)' do
    context 'ログイン済み & 未購入 & 他人の出品' do
      it '200 を返す' do
        sign_in buyer
        get item_orders_path(item)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /items/:item_id/orders (create)' do
    it '決済成功でリダイレクト' do
      sign_in buyer
      post item_orders_path(item), params: {
        order_address: {
          postal_code:   '123-4567',
          prefecture_id: 2,
          city:          '横浜市緑区',
          block:         '青山1-1-1',
          building:      '',
          phone_number:  '09012345678',
          token:         'tok_test_abc123' # OrdersController#order_params で permit 済み前提
        }
      }
      expect(response).to have_http_status(:found) # 302
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'ガード動作の確認' do
    context 'ログイン済み & 売却済み' do
      it '直リンクでもトップにリダイレクト' do
        create(:order, item: item, user: buyer) # 売却済みにする
        third_user = create(:user)
        sign_in third_user
        get item_orders_path(item)
        expect(response).to redirect_to(root_path)
      end
    end

    context '未ログイン' do
      it 'ログインページへリダイレクト' do
        get item_orders_path(item)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

