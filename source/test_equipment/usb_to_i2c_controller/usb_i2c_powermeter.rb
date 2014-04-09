# Code to start server process to listen for incomming request
# to measure power using USB-to-I2C power meter card

require 'socket'                # Get sockets from stdlib

server = TCPServer.open('158.218.101.68', 2000)   # Replace IP address with your server's IP
                                                  # Socket to listen on port 2000
                                                  # You will need to set the corresponding IP
                                                  # and PORT in your bench file.
loop {                          
  Thread.start(server.accept) do |client|
    app_path=client.gets.strip
    num_samples=client.gets.strip
    delay_between_samples=client.gets.strip
    client.puts("got path:#{app_path}")
    client.puts("got samples:#{num_samples}")
    client.puts("got delay:#{delay_between_samples}")
    client.puts(Time.now.ctime) # Send the time to the client
    data=`#{app_path} -n #{num_samples} -d #{delay_between_samples} -c 4527`
    data.each_line {|line|
	    client.puts line
    }
    client.puts "Closing the connection. Bye!"
    client.close                # Disconnect from the client
  end
}