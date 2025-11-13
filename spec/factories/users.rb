# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:nickname) { |n| "user#{n}" }
    sequence(:email)    { |n| "user#{n}@example.com" }
    password              { 'a1b2c3' }
    password_confirmation { 'a1b2c3' }
    last_name             { '山田' }
    first_name            { '太郎' }
    last_name_kana        { 'ヤマダ' }
    first_name_kana       { 'タロウ' }
    birth_date            { Date.new(2000,1,1) }
  end
end
