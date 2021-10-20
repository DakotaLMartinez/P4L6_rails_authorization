class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :bio, :admin
end
