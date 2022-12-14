# encoding: utf-8
require 'sinatra'
require 'haml'
require 'sinatra/cookies'
require 'kramdown'
require 'json'

require_relative 'helpers/partials'
class YaIn < Sinatra::Application
	enable :sessions

	configure :production do
		set :haml, { :ugly=>true }
		set :clean_trace, true
	end

	helpers Sinatra::Cookies
	helpers PartialPartials
	helpers do
		include Rack::Utils
		alias_method :h, :escape_html
		def markdown(html)
			Kramdown::Document.new(html, coderay_line_numbers:nil, coderay_css: :class).to_html
		end
	end
end

require_relative 'models/init'
require_relative 'routes/init'