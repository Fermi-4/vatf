require 'serialport'
require 'thread'

class BaseListener 
  attr_reader :match, :cmd, :expect, :response
  def initialize(cmd,expect,check_cmd_echo)
    first_cmd_word = cmd.split(/\s/)[0].to_s
    i = 0
    first_cmd_word.each_byte {|c| 
      first_cmd_word[i] = '.'  if c.to_i < 32
      i+=1
    }
    @cmd = Regexp.new(Regexp.escape(first_cmd_word))
	#@cmd = /#{first_cmd_word}.+?#{expect}/m
    @expect = /#{expect}/m
	@check_cmd_echo = check_cmd_echo
    @response = ''
    @match = false
	#puts "\nBaseListener: cmd=#{@cmd}, expect=#{@expect}, cmd_echo?#{@check_cmd_echo}" # TODO REMOVE DEBUG PRINT
  end

  def process_response(data)
    @response += data
  end
  
  def match
    @match = true   if ( @response.index(@expect) && (!@check_cmd_echo || @response.index(/#{@cmd}.+?#{@expect}/m)) )
	#@match = true   if ( @response.index(@expect) && (!@check_cmd_echo || @response.index(@cmd)))
    @match
  end
end
  
class SerialBaseListenerClient < SerialPort
  include Log4r  
  attr_reader :response
  
  def SerialBaseListenerClient::new(platform_info)
    @port   = platform_info.serial_port
    @params   = platform_info.serial_params
    @prompt      = platform_info.prompt
    @boot_prompt = platform_info.boot_prompt
    if /^\s*\d+/.match(@port.to_s)
      super(@port.to_i,@params)
    else
      super(@port,@params)
    end
  end
  
  def add_listener(listener)
    @listeners << listener
  end
  
  def remove_listener(listener)
    @listeners.delete(listener)
  end
  
  def notify_listeners(data)
    @listeners.each { |listener|
      listener.process_response(data)
    }
    @session_data += data
  end
  
  def start_listening
    self.read_timeout = 125
    @listeners = Array.new
    @session_data = ''
    @keep_listening = true
    @listen_thread = Thread.new {
      while @keep_listening
        if !eof?
          # last_read = readpartial(1024) 
          last_read = read_nonblock(1024) 
          notify_listeners(last_read)
          Kernel.print last_read
        end
      end
    }	
  end
  
  def stop_listening
    @keep_listening = false
    @listen_thread.join(5)
  end

  def send_cmd(command)
    puts(command)
  end
  
  def write_cmd(command)
    write(command)
  end

  def disconnect
    stop_listening
    self.close
  end    
end

class TelnetBaseListenerClient < Net::Telnet
  include Log4r  
  attr_reader :response
  
  def initialize(platform_info,serial_server)
    if serial_server
	  @telnet_ip   = platform_info.serial_server_ip
	  @telnet_port = platform_info.serial_server_port
	else
	  @telnet_ip   = platform_info.telnet_ip
      @telnet_port = platform_info.telnet_port
	end
    @prompt      = platform_info.prompt
    @boot_prompt = platform_info.boot_prompt
    @telnet_login = platform_info.telnet_login
    @telnet_passwd = platform_info.telnet_passwd
		@login_prompt  = platform_info.login_prompt if platform_info.respond_to?:login_prompt
	
	super( "Host" => @telnet_ip,
           "Port" => @telnet_port,
           "Waittime" => 0,
           "Prompt" => @prompt,
           "Telnetmode" => true,
           "Binmode" => false )
  end
  
  def add_listener(listener)
    @listeners << listener
  end
  
  def remove_listener(listener)
    @listeners.delete(listener)
  end
  
  def notify_listeners(data)
    @listeners.each { |listener|
      listener.process_response(data)
    }
    @session_data += data
  end
  
  def start_listening
    @listeners = Array.new
    @session_data = ''
    @keep_listening = true
    @listen_thread = Thread.new {
      while @keep_listening
        if !eof?
          last_read = readpartial(1024) 
          #last_read = read_nonblock(1024) 
          notify_listeners(last_read)
          Kernel.print last_read
        end
      end
    }	
  end
  
  def stop_listening
    @keep_listening = false
    @listen_thread.join(5)
  end

  def send_cmd(command)
    puts(command)
  end
  
  def write_cmd(command)
    write(command)
  end

  def disconnect
    stop_listening
    self.close
  end    
end
