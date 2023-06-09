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

    def send_sudo_cmd(command, expected_match=/.*/ ,timeout=30)
      cmd=Array(command)
      cmd << '' if cmd.length < 2
      begin
        @timeout = false
        Timeout::timeout(timeout) {
        @response = ''
        log_info("Cmd: sudo -E -S #{cmd*','}")
        @response = `sudo -E -S #{cmd[0]} 2>&1 << EOF
#{@telnet_passwd}
EOF
#{cmd[1..-1]*"\n"}
`
        log_info('Response: '+@response)
        }
        @timeout = @response.match(expected_match) == nil
      rescue Timeout::Error => e
        puts "TIMEOUT executing #{cmd}"
        log_error("On command "+cmd.to_s+"\n"+e.to_s+"Target: \n" + @response.to_s)
        @timeout = true 
      end
    end
    
    def send_cmd(command, expected_match=/.*/, timeout=10, check_cmd_echo=true)
      begin
        @timeout = false
        Timeout::timeout(timeout.to_i) {
          @response = ''
          log_info('Cmd: '+command.to_s)
          @response = `#{command} 2>&1` 
          log_info('Response: '+@response)		
        }
        @timeout = @response.match(expected_match) == nil
      rescue Timeout::Error => e
        puts "TIMEOUT executing #{command}"
        log_error("On command "+command.to_s+"\n"+e.to_s+"Target: \n" + @response.to_s)
        @timeout = true
      end
    end
    
    def send_cmd_nonblock(command, expected_match=/.*/, timeout=10, check_cmd_echo=true)
      Thread.new(command, expected_match, timeout, check_cmd_echo) do |a,b,c,d|
        send_cmd(a,b,c,d)
      end
      sleep 1   # Make sure the new thread starts before returning to calling thread
    end
	
    def send_sudo_cmd_nonblock(command, expected_match=/.*/, timeout=10)
      Thread.new(command, expected_match, timeout) do |a,b,c|
        send_sudo_cmd(a,b,c)
      end
      sleep 1   # Make sure the new thread starts before returning to calling thread
    end
    
    def serial_load(*load_list)
      load_list.each do |l_spec|
        r = nil
        w = nil
        status = ''
        bin_path = ''
        begin
          bin_path = l_spec['bin_path']
          timeout = l_spec['timeout'] ? l_spec['timeout'].to_i : 90
          load_re = l_spec['load_re'] ? /#{l_spec['load_re']}/ : /Transfer\s*complete/im
          load_cmd = l_spec['load_cmd'] ? l_spec['load_cmd'] : 'sx -k --xmodem'
          load_port = l_spec['port']
          baudrate = l_spec['baudrate'] ? l_spec['baudrate'].to_i : 115200

          raise "File #{bin_path} specified for loading does not exists" if !File.exist?(bin_path) || !File.file?(bin_path)
          raise "Port used to load the image was not specified #{l_spec.to_s} " if !load_port

          send_cmd("stty -F #{load_port} #{baudrate} -crtscts")
        
          r,w = IO.pipe
          log_info("#{bin_path} tranfer started ...")
          sx_thread = Thread.new {
          Thread.pass
            Open3.pipeline("/usr/bin/timeout #{timeout} #{load_cmd} #{bin_path}", :in => load_port, :out => load_port, :err=>w)
          }
          status = ''
          Timeout::timeout(timeout) {
            status = r.read(8)
            while !status.match(load_re) do
              #puts status #Uncomment to debug
              status += r.read_nonblock(8) if !r.eof?
            end
          }
        rescue Timeout::Error => e
          puts "TIMEOUT loading image #{bin_path}"
          log_info("TIMEOUT loading image #{bin_path}")
          raise "TIMEOUT loading image #{bin_path}\n#{e}"
        ensure
          Thread.new {
            log_info(status)
          }
          w.close() if w
          r.close() if r
        end
      end
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
