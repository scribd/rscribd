# This is based on a great snippet from Pivot Labs, used with permission:
# http://pivots.pivotallabs.com/users/damon/blog/articles/227-standup-04-27-07-testing-file-uploads

require 'net/https'
require 'rubygems'
require 'mime/types' # Requires gem install mime-types
require 'cgi'

# @private
module Net
  # @private
  class HTTP::Post
    def multipart_params=(param_hash={})
      boundary_token = [Array.new(8) {rand(256)}].join
      self.content_type = "multipart/form-data; boundary=#{boundary_token}"
      boundary_marker = "--#{boundary_token}\r\n"
      self.body = param_hash.inject('') do |memo, (param_name, param_value)|
        memo << boundary_marker
        case param_value
        when File
          file_to_multipart(memo, param_name, param_value)
        else
          memo << text_to_multipart(param_name, param_value.to_s)
        end
      end << "--#{boundary_token}--\r\n"
    end

    protected
    def file_to_multipart(memo, key,file)
      filename = File.basename(file.path)
      mime_types = MIME::Types.of(filename)
      mime_type = mime_types.empty? ? "application/octet-stream" : mime_types.first.content_type
      memo << %Q|Content-Disposition: form-data; name="#{key}"; filename="#{filename}"\r\n|
      memo << "Content-Transfer-Encoding: binary\r\n"
      memo << "Content-Type: #{mime_type}\r\n\r\n#{file.read}\r\n"
    end

    def text_to_multipart(key,value)
      "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n#{value}\r\n"
    end
  end
end
