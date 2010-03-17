require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

require File.dirname(__FILE__)+'/equipment_connection'

module Equipment

  class EquipmentDriver
    include Log4r  
    attr_reader :target
    
    
    def initialize(platform_info, log_path = nil)
      start_logger(log_path) if log_path
      log_info("Starting target session") if @targetc_log
      @platform_info = platform_info
      platform_info.instance_variables.each {|var|
        if platform_info.instance_variable_get(var).to_s.size > 0   
          self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
          self.instance_variable_set(var, platform_info.instance_variable_get(var))
        end
      }
      @target = EquipmentConnection.new(@platform_info) 
      rescue Exception => e
        log_info("Initialize: "+e.to_s)
        raise
    end
    
    def connect(params)
      @target.connect(params)
      log_info("Connected to #{@platform_info.name} via #{params['type']} ")
    end

    def disconnect
      @target.disconnect if @target
    end
    
    def send_cmd(command, expected_match=/.*/, timeout=10, clear_history=true)
      log_info("Host: " + command)
      @target.send_cmd(command, expected_match, timeout, clear_history)
      rescue Timeout::Error => e
        puts ">>>> On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s
        log_error("On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s)
      rescue Exception => e
        log_error("On command "+command.to_s+"\n"+e.to_s+"Target: \n" + response)
        raise
      ensure
        log_info("Target: \n" + response)
    end
    
    def response
      @target.response
    end
    
    def timeout?
      @target.timeout?
    end
    
    def update_response(type='default')
      x = case type.to_s.downcase
      when 'telnet':
        @target.telnet.update_response
      when 'serial':
        @target.serial.update_response
      else
        @target.update_response
      end
      #log_info("Target: \n" + x)
      x
    end
    
    #Starts the logger for the session. Takes the log file path as parameter.
    def start_logger(file_path)
      if @targetc_log
        stop_logger
      end
      Log4r::Logger.new('targetc_log')
      @targetc_log_outputter = Log4r::FileOutputter.new("switch_log_out",{:filename => file_path.to_s , :truncate => false})
      @targetc_log = Log4r::Logger['targetc_log']
      @targetc_log.level = Log4r::DEBUG
      @targetc_log.add  @targetc_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @targetc_log_outputter.formatter = @pattern_formatter     
    end
    
    def stop_logger
      @targetc_log_outputter = nil if @targetc_log_outputter
      @targetc_log = nil if @targetc_log
    end
    
    def log_warning(warning)
        @targetc_log.warn(warning) if @targetc_log
    end
    
    def log_info(info)
      @targetc_log.info(info) if @targetc_log
    end

    def log_error(error)
      @targetc_log.error(error) if @targetc_log
    end

    def log_debug(debug_info)
      @targetc_log.debug(debug_info) if @targetc_log
    end

  end
  
end