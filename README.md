# rscribd

* 1.3.0 (July 5, 2011)

## DESCRIPTION

This gem provides a simple and powerful library for the Scribd API, allowing you
to write Ruby applications or Ruby on Rails websites that upload, convert,
display, search, and control documents in many formats. For more information on
the Scribd platform, visit the Developer web page on Scribd.

## FEATURES

* Upload your documents to Scribd's servers and access them using the gem
* Upload local files or from remote web sites
* Search, tag, and organize documents
* Associate documents with your users' accounts

## SYNOPSIS

This API allows you to use Scribd's Flash viewer on your website. You'll be able
to take advantage of Scribd's scalable document conversion system to convert
your documents into platform-independent formats. You can leverage Scribd's
storage system to store your documents in accessible manner. Scribd's ad system
will help you monetize your documents easily.

First, you'll need to get a Scribd API account. Visit Scribd to apply for a
developer account.

On the Platform site you will be given an API key and secret. The API object
will need these to authenticate you:

```ruby
require 'rscribd'
Scribd::API.instance.key = 'your API key'
Scribd::API.instance.secret = 'your API secret'
```

Next, log into the Scribd website:

```ruby
Scribd::User.login 'username', 'password'
```

You are now ready to use Scribd to manage your documents. For instance, to
upload a document:

```ruby
doc = Scribd::Document.upload(:file => 'your-file.pdf')
```

For more information, please see the documentation for the `Scribd::API`,
`Scribd::User`, and `Scribd::Document` classes. (You can also check out the docs for
the other classes for a more in-depth look at this gem's features).

## REQUIREMENTS

* A Scribd API account
* Ruby 1.8 or newer, with RubyGems 1.3 or newer.
* (optional) [multipart-post gem by Nick Sieger](https://github.com/scribd/rscribd.git)

## INSTALL

    sudo gem install rscribd

To use the optional multipart-post gem by Nick Sieger, make sure it is available in the load path and call:

```ruby
Scribd::API.instance.enable_multipart_post_gem

# and to stop using the multipart-post gem
Scribd::API.instance.disable_multipart_post_gem
```

## LICENSE

(The MIT License)

Copyright (c) 2007- The Scribd Team

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
