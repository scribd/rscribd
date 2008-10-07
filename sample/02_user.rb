# Example 2 - Signing in as a user, and accessing a user's files.

require 'rubygems'
require 'rscribd'

# Use your API key / secret here
api_key = ''
api_secret = ''

# Edit these to a real Scribd username/password pair
username = ''
password = ''

# Create a scribd object
Scribd::API.instance.key = api_key
Scribd::API.instance.secret = api_secret
#Scribd::API.instance.debug = true

begin

  # Login your Scribd API object as a particular user
  # NOTE: Edit this to the username and password of a real Scribd user
  user = Scribd::User.login username, password

  docs = user.documents

  puts "User #{user.username} has #{docs.size} docs"
  if docs.size > 0
    puts "User's docs:" 
    for doc in docs
      puts "#{doc.title}"
    end
  end

  results = Scribd::Document.find(:all, :query => 'checklist') # Search over the user's docs for the string 'checklist'
  puts "Search through docs turned up #{results.size} results:"
  for doc in results
    puts "#{doc.title}"
  end
  

rescue Scribd::ResponseError => e
  puts "failed code=#{e.code} error='#{e.message}'"
end
