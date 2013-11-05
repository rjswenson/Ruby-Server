require "socket"
require "uri"

# Files will be served from this directory.
WEB_ROOT = './public'

# Map extensions to their content type.
CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt'  => 'text/plain',
  'png'  => 'image/png',
  'jpg'  => 'image/jpeg',
  'gif'  => 'image/gif'
}

# Treat as binary if not a content above.
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

# Split method to find extention and pass.
def content_type(path)
  extention = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(extention, DEFAULT_CONTENT_TYPE)
end

# Request parser to generate correct path to file.
# We need to sanitize the uri to remove .. characters
# so that people cannot use curl to enter our directory tree.
def requested_file(request_line)
  request_uri = request_line.split(" ")[1]
  path        = URI.unescape(URI(request_uri).path)

  cleaned_path = []

  parts = path.split("/")
  parts.each do |part|
    next if part.empty? || part == "."
    part == ".." ? cleaned_path.pop : cleaned_path << part
  end

  File.join(WEB_ROOT, *cleaned_path)
end

# Initializes server with  listening location and port.
server = TCPServer.new('localhost', 6969)

loop do

  # Wait until client connects, then return socket.
  socket = server.accept

  # Read the first line of request.
  request_line = socket.gets

  # Log the request to the console for debugging
  STDERR.puts request_line

  path = requested_file(request_line)
  path = File.join(path, 'index.html') if File.directory?(path)

  if File.exist?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|
      socket.print "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: #{content_type(file)}\r\n" +
                    "Content-Length: #{file.size}\r\n" +
                    "Connection: close\r\n"

      socket.print "\r\n"

  # Writes the contents of file to the socket.
      IO.copy_stream(file, socket)
    end
  else
    message = "\n\nNICE TRY!\n" +
              "You don't belong here.\n" +
              "~~~~~~~~~~~~~~~~~~~~~~\n\n\n" +

  "            .andAHHAbnn.
           .aAHHHAAUUAAHHHAn.
          dHP^~          ~^THb.
    .   .AHF                YHA.   .
    |  .AHHb.              .dHHA.  |
    |  HHAUAAHAbn      adAHAAUAHA  |
    I  HF~_____        ____ ]HHH   I
   HHI HAPK~-~^YUHb  dAHHHHHHHHHH IHH    , - - - ,
   HHI HHHD> .andHH  HHUUP^~YHHHH IHH  /          `
   YUI ]HHP     .~Y  P~.     THH[ IUP ,            |
      `HK                   ]HH      ,     NOPE!    |
        THAn.  .d.aAAn.b.  .dHHP   <       ~~~~-   |
        ]HHHHAAUP ~~ YUAAHHHH[       `            /
        `HHP^~  .annn.  ~^YHH          `- - - - `
         YHb    ~    ~    dHF
          `YAb..abdHHbndbndAP'
           THHAAb.  .adAHHF
            `UHHHHHHHHHHU'
              ]HHUUHHHHHH[
            .adHHb HHHHHbn.
     ..andAAHHHHHHb.AHHHHHHHAAbnn..
.ndAAHHHHHHUUHHHHHHHHHHUP^~~^YUHHHAAbn.
  ~^YUHHP   ~^YUHHUP^~        ^YUP^
                ~~~\n\n\n\n"

    socket.print "HTTP/1.1 404 Not Found\r\n" +
                  "Content-Type: text/plain\r\n" +
                  "Content-Length: #{message.size}\r\n" +
                  "Connection: close\r\n"
    socket.print "\r\n"
    socket.print message
  end

  socket.close
end
