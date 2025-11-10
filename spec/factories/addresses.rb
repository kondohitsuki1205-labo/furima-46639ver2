FactoryBot.define do
  factory :address do
    postal_code { "MyString" }
    prefecture_id { 1 }
    city { "MyString" }
    block { "MyString" }
    building { "MyString" }
    phone_number { "MyString" }
    order { nil }
  end
end
