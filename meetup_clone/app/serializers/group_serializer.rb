class GroupSerializer < GroupIndexSerializer
  has_many :members
  has_many :events
end
