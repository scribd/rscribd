# while c = File.read(max_size); end  # still reads the whole file into memory
# buffer = ''; while c = File.read(max_size, buffer ); end  # reuses a string variable to reduce memory usage
class BufferedUploadIO < UploadIO
  def initialize(*args)
    super(*args)
    @buffer = ''
  end

  def read(amount, buffer = @buffer)
    @io.read(amount, buffer)
  end
end
