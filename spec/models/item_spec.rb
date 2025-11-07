require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:item) { build(:item) }

  context '保存できる' do
    it '必要項目が揃えば有効' do
      expect(item).to be_valid
    end

    it '価格が300と9_999_999の境界でも有効' do
      item.price = 300
      expect(item).to be_valid
      item.price = 9_999_999
      expect(item).to be_valid
    end
  end

  context '保存できない' do
    it '画像が必須' do
      item.image.detach
      expect(item).to be_invalid
      expect(item.errors[:image]).to be_present
    end

    it '名前が必須' do
      item.name = ''
      expect(item).to be_invalid
      expect(item.errors[:name]).to be_present
    end

    it '説明が必須' do
      item.description = ''
      expect(item).to be_invalid
      expect(item.errors[:description]).to be_present
    end

    it '価格が必須' do
      item.price = nil
      expect(item).to be_invalid
      expect(item.errors[:price]).to be_present
    end

    it '価格は半角整数のみ（英字混在はNG）' do
      item.price = '1000a'
      expect(item).to be_invalid
      expect(item.errors[:price]).to be_present
    end

    it '価格は半角整数のみ（全角はNG）' do
      item.price = '１０００'
      expect(item).to be_invalid
      expect(item.errors[:price]).to be_present
    end

    it '価格は半角整数のみ（小数はNG）' do
      item.price = '1000.5'
      expect(item).to be_invalid
      expect(item.errors[:price]).to be_present
    end

    it '価格が299はNG' do
      item.price = 299
      expect(item).to be_invalid
      expect(item.errors[:price]).to be_present
    end

    it '価格が10_000_000はNG' do
      item.price = 10_000_000
      expect(item).to be_invalid
      expect(item.errors[:price]).to be_present
    end

    it "ActiveHashのIDが1（'---'）はNG" do
      item.category_id = 1
      item.condition_id = 1
      item.shipping_fee_id = 1
      item.prefecture_id = 1
      item.scheduled_delivery_id = 1
      expect(item).to be_invalid
      expect(item.errors[:category_id]).to be_present
      expect(item.errors[:condition_id]).to be_present
      expect(item.errors[:shipping_fee_id]).to be_present
      expect(item.errors[:prefecture_id]).to be_present
      expect(item.errors[:scheduled_delivery_id]).to be_present
    end
  end
end
