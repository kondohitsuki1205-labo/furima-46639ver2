class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # --- 定数定義 ---
  FULL_WIDTH = /\A[^\x01-\x7E]+\z/
  KATAKANA   = /\A[ァ-ヴー]+\z/
  # パスワードの正規表現も定数化
  PASSWORD_FORMAT = /\A(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+\z/

  with_options presence: true do
    validates :nickname, :birth_date
    validates :last_name, :first_name,
              format: { with: FULL_WIDTH, message: 'は全角で入力してください' }
    validates :last_name_kana, :first_name_kana,
              format: { with: KATAKANA,   message: 'は全角カナで入力してください' }
  end

  validates :password,
            format: { with: PASSWORD_FORMAT, message: 'は英字と数字の両方を含めてください' },
            allow_nil: true
end