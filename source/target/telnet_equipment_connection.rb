require 'net/telnet'
require 'rubygems'
require 'timeout'


class TelnetEquipmentConnection < Net::Telnet
  attr_reader :telnet
  def initialize(platform_info)
    @telnet_ip   = platform_info.telnet_ip
    @telnet_port = platform_info.telnet_port
    @prompt      = platform_info.prompt
    @boot_prompt = platform_info.boot_prompt
    @telnet_login = platform_info.telnet_login
    @telnet_passwd = platform_info.telnet_passwd
    super( "Host" => @telnet_ip,
            "Port" => @telnet_port,
            "Waittime" => 0,
            "Prompt" => @prompt,
            "Telnetmode" => true,
            "Binmode" => false)
    rescue Exception => e
      raise
  end

  def connect
    send_cmd("",/.*/)  if @telnet_port.to_s != '23'
    if @telnet_login && @telnet_passwd then
      login(@telnet_login.to_s, @telnet_passwd){ |c| 
      Kernel.print c 
      break if c.match(/(#{@prompt})|(#{@boot_prompt})/)
      }
    elsif @telnet_login
      login(@telnet_login.to_s){ |c| 
      Kernel.print c
      break if c.match(/(#{@prompt})|(#{@boot_prompt})/)
      }
    end
  end

  def disconnect
		close 
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
      partial_response = ''
      puts(command)
      if clear_history
        first_cmd_word = command.split(/\s/)[0].to_s
        i = 0
        first_cmd_word.each_byte {|c| 
          first_cmd_word[i] = '.'  if c.to_i < 32
          i+=1
        }
        first_cmd_word = Regexp.new(first_cmd_word)
      end
      status = Timeout::timeout(timeout) {
        if clear_history
          while(!clear_buffer.match(first_cmd_word)) do #clearing the read buffer
            clear_buffer+= preprocess(readpartial(8)) if !eof?
          end
          partial_response = clear_buffer.scan(/#{first_cmd_word}.*/m)[0]
          index = clear_buffer.index(partial_response)
          clear_buffer = clear_buffer[0,[index-1,0].max]
        end
        while(!partial_response.match(expected_match))
          if !eof?
            last_read = preprocess(readpartial(1024)) 
            partial_response += last_read
            Kernel.print last_read
          end
        end
        raise Timeout::Error.new("Error while sending #{command} to #{@telnet_ip}") if !partial_response.match(expected_match)
      }
    rescue Timeout::Error => e
      @is_timeout = true
      raise
    rescue Exception => e
      raise
    ensure
      @response = clear_buffer + partial_response
    end  
  end
  
  def response
    @response
  end
  
  def timeout?
    @is_timeout
  end
  
end
