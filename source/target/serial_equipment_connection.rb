require 'rubygems'
require 'timeout'
Kernel::require 'serialport'

class SerialEquipmentConnection < SerialPort

  def SerialEquipmentConnection::new(platform_info)
    @port   = platform_info.serial_port
    @params   = platform_info.serial_params
    @prompt      = platform_info.prompt
    @boot_prompt = platform_info.boot_prompt
    super(@port.to_i, @params)
    rescue Exception => e
      raise
  end

  def connect
  end

  def disconnect
    close()
  end

  def send_cmd(*params)
    command        = params[0]
    expected_match = params[1] ? params[1] : Regexp.new('.*')
    timeout        = params[2] ? params[2] : 30
    clear_history  = params[3]==nil ? true : params[3]
    @is_timeout = false
    begin
    @response = ""
    clear_buffer = ''
    init_buffer = ''
    command_regex =''
    puts(command)
    if clear_history
      i = 0
      partial_command = command[0,8]
      partial_command.each_byte {|c| 
        if c.to_i < 32 
        command_regex << '.'   
        elsif regex_character(c)
        command_regex << sprintf("\\%c",c)  
        else
        command_regex << sprintf("%c",c)  
        end
      }
    end
    partial_response = ''
    status = Timeout::timeout(timeout) {
      if clear_history
        while(!init_buffer.match(/#{command_regex}/m)) do #clearing the read buffer
          init_buffer << readpartial(128) if !eof?
        end
        partial_response = init_buffer.scan(/#{command_regex}.*/m)[0]
        index = init_buffer.index(partial_response)
        clear_buffer = init_buffer[0,[index-1,0].max]
        partial_response = init_buffer[index..-1]
      end
      while(!partial_response.match(expected_match))
        if !eof?
          last_read = readpartial(1024) 
          partial_response << last_read
          Kernel.print last_read
        end
      end
      raise Timeout::Error.new("Error while sending #{command} to #{@telnet_ip}") if !partial_response.match(expected_match)
    }
    rescue Timeout::Error => e
      @is_timeout = true
      raise
    rescue Exception => e
       Kernel.print e.to_s+"\n"+e.backtrace.to_s
       raise
    end
    ensure
      @response = clear_buffer + partial_response
  end
  
  def response
    @response
  end
  
  def timeout?
    @is_timeout
  end
  
  def update_response
    last_read = partial_response = ''
    while !eof?
      last_read = readpartial(1024)
      partial_response << last_read
      Kernel.print last_read
    end
    puts "DEBUG: Returning from serial_connection:update_response"
    @response = partial_response
  end
  
  def regex_character(c)
    [91, 92, 94, 36, 46, 124, 63, 42, 43, 40, 41].include?(c.to_i)
  end
  
end
