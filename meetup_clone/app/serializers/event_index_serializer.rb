class EventIndexSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :location, :start_time, :end_time, :time, :user_event

  def time
    "From #{object.start_time.strftime('%A, %m/%d/%y at %I:%M %p')} to #{object.end_time.strftime('%A, %m/%d/%y at %I:%M %p')}"
  end

  def user_event
    current_user.user_events.find_by(event_id: object.id)
  end
end
