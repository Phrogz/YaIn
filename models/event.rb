# encoding: utf-8
class Event < Sequel::Model
	one_to_many :times, class: :EventTime
	def upcoming
		times
		.select{ _1.starts_at > Time.now }
		.sort_by{ _1.starts_at }
	end
	def has_upcoming?
		!upcoming.empty?
	end
end

class EventTime < Sequel::Model
	many_to_one :event
	one_to_many :signups
	def upcoming?
		starts_at > Time.now
	end
	def status_for(user)
		if signup = signups_dataset[name:user]
			signup.confirmation_type
		else
			ConfirmationType::UNKNOWN
		end
	end
end

class Signup < Sequel::Model
	many_to_one :confirmation_type
	def self.all_users
		select(:name).distinct.map(:name)
	end
end

class ConfirmationType < Sequel::Model
	UNKNOWN = self[label:'Unknown']
	one_to_many :signups
end