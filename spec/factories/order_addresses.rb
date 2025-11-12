FactoryBot.define do
  factory :order_address do
    postal_code    { '123-4567' }
    prefecture_id  { 2 }
    city           { '横浜市緑区' }
    block          { '青山1-1-1' }
    building       { '柳ビル103' }
    phone_number   { '09012345678' }
    token          { 'tok_test_abc' }
  end
end
