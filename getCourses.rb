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

	if i >= 487
		puts result["name"]
	end

	if result["courses"][0] #checks taht home_link exists(was causing problems on some courses)
		courses << {"title" => result["name"], "link" => result["courses"][0]["home_link"], "categories" => categories}
	else
		courses << {"title" => result["name"], "link" => "https://www.coursera.org", "categories" => categories}
	end
	i +=1
end

#print "Total number of courses: #{i}"
#print  courses
