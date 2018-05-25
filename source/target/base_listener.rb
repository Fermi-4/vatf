require 'serialport'
require 'thread'
require 'socket'

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
    @expect = /#{expect}/m
    @check_cmd_echo = check_cmd_echo
    @response = ''
    @match = false
  end

  def process_response(data)
    @response += data
  end
  
  def match
    @match = (@response.index(@expect) && (!@check_cmd_echo || @response.index(/#{@cmd}.+?#{@expect}/m)) )
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
    if @listen_thread
      @listen_thread.kill 
      @listen_thread.join(5)
      @listen_thread = nil
    end
  end

  def send_cmd(command)
    puts(command)
    flush
  end
  
  def write_cmd(command)
    write(command)
    flush
  end

  def disconnect
    stop_listening
    self.close if !self.closed?
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
  @password_prompt  = platform_info.password_prompt if platform_info.respond_to?:password_prompt
  @timeout = 10 # Default timeout of 10 secs
  @timeout = platform_info.timeout if platform_info.respond_to?:timeout
  platform_info.telnet_bin_mode != nil ? @telnet_bin_mode = platform_info.telnet_bin_mode : @telnet_bin_mode = true
  super( "Host" => @telnet_ip,
           "Port" => @telnet_port,
           "Waittime" => 0,
           "Prompt" => @prompt,
           "Telnetmode" => true,
           "Binmode" => @telnet_bin_mode,
           "Timeout" => @timeout)
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
          #last_read = readpartial(1024) 
          last_read = read_nonblock(1024) 
          notify_listeners(last_read)
          Kernel.print last_read
        end
      end
    }  
  end
  
  def stop_listening
    @keep_listening = false
    if @listen_thread
      @listen_thread.kill 
      @listen_thread.join(5)
    end
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

  def method_missing(method, *args)
    if @sock.respond_to?(method.to_s)
      @sock.__send__(method, *args)
    else
      super
    end
  end
end

class TcpIpBaseListenerClient < TCPSocket
  include Log4r  
  attr_reader :response
  
  def initialize(platform_info)
    @telnet_ip   = platform_info.telnet_ip
    @telnet_port = platform_info.telnet_port
    super( @telnet_ip,
           @telnet_port)
    binmode() if platform_info.telnet_bin_mode
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
          #last_read = readpartial(1024) 
          last_read = read_nonblock(1024) 
          notify_listeners(last_read)
          Kernel.print last_read
        end
      end
    }  
  end
  
  def stop_listening
    @keep_listening = false
    if @listen_thread
      @listen_thread.kill 
      @listen_thread.join(5)
    end
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
