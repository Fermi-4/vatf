require 'net/telnet'
require 'rubygems'
require 'fileutils'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require File.dirname(__FILE__)+'/drvif_cfg'
include DrvifCfg
require File.dirname(__FILE__)+'/evm_start'
include EVMStart
require File.dirname(__FILE__)+'/xdp_var_set_src_evm'
include XDPVarSetSrcEVM
require File.dirname(__FILE__)+'/xdp_var_set_tgt_PC'
include XDPVarSetTgtPC
require File.dirname(__FILE__)+'/dsp_glob_cfg'
include DSPGlobConfig
module Vgdk
#include Log4r

  class VgdkLinuxClientTomahawk 
    include Log4r  
    Logger = Log4r::Logger 
    attr_accessor :host, :port, :waittime
    attr_reader :response, :is_timeout
    @@start_session = 0 
    def initialize(platform_info, log_path = nil)
    begin
      start_logger(log_path) if log_path
      log_info("Starting target session") if @targetc_log
      @waittime = 0
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
	 	@target.login(@telnet_login.to_s, @telnet_passwd){ |c| print c }
	  elsif @telnet_login
		@target.login(@telnet_login.to_s){ |c| print c }
      end

      rescue Exception => e
       	log_info("Initialize: "+e.to_s)
        raise
      end
        connect
        if(@@start_session == 0)
            send_board_config()
            @@start_session = 1
        end
    end
    
    def connect
    end
    
    def disconnect
		ensure
		  @target.close if @target
		  @target = nil
    end
    
    def send_board_config()
      send_drvif_cfg()
      send_evm_start()
      send_xdp_var_set_srm_evm()
      send_xdp_var_set_tgt_pc()
      send_dsp_glob_config()
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
        # if(/ACK DONE/.match(expected_match.to_s))
          # puts "On command: "+command.to_s+" ACK DONE not received from DUT, exiting"
          # log_error("On command: "+command.to_s+" ACK DONE not received from DUT, exiting >>> error: "+e.to_s)
          # raise e
        # end
      rescue Exception => e
        log_error("On command "+command.to_s+"\n"+e.to_s+"Target: \n" + @response)
        raise
      end
      ensure
      	@response = clear_buffer + partial_response
      	log_info("Target: \n" + @response)
    end
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

  end
end




