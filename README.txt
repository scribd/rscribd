= rscribd

* 1.0.1 (Mar 4, 2009)

== DESCRIPTION:

This gem provides a simple and powerful library for the Scribd API, allowing you
to write Ruby applications or Ruby on Rails websites that upload, convert,
display, search, and control documents in many formats. For more information on
the Scribd platform, visit http://www.scribd.com/publisher

== FEATURES:

* Upload your documents to Scribd's servers and access them using the gem
* Upload local files or from remote web sites
* Search, tag, and organize documents
* Associate documents with your users' accounts

== SYNOPSIS:

This API allows you to use Scribd's Flash viewer on your website. You'll be able
to take advantage of Scribd's scalable document conversion system to convert
your documents into platform-independent formats. You can leverage Scribd's
storage system to store your documents in accessible manner. Scribd's ad system
will help you monetize your documents easily.

First, you'll need to get a Scribd API account. Visit
http://www.scribd.com/publisher/api to apply for a platform account.

On the Platform site you will be given an API key and secret. The API object
will need these to authenticate you:

  require 'rscribd'
  Scribd::API.instance.key = 'your API key'
  Scribd::API.instance.secret = 'your API secret'

Next, log into the Scribd website:

  Scribd::User.login 'username', 'password'

You are now ready to use Scribd to manage your documents. For instance, to
upload a document:

  doc = Scribd::Document.upload(:file => 'your-file.pdf')

For more information, please see the documentation for the Scribd::API,
Scribd::User, and Scribd::Document classes. (You can also check out the docs for
the other classes for a more in-depth look at this gem's features).

== REQUIREMENTS:

* A Scribd API account
* mime-types gem

== INSTALL:

* The client library is a RubyGem called *rscribd*. To install, type:

  sudo gem install rscribd

== LICENSE:

(The MIT License)

Copyright (c) 2007-2008 The Scribd Team

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
