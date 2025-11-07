FactoryBot.define do
  factory :item do
    association :user

    sequence(:name)        { |n| "テスト商品#{n}" }
    sequence(:description) { |n| "これはテスト用の説明文です。#{n}" }

    category_id           { 2 }
    condition_id          { 2 }
    shipping_fee_id       { 2 }
    prefecture_id         { 2 }
    scheduled_delivery_id { 2 }

    price { 1000 }

    after(:build) do |item|
      path = Rails.root.join('spec/fixtures/files/test.png')
      raise "Fixture missing: #{path}" unless File.exist?(path)

      item.image.attach(
        io: File.open(path),
        filename: 'test.png',
        content_type: 'image/png'
      )
    end
  end
end
