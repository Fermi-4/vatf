require 'net/telnet'
require 'rubygems'
require 'fileutils'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module DvtbHandlers
include Log4r

  class DvtbLinuxClient
    Logger = Log4r::Logger  
    def initialize(platform_info, log_path = nil)
      start_logger(log_path) if log_path
      log_info("Starting target session") if @dvtbc_log
      @host=platform_info.telnet_ip
      @port=platform_info.telnet_port
	  @prompt=platform_info.prompt
	  @smb_info = platform_info.samba_root_path.gsub(/\/$/,'')
	  @media_data_path = '/dvtb/'
      @linux_client = Net::Telnet::new( "Host" => @host,
                                  "Port" => @port,
                                  "Prompt" => /#/,
                                  "Telnetmode" => true)
								  
      send_cmd(@linux_client, "cd /dvtb", '#')
      send_cmd(@linux_client, "./loadmodules.sh", '#')
	  send_cmd(@linux_client, "cat /dev/zero > /dev/fb/2", '#')
	  send_cmd(@linux_client, "cat /dev/zero > /dev/fb/3", '#')
      send_cmd(@linux_client, "/dvtb/dvtb-dm355", @prompt) 
      rescue Exception => e
        log_info(e.to_s)
        raise "Could not start Linux Client\n"+e.to_s 
    end
    
    def get_param(params)
      if params.kind_of?(Hash)
        string = params["Class"]+" "+params["Param"]   
      else
        string = params
      end
      send_cmd(@linux_client, "getp "+string, "PASS")
    end
    
    def set_param(params)
      if params.kind_of?(Hash)
        string = params["Class"].to_s+" "+params["Param"].to_s+" "+params["Value"].to_s   
      else
        string = params
      end
      send_cmd(@linux_client, "setp "+string, "PASS")
    end
    
    def video_decoding(params)
      exec_func(params.merge({"function" => "viddec1"}))
    end
    
    def video_encoding(params)
      exec_func(params.merge({"function" => "videnc1"}))
    end
    
    def audio_encoding(params)
      exec_func(params.merge({"function" => "audenc"}))
    end
    
    def audio_decoding(params)
      exec_func(params.merge({"function" => "auddec"}))
    end
    
    def speech_decoding(params)
      exec_func(params.merge({"function" => "sphdec"}))
    end
    
    def speech_encoding(params)
      exec_func(params.merge({"function" => "sphenc"}))
    end
    
    def video_encoding_decoding(params={})
      exec_func(params.merge({"function" => "videncdec"})) 
    end
    
	def speech_encoding_decoding(params={})
	  exec_func(params.merge({"function" => "sphencdec"}))
    end

    def audio_capture(params)
      exec_func(params.merge({"function" => "audio"}))
    end
    
    def audio_play(params)
      exec_func(params.merge({"function" => "audio"}))
    end
    
    def audio_loopback(params={})
      exec_func(params.merge({"function" => "audioloop"}))
    end
    
    def video_loopback(params={})
      exec_func(params.merge({"function" => "videoloop"}))
    end
    
    def disconnect
	  send_cmd(@linux_client, "exit", '#')
      @linux_client.close if @linux_client
      ensure
        @linux_client = nil
    end
    
    
    #Starts the logger for the session. Takes the log file path as parameter.
    def start_logger(file_path)
      if @dvtbc_log
        stop_logger
      end
      Logger.new('dvtbc_log')
      @dvtbc_log_outputter = Log4r::FileOutputter.new("switch_log_out",{:filename => file_path.to_s , :truncate => false})
      @dvtbc_log = Logger['dvtbc_log']
      @dvtbc_log.level = Log4r::DEBUG
      @dvtbc_log.add  @dvtbc_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @dvtbc_log_outputter.formatter = @pattern_formatter     
    end
    
    #Stops the logger.
    def stop_logger
        @dvtbc_log_outputter = nil if @dvtbc_log_outputter
        @dvtbc_log = nil if @dvtbc_log
    end
    
    def wait_for_threads
    end
     
    private
      def log_info(info)
        @dvtbc_log.info(info) if @dvtbc_log
      end
      
      def log_error(error)
        @dvtbc_log.error(error) if @dvtbc_log
      end
		
	  def log_warning(warning)
		@dvtbc_log.warn(warning)
	  end
      
      def send_cmd(ioStream, command, match=".*", timeout=20)
        log_info("Host: "+command.to_s)
		response = ''
        ioStream.cmd("String" => command, "Match" => /#{match}/,"Timeout" => timeout) do |recv_data|
			response+=recv_data
        end
		log_info("Target: "+response)
        rescue Exception => e
          log_error("On command "+command.to_s+"\nTarget: "+response+'\n'+e.to_s)
          raise
      end 
      
      def exec_func(params)
        command = "func "+params["function"]
		if params["Source"]
		    FileUtils.mkdir_p(@smb_info+@media_data_path) unless File.exist?(@smb_info+@media_data_path)
			media_source = @media_data_path+params["function"]+'_source_'+Time.now.to_f.round.to_s+'.dat'
			FileUtils.cp(params["Source"],@smb_info+media_source)
			command += " -s "+media_source
		end
		if params["Target"]
		    FileUtils.mkdir_p(@smb_info+@media_data_path) unless File.exist?(@smb_info+@media_data_path)
			media_target = @media_data_path+params["function"]+'_target_'+Time.now.to_f.round.to_s+'.dat'
			command += " -t "+media_target
        end			
        send_cmd(@linux_client, command,'completed',60)
		ensure
			if params["Target"] && File.exist?(@smb_info+media_target)
				FileUtils.cp(@smb_info+media_target, params["Target"])
				FileUtils.rm(@smb_info+media_target)
			end
			if params["Source"] && File.exist?(@smb_info+media_source)
				FileUtils.rm(@smb_info+media_source)
			end
      end  
  end
end




