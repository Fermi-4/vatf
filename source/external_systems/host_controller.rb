require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require 'open3'
require 'timeout'

module ExternalSystems
include Log4r

  class HostController
    Logger = Log4r::Logger 
    attr_accessor :response
	attr_reader :is_timeout
    
    def initialize(host_info, log_path = nil)
      start_logger(log_path) if log_path
      log_info("Starting external host session") if @host_log
	  host_info.instance_variables.each {|var|
        	if host_info.instance_variable_get(var).to_s.size > 0   
             self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
             self.instance_variable_set(var, host_info.instance_variable_get(var))
         end
      }
	  connect
	  
      rescue Exception => e
        log_error(e.to_s)   
        raise		
    end
    
    def connect
      if @telnet_ip.strip.downcase.eql?('127.0.0.1') || @telnet_ip.strip.downcase.eql?('localhost')
	    @host = IO.popen("C:\\WINDOWS\\system32\\cmd.exe","r+")
		raise "local host execution requires definition of the prompt variable in bench file" if !@prompt
	  else
		@host = Net::Telnet::new( "Host" => @telnet_ip,
                                  "Port" => @telnet_port,
                                  "Waittime" => 0.1,
                                  "Prompt" => @prompt,
                                  "Telnetmode" => true,
                                  "Binmode" => false)
		if @telnet_passwd.to_s != ''
			@host.login(@telnet_login,@telnet_passwd)
		else
			@host.login(@telnet_login)
		end
		  
	  end
    end
    
    def send_cmd(command, expected_match=/.*/, timeout=10)
	    @is_timeout = false
        @response = ''
        first_cmd_word = command.split(/\s/)[0].to_s
        clear_buffer = ''
        last_line = ''
        log_info('Cmd: ' + command)
        if !@host.kind_of?(Net::Telnet)
            @host.puts(command+' 2>&1')
        else
            @host.puts(command)
        end
        first_cmd_word = command.split(/\s/)[0].to_s
        clear_buffer = ''
        last_line = ''
        partial_response = ''
        Timeout::timeout(timeout) {
          while(!last_line.include?(first_cmd_word)) do #clearing the read buffer
              if !@host.eof?
                clear_buffer+= last_line
                last_line = preprocess(@host.readline)
              end
          end
          #partial_response = last_line if expected_match!=@prompt
          @host.puts('') #required to obtain the command prompt
          Timeout
          while(!partial_response.match(expected_match) && !partial_response.match(/.*#{@prompt}\s*$/im))
  	  	    partial_response += preprocess(@host.readline) if !@host.eof?
  	      end
          @response = clear_buffer + partial_response
          raise Timeout::Error.new('Timedout waiting for response from host') if !partial_response.match(expected_match)
        }
        log_info('Response: ' + clear_buffer + @response)
        true
        rescue Timeout::Error => e
            log_error("On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s)
            log_error('Response: '+ clear_buffer +@response)
						@is_timeout = true
            false
        rescue Exception => e
            log_error("On command "+command.to_s+"\n"+e.to_s+@response.to_s)
            raise
    end
    
    def preprocess(response)
        if !@host.kind_of?(Net::Telnet)
            response
        else
            @host.preprocess(response)
        end
    end
    
    def disconnect
	  if !@host.kind_of?(Net::Telnet)
		@host.puts("exit")
      else		
		@host.close if @host
	  end
      ensure
        @host = nil
    end
	
	def switch_to_sudo_super_user
		if @host.kind_of?(Net::Telnet) 
			if !send_cmd('whoami',/whoami.*root.*#{@prompt}/im)
				send_cmd('sudo su -',/(Password:)|(.+#)/im)
				if response.include?('Password')
					raise 'Unable to switch to root ' if !send_cmd(@telnet_passwd,/.+#/m)
				end
				@prompt = /#/
			end
		end
	end
    
    #Starts the logger for the session. Takes the log file path as parameter.
    def start_logger(file_path)
      if @host_log
        stop_logger
      end
      Logger.new('ext_host_log')
      @host_log_outputter = Log4r::FileOutputter.new("ext_log_out",{:filename => file_path.to_s , :truncate => false})
      @host_log = Logger['ext_host_log']
      @host_log.level = Log4r::DEBUG
      @host_log.add  @host_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @host_log_outputter.formatter = @pattern_formatter     
    end
    
    #Stops the logger.
    def stop_logger
        @host_log_outputter = nil if @host_log_outputter
        @host_log = nil if @host_log
    end
    
    private
	def log_info(info)
	  @host_log.info(info) if @host_log
	end

	def log_error(error)
	  @host_log.error(error) if @host_log
	end

	def log_warning(warning_info)
	  @host_log.warning(warning_info) if @host_log
	end          
  
  end
end
