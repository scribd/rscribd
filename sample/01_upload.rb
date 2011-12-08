# Example 1 - Uploading a test text file and removing it afterwards.
require 'rubygems'
require 'rscribd'

# Use your API key / secret here
Scribd::API.key = ""
Scribd::API.secret = ""

begin
  Scribd::User.login "USERNAME", "PASSWORD"
  
  # Upload the document from a file
  print "Uploading a document ... "

  doc = Scribd::Document.upload :file => File.join(File.dirname(__FILE__), 'test.txt')
  puts "Done doc_id=#{doc.id}, doc_access_key=#{doc.access_key}"

  # Poll API until conversion is complete
  while (doc.conversion_status == 'PROCESSING')
    puts "Document conversion is processing"
    sleep(2) # Very important to sleep to prevent a runaway loop that will get your app blocked
  end
  puts "Document conversion is complete"

  # Edit various options of the document
  # Note you can also edit options before your doc is done converting
  doc.title = 'This is a test doc!'
  doc.description = "I'm testing out the Scribd API!"
  doc.access = 'private'
  doc.language = 'en'
  doc.license = 'c'
  doc.tags = 'test,api'
  doc.show_ads = true
  doc.save

  # Delete the uploaded document
  print "Deleting a document ... "
  doc.destroy
  
  puts "Done doc_id=#{doc.id}"
rescue Scribd::ResponseError => e
  puts "failed code=#{e.code} error='#{e.message}'"
end