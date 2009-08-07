require 'rubyclr'

reference_file 'C:\Program Files\Automation Studio\DvtbClient.dll'

module DvtbHandlers  
  include DvtbHandler 
  include System::Collections
  include System 
  class DvtbDllClient
    
    def initialize(platform_info, log_path = nil)
        equipInfo = Hashtable.new
        equipInfo.Add("telnet_ip",platform_info.telnet_ip) 
        equipInfo.Add("telnet_port",platform_info.telnet_port)      
        @my_dvtb_client = DvtbHandler::DvtbClient.new(equipInfo,log_path)
    end
    
    def start_logger(log_path)
        @my_dvtb_client.StartLogger(log_path)
    end

	def set_max_number_of_sockets(video_num_sockets,audio_num_sockets)
		@num_sockets_set = true
		@my_dvtb_client.SetMaxNumberOfSockets(video_num_sockets,audio_num_sockets)
	end
      
    def get_param(params)
      @my_dvtb_client.GetParam(get_dotnet_hash(params))
    end
    
    def set_param(params)
      @my_dvtb_client.SetParam(get_dotnet_hash(params))
    end
    
    def video_decoding(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.video_decoding(get_dotnet_hash(params))
    end
    
    def video_encoding(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.VideoEncoding(get_dotnet_hash(params))
    end
    
    def audio_encoding(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
	  encoder_params = {"function" => "audenc"}.merge(params)
      @my_dvtb_client.AudioEncoding(get_dotnet_hash(encoder_params))
    end
    
    def audio_decoding(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.AudioDecoding(get_dotnet_hash(params))
    end
    
    def speech_decoding(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.SpeechDecoding(get_dotnet_hash(params))
    end
    
    def speech_encoding(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.SpeechEncoding(get_dotnet_hash(params))
    end
	
	def image_decoding(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.ImageDecoding(get_dotnet_hash(params))
    end

	def image_encoding(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.ImageEncoding(get_dotnet_hash(params))
    end
		   
    def video_encoding_decoding(params = nil)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
	  @my_dvtb_client.VideoEncodingDecoding(get_dotnet_hash(params))
    end
    
	def speech_encoding_decoding(params = nil)
	  raise "Maximum number of sockets have not been set" if !@num_sockets_set
	  @my_dvtb_client.SpeechEncodingDecoding(get_dotnet_hash(params))
    end
	
	def audio_encoding_decoding(params = nil)
	  raise "Maximum number of sockets have not been set" if !@num_sockets_set
	  @my_dvtb_client.AudioEncodingDecoding(get_dotnet_hash(params))
    end
	
	def image_encoding_decoding(params = nil)
	  raise "Maximum number of sockets have not been set" if !@num_sockets_set
	  @my_dvtb_client.ImageEncodingDecoding(get_dotnet_hash(params))
    end
		
    def audio_capture(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.AudioCapture(get_dotnet_hash(params))
    end
    
    def audio_play(params)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.AudioPlay(get_dotnet_hash(params))
    end
    
    def audio_loopback(params = nil)
      raise "Maximum number of sockets have not been set" if !@num_sockets_set
      @my_dvtb_client.AudioLoopback(get_dotnet_hash(params))
    end
    
    def video_loopback(params = nil)
        raise "Maximum number of sockets have not been set" if !@num_sockets_set
    	@my_dvtb_client.VideoLoopback(get_dotnet_hash(params))
    end
	
	def video_capture(params)
	  raise "Maximum number of sockets have not been set" if !@num_sockets_set
	  @my_dvtb_client.VideoCapture(get_dotnet_hash(params))
	end
	
	def video_play(params)
	  raise "Maximum number of sockets have not been set" if !@num_sockets_set
	  @my_dvtb_client.VideoPlay(get_dotnet_hash(params))
	end
    
    def disconnect
      @my_dvtb_client.Disconnect if @my_dvtb_client
      ensure
          @my_dvtb_client = nil
    end
    
    #Stops the logger.
    def stop_logger
        @my_dvtb_client.StopLogger
    end
    
    def wait_for_threads
		@my_dvtb_client.WaitForThreads
    end
    
    private
    
    def get_dotnet_hash(ruby_hash = nil)
        result = Hashtable.new
		result["mandatory"] = true if !ruby_hash || !ruby_hash["mandatory"]
        ruby_hash.each{|key,val| result.Add(key,val)} if ruby_hash
        result
    end
    
  end
end

