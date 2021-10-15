class EventSerializer < EventIndexSerializer
  attributes :creator
  has_many :attendees
  belongs_to :group, serializer: EventGroupSerializer

  def creator
    object.user.username
  end
end
