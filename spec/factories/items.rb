FactoryBot.define do
  factory :item do
    association :user
    name                  { "テスト商品" }
    description           { "説明テキスト" }
    category_id           { 2 }
    condition_id          { 2 }
    shipping_fee_id       { 2 }
    prefecture_id         { 2 }
    scheduled_delivery_id { 2 }
    price                 { 1000 }

    transient { attach_image { true } }

    after(:build) do |item, evaluator|
      next unless evaluator.attach_image
      path = Rails.root.join('spec/fixtures/files/test.png')
      item.image.attach(
        io: File.open(path),
        filename: 'test.png',
        content_type: 'image/png'
      )
    end
  end
end