require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module Equipment

  class LinuxLocalHostDriver
    include Log4r  
    attr_reader :target
    
    
    def initialize(platform_info, log_path = nil)
      start_logger(log_path) if log_path
      log_info("Starting target session") if @targetc_log
      @response = ''
      @platform_info = platform_info
      platform_info.instance_variables.each {|var|
        self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
        self.instance_variable_set(var, platform_info.instance_variable_get(var))
      }
      rescue Exception => e
        log_info("Initialize: "+e.to_s)
        raise
    end
    
    def connect(params)
    end

    def disconnect
    end

    def send_sudo_cmd(cmd, expected_match=/.*/ ,password=@telnet_passwd, timeout=30)
      log_info("Cmd: sudo -E -S #{cmd}")
      @response = `sudo -E -S #{cmd} << EOF
#{password}
EOF` 
      log_info('Response: '+@response)		
      @timeout = @response.match(expected_match) != nil
    end
    
    def send_cmd(command, expected_match=/.*/, timeout=10, check_cmd_echo=true)
      log_info('Cmd: '+command.to_s)
      @response = `#{command} 2>&1` 
      log_info('Response: '+@response)		
      @timeout = @response.match(expected_match) != nil
    end
    
    def response
      @response
    end
    
    def timeout?
      @timeout
    end
    
    def update_response(type='default')
      @response
    end

    def file_exists?(file)
      File.exists?(file)
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
