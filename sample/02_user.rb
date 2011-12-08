# Example 2 - Signing in as a user, and accessing a user's files.
require 'rubygems'
require 'rscribd'

# Use your API key / secret here
Scribd::API.key = ""
Scribd::API.secret = ""

begin
  # Login your Scribd API object as a particular user
  # NOTE: Edit this to the username and password of a real Scribd user
  user = Scribd::User.login "LOGIN", "PASSWORD"
  
  docs = user.documents

  puts "User #{user.username} has #{docs.size} docs"
  if docs.size > 0
    puts "User's docs:" 
    docs.each do |doc|
      puts "#{doc.title}"
    end
  end

  results = Scribd::Document.find :query => 'resume' # Search over the user's docs for the string 'checklist'
  
  puts "Search through docs turned up #{results.size} results:"
  results.each do |doc|
    puts "#{doc.title}"
  end

rescue Scribd::ResponseError => e
  puts "failed code=#{e.code} error='#{e.message}'"
end