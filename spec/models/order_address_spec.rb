require 'rails_helper'
RSpec.describe OrderAddress, type: :model do
  let(:valid_attrs) do
    {
      postal_code: '123-4567',
      prefecture_id: 2,
      city: '渋谷区',
      block: '神南1-1-1', # ← Addressのカラムが addresses の場合はここを addresses: に変える（後述）
      building: 'XXビル',
      phone_number: '0901234567',
      token: 'tok_abc',
      user_id: 100,  # ダミー
      item_id: 200   # ダミー
    }
  end

  describe '商品購入（住所+注文の保存）' do
    context '購入できるとき' do
      it '必要項目が揃っていれば有効（buildingは任意）' do
        expect(OrderAddress.new(valid_attrs)).to be_valid
      end

      it 'buildingが空でも有効' do
        attrs = valid_attrs.merge(building: nil)
        expect(OrderAddress.new(attrs)).to be_valid
      end

      it '電話番号は10桁でも有効' do
        attrs = valid_attrs.merge(phone_number: '0312345678')
        expect(OrderAddress.new(attrs)).to be_valid
      end

      it '電話番号は11桁でも有効' do
        attrs = valid_attrs.merge(phone_number: '09012345678')
        expect(OrderAddress.new(attrs)).to be_valid
      end
    end

    context '保存処理（副作用）' do
      # ここだけ DB を使う
      let(:user) { create(:user) }
      let(:item) { create(:item) } # 画像必須なら factory で自動添付されるように（下記参照）
      let(:save_attrs) { valid_attrs.merge(user_id: user.id, item_id: item.id) }

      it 'saveでOrderとAddressが作成される' do
        oa = OrderAddress.new(save_attrs)
        expect do
          expect(oa.save).to eq true
        end.to change(Order, :count).by(1)
                                    .and change(Address, :count).by(1)
      end
    end
  end
end
