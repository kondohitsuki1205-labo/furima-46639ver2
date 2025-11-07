require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  context '有効な場合' do
    it 'factoryのデフォルトで有効' do
      expect(user).to be_valid
    end
  end

  # --- Shoulda-matchers によるリファクタリング (必須項目) ---
  context '必須項目の検証' do
    it { is_expected.to validate_presence_of(:nickname) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name_kana) }
    it { is_expected.to validate_presence_of(:first_name_kana) }
    it { is_expected.to validate_presence_of(:birth_date) }
  end

  # --- Shoulda-matchers によるリファクタリング (メール) ---
  context 'メールの検証' do
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value('test@example.com').for(:email) }
    it { is_expected.not_to allow_value('invalid.example.com').for(:email) }
  end

  # --- Shoulda-matchers (一部) + カスタム検証 (一部) ---
  context 'パスワードの検証' do
    it { is_expected.to validate_length_of(:password).is_at_least(6) }
    it { is_expected.to validate_confirmation_of(:password) }

    # === カスタムバリデーション (英数混在) ===
    it '英字のみは無効（英数混在が必須）' do
      user.password = user.password_confirmation = 'abcdef'
      expect(user).to be_invalid
      expect(user.errors[:password]).to be_present
    end

    it '数字のみは無効（英数混在が必須）' do
      user.password = user.password_confirmation = '123456'
      expect(user).to be_invalid
      expect(user.errors[:password]).to be_present
    end
  end

  # --- カスタムバリデーション  ---
  context '氏名の形式' do
    it 'last_name/first_name は全角文字のみ' do
      user.last_name  = 'Yamada'
      user.first_name = 'Taro'
      expect(user).to be_invalid
      expect(user.errors[:last_name]).to be_present
      expect(user.errors[:first_name]).to be_present
    end

    it 'last_name_kana/first_name_kana は全角カナのみ' do
      user.last_name_kana  = 'やまだ' # ひらがな
      user.first_name_kana = 'たろう' # ひらがな
      expect(user).to be_invalid
      expect(user.errors[:last_name_kana]).to be_present
      expect(user.errors[:first_name_kana]).to be_present
    end
  end
end
