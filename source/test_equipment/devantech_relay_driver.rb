require 'socket'
require 'timeout'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
include Log4r

  # This class controls Devantech Relay http://www.robot-electronics.co.uk/htm/eth_rly16tech.htm
  class DevantechRelayController
    Logger = Log4r::Logger 
    def initialize(platform_info, log_path = nil)
      platform_info.instance_variables.each {|var|
         	#if platform_info.instance_variable_get(var).kind_of?(String) && platform_info.instance_variable_get(var).to_s.size > 0
        	if platform_info.instance_variable_get(var).to_s.size > 0   
             self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
             self.instance_variable_set(var, platform_info.instance_variable_get(var))
         end
      }
      @host = @telnet_ip
      @port = @telnet_port != nil ? @telnet_port : 17494
      @login = @telnet_login != nil ? @telnet_login : "admin"
      @passwd = @telnet_passwd != nil ? @telnet_passwd : "password"
      @output = ""
      start_logger(log_path) if log_path
      log_info("Starting target session") if @relay_log
		end
    
    def login
    end
    
    def logout
    end
    
    # Close NC/Open NO contact (passive state) at the specified address
    # * address - the port/relay to toggle
    def switch_on(address)
      _switch("OFF", address) #Set relay to passive state
    end
    
    # Open NC/Close NO contact (active state) at the specified address
    # * address - the port/relay to toggle
    def switch_off(address)
      _switch("ON", address) #Set relay to active state
    end
		
    # Cycle (switch_off, switch_on) the port/relay at the specified address
    # * address - the port/relay address to cycle
    # * waittime - how long to wait between cycling (default: 5 seconds)
    def reset(address, waittime=1)
      switch_off(address) 
      sleep(waittime)
      switch_on(address)
    end


    # Will active relays for each '1' in index
    def sysboot(settings, address=nil)
      settings.split("").each_with_index do |val,idx|
        if val == '0'
          _switch("OFF", idx.to_i + 1)
        else
          _switch("ON", idx.to_i + 1)
        end
      end
    end


    #Starts the logger for the session. Takes the log file path as parameter.
    # * file_path - the path to store the log
    def start_logger(file_path)
      if @relay_log
        stop_logger
      end
      Logger.new('devantech_log')
      @relay_log_outputter = Log4r::FileOutputter.new("devantech_log_out",{:filename => file_path.to_s , :truncate => false})
      @relay_log= Logger['devantech_log']
      @relay_log.level = Log4r::DEBUG
      @relay_log.add  @relay_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @relay_log_outputter.formatter = @pattern_formatter     
    end
    
    #Stops the logger.
    def stop_logger
        @relay_log_outputter = nil if @relay_log_outputter
        @relay_log = nil if @relay_log
    end
    
    private
    
    def _switch(type, address)
      status_cmd = 0x5b
      base_add = 0x64
      base_add = 0x6e if type == "OFF"
      sock = TCPSocket.open(@host, @port)
      status = Timeout::timeout(10) {
        if sock == nil
          raise "Could not connect to power controller"
        end
        addr = base_add + address
        sock.write(addr.chr)
        sock.write(status_cmd.chr)
        result = ((sock.read(1).unpack('C')[0]  >> (address - 1)) & 0x01)
        if (result == 0 and type == "ON") or (result == 1 and type == "OFF")
          raise "Power controller did not set relay properly"
        end
      }
      rescue Timeout::Error 
        raise "Timeout communicating with power controller"
      ensure
          sock.close if sock
    end
    
    def log_info(info)
      @relay_log.info(info) if @relay_log
    end

    def log_error(error)
      @relay_log.error(error) if @relay_log
    end
    
    def disconnect()
      
    end
    
  end
end

