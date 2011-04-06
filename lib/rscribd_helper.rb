module RscribdHelper
  def display_scribd_reader(doc_id, doc_key, options = {})
    opts = {
        :jsapi_version => 1,
        :hide_disabled_buttons => true,
        :mode => "slide"
    }.merge(options)

    if doc_id and doc_key
      str = []
      str << "<div id='embedded_flash'><a href='http://www.scribd.com'>Scribd</a></div>"
      str << "<script type='text/javascript'>"
      str << "  var scribd_doc = scribd.Document.getDoc( #{doc_id}, '#{doc_key}' );"
      str << "  var oniPaperReady = function(e){"
      str << "    // scribd_doc.api.setPage(3);"
      str << "  }"
      opts.each do |k,v|
        if v.is_a?(String)
          str << "scribd_doc.addParam( '#{k}', '#{v}' );"
        else
          str << "scribd_doc.addParam( '#{k}', #{v} );"
        end
      end
      str << "scribd_doc.addEventListener( 'iPaperReady', oniPaperReady );"
      str << "scribd_doc.write( 'embedded_flash' );"
      str << "</script>"
      return content_tag("div", str.join("\n").html_safe, :class => "scribd_reader")
    else
      return "Scribd document not found."
    end
  end
end