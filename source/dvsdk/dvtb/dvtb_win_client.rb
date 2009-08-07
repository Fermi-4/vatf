require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module DvtbHandlers
include Log4r

  class DvtbWindowsClient
    Logger = Log4r::Logger  
    def initialize(platform_info, log_path = nil)
      start_logger(log_path) if log_path
      log_info("Starting target session") if @dvtbc_log
      host=platform_info.telnet_ip
      port=platform_info.telnet_port
      @win_client = IO.popen("dvtb -h #{host} -p #{port}", "w+")
      #win_client.binmode
      #@win_client.puts("C:\n")
     # @win_client.flush()
      #@win_client.puts("dvtb -h #{host} -p #{port}") 
      #@win_client.puts("dvtb -h 10.218.111.105 -p 5000\n")
    # puts @win_client.readline("DVTB>") 
     # @win_client.flush()
      #send_cmd(@win_client, "dvtb -h #{host} -p #{port}\n", "DVTB") 
      rescue Exception => e
        log_info(e.to_s)
        raise "Could not start Win Client" 
    end
    
    def get_param(params)
      if params.kind_of?(Hash)
        string = params["Class"]+" "+params["Param"]   
      else
        string = params
      end
      send_cmd(@win_client, "getp "+string, "PASS")
    end
    
    def set_param(params)
      if params.kind_of?(Hash)
        string = params["Class"]+" "+params["Param"]+" "+params["Value"]   
      else
        string = params
      end
      send_cmd(@win_client, "setp "+string+"\n", "PASS")
    end
    
    def video_decoding(params)
      if params["Target"]
        send_cmd(@win_client, "func viddec -s "+params["Source"]+" -t "+params["Target"]+"\n", "PNDG")
      else
        send_cmd(@win_client, "func viddec -s "+params["Source"]+"\n", "PNDG")
      end
    end
    
    def video_encoding(params)
      if params["Source"]
        send_cmd(@win_client, "func #{params["encoder"]} -t "+params["Target"]+" -s "+params["Source"]+"\n", "PNDG")
      else
        send_cmd(@win_client, "func #{encoder} -t "+params["Target"]+"\n", "PNDG")
      end
    end
    
    def audio_encoding(params)
      if params["Target"]
        send_cmd(@win_client, "func audenc -s "+params["Source"]+" -t "+params["Target"]+"\n", "PNDG")
      else
        send_cmd(@win_client, "func audenc -s "+params["Source"]+"\n", "PNDG")
      end
    end
    
    def audio_decoding(params)
      if params["Target"]
        send_cmd(@win_client, "func auddec -s "+params["Source"]+" -t "+params["Target"]+"\n", "PNDG")
      else
        send_cmd(@win_client, "func auddec -s "+params["Source"]+"\n", "PNDG")
      end
    end
    
    def speech_decoding(params)
      if params["Target"]
        send_cmd(@win_client, "func sphdec -s "+params["Source"]+" -t "+params["Target"]+"\n","PNDG")
      else
        send_cmd(@win_client, "func sphdec -s "+params["Source"]+"\n", "PNDG")
      end
    end
    
    def speech_encoding(params)
      if params["Source"]
        send_cmd(@win_client, "func sphenc -t "+params["Target"]+" -s "+params["Source"]+"\n","PNDG")
      else
        send_cmd(@win_client, "func sphenc -t "+params["Target"]+"\n","PNDG")
      end
    end
    
    def video_encoding_decoding(params)
      send_cmd(@win_client, "func videncdec -s "+params["Source"]+" -t "+params["Target"]+"\n","PNDG")
    end
    
    def audio_capture(params)
      send_cmd(@win_client, "func audio -t "+params["Target"]+"\n","PNDG")
    end
    
    def audio_play(params)
      send_cmd(@win_client, "func audio -s "+params["Source"]+"\n", "PNDG")
    end
    
    def audio_loopback(params)
      send_cmd(@win_client, "func audioloop"+"\n", "PNDG")
    end
    
    def disconnect
      @win_client.close if @win_client
      ensure
        @win_client = nil
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
     
    private
      def log_info(info)
        @dvtbc_log.info(info) if @dvtbc_log
      end
      
      def log_error(error)
        @dvtbc_log.error(error) if @dvtbc_log
      end
      
      def send_cmd(ioStream, command, match=".*", timeout=10)
        log_info("Host: "+command.to_s)
        #ioStream.write(command)
        ioStream.puts(command)
        raise "Expect Timeout" if host_expect(ioStream, match, timeout) > 0 
        rescue Exception => e
          log_error("On command "+command.to_s+"\n"+e.to_s+response.to_s)
          raise
      end
    
    def host_expect(host_pipe, expect_string, expect_timeout=20)
#      Timeout::timeout(expect_timeout) do
        while(true)
        sleep 1
#	host_pipe.each_byte{|b|
#	     putc(b)
#	     break if host_pipe.eof
#	 }
	#host_pipe.read(1,pipe_output)
        pipe_output = host_pipe.gets
          if /#{expect_string}/.match(pipe_output) then
            log_info("Target: "+pipe_output)
            return 0
          else
            log_info("Target: "+pipe_output)
          end
        end
 #     end
     rescue Timeout::Error
      return 1
   end 

    
    
  end
end




