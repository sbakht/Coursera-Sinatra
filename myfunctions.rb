require 'openssl'
require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'pony'

def getCourses
	
	url = "https://www.coursera.org/maestro/api/topic/list?full=1"
	# uri = URI.parse(url)
	# http = Net::HTTP.new(uri.host, uri.port)
	# http.use_ssl = true
	# http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	# response = http.request(Net::HTTP::Get.new(uri.request_uri))

	req = Net::HTTP::Get.new(url.path)
	response = Net::HTTP.start(url.host, url.port) {|http|
	  http.request(req)
	}
	puts response.body

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
		if result["courses"][0] #checks that home_link exists(was causing problems on some courses)
			courses << {"title" => result["name"], "link" => result["courses"][0]["home_link"], "categories" => categories}
		else
			courses << {"title" => result["name"], "link" => "https://www.coursera.org", "categories" => categories}
		end
		i +=1
	end

	#print "Total number of courses: #{i}"
	return courses
end

def updateAndEmailDatabase(dB)
	newCourses = ""
	c = dB[:courses]
	@courses = getCourses
	@courses.each do |course|
		if !c.first(:title => course['title']) #checks for duplicate DB entries
			c.insert(:title => course["title"], :link => course["link"], :categories => course["categories"].join(","))
			newCourses << "#{course['title']} - #{course['link']} \n\n"
		end
	end
	emailUsers(newCourses, dB)
	redirect '/'
end

def emailUsers(newCourses, dB)

	loginDetails = smtpLogin
	emailList = dB[:emails].all
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
	contents = YAML.load_file('config.yml')
	return contents
end