require 'net/http'
require 'timeout'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
include Log4r

  # This class controls Digital Loggers DIN Relay http://www.digital-loggers.com/din.html
  class DlDinRelayController
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
      @login = @telnet_login != nil ? @telnet_login : "admin"
      @passwd = @telnet_passwd != nil ? @telnet_passwd : "95ymy5"
      @output = ""
      start_logger(log_path) if log_path
      log_info("Starting target session") if @dl_log
		end
    
    def login
    end
    
    def logout
    end
    
    # Turns ON/Close Relay at the specified address
    # * address - the port/relay to turn ON
    def switch_on(address)
      _switch("ON", address)
    end
    
    # Turns OFF/Open the Relay at the specified address
    # * address - the port/reay to turn OFF
    def switch_off(address)
      _switch("OFF", address)
    end

    def _switch(type, address)
      type.upcase!
      sleep_time = 1
      sleep_time = 12 if type.match(/OFF/)
      6.times {
        begin 
          send_cmd(address, "ON", 2)
          sleep sleep_time
          3.times {
            begin
              send_cmd(address, "OFF", 2)
              return
            rescue 
              next
            end
          }
          raise "Could not turn relay OFF"
        rescue
          next
        end
      }
      raise "Timeout trying to switch #{type} port #{address}"
    end
		
    # Cycle (Turn OFF and ON) the port/relay at the specified address
    # * address - the port/relay address to cycle
    # * waittime - how long to wait between cycling (default: 5 seconds)
    def reset(address, waittime=3)
      switch_off(address)
      sleep(waittime)
      switch_on(address) 
    end

    # sends a command to the unit
    # * address - 0-7 (Address of relay)
    # * type - ON or OFF
    # * wait_time - how long to wait for DIN web server response
    def send_cmd(address, type, wait_time=4)
      uri = URI("http://#{@host}/outlet?#{address}=#{type}")
      log_info("Host: \n" + uri.to_s)
      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth @login, @passwd
      res = nil
      Timeout::timeout(wait_time) do
        res = Net::HTTP.start(uri.host, uri.port) {|http|
          http.request(req)
        }
      end
      log_info("Target: \n" + res.msg)
      rescue Timeout::Error
        log_error("Timeout waiting for DIN Relay server")
        raise
      rescue Exception => e
        log_error("Error while trying to turn #{type} port #{address}\n"+e.to_s)
        raise
    end  
    
    
    #Starts the logger for the session. Takes the log file path as parameter.
    # * file_path - the path to store the log
    def start_logger(file_path)
      if @dl_log
        stop_logger
      end
      Logger.new('dl_din_log')
      @dl_log_outputter = Log4r::FileOutputter.new("switch_log_out",{:filename => file_path.to_s , :truncate => false})
      @dl_log= Logger['dl_log']
      @dl_log.level = Log4r::DEBUG
      @dl_log.add  @dl_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @dl_log_outputter.formatter = @pattern_formatter     
    end
    
    #Stops the logger.
    def stop_logger
        @dl_log_outputter = nil if @dl_log_outputter
        @dl_log = nil if @dl_log
    end
    
    private
    
    def log_info(info)
      @dl_log.info(info) if @dl_log
    end

    def log_error(error)
      @dl_log.error(error) if @dl_log
    end
    
    def disconnect()
      
    end
    
  end
end

