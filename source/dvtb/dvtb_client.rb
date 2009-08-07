require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module DvtbHandlers
include Log4r

  class DvtbClient
    Logger = Log4r::Logger 
    attr_accessor :host, :port, :waittime
    attr_reader   :HeaderId, :DvtbRetCode
	
	@@max_sockets = 4
    @host           # Target IP address
    @port           # TCP port on which the target server is listening 
    @waittime       # Waiting time for server response
    @target         # Internal handler to Target Telnet session
    @media_files_semaphore #Mutex used to synchronize access to the media_files_array 
  
    @@DVTB_STR = "string"
    @@DVTB_INT = "int"
    DvtbClass = Struct.new("DvtbClass", :name, :parameters)
    DvtbParam = Struct.new("DvtbParam", :type, :description, :values, :default)
    # Engine Class Paramaters
    @@dvtbEngineClassParams = { "name"    =>  DvtbParam.new(@@DVTB_STR, "Engine name", "encode, decode, encdec", "encdec"),
                                "trace"   =>  DvtbParam.new(@@DVTB_INT, "Enable(1) | Disable(0) traces", "0 or 1", "0") }
    @@dvtbEngineClass = DvtbClass.new("engine", @@dvtbEngineClassParams)
    # Audio Class Paramaters                            
    @@dvtbAudioClassParams = {  "mode"       =>  DvtbParam.new(@@DVTB_INT, "Audio Mode", "DVTB_CAPTURE|DVTB_PLAY", "DVTB_PLAY = 0"),
                                "samplerate" =>  DvtbParam.new(@@DVTB_INT, "Audio Sample Rate", "?", "44100"),
                                "devselect"  =>  DvtbParam.new(@@DVTB_INT, "Audio Device Selector", "?", "PSP_AUDIO_SPK_OUT"),
                                "gain"       =>  DvtbParam.new(@@DVTB_INT, "Audio Gain", "?", "100"),
                                "seconds"    =>  DvtbParam.new(@@DVTB_INT, "Audio play/record time in seconds", "?", "5"),
                                "framesize"  =>  DvtbParam.new(@@DVTB_INT, "?", "?", "DEF_AUDIO_BUFLEN * sizeof(MdUns)") }
    @@dvtbAudioClass = DvtbClass.new("audio", @@dvtbAudioClassParams)
    # Video Procesing Front-End Class Paramaters 
    @@dvtbVpfeClassParams = {   "tvp5146format" =>  DvtbParam.new(@@DVTB_INT, "Input Video format of TVP5146", "?", "PSP_VPFE_TVP5146_FORMAT_COMPOSITE"),
                                "tvp5146mode"   =>  DvtbParam.new(@@DVTB_INT, "Input Video mode of TVP5146", "NTSC|PAL|AUTO", "PSP_VPFE_TVP5146_MODE_AUTO"),
                                "ffmode"  =>  DvtbParam.new(@@DVTB_INT, "Input Video Field mode", "?", "PSP_VPSS_FIELD_MODE"),
                                "width"   =>  DvtbParam.new(@@DVTB_INT, "Input Video's number of pixels per line", "...", "NTSC_WIDTH = 720"),
                                "height"  =>  DvtbParam.new(@@DVTB_INT, "Input Video's number of lines", "...", "NTSC_HEIGHT = 480"),
                                "xoffset" =>  DvtbParam.new(@@DVTB_INT, "Input video horizontal start pixel", "0-width", "0"),
                                "yoffset" =>  DvtbParam.new(@@DVTB_INT, "Input video vertical start pixel", "0-height", "0") }
    @@dvtbVpfeClass = DvtbClass.new("vpfe", @@dvtbVpfeClassParams)
    # Video Procesing Back-End Class Paramaters   
    @@dvtbVpbeClassParams = {   "vencmode" =>  DvtbParam.new(@@DVTB_INT, "Output Video display standard", "?", "PSP_VPBE_DISPLAY_NTSC_INTERLACED_COMPOSITE"),
                                "hscale"   =>  DvtbParam.new(@@DVTB_INT, "Output Video horizontal scaling", "?", "PSP_VPBE_ZOOM_IDENTITY"),
                                "vscale"   =>  DvtbParam.new(@@DVTB_INT, "Output Video vertical scaling", "?", "PSP_VPBE_ZOOM_IDENTITY"),
                                "ffmode"  =>  DvtbParam.new(@@DVTB_INT, "Output Video Frame mode", "?", "PSP_VPSS_FRAME_MODE"),
                                "width"   =>  DvtbParam.new(@@DVTB_INT, "Output Video's number of pixels per line", "...", "NTSC_WIDTH = 720"),
                                "height"  =>  DvtbParam.new(@@DVTB_INT, "Output Video's number of lines", "...", "NTSC_HEIGHT = 480"),
                                "xoffset" =>  DvtbParam.new(@@DVTB_INT, "Output video left margin", "0-width", "0"),
                                "yoffset" =>  DvtbParam.new(@@DVTB_INT, "Output video otp margin", "0-height", "0") }
    @@dvtbVpbeClass = DvtbClass.new("vpbe", @@dvtbVpbeClassParams)
    
    # Video Decoder Class Paramaters   
    @@dvtbVidDecClassParams = { "codec"        =>  DvtbParam.new(@@DVTB_STR, "Video Decoder Name", "mpeg2dec | mpeg4dec | h264dec", "mpeg2dec"),
                                "maxHeight"    =>  DvtbParam.new(@@DVTB_INT, "Maximum Video Height in lines", "...", "480"),
                                "maxWidth"     =>  DvtbParam.new(@@DVTB_INT, "Maximum Video Width in pixels", "...", "720"),
                                "maxFrameRate" =>  DvtbParam.new(@@DVTB_INT, "Maximum Video Frame rate in fps*1000", "...", "30000"),
                                "maxBitRate"   =>  DvtbParam.new(@@DVTB_INT, "Maximum Video Bit rate in bits per second", "...", "400000"),
                                "dataEndianness"    =>  DvtbParam.new(@@DVTB_INT, "Endianess of input data", "1: BigEndian | 2: 16LittleEndian | 3: 32LittleEndian", "1"),
                                "forceChromaFormat" =>  DvtbParam.new(@@DVTB_INT, "Force Decode in given Chroma Format", "1: YUV 4:2:0 planar | 4: YUV 4:2:2 interleaved", "4"),
                                "decodeHeader"  =>  DvtbParam.new(@@DVTB_INT, "Number of access units to decode (dynamic parameter)", "0: Decode access unit | 1: Decode only header", "0"),
                                "displayWidth"  =>  DvtbParam.new(@@DVTB_INT, "Pitch (dynamic parameter)", "...", "720"),
                                "frameSkipMode" =>  DvtbParam.new(@@DVTB_INT, "Frame Skip Mode (dynamic parameter)", "0:Don't Skip current frame", "0") }
    @@dvtbVidDecClass = DvtbClass.new("viddec", @@dvtbVidDecClassParams)
    
    # Video Encoder Class Paramaters   
    @@dvtbVidEncClassParams = { "codec"        =>  DvtbParam.new(@@DVTB_STR, "Video Encoder Name", "mpeg4enc | h264enc", "mpeg4enc"),
                                "maxHeight"    =>  DvtbParam.new(@@DVTB_INT, "Maximum Height in lines", "480|576|...", "480"),
                                "maxWidth"     =>  DvtbParam.new(@@DVTB_INT, "Maximum Width in pixels", "...", "720"),
                                "maxFrameRate" =>  DvtbParam.new(@@DVTB_INT, "Maximum Frame rate in fps*1000", "30000|25000|...", "30000"),
                                "maxBitRate"   =>  DvtbParam.new(@@DVTB_INT, "Maximum Bit rate in bits per second", "...", "400000"),
                                "dataEndianness"    =>  DvtbParam.new(@@DVTB_INT, "Endianess of output data", "1: BigEndian | 2: 16LittleEndian | 3: 32LittleEndian", "1"),
                                "inputChromaFormat" =>  DvtbParam.new(@@DVTB_INT, "Input Chroma Format", "1: YUV 4:2:0 planar | 4: YUV 4:2:2 interleaved", "4"),
                                "encodingPreset"    =>  DvtbParam.new(@@DVTB_INT, "Encoding Preset", "0", "0"),
                                "rateControlPreset" =>  DvtbParam.new(@@DVTB_INT, "Rate Control Presets", "1:Stringent CBR (Low Delay) | 2:Constrained VBR (Storage) | 3: Two Pass rate control | 4: Unconstrainbed VBR (None)", "1"),
                                "maxInterFrameInterval" =>  DvtbParam.new(@@DVTB_INT, "Maximum I to P frame distance", "0|...", "0"),
                                "inputContentType"      =>  DvtbParam.new(@@DVTB_INT, "Type of input video content", "0:Progressive | 1:Interlaced", "0"),
                                "inputHeight"        =>  DvtbParam.new(@@DVTB_INT, "Input frame height (dynamic parameter)", "...", "480"),
                                "inputWidth"         =>  DvtbParam.new(@@DVTB_INT, "Input frame width (dynamic parameter)", "...", "720"),
                                "refFrameRate"       =>  DvtbParam.new(@@DVTB_INT, "Reference/Input Frame Rate in fps*1000 (dynamic parameter)", "...", "30000"),
                                "targetFrameRate"    =>  DvtbParam.new(@@DVTB_INT, "Target Frame Rate in fps*1000 (dynamic parameter)", "...", "30000"),
                                "targetBitRate"      =>  DvtbParam.new(@@DVTB_INT, "Target Bit Rate (dynamic parameter)", "...", "4000000"),
                                "intraFrameInterval" =>  DvtbParam.new(@@DVTB_INT, "Intra frame interval (dynamic parameter)", "30|15|...", "30"),
                                "generateHeader"     =>  DvtbParam.new(@@DVTB_INT, "Mode of Encode (dynamic parameter)", "0: Encode access unit | 1: Generate only header", "0"),
                                "captureWidth"  =>  DvtbParam.new(@@DVTB_INT, "Pitch (dynamic parameter)", "...", "720"),
                                "forceIFrame"   =>  DvtbParam.new(@@DVTB_INT, "Force the encoded frames to be I frames (dynamic parameter)", "0|?", "0"),
                                "numframes"     =>  DvtbParam.new(@@DVTB_INT, "Number of frames to capture/encode (DVTB parameter)", "30|300|1800|...", "30") }
    @@dvtbVidEncClass = DvtbClass.new("videnc", @@dvtbVidEncClassParams)
    
    # Audio Decoder Class Paramaters   
    @@dvtbAudDecClassParams = { "codec"          =>  DvtbParam.new(@@DVTB_STR, "Audio Decoder Name", "aacdec|?", "aacdec"),
                                "maxSampleRate"  =>  DvtbParam.new(@@DVTB_INT, "Audio Maximum Sampling Rate", "...", "96000"),
                                "maxBitRate"     =>  DvtbParam.new(@@DVTB_INT, "Maximum Audio Bit rate", "...", "AUDDEC_MAX_SR*AUDDEC_MAX_CH*4"),
                                "maxNoOfCh"      =>  DvtbParam.new(@@DVTB_INT, "Maximum number of channels", "?", "?"),
                                "dataEndianness" =>  DvtbParam.new(@@DVTB_INT, "Endianess of audio data", "1: BigEndian | 2: 16LittleEndian | 3: 32LittleEndian", "2"),
                                "outputFormat"   =>  DvtbParam.new(@@DVTB_INT, "Audio Outout format", "?", "IAUDIO_INTERLEAVED") }
    @@dvtbAudDecClass = DvtbClass.new("auddec", @@dvtbAudDecClassParams)
    
    # Speech Decoder Class Paramaters   
    @@dvtbSphDecClassParams = { "codec"         =>  DvtbParam.new(@@DVTB_STR, "Speech Decoder Name", "g711dec|?", "g711dec"),
                                "dataEnable"    =>  DvtbParam.new(@@DVTB_INT, "Enable Speech decoder", "OFF=0, ON=1", "0"),
                                "compandingLaw" =>  DvtbParam.new(@@DVTB_INT, "Speech Companding law", "?", "ISPEECH_ALAW"),
                                "packingType"   =>  DvtbParam.new(@@DVTB_INT, "Speech Packing Type", "?", "1"),
                                "numframes"     =>  DvtbParam.new(@@DVTB_INT, "Number of Speech frames", "...", "1000") }
    @@dvtbSphDecClass = DvtbClass.new("sphdec", @@dvtbSphDecClassParams)
    
    # Speech Encoder Class Paramaters   
    @@dvtbSphEncClassParams = { "codec"         =>  DvtbParam.new(@@DVTB_STR, "Speech Encoder Name", "g711enc|?", "g711enc"),
                                "frameSize"     =>  DvtbParam.new(@@DVTB_INT, "Speech encoder frame size", "...", "80"),
                                "compandingLaw" =>  DvtbParam.new(@@DVTB_INT, "Speech Companding law", "?", "ISPEECH_ALAW"),
                                "packingType"   =>  DvtbParam.new(@@DVTB_INT, "Speech Packing Type", "?", "1"),
                                "vadSelection"  =>  DvtbParam.new(@@DVTB_INT, "Speech Activity Detection", "0|1", "0"),
                                "numframes"     =>  DvtbParam.new(@@DVTB_INT, "Number of Speech frames", "...", "1000") }
    @@dvtbSphEncClass = DvtbClass.new("sphdec", @@dvtbSphEncClassParams)
    
    # TODO: Add information about remaining Classes
    @@dvtbClasses = [@@dvtbEngineClass, @@dvtbAudioClass, @@dvtbVpfeClass, @@dvtbVpbeClass, @@dvtbVidDecClass, @@dvtbVidEncClass, @@dvtbAudDecClass, @@dvtbSphDecClass, @@dvtbSphEncClass]

    
    @@headerId = {
      :DVTB_INVALID          => 0x0,  
      :DVTB_COMMAND          => 0xC0,
      :DVTB_RESPONSE         => 0xA0,
      :DVTB_ASYNC_RESPONSE   => 0xA1,
      :DVTB_SOC_CLOSE        => 0xA2,
      :DVTB_RECON            => 0xA3,
      :DVTB_DATA             => 0xD0,
      :DVTB_ERROR            => 0xE0,
      :DVTB_LOG              => 0xE1,
      :DVTB_DEBUG            => 0xE2,
      :DVTB_FOPEN            => 0xF0,
      :DVTB_FREAD            => 0xF1,
      :DVTB_FWRITE           => 0xF2,
      :DVTB_FSEEK            => 0xF3,
      :DVTB_FTELL            => 0xF4,
      :DVTB_FCLOSE           => 0xF5,
      :DVTB_FEOF             => 0xF6
    }

    @@dvtbRetCode = {
      :DVTB_FAIL     => -1,
      :DVTB_SUCCESS  => 0
    }
    
    def initialize(platform_info, log_path = nil)
	  @num_sockets = @@max_sockets
      start_logger(log_path) if log_path
      log_info("Starting target session") if @dvtbc_log
      @host=platform_info.telnet_ip
      @port=platform_info.telnet_port
      @waittime=0
      @target = Net::Telnet::new( "Host" => @host,
                                  "Port" => @port,
                                  "Waittime" => @waittime,
                                  "Prompt" => /.*/,
                                  "Telnetmode" => false,
                                  "Binmode" => true)
      @threads_array = Array.new
      @media_files = Array.new
      @media_files[0] = nil 
      @media_files_semaphore = Mutex.new
	  @num_sockets_semaphore = Mutex.new
      rescue Exception => e
        log_info(e.to_s)
        
    end

	def set_max_number_of_sockets(num_sockets)
		@num_sockets = num_sockets
		@@max_sockets = num_sockets
	end
    
    def print_params_help()
      @@dvtbClasses.each {|klass|
        puts "\n"
        puts "===================Class Name: #{klass.name}====================="
        klass.parameters.each_pair {|key,value| 
          puts "--Param Name: #{key}"
          puts "    Type:    #{value.type}"
          puts "    Desc:    #{value.description}"
          puts "    Values:  #{value.values}"
          puts "    Default: #{value.default}"
        }
      }
    end
    
    
    def send_cmd(command, match=".*", timeout=10)
      if command.to_s.include?("func")
	      @num_sockets_semaphore.synchronize{@num_sockets -= 1}
	      while @num_sockets < 0
		      sleep 4
	      end
	  end
      dvtbc_send(@target,:DVTB_COMMAND, command)
      response = nil
      @target.waitfor("Match"=>/#{match}/) do |recv_data|
        response = recv_data 
      end
      log_info("Target: "+response) if response
      if response.include?([@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
		Timeout::timeout(10, "Timeout waiting for async response confirmation") do
		  log_info("Target: "+@target.readline("PNDG\x00"))
		end
		target_index = @target.read(4)
		log_info("Target: "+target_index)
		target_index = target_index.unpack('V')[0]
		dut_socket = Net::Telnet::new( "Host" => @host, "Port" => @port, "Waittime" => @waittime, "Prompt" => /.*/, "Telnetmode" => false, "Binmode" => true)
		dvtbc_send(dut_socket,nil,target_index)
		@threads_array << Thread.new{dvtb_file_ops(dut_socket)}
      end 
      
      rescue Exception => e
        log_error("On command "+command.to_s+"\n"+e.to_s+response.to_s)
        raise
    end
    
      
    def get_param(params)
      if params.kind_of?(Hash)
        string = params["Class"]+" "+params["Param"]   
      else
        string = params
      end
      send_cmd("getp "+string+"\n", "PASS")
    end
    
    def set_param(params)
      if params.kind_of?(Hash)
        string = params["Class"]+" "+params["Param"]+" "+params["Value"]   
      else
        string = params
      end
      send_cmd("setp "+string+"\n", "PASS")
    end
    
    def video_decoding(params)
      if params["Target"]
        send_cmd("func viddec -s "+params["Source"]+" -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      else
        send_cmd("func viddec -s "+params["Source"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      end
    end
    
    def video_encoding(params)
      if params["Source"]
        send_cmd("func videnc -t "+params["Target"]+" -s "+params["Source"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      else
        send_cmd("func videnc -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      end
    end
    
    def audio_encoding(params)
	  encoder_params = {"Encoder" => "audenc"}.merge(params)
      if encoder_params["Source"]
        send_cmd("func #{encoder_params["Encoder"]} -s "+encoder_params["Source"]+" -t "+encoder_params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      else
        send_cmd("func #{encoder_params["Encoder"]} -t "+encoder_params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      end
    end
    
    def audio_decoding(params)
      if params["Target"]
        send_cmd("func auddec -s "+params["Source"]+" -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      else
        send_cmd("func auddec -s "+params["Source"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      end
    end
    
    def speech_decoding(params)
      if params["Target"]
        send_cmd("func sphdec -s "+params["Source"]+" -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      else
        send_cmd("func sphdec -s "+params["Source"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      end
    end
    
    def speech_encoding(params)
      if params["Source"]
        send_cmd("func sphenc -t "+params["Target"]+" -s "+params["Source"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      else
        send_cmd("func sphenc -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
      end
    end
    
    def video_encoding_decoding(params = nil)
	  if params
		send_cmd("func videncdec -s "+params["Source"]+" -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
	  else
		send_cmd("func videncdec\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
	  end
    end
    
	def speech_encoding_decoding(params = nil)
	  if params
		send_cmd("func sphencdec -s "+params["Source"]+" -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
	  else
		send_cmd("func sphencdec\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
	  end
    end
	
    def audio_capture(params)
      send_cmd("func audio -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
    end
    
    def audio_play(params)
      send_cmd("func audio -s "+params["Source"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
    end
    
    def audio_loopback(params)
      send_cmd("func audioloop"+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
    end
    
    def video_loopback(params)
      send_cmd("func vidloop"+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
    end
	
	def video_capture(params)
	  send_cmd("func vpfe -t "+params["Target"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
	end
	
	def video_play(params)
	  send_cmd("func vpbe -s "+params["Source"]+"\n", [@@headerId[:DVTB_ASYNC_RESPONSE]].pack("C"))
	end
    
    def disconnect
      dvtbc_send(@target,:DVTB_RECON)
      @target.close if @target
      ensure
        @target = nil
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
		@threads_array.each{|dut_thread| dut_thread.join if dut_thread.alive?}
    end
    
    private
      def log_info(info)
        @dvtbc_log.info(info) if @dvtbc_log
      end
      
      def log_error(error)
        @dvtbc_log.error(error) if @dvtbc_log
      end
      
      def log_info(debug_info)
        @dvtbc_log.info(debug_info) if @dvtbc_log
      end
      
      def dvtb_file_ops(dut_socket)
        return_code = @@dvtbRetCode[:DVTB_FAIL]
        begin
            dvtb_hdr = dut_socket.read(1)
            log_info ("Target: "+dvtb_hdr.to_s)
            return_code = case dvtb_hdr.unpack('C')[0]  
                          when @@headerId[:DVTB_RESPONSE]
                            data = dvtbc_read_data(dut_socket)
                            data += dvtbc_read_data(dut_socket)
                            log_info("Target: "+data)
 #                           return @@dvtbRetCode[:DVTB_SUCCESS]
                          when @@headerId[:DVTB_ERROR]
                            dvtbc_error(dut_socket)
                          when @@headerId[:DVTB_LOG]
                            dvtbc_log(dut_socket)
                          when @@headerId[:DVTB_DEBUG]
                            dvtbc_debug(dut_socket)
                          when @@headerId[:DVTB_FOPEN]
                            dvtbc_fopen(dut_socket)
                          when @@headerId[:DVTB_FREAD]
                            dvtbc_fread(dut_socket)
                          when @@headerId[:DVTB_FWRITE]
                            dvtbc_fwrite(dut_socket)
                          when @@headerId[:DVTB_FSEEK]
                            dvtbc_fseek(dut_socket)
                          when @@headerId[:DVTB_FTELL]
                            dvtbc_ftell(dut_socket)
                          when @@headerId[:DVTB_FCLOSE]
                            dvtbc_fclose(dut_socket)
                          when @@headerId[:DVTB_FEOF]
                            dvtbc_feof(dut_socket)
                          when @@headerId[:DVTB_SOC_CLOSE]
                            return dvtbc_free_socket_thread(dut_socket) 
                          else
                            log_error("Invalid Command "+dvtb_hdr.to_s+" for file operations")
                            raise "Invalid Command "+dvtb_hdr.to_s+" for file operations"
                          end
        end until return_code == @@dvtbRetCode[:DVTB_FAIL] || @target.closed? || dut_socket.closed?
        ensure
          dut_socket.close if !dut_socket.closed?
          return_code   
    end

    
    def dvtbc_error(dut_socket)
      error = dvtbc_read_data(dut_socket)
      error += dvtbc_read_data(dut_socket)
      log_error(error.to_s)
      @@dvtbRetCode[:DVTB_FAIL]
      
      rescue Exception => e
        log_error(e.to_s)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_log(dut_socket)
      log = dvtbc_read_data(dut_socket)
      log_error(log.to_s)
      @@dvtbRetCode[:DVTB_SUCCESS]
      
      rescue Exception => e
        log_error(e.to_s)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_debug(dut_socket)
      dbg = dvtbc_read_data(dut_socket)
      @dvtbc_log.debug(dbg.to_s)
      @@dvtbRetCode[:DVTB_SUCCESS]
      
      rescue Exception => e
        log_error(e.to_s)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_fopen(dut_socket)
      filepath_length = dut_socket.read(4).unpack('V')[0]
      log_info "Target: "+filepath_length.to_s
      file_name = dut_socket.read(filepath_length).gsub("\x00","")
      log_info "Target: "+file_name
      filemode_length = dut_socket.read(4).unpack('V')[0]
      log_info "Target: "+filemode_length.to_s
      file_mode = dut_socket.read(filemode_length).gsub("\x00","")
      log_info "Target: "+file_mode
      @media_files_semaphore.synchronize {
        @media_files << File.new(file_name,file_mode)
        dvtbc_send(dut_socket,:DVTB_RESPONSE,@media_files.length-1)
      } 
      @@dvtbRetCode[:DVTB_SUCCESS]
      rescue Exception => e
        log_error(e.to_s)
        dvtbc_send(dut_socket,:DVTB_ERROR)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_fwrite(dut_socket)
      fd = dut_socket.read(4).unpack('V')[0] 
      size = dut_socket.read(4).unpack('V')[0]
      data = dut_socket.read(size)
      log_info("TARGET: Write #{size} bytes to file Index:#{fd}")
      num_bytes = @media_files[fd].write(data) 
      if num_bytes <= 0 
        dvtbc_send(dut_socket,:DVTB_ERROR,fd) 
      else
        dvtbc_send(dut_socket,:DVTB_DATA,fd)
        dvtbc_send(dut_socket,nil,num_bytes) 
      end
      
      @@dvtbRetCode[:DVTB_SUCCESS]
      rescue Exception => e
        log_error(e.to_s)
        dvtbc_send(dut_socket,:DVTB_ERROR)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_fread(dut_socket)
	    fd = dut_socket.read(4).unpack('V')[0] 
      size = dut_socket.read(4).unpack('V')[0]
      log_info("TARGET: Read #{size} bytes from file Index:#{fd}")
      data = @media_files[fd].read(size)
      if !data || data.length <= 0 
        dvtbc_send(dut_socket,:DVTB_ERROR,fd) 
      else
        dvtbc_send(dut_socket,:DVTB_DATA,fd)
        dvtbc_send_data(dut_socket,data) 
      end
      
      @@dvtbRetCode[:DVTB_SUCCESS]
      rescue Exception => e
        log_error(e.to_s)
        dvtbc_send(dut_socket,:DVTB_ERROR)
        @@dvtbRetCode[:DVTB_FAIL]
        
    end
    
    def dvtbc_send_data(dut_socket,msg = nil)
      if msg        
        dut_socket.write([msg.size].pack("V")+msg)
      end
    end
    
    def dvtbc_read_data(dut_socket)
      size = dut_socket.read(4).unpack('V')[0]
      raise "Packet size should be greater than 0" if size <= 0
      dut_socket.read(size)
    end
    
    def dvtbc_ftell
      @@dvtbRetCode[:DVTB_SUCCESS] 
    end
    
    def dvtbc_fclose(dut_socket)
      fd = dut_socket.read(4).unpack('V')[0]
      log_info "Host: closing file at index #{fd}"
      @media_files[fd].close if @media_files[fd]
      dvtbc_send(dut_socket,:DVTB_RESPONSE,fd)
      @media_files[fd] = nil
      @@dvtbRetCode[:DVTB_SUCCESS]
      rescue Exception => e
        log_error(e.to_s)
        dvtbc_send(dut_socket,:DVTB_ERROR)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_feof(dut_socket)
      fd = dut_socket.read(4).unpack('V')[0]
      file_eof = 0
      file_eof = 4 if @media_files[fd].eof
      dvtbc_send(dut_socket,:DVTB_RESPONSE,fd)
      dvtbc_send(dut_socket,nil,file_eof) 
      @@dvtbRetCode[:DVTB_SUCCESS]
      rescue Exception => e
        log_error(e.to_s)
        dvtbc_send(dut_socket,:DVTB_ERROR)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_fseek(dut_socket)
      fd = dut_socket.read(4).unpack('V')[0]
      offset = dut_socket.read(4).unpack('l')[0]
      whence = dut_socket.read(4).unpack('V')[0]
      log_info("Host: fseek from position #{whence} and offset #{offset} in file with index #{fd}")      
      @media_files[fd].seek(offset,whence)       
      dvtbc_send(dut_socket,:DVTB_RESPONSE,fd) 
      @@dvtbRetCode[:DVTB_SUCCESS]
      
      rescue Exception => e
        log_error(e.to_s)
        dvtbc_send(dut_socket,:DVTB_ERROR)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_free_socket_thread(dut_socket)
      dut_socket.close if dut_socket
	  @num_sockets_semaphore.synchronize{@num_sockets += 1}
      @@dvtbRetCode[:DVTB_SUCCESS]
      
      rescue Exception => e
        log_error(e.to_s)
        dvtbc_send(dut_socket,:DVTB_ERROR)
        @@dvtbRetCode[:DVTB_FAIL]
    end
    
    def dvtbc_send(dut_socket,type = nil , msg = nil)
      log_info("Host: "+@@headerId[type].to_s)
      dut_socket.putc(@@headerId[type]) if type
      if msg 
        if !msg.is_a?(String)
          msg = [msg].pack("V")
          dut_socket.write(msg)
        else
          dut_socket.write([msg.size+1].pack("V")+msg+"\x00")
        end             
        log_info("Host: "+[msg.size+1].pack("V").to_s+msg.to_s+"\x00") 
      end
    end
    
  end
end
