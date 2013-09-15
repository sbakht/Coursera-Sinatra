require 'sinatra'
#require 'sinatra/reloader'
require 'data_mapper'
require_relative 'myfunctions'


NUM_DISPLAY_COURSES = 10

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/courses.db")

class CourseDB
	include DataMapper::Resource
	property :id, Serial
	property :title, Text, :required => true
	property :link, Text
	property :categories, Object
end

class EmailDB
	include DataMapper::Resource
	property :id, Serial
	property :email, Text, :required => true
end

DataMapper.finalize.auto_upgrade!

#escapes html to prevent hackers
helpers do  
    include Rack::Utils  
    alias_method :h, :escape_html  
end


Thread.new do # trivial example work thread
  while true do
  	sleep 3600
    updateAndEmailDatabase
  end
end

get '/' do
	@courses = CourseDB.all :order => :id.desc
	@emails = EmailDB.all :order => :id.desc
	erb :main
end

post '/' do
	if params[:newemail]
		e = EmailDB.new
		e.email = params[:newemail]
		e.save
	end
	@courses = CourseDB.all :order => :id.desc
	@categorySelection = params[:category]
	@emails = EmailDB.all :order => :id.desc
	erb :main
	#redirect '/'
end

get '/update' do
	updateAndEmailDatabase
end

get '/testemail' do
	emailUsers
	redirect '/'
end
