\# テーブル設計



\## users テーブル



| Column             | Type   | Options                   |

| ------------------ | ------ | ------------------------- |

| nickname           | string | null: false               |

| email              | string | null: false, unique: true |

| encrypted\_password | string | null: false               |

| last\_name          | string | null: false               |

| first\_name         | string | null: false               |

| last\_name\_kana     | string | null: false               |

| first\_name\_kana    | string | null: false               |

| birth\_date         | date   | null: false               |



\### Association

\- has\_many :items

\- has\_many :orders





\## items テーブル



| Column                | Type       | Options                        |

| --------------------- | ---------- | ------------------------------ |

| name                  | string     | null: false                    |

| description           | text       | null: false                    |

| category\_id           | integer    | null: false                    |

| condition\_id          | integer    | null: false                    |

| shipping\_fee\_id       | integer    | null: false                    |

| prefecture\_id         | integer    | null: false                    |

| scheduled\_delivery\_id | integer    | null: false                    |

| price                 | integer    | null: false                    |

| user                  | references | null: false, foreign\_key: true |



\### Association

\- belongs\_to :user

\- has\_one :order

\- has\_one\_attached :image

\- belongs\_to :category # ActiveHash

\- belongs\_to :condition # ActiveHash

\- belongs\_to :shipping\_fee # ActiveHash

\- belongs\_to :prefecture # ActiveHash

\- belongs to :scheduled\_delivery # ActiveHash





\## orders テーブル



| Column | Type       | Options                        |

| ------ | ---------- | ------------------------------ |

| item   | references | null: false, foreign\_key: true |

| user   | references | null: false, foreign\_key: true |



\### Association

\- belongs\_to :user

\- belongs\_to :item

\- has\_one :address





\## addresses テーブル



| Column        | Type       | Options                        |

| ------------- | ---------- | ------------------------------ |

| postal\_code   | string     | null: false                    |

| prefecture\_id | integer    | null: false                    |

| city          | string     | null: false                    |

| block         | string     | null: false                    |

| building      | string     |                                |

| phone\_number  | string     | null: false                    |

| order         | references | null: false, foreign\_key: true |



\### Association

\- belongs\_to :order





制約 / インデックス



UNIQUE

&nbsp;orders.item\_id

&nbsp;addresses.order\_id



FK + NOT NULL

&nbsp;items.user\_id / orders.user\_id / orders.item\_id / addresses.order\_id

&nbsp;users（Devise）

&nbsp;email（unique）





