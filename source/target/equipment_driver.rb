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
        self.class.class_eval {attr_accessor *(var.to_s.gsub('@',''))}
        self.instance_variable_set(var, platform_info.instance_variable_get(var))
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

    def disconnect(type='all')
      @target.disconnect(type) if @target
      log_info("Disconnected #{type} from #{@platform_info.name}")
    end
    
    def send_cmd(command, expected_match=/.*/, timeout=10, check_cmd_echo=true, append_linefeed=true)
	    log_info("Host: " + command)
      @target.send_cmd(command, expected_match, timeout, check_cmd_echo, append_linefeed)
      @target.response
      rescue Timeout::Error => e
        expected_str = expected_match.to_s
        expected_str = "#{command}.+?#{expected_match}" if check_cmd_echo
        puts ">>>> On command: "+command.to_s+" waiting for "+expected_str+" >>> error: "+e.to_s
        log_error("On command: "+command.to_s+" waiting for "+expected_str+" >>> error: "+e.to_s)
      rescue Exception => e
        log_error("On command "+command.to_s+"\n"+e.to_s+"Target: \n" + response.to_s)
        raise
      ensure
        log_info("Target: \n" + response.to_s)
    end
    
    def method_missing(method, *args)
      if @target.ccs && @target.ccs.respond_to?(method)
        log_info("Calling CCS method #{method.to_s} with params #{args.to_s}")
        @target.ccs.logfp = self.method(:log_info)
        @target.ccs.send(method, *args)
      else
        super
      end
    end
    
    def wait_for(expected_match=/.*/, timeout=10)
      @target.wait_for(expected_match,timeout)
      rescue Timeout::Error => e
        puts ">>>>  waiting for "+expected_match.to_s+" >>> error: "+e.to_s
        log_error("waiting for "+expected_match.to_s+" >>> error: "+e.to_s)
      rescue Exception => e
        log_error("Target: \n" + response.to_s)
        raise
      ensure
        log_info("Target: \n" + response.to_s)
    end
    
    def read_for(time)
      @target.read_for(time)
      rescue Exception => e
        log_error("Target: \n" + response.to_s)
        raise
      ensure
        log_info("Target: \n" + response.to_s)
    end
    
    def response
      @target.response
    end
    
    def timeout?
      @target.timeout?
    end
    
    def update_response(type='default')
      x = case type.to_s.downcase
      when 'telnet'
        @target.telnet.update_response
      when 'serial'
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
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %M",:date_pattern => "%H:%M:%S")
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
      z= info.encode('ASCII', 'UTF-8', :universal_newline => true, :invalid => :replace, :undef => :replace, :replace => '')
      z.gsub!(/[^[:print:][:space:]]/m,'')
      @targetc_log.info(z) if @targetc_log
    end

    def log_error(error)
      z= error.encode('ASCII', 'UTF-8', :universal_newline => true, :invalid => :replace, :undef => :replace, :replace => '')
      z.gsub!(/[^[:print:][:space:]]/m,'')
      @targetc_log.error(z) if @targetc_log
    end

    def log_debug(debug_info)
      z= debug_info.encode('ASCII', 'UTF-8', :universal_newline => true, :invalid => :replace, :undef => :replace, :replace => '')
      z.gsub!(/[^[:print:][:space:]]/m,'')
      @targetc_log.debug(z) if @targetc_log
    end

  end
  
end
