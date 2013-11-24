require 'sinatra'
require 'sequel'
enable :sessions
require_relative 'myfunctions'

production = true
if production
	DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://course.db')
else 
	require 'sinatra/reloader'
	DB = Sequel.connect('sqlite://course.db')
end

NUM_DISPLAY_COURSES = 10


#escapes html to prevent hackers
helpers do  
    include Rack::Utils  
    alias_method :h, :escape_html  
end



get '/' do
	@courses = DB[:courses].reverse_order(:id).all #reverses order so latest courses at top
	@emails = DB[:emails].all
	erb :main
end

post '/' do
	@courses = DB[:courses].reverse_order(:id).all
	@categorySelection = params[:category]
	@emails = DB[:emails].all
	erb :main
	# redirect '/'
end

get '/update' do
	updateAndEmailDatabase(DB)
end

get '/testemail' do
	emailUsers
	redirect '/'
end

post '/emailSubmit' do
	if params[:newemail]
		e = DB[:emails]
		e.insert(:email => params[:newemail])
	end
	flash[:notice] = "Your email has been added to the mailing list!"
	redirect '/'
end

Thread.new do # trivial example work thread
  while true do
  	sleep 3600
    updateAndEmailDatabase(DB)
  end
end
