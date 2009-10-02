# apc_power_controller.rb v.10
# Copyright: 4/18/2008 Texas Instruments Inc.

#require 'rubyclr'
require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
include Log4r

  # This class controls basic functions used in the ApcPowercontrollers, such as on, off, reboot, and get port status.  The interactions from this driver can be logged using Log4r functionality
  class ApcPowerController
    Logger = Log4r::Logger 
    #attr_accessor :host, :port
    
    #initialize the ip, port, telnet_login, password, and log path
    # The first variable must be a hash that defines
    # * telnet_ip - REQUIRED - the ip of the apc power controller
    # * telnet_port - REQUIRED - the port the apc power controller is sitting on (default- 23)
    # * telnet_login - the telnet_login to send to the apc powercontroller (default- apc)
    # * telnet_passwd - the password for the apc powercontroller user specified in telnet_login (default- apc)
    # * log_path - the path for the log file (default - nil ie. do not log)
    def initialize(platform_info, log_path = nil)
      platform_info.instance_variables.each {|var|
         	#if platform_info.instance_variable_get(var).kind_of?(String) && platform_info.instance_variable_get(var).to_s.size > 0
        	if platform_info.instance_variable_get(var).to_s.size > 0   
             self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
             self.instance_variable_set(var, platform_info.instance_variable_get(var))
         end
      }
      @host = @telnet_ip
      @port = @telnet_port
      @telnet_login = @telnet_login != nil ? @telnet_login : "apc"
      @telnet_passwd = @telnet_passwd != nil ? @telnet_passwd : "apc"
      @output = ""
      start_logger(log_path) if log_path
      log_info("Starting target session") if @apc_log
			login
			@version = /v(\d+)\.\d+\.\d+/.match(@response).captures[0].to_i # Added to track different sw versions w/ different menu options
			logout
		end
    
    # get_status returns the ON/OFF status of the equipment with the specified address
    # * pow_address - the port address to get the status of
    def get_status(pow_address)
      login
      
      send_cmd("1")
      send_cmd("3")
      send_cmd(pow_address.to_s)
      send_cmd("1")
      ret = /\bState\s+:\s+\bON/.match(@response) ? "APC port %s is ON" % pow_address.to_s : "APC port %s is OFF" % pow_address.to_s
      
      logout
      
      puts ret
    end
    
    # Turns ON the equipment at the specified address
    # * pow_address - the port address to turn ON
    def switch_on(pow_address)
      #login to apc
      login
      
      # move to proper menu
      send_cmd("1")
      if @version == 2
				send_cmd("3")
			else
				send_cmd("2")
				send_cmd("1")
			end
      send_cmd(pow_address.to_s)
      send_cmd("1")
      send_cmd("1")
      send_cmd("yes")
      send_cmd("")
      
      #check to make sure the port is ON
      ret = /\bState\s+:\s+\bON/.match(@response) ? "APC port %s ON" % pow_address.to_s : "FAILED to turn port %s ON" % pow_address.to_s
            
      #logout of the apc
      logout
      
      puts ret
    end
    
    # Turns OFF the equipment at the specified address
    # * pow_address - the port address to turn OFF
    def switch_off(pow_address)
      #login to apc
      login
      
      # move to proper menu
      send_cmd("1")
      if @version == 2
				send_cmd("3")
			else
				send_cmd("2")
				send_cmd("1")
			end
      send_cmd(pow_address.to_s)
      send_cmd("1")
      send_cmd("2")
      send_cmd("yes")
      send_cmd("")
      
      #check to make sure the port is OFF
      ret = /\bState\s+:\s+\bOFF/.match(@response) ? "APC port %s OFF" % pow_address.to_s : "FAILED to turn port %s OFF" % pow_address.to_s
            
      #logout of the apc
      logout
      
      puts ret
    end
		
    # Power cycles the equipment at the specified address
    # * pow_address - the port address to powercycle
    # * waittime - how long to wait between powercycling (default: 5 seconds)
    def reset(pow_address, waittime=5)
      switch_off(pow_address)
      sleep(waittime)
      switch_on(pow_address) 
    end
    
    #Starts the logger for the session. Takes the log file path as parameter.
    # * file_path - the path to store the log
    def start_logger(file_path)
      if @apc_log
        stop_logger
      end
      Logger.new('apc_log')
      @apc_log_outputter = Log4r::FileOutputter.new("switch_log_out",{:filename => file_path.to_s , :truncate => false})
      @apc_log= Logger['apc_log']
      @apc_log.level = Log4r::DEBUG
      @apc_log.add  @apc_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @apc_log_outputter.formatter = @pattern_formatter     
    end
    
    #Stops the logger.
    def stop_logger
        @apc_log_outputter = nil if @dvtbc_log_outputter
        @apc_log = nil if @apc_log
    end
    
    private
    
    # logs into the unit and sends the given the initialized telnet_login & password
    def login
        @apc = Net::Telnet::new( "Host" => @host,
                                  "Port" => @port,
                                  "Waittime" => 0.1, 
                                  "Telnetmode" => true,
                                  "Prompt" => /[>]/n,
                                  "Binmode" => false)
                                  
      #login using telnet_login & password
      send_cmd("", /User/, 5)
      send_cmd(@telnet_login, /Password/, 5)
      send_cmd(@telnet_passwd)        
    end
    
    # logs out of the unit by sending escape until the user is at the top level screen, then sends "4" which is the logout selection
    def logout
      #send ESC escape sequence until your at the top level (where there is 4- Logout)
      until @response.match(/4\-\s+\bLogout/)
        send_cmd("\e")
      end
      
      send_cmd("4") # logout by executing the "4" command
      @apc.close() # close the socket
    end
    
    # sends a command to the unit
    # * command - the command to SEND
    # * match - the string to EXPECT (default - />/ (the prompt)
    # * timeout - how long to wait for the EXPECT string after issuing SEND (default - 5)
    def send_cmd(command, match=/>/, timeout=5)
        @response = ""
        @apc.cmd("String" => command, "Match" => match, "Timeout" => timeout) { |str|
            # DEBUG-- print str
            @response += str
        }
        log_info("Target: \n" + @response)
        rescue Exception => e
        log_error("On command "+command.to_s+"\n"+e.to_s)
        raise
      end  
      
    def log_info(info)
      @apc_log.info(info) if @apc_log
    end
    def log_error(error)
      @apc_log.error(error) if @apc_log
    end
    def log_info(debug_info)
      @apc_log.info(debug_info) if @apc_log
    end
    def disconnect()
      
    end
    
  end
end

