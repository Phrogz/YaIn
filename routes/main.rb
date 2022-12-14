# encoding: utf-8
class YaIn < Sinatra::Application
	get "/" do
		@title = "Welcome to 'Ya In?'"
		@user = cookies[:uname]
		if @user
			response.set_cookie('uname', value:@user, expires:(Time.now + 120 * 24 * 3600))
			haml :main
		else
			redirect "/name"
		end
	end

	get "/name" do
		@title = "Set your name for 'Ya in?'"
		@user = cookies[:uname]
		haml :name
	end

	post "/name" do
		new_user = params[:name] && params[:name].strip[0...25].strip
		if new_user && new_user.length > 0
			old_user = cookies[:uname]
			if old_user
				puts "Renaming #{old_user.inspect} to #{new_user.inspect}"
				begin
					Signup.where(name:old_user).update(name:new_user)
				rescue Sequel::UniqueConstraintViolation
					puts "Would have caused a collision"
				end
			end
			response.set_cookie('uname', value:new_user, expires:(Time.now + 120 * 24 * 3600))
		end
		redirect "/#{params[:returnto]}"
	end

	get "/:event" do
		redirect "/name?returnto=#{params['event']}" unless @user = cookies[:uname]

		response.set_cookie('uname', value:@user, expires:(Time.now + 120 * 24 * 3600))
		@event = Event[id: params['event']]
		if @event
			@title = "Ya in for #{@event.name}?"
			users = Signup.all_users
			@times = params.keys.include?('all') ? @event.times.sort_by{ |t| t.starts_at } : @event.upcoming
			haml :event
		else
			redirect '/'
		end
	end

	post "/signup" do
		content_type :json
		if user=cookies[:uname]
			signup = Signup[{event_time_id:params['time'], name:user}]
			next_type = ConfirmationType::NEXT[signup && signup.confirmation_type_id]
			if signup
				signup.update confirmation_type_id:next_type.id
			else
				Signup.insert(event_time_id:params['time'], name:user, confirmation_type_id:next_type.id)
			end

			{
				status: next_type.label,
				newHTML: partial(:_event_block, time:EventTime[params['time']], user:user)
			}
		else
			{ error:"Could not find user" }
		end.to_json
	end

	get "/attendees/:time" do
		content_type :json
		DB
		.from(:signups)
		.where(event_time_id:params['time'])
		.join(:confirmation_types, id: :confirmation_type_id)
		.where{ confirmation_type_id > 0 }
		.select(:name, :label)
		.order_by(:confirmation_type_id)
		.all
		.group_by{ |row| row[:label].downcase }
		.map{ |label, people| [label, people.map{ |hash| h hash[:name] }] }
		.to_h.to_json
	end

	get "/summary/:time" do
		content_type :json
		if user=cookies[:uname]
			{
				newHTML: partial(:_event_block, time:EventTime[params['time']], user:user)
			}
		else
			{ error:"Could not find user" }
		end.to_json
	end
end