require 'rails_helper'

RSpec.describe OrderAddress, type: :model do
  # 実体を作ってIDを流し込む（ダミー数値IDは使わない）
  let(:buyer)  { create(:user) }
  let(:seller) { create(:user) }
  let(:item)   { create(:item, user: seller) } # 画像必須ならfactoryで添付済み想定

  let(:base_attrs) do
    {
      postal_code: '123-4567',
      prefecture_id: 2,
      city: '渋谷区',
      block: '神南1-1-1', # schema.rbのカラム名が block なので block のまま
      building: 'XXビル',
      phone_number: '0901234567', # 10桁でもOK判定用の初期値
      token: 'tok_test_abc',
      user_id: buyer.id,
      item_id: item.id
    }
  end

  describe '商品購入（住所+注文の保存）' do
    context '購入できるとき' do
      it '必要項目が揃っていれば有効（buildingは任意）' do
        expect(OrderAddress.new(base_attrs)).to be_valid
      end

      it 'buildingが空でも有効' do
        expect(OrderAddress.new(base_attrs.merge(building: ''))).to be_valid
      end

      it '電話番号は10桁でも有効' do
        expect(OrderAddress.new(base_attrs.merge(phone_number: '0312345678'))).to be_valid
      end

      it '電話番号は11桁でも有効' do
        expect(OrderAddress.new(base_attrs.merge(phone_number: '09012345678'))).to be_valid
      end
    end

    context '購入できないとき（バリデーション）' do
      it 'user_idが空だと無効' do
        oa = OrderAddress.new(base_attrs.merge(user_id: nil))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include("User can't be blank")
      end

      it 'item_idが空だと無効' do
        oa = OrderAddress.new(base_attrs.merge(item_id: nil))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include("Item can't be blank")
      end

      it 'tokenが空だと無効' do
        oa = OrderAddress.new(base_attrs.merge(token: nil))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include("Token can't be blank")
      end

      it '郵便番号が空だと無効' do
        oa = OrderAddress.new(base_attrs.merge(postal_code: ''))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include("Postal code can't be blank")
      end

      it '郵便番号が「3桁-4桁」でないと無効（ハイフンなし）' do
        oa = OrderAddress.new(base_attrs.merge(postal_code: '1234567'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Postal code is invalid')
      end

      it '郵便番号が全角だと無効' do
        oa = OrderAddress.new(base_attrs.merge(postal_code: '１２３-４５６７'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Postal code is invalid')
      end

      it '都道府県が未選択(1)だと無効' do
        oa = OrderAddress.new(base_attrs.merge(prefecture_id: 1))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Prefecture must be other than 1')
      end

      it '市区町村が空だと無効' do
        oa = OrderAddress.new(base_attrs.merge(city: ''))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include("City can't be blank")
      end

      it '番地が空だと無効' do
        oa = OrderAddress.new(base_attrs.merge(block: ''))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include("Block can't be blank")
      end

      it '電話番号が空だと無効' do
        oa = OrderAddress.new(base_attrs.merge(phone_number: ''))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include("Phone number can't be blank")
      end

      it '電話番号が9桁以下は無効' do
        oa = OrderAddress.new(base_attrs.merge(phone_number: '031234567')) # 9桁
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Phone number is invalid')
      end

      it '電話番号が12桁以上は無効' do
        oa = OrderAddress.new(base_attrs.merge(phone_number: '090123456789')) # 12桁
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Phone number is invalid')
      end

      it '電話番号にハイフンが含まれると無効' do
        oa = OrderAddress.new(base_attrs.merge(phone_number: '090-1234-5678'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Phone number is invalid')
      end

      it '電話番号が全角数字だと無効' do
        oa = OrderAddress.new(base_attrs.merge(phone_number: '０９０１２３４５６７８'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Phone number is invalid')
      end
    end

    context '購入できないとき（追加のフォーマット検証）' do
      it '都道府県がnilだと無効' do
        oa = OrderAddress.new(base_attrs.merge(prefecture_id: nil))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Prefecture is not a number')
      end

      it '郵便番号が「2桁-5桁」は無効（ハイフン位置違い）' do
        oa = OrderAddress.new(base_attrs.merge(postal_code: '12-34567'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Postal code is invalid')
      end

      it '郵便番号が「4桁-3桁」は無効（桁数違い）' do
        oa = OrderAddress.new(base_attrs.merge(postal_code: '1234-567'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Postal code is invalid')
      end

      it '電話番号に空白が含まれると無効' do
        oa = OrderAddress.new(base_attrs.merge(phone_number: '090 1234 5678'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Phone number is invalid')
      end

      it '電話番号に英字が含まれると無効' do
        oa = OrderAddress.new(base_attrs.merge(phone_number: '090abcd5678'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Phone number is invalid')
      end

      it '電話番号が+付き（国際表記）だと無効' do
        oa = OrderAddress.new(base_attrs.merge(phone_number: '+819012345678'))
        expect(oa).to be_invalid
        expect(oa.errors.full_messages).to include('Phone number is invalid')
      end
    end

    context '保存失敗時は副作用なし' do
      it '無効なときはOrder/Addressが増えない' do
        oa = OrderAddress.new(base_attrs.merge(postal_code: '1234567')) # ハイフン無しで無効
        expect do
          expect(oa.save).to eq false
        end.to not_change(Order, :count)
          .and not_change(Address, :count)
      end
    end

    context '保存処理（副作用）' do
      it 'saveでOrderとAddressが作成される' do
        oa = OrderAddress.new(base_attrs)
        expect do
          expect(oa.save).to eq true
        end.to change(Order, :count).by(1)
                                    .and change(Address, :count).by(1)

        order   = Order.order(:created_at).last
        address = Address.order(:created_at).last

        expect(order.user_id).to eq(buyer.id)
        expect(order.item_id).to eq(item.id)
        expect(address.order_id).to eq(order.id)
        expect(address.postal_code).to eq('123-4567')
        expect(address.block).to eq('神南1-1-1')
      end
    end
  end
end
