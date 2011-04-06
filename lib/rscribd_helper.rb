module RscribdHelper
    def display_scribd_reader(doc_id, doc_key, options = {})
    opts = {
        :width => "100%",
        :height => "600",
        :hide_disabled_buttons => true,
        :mode => "slide"
    }.merge(options)

    str = []
    str << "<div id='embedded_flash'><a href='http://www.scribd.com'>Scribd</a></div>"
    str << "<script type='text/javascript'>"
    str << "  var scribd_doc = scribd.Document.getDoc( #{doc_id}, '#{doc_key}' );"
    str << "  var oniPaperReady = function(e){"
    str << "    // scribd_doc.api.setPage(3);"
    str << "  }"
    str << "scribd_doc.addParam( 'jsapi_version', 1 );"
    str << "scribd_doc.addParam( 'width', '#{opts[:width]}' );"
    str << "scribd_doc.addParam( 'height', '#{opts[:height]}' );"
    str << "scribd_doc.addParam( 'hide_disabled_buttons', #{opts[:hide_disabled_buttons]} );"
    str << "scribd_doc.addParam( 'mode', '#{opts[:mode]}' );"
    str << "scribd_doc.addEventListener( 'iPaperReady', oniPaperReady );"
    str << "scribd_doc.write( 'embedded_flash' );"
    str << "</script>"
    return content_tag("div", str.join("\n").html_safe, :class => "scribd_reader")
  end
end