class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # --- 定数定義 ---
  NAME_JP      = /\A[\p{Hiragana}\p{Katakana}\p{Han}ー]+\z/
  KATAKANA_JP  = /\A[\p{Katakana}ー]+\z/
  PASSWORD_FMT = /\A(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+\z/

  with_options presence: true do
    validates :nickname, :birth_date
    validates :last_name, :first_name,
              format: { with: NAME_JP, message: 'は全角（漢字・ひらがな・カタカナ）のみで入力してください' }
    validates :last_name_kana, :first_name_kana,
              format: { with: KATAKANA_JP,   message: 'は全角カタカナのみで入力してください' }
  end

  validates :password,
            format: { with: PASSWORD_FMT, message: 'は英字と数字の両方を含めてください' },
            allow_nil: true
end