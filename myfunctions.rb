

def getCourses
	require 'openssl'
	require 'net/http'
	require 'uri'
	require 'json'
		
	uri = URI.parse("https://www.coursera.org/maestro/api/topic/list?full=1")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	response = http.request(Net::HTTP::Get.new(uri.request_uri))

	results = JSON.parse(response.body)

	courses = []
	i = 1
	results.to_a.each do |result|
		categories = []
		#link = "http://"
		#link << result["courses"][0]["home_link"].to_s[14..-6]
		result["categories"].each do |category| 
			categories << category["name"] #gets categories for each class
		end
		courses << {"title" => result["name"], "link" => result["courses"][0]["home_link"], "categories" => categories}
		i +=1
	end

	#print "Total number of courses: #{i}"
	return courses
end

def updateAndEmailDatabase
	newCourses = ""
	@courses = getCourses
	@courses.each do |course|
		if !CourseDB.first(:title => course['title']) #checks for duplicate DB entries
			c = CourseDB.new
			c.title = course['title']
			c.link = course['link']
			c.categories = course['categories']
			c.save
			newCourses << "#{course['title']} - #{course['link']} \n\n"
		end
	end
	emailUsers(newCourses)
	redirect '/'
end

def emailUsers(newCourses)
	require 'pony'

	loginDetails = smtpLogin
	emailList = EmailDB.all :order => :id.asc
	emailList.each do |emailItem|
	    Pony.mail({ :to => emailItem.email, #.email is the email piece from an emailItem is an item in database
	    :from => 'classnotify@courseratracker.com',
	    :subject => 'New Coursera Classes Notification',
	    :body => "Courses recently added:\n#{newCourses}",
	    :via => :smtp,
	    :via_options => {
	     :address              => 'smtp.gmail.com',
	     :port                 => '587',
	     :enable_starttls_auto => true,
	     :user_name            => loginDetails["email"],
	     :password             => loginDetails["password"],
	     :authentication       => :plain, 
	     :domain               => "localhost.localdomain" 
	     }
	    })
	end
end

def smtpLogin
	require 'yaml'
	contents = YAML.load_file('config.yml')
	return contents
end