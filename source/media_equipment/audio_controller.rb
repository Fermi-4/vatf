require 'dl/import'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module MediaEquipment
  extend DL::Importable
  dlload "winmm.dll"
  typealias("lpctstr","const char*")
  typealias("lptstr","char *")
  typealias("handle", "void *")   
  typealias("dword","unsigned long")
  typealias("bool","int")
  extern "uint mciSendString(lpctstr, lptstr, uint, handle)"
  include Log4r
  Logger = Log4r::Logger
#This class is used to control the audio card in pc, it allows playback, record, and simultaneous playback/record of wav files 
  class AudioController
    @@command_result = {
		257 => "MCIERR INVALID DEVICE ID",
		259 => "MCIERR UNRECOGNIZED KEYWORD",
		261 => "MCIERR UNRECOGNIZED COMMAND",
		262 => "MCIERR HARDWARE",
		263 => "MCIERR INVALID DEVICE NAME",
		264 => "MCIERR OUT OF MEMORY",
		265 => "MCIERR DEVICE OPEN",
		266 => "MCIERR CANNOT LOAD DRIVER",
		267 => "MCIERR MISSING COMMAND STRING",
		268 => "MCIERR PARAM OVERFLOW",
		269 => "MCIERR MISSING STRING ARGUMENT",
		270 => "MCIERR BAD INTEGER",
		271 => "MCIERR PARSER INTERNAL",
		272 => "MCIERR DRIVER INTERNAL",
		273 => "MCIERR MISSING PARAMETER",
		274 => "MCIERR UNSUPPORTED FUNCTION",
		275 => "MCIERR FILE NOT FOUND",
		276 => "MCIERR DEVICE NOT READY",
		277 => "MCIERR INTERNAL",
		278 => "MCIERR DRIVER",
		279 => "MCIERR CANNOT USE ALL",
		280 => "MCIERR MULTIPLE",
		281 => "MCIERR EXTENSION NOT FOUND",
		282 => "MCIERR OUTOFRANGE",
		284 => "MCIERR FLAGS NOT COMPATIBLE",
		286 => "MCIERR FILE NOT SAVED",
		287 => "MCIERR DEVICE TYPE REQUIRED",
		288 => "MCIERR DEVICE LOCKED",
		289 => "MCIERR DUPLICATE ALIAS",
		290 => "MCIERR BAD CONSTANT",
		291 => "MCIERR MUST USE SHAREABLE",
		292 => "MCIERR MISSING DEVICE NAME",
		293 => "MCIERR BAD TIME FORMAT",
		294 => "MCIERR NO CLOSING QUOTE",
		295 => "MCIERR DUPLICATE FLAGS",
		296 => "MCIERR INVALID FILE",
		297 => "MCIERR NULL PARAMETER BLOCK",
		298 => "MCIERR UNNAMED RESOURCE",
		299 => "MCIERR NEW REQUIRES ALIAS",
		300 => "MCIERR NOTIFY ON AUTO OPEN",
		301 => "MCIERR NO ELEMENT ALLOWED",
		302 => "MCIERR NONAPPLICABLE FUNCTION",
		303 => "MCIERR ILLEGAL FOR AUTO OPEN",
		304 => "MCIERR FILENAME REQUIRED",
		305 => "MCIERR EXTRA CHARACTERS",
		306 => "MCIERR DEVICE NOT INSTALLED",
		307 => "MCIERR GET CD",
		308 => "MCIERR SET CD",
		309 => "MCIERR SET DRIVE",
		310 => "MCIERR DEVICE LENGTH",
		311 => "MCIERR DEVICE ORD LENGTH",
		312 => "MCIERR NO INTEGER",
		320 => "MCIERR WAVE OUTPUTSINUSE",
		321 => "MCIERR WAVE SETOUTPUTINUSE",
		322 => "MCIERR WAVE INPUTSINUSE",
		323 => "MCIERR WAVE SETINPUTINUSE",
		324 => "MCIERR WAVE OUTPUTUNSPECIFIED",
		325 => "MCIERR WAVE INPUTUNSPECIFIED",
		326 => "MCIERR WAVE OUTPUTSUNSUITABLE",
		327 => "MCIERR WAVE SETOUTPUTUNSUITABLE",
		328 => "MCIERR WAVE INPUTSUNSUITABLE",
		329 => "MCIERR WAVE SETINPUTUNSUITABLE",
		336 => "MCIERR SEQ DIV INCOMPATIBLE",
		337 => "MCIERR SEQ PORT INUSE",
		338 => "MCIERR SEQ PORT NONEXISTENT",
		339 => "MCIERR SEQ PORT MAPNODEVICE",
		340 => "MCIERR SEQ PORT MISCERROR",
		341 => "MCIERR SEQ TIMER",
		342 => "MCIERR SEQ PORTUNSPECIFIED",
		343 => "MCIERR SEQ NOMIDIPRESENT",
		346 => "MCIERR NO WINDOW",
		347 => "MCIERR CREATEWINDOW",
		348 => "MCIERR FILE READ",
		349 => "MCIERR FILE WRITE",
		350 => "MCIERR NO IDENTITY",
	}
    #Constructor of of the class only uses the log_path if provided to instantiate a logger, audio_info is provided
    #for compliance with the video atf.
    def initialize(audio_info,log_path = nil)
      start_logger(log_path) if log_path
      log_info("Starting Audio session")
      @rec_file = nil
      @play_alias = "wav_src"
      @rec_alias = "wav_dst"
    end
   
   #This function is used to play wav file, it is a blocking function. Takes file_name(string) path of the file to be played.
    def sync_play_wav_file(file_name)
      open_wav_device(file_name, @play_alias)
      raise "Unable to play wav file " + file_name  if send_command("play " + @play_alias + " wait", nil) != 0
      rescue Exception => e
        log_error(e.to_s)
        raise e
      ensure
        send_command("close " + @play_alias, nil)       
    end
    
    #This function is used to play wav file, it is a blocking function. Takes file_name(string) path of the file to be played.
    def stop_playing_wav_file()
      send_command("stop " + @play_alias + " wait", nil) 
      send_command("close " + @play_alias + " wait", nil)      
    end

    #This function is used to play wav file, it is a non-blocking function. Takes file_name(string) path of the file to be played.
    def async_play_wav_file(file_name)
        open_wav_device(file_name, @play_alias)      
        raise "Unable to play wav file " + file_name if send_command("play " + @play_alias + " notify",nil) != 0
        rescue Exception => e
          log_error(e.to_s)
          send_command("close " + @play_alias, nil)
          raise e
    end
=begin commented out because async operations are still not supported
    def async_play_and_record_wav_file(src_file,  file_name)
        start_recording_wav_file(file_name)
        async_play_wav_file(src_file)
    end
     
    def play_done do
      send_command("close "+@play_alias, nil)
      if @rec_file != nil
        save_result = 0
        save_result += send_command("stop " + @rec_alias, nil)
        save_result += send_command("save " + @rec_alias + " " + @rec_file, nil)
        save_result += send_command("close " + @rec_alias, nil)
        raise "Unable to save audio data into file " + @rec_file if save_result != 0
      end
    end
=end
    #This function is used to play a file (src_file) and record a file at the same time(file_name). Takes src_file (string) path of the file to be played,  file_name (string) path of the file to be recorded, 
	# and audio_params (hash) audio_params (Hash) containing the audio recording setting whose pairs  must be in the set
    #{"aligment" => (integer),"bits_per_sample" => (integer),"channels" => (integer),"samples_per_sec" => (integer),"format" => (string: "pcm))}  as parameters.      
    def sync_play_and_record_wav_file(src_file, file_name, audio_params = nil)
        start_recording_wav_file(file_name,audio_params)
        sync_play_wav_file(src_file)
        sleep 1
        stop_recording_wav_file()
    end
    
    #This function is used to record a wav file. Takes file_name (string) path of the file where the recorded audio will be stored, 
	# and audio_params (hash) audio_params (Hash) containing the audio recording setting whose pairs  must be in the set
    #{"aligment" => (integer),"bits_per_sample" => (integer),"channels" => (integer),"samples_per_sec" => (integer),"format" => (string: "pcm))}  as parameters.      
    def start_recording_wav_file(file_name,audio_params = nil)
        open_wav_device("new", @rec_alias)
		set_rec_params(audio_params)
        @rec_file = file_name              
        raise "Unable to start wav recording process for file " + file_name if send_command("record " + @rec_alias, nil) != 0
        rescue Exception =>e
            log_error(e.to_s)
            send_command("close " + @rec_alias, nil)
            raise e
    end
    
    #This function is used to record audio for a specific amount of time. Takes file_name (string) path of the file where the recorded audio will be stored,  msec_duration the amount of time to be recorded in msec, 
	# and audio_params (hash) audio_params (Hash) containing the audio recording setting whose pairs  must be in the set
    #{"aligment" => (integer),"bits_per_sample" => (integer),"channels" => (integer),"samples_per_sec" => (integer),"format" => (string: "pcm))}  as parameters.      
    def start_time_recording_wav_file(file_name,  msec_duration, audio_params = nil)
        open_wav_device("new", @rec_alias)
		set_rec_params(audio_params)
        send_command("set " + @rec_alias + " time format milliseconds",nil)
        @rec_file = file_name
        raise "Unable to start wav recording process for file " + file_name if send_command("record " + @rec_alias+ " to "+msec_duration.to_s, nil) != 0
        rescue Exception => e
            log_error(e.to_s)
            send_command("close " + @rec_alias, nil)
            raise e
    end
    
    #This functions stops the recorder and saves the audio to a file.
    def stop_recording_wav_file()
        save_result = 0
        save_result += send_command("stop " + @rec_alias, nil)
        save_result += send_command("save " + @rec_alias + " " + @rec_file, nil)
        save_result += send_command("close " + @rec_alias, nil)
        raise "Unable to save audio data into file " + @rec_file if save_result != 0
        rescue Exception => e
          log_error(e.to_s)
          raise e
    end
    
    #This function is used to set the recording parameter. Takes audio_params (Hash) containing the audio recording setting whose pairs  must be in the set
    #{"aligment" => (integer),"bits_per_sample" => (integer),"channels" => (integer),"samples_per_sec" => (integer),"format" => (string: "pcm))}
    def set_rec_params(audio_params)
	  if audio_params
	      res = send_command("set " + @rec_alias + " alignment " + audio_params["alignment"].to_s+ " wait",nil) if audio_params["alignment"] 
	      res += send_command("set " + @rec_alias + " bitspersample " + audio_params["bits_per_sample"].to_s+ " wait",nil) if audio_params["bits_per_sample"]
	      res += send_command("set " + @rec_alias + " channels " + audio_params["channels"].to_s+ " wait",nil) if audio_params["channels"]     
	      res += send_command("set " + @rec_alias + " samplespersec " + audio_params["samples_per_sec"].to_s+ " wait",nil) if audio_params["samples_per_sec"]     
	      res += send_command("set " + @rec_alias + " format tag " + audio_params["format"].to_s+ " wait",nil) if audio_params["format"]       
	      if res != 0 
	        send_command("close " + @rec_alias, nil)
	        raise "Unable to set recorder parameters"
	      end
	      log_warning("set " + @rec_alias + " bytespersec " +  audio_params["bytes_per_sec"].to_s + " wait was not successful!!!!") if audio_params["bytes_per_sec"] && send_command("set " + @rec_alias + " bytespersec " + audio_params["bytes_per_sec"].to_s + " wait", nil) != 0
      end
	  rescue Exception => e
        log_error(e.to_s)
        raise e
    end
    
    #Starts the logger for the session. Takes the log file path as parameter.
      def start_logger(file_path)
        if @audio_log
          stop_logger
        end
        Logger.new('audio_log')
        @audio_log_outputter = Log4r::FileOutputter.new("audio_log_out",{:filename => file_path.to_s , :truncate => false})
        @audio_log = Logger['audio_log']
        @audio_log.level = Log4r::DEBUG
        @audio_log.add  @audio_log_outputter
        @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
        @audio_log_outputter.formatter = @pattern_formatter     
      end
    
    #Stops the logger.
      def stop_logger
          @audio_log_outputter = nil 
          @audio_log = nil
      end
    private
    
    #This function is used to send commands to the wav player
    def send_command(command, cmd_delegate)
        log_info("Command: "+command)
		res = MediaEquipment::mciSendString(command, "", 0, cmd_delegate)
		log_info("Result: "+res.to_s)
		if @@command_result[res]
			log_error("Result description: "+@@command_result[res])
		end
        return res
    end

    #This function is used to open a wav device
    def open_wav_device(dev_name,  dev_alias)
        raise "Unable to open " + dev_name if send_command("open " + dev_name + " type waveaudio alias " + dev_alias, nil) != 0
        rescue Exception => e
          log_error(e.to_s)
          raise e
    end
           
      def log_info(info)
		    @audio_log.info(info) if @audio_log
	    end
	  
	    def log_error(error)
		    @audio_log.error(error) if @audio_log
	    end
      
      def log_warning(warn)
		    @audio_log.warn(warn) if @audio_log
	    end
      
  end
end

