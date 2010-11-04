# apc_power_controller.rb v.10
# Copyright: 4/18/2008 Texas Instruments Inc.

require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
include Log4r

  # This class controls basic functions used in the ApcPowercontrollers, such as on, off, reboot, and get port status.  The interactions from this driver can be logged using Log4r functionality
  class StafApcPowerController
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
      @telnet_ip
      @telnet_port
      @telnet_login = @telnet_login != nil ? @telnet_login : "apc"
      @telnet_passwd = @telnet_passwd != nil ? @telnet_passwd : "apc"
      @apc_id = rand(36**8).to_s(36).strip
      start_logger(log_path) if log_path
      log_info("Starting target session") if @apc_log
			login
		end
    
    # get_status returns the ON/OFF status of the equipment with the specified address
    # * pow_address - the port address to get the status of
    def get_status(pow_address)
      apc_submit("GET #{@apc_id} PORT #{pow_address} STATUS")
    end
    
    # Turns ON the equipment at the specified address
    # * pow_address - the port address to turn ON
    def switch_on(pow_address)
      apc_submit("SWITCH #{@apc_id} PORT #{pow_address} ON")
    end
    
    # Turns OFF the equipment at the specified address
    # * pow_address - the port address to turn OFF
    def switch_off(pow_address)
      apc_submit("SWITCH #{@apc_id} PORT #{pow_address} OFF")
    end
		
    # Power cycles the equipment at the specified address
    # * pow_address - the port address to powercycle
    # * waittime - how long to wait between powercycling (default: 5 seconds)
    def reset(pow_address, waittime=1)
      apc_submit("RESET #{@apc_id} PORT #{pow_address} DELAY #{waittime*1000}")
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
    
    def disconnect()
      if @staf_handle
        apc_submit("DELETE #{@apc_id}") 
      end
    end
    
    private
    
    # logs into the staf service and registers the apc with the given telnet_login & password and id
    def login
      @staf_handle = STAFHandle.new("staf_ruby_apc")
      apc_usr_pass = ''
      apc_usr_pass += ' USERNAME ' + @telnet_login if @telnet_login
      apc_usr_pass += ' PASSWORD ' + @telnet_passwd if @telnet_passwd
      staf_result = @staf_handle.submit(@params['staf_ip'],@id,"ADD #{@telnet_ip} ID #{@apc_id} " + apc_usr_pass) 
      log_info(staf_result.result)
      if(staf_result.rc != 0)
        raise "Unable to register the apc #{@name} id #{@id} with the staf service at #{@params['staf_ip']}"
      end
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
     
    def apc_submit(command)
      log_info('Cmd: ' + command)
      staf_result = @staf_handle.submit(@params['staf_ip'],@id,command)
      log_info('Result: ' + staf_result.result)
      puts staf_result.result
      staf_result.result
    end
    
  end
end

