require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require 'timeout'

module LspTargetHandlers
  class LspTargetController
    include Log4r  
    Logger = Log4r::Logger 
    attr_accessor :host, :port, :waittime
    attr_reader :response, :is_timeout

    #Starts the logger for the session. Takes the log file path as parameter.
    def start_logger(file_path)
      if @targetc_log
        stop_logger
      end
      Logger.new('targetc_log')
      @targetc_log_outputter = Log4r::FileOutputter.new("switch_log_out",{:filename => file_path.to_s , :truncate => false})
      @targetc_log = Logger['targetc_log']
      @targetc_log.level = Log4r::DEBUG
      @targetc_log.add  @targetc_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @targetc_log_outputter.formatter = @pattern_formatter     
    end
    
    #Stops the logger.
    def stop_logger
      @targetc_log_outputter = nil if @targetc_log_outputter
      @targetc_log = nil if @targetc_log
    end
    
    def send_cmd(command, expected_match=/.*/, timeout=30)
      @is_timeout = false
      begin
      @response = ""
      log_info("Host: " + command)
      @target.puts(command)
      first_cmd_word = command.split(/\s/)[0].to_s
      i = 0
      first_cmd_word.each_byte {|c| 
          first_cmd_word[i] = '.'  if c.to_i < 32
          i+=1
      }
      
      first_cmd_word = Regexp.new(first_cmd_word)
      clear_buffer = ''
      partial_response = ''
      status = Timeout::timeout(timeout) {
    	  while(!clear_buffer.match(first_cmd_word)) do #clearing the read buffer
              #Thread.critical = true
              clear_buffer+= @target.preprocess(@target.readpartial(8)) if !@target.eof?
              #Thread.critical = false
          end
          partial_response = clear_buffer.scan(/#{first_cmd_word}.*/m)[0]
          index = clear_buffer.index(partial_response)
          clear_buffer = clear_buffer[0,[index-1,0].max]
          while(!partial_response.match(expected_match))
	  	      if !@target.eof?
				  last_read = @target.preprocess(@target.readpartial(1024)) 
	  	      	  partial_response += last_read
	  	          print last_read
			  end
	      end
	      raise Timeout::Error.new("Error while sending #{command} to #{@telnet_ip}") if !partial_response.match(expected_match)
      }
      rescue Timeout::Error => e
        puts ">>>> On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s
        log_error("On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s)
        @is_timeout = true
      rescue Exception => e
        log_error("On command "+command.to_s+"\n"+e.to_s+"Target: \n" + @response)
        raise
      end
      ensure
      	@response = clear_buffer + partial_response
      	log_info("Target: \n" + @response)
    end
    
    def disconnect
		ensure
		  @target.close if @target
		  @target = nil
    end
            
    def initialize(platform_info, log_path = nil)
      begin
      start_logger(log_path) if log_path
      log_info("Starting target session") if @targetc_log
      #@telnet_passwd = nil
      #@telnet_login = nil
      @waittime = 0
      #@waittime = 0.3
      platform_info.instance_variables.each {|var|
         	#if platform_info.instance_variable_get(var).kind_of?(String) && platform_info.instance_variable_get(var).to_s.size > 0
        	if platform_info.instance_variable_get(var).to_s.size > 0   
             self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
             self.instance_variable_set(var, platform_info.instance_variable_get(var))
         end
      }
            
      @target = Net::Telnet::new( "Host" => @telnet_ip,
                                  "Port" => @telnet_port,
                                  "Waittime" => @waittime,
                                  "Prompt" => @prompt,
                                  "Telnetmode" => true,
                                  "Binmode" => false)
      send_cmd("",/.*/)
      if @telnet_login && @telnet_passwd then
        @target.login(@telnet_login.to_s, @telnet_passwd){ |c| 
        print c 
        break if c.match(/#{@prompt}/)}
      elsif @telnet_login
        @target.login(@telnet_login.to_s){ |c| 
        print c
        break if c.match(/#{@prompt}/)}
      end

      rescue Exception => e
       	log_info("Initialize: "+e.to_s)
        raise
      end
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
		
		# Copy an image from the build server to the tftp server
    # Reboot the @and load the image into it in the bootloader
    # Boots into the new image, leaving the user at the command prompt 
    # Required Params: 
    # 'image_path' must be defined in the params hash, this is the path to your build directory
    # 'tftp_path' must be defined in the params hash, this is the base path to your tftp server (where the files will be copied)
    # 'tftp_ip' must be defined in the params hash if you have any modules, this is the ip of your tftp server (where the files will be copied & the modules will be copied from)
    def boot (params)
		  @power_handler = params['power_handler'] if !@power_handler
      image_path = params['image_path']
      puts "\n\n====== uImage is at #{image_path} =========="
      tftp_path  = params['server'].tftp_path
      tftp_ip    = params['server'].telnet_ip
      samba_path = params['samba_path'] 
			nfs_path   = params['nfs_path']
			nfs_root   = params['nfs_root']
      boot_args = SiteInfo::Bootargs[params['platform'].downcase.strip]
      boot_args = params['bootargs'] if params['bootargs']
      tmp_path = "#{params['tester'].downcase.strip}/#{params['target'].downcase.strip}/#{params['platform'].downcase.strip}"
      if image_path != nil && File.exists?(image_path) && get_image(image_path, samba_path, params['server'], tmp_path, nfs_path) then
        boot_to_bootloader()
        #set bootloader env vars and tftp the image to the unit -- Note: add more commands here if you need to change the environment further
        send_cmd("setenv serverip #{tftp_ip}",@boot_prompt, 30)
        send_cmd("setenv bootcmd 'dhcp;bootm'",@boot_prompt, 30)
        send_cmd("setenv bootfile #{tmp_path}/#{File.basename(image_path)}",@boot_prompt, 30)
        raise 'Unable to set bootfile' if @is_timeout
        send_cmd("setenv nfs_root_path #{params['server'].telnet_ip}:#{nfs_root}",@boot_prompt, 30)
        raise 'Unable to set nfs root path' if @is_timeout
        send_cmd("setenv bootargs #{boot_args}",@boot_prompt, 30)
        raise 'Unable to set bootargs' if @is_timeout
        send_cmd("saveenv",@boot_prompt, 10)
        raise 'Unable save environment' if @is_timeout
        send_cmd("printenv", @boot_prompt, 20)
        send_cmd('boot', /login/, 120)
        raise 'Unable to boot platform' if @is_timeout
        # command prompt context commands
        send_cmd(@login, @prompt, 10) # login to the unit
        raise 'Unable to login' if @is_timeout
      else
        raise "image #{image_path} does not exist, unable to copy"
      end
    end

    # stop the bootloader after a reboot
    def stop_boot()
      0.upto 3 do
        send_cmd("\e", @boot_prompt, 1)
      end
    end
    
    # Reboot the unit to the bootloader prompt
    def boot_to_bootloader()
      puts 'rebooting DUT'
			if @power_port !=nil
        puts 'Resetting @using power switch'
        @power_handler.reset(@power_port)
        send_cmd("\e", /U-Boot/, 3)
      else
        send_cmd('reboot', /U-Boot/, 40)
      end
      # stop the autobooter from autobooting the box
      #0.upto 30 do
      0.upto 5 do
        send_cmd("\n", @boot_prompt, 1)
        puts 'Sending esc character'
        sleep 1
        break if !@is_timeout
      end
      # now in the uboot prompt
    end
    
    # Boot to the login prompt (will NOT login for you)
    def boot_to_image()
		  if @power_port !=nil
        puts 'Resetting @using power switch'
       @power_handler.reset(@power_port)
      else
        send_cmd('reboot', /Hit any key to stop autoboot:/, 30)
      end
    end
    
    # Copy the image files and module.ko files from the build directory into the ftp directory
    def get_image(src_win, dst_folder_win, server, dst_linux, nfs_path)
      # Copy images and modules (.ko) tftp server
      @build_files = Array.new
      src_folder = File.dirname(src_win)
      BuildClient.dir_search(src_folder, @build_files)
      dst_linux = "/#{dst_linux}" if !(/^\//.match(dst_linux))
      @build_files.each {|f|
        dst_path   = dst_folder_win+"\\#{File.basename(f)}"    # This is the Windows'samba path
        if f.gsub(/\\/,'/') == src_win.gsub(/\\/,'/') 
          puts "copy from: #{f}"
          puts "copy to: #{dst_path}"
          BuildClient.copy(f, dst_path)
          raise "Please specify TFTP path like /tftproot in Linux server in bench file." if server.tftp_path.to_s == ''
          server.send_cmd("mkdir -p -m 666 #{server.tftp_path}#{dst_linux}",server.prompt, 10)
          server.send_cmd("mv -f #{nfs_path}/#{File.basename(f)} #{server.tftp_path}#{dst_linux}", server.prompt, 10)
        elsif File.extname(f) == '.ko'
          BuildClient.copy(f, dst_path) 
        end
      }
      true 
    end

  end
end
