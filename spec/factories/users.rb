FactoryBot.define do
  factory :user do
    nickname            { Faker::Internet.username }
    email               { Faker::Internet.unique.email }
    password            { 'a1b2c3' } # 英数混在・6文字以上
    password_confirmation { password }
    last_name           { '山田' }            # 全角
    first_name          { '太郎' }            # 全角
    last_name_kana      { 'ヤマダ' }          # 全角カナ
    first_name_kana     { 'タロウ' }          # 全角カナ
    birth_date          { Date.new(2000, 1, 1) }
  end
end
