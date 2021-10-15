class BookSerializer < ActiveModel::Serializer
  attributes :id
  has_many :users, key: :readers
end
