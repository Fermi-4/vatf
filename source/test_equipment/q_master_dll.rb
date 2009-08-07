require 'rubyclr'

reference_file 'C:\Program Files\Automation Studio\TeHandlers.dll'
 
module TestEquipment
  include TeHandlers
  include System::Collections
  include System 
  
  class QMasterDriver
    
    def initialize(qmaster_info, log_path = nil)
        equipInfo = Hashtable.new
        equipInfo.Add("telnet_ip",qmaster_info.telnet_ip) 
        equipInfo.Add("telnet_port",qmaster_info.telnet_port)      
        @my_qm_dll_driver = TeHandlers::QmasterDllDriver.new(equipInfo,log_path)
    end
    
    #Starts the logger for the session. Takes the log file path as parameter (string).
    def start_logger(log_path)
        @my_qm_dll_driver.StartLogger(log_path)
    end
      
    #Stops the logger.
    def stop_logger
        @my_qm_dll_driver.StopLogger
    end
    
    def calibrate(resolution, is_pal)
	    #Add new calibration files here, with respective resolution key
		cal_files = {
			"704x480" => "football_704x480_420p_150frames_30fps.avi",
			"720x480" => "sheilds_720x480_420p_252frames_30fps.avi"
		}
		
        cal_info = Hash.new
		cal_info["resolution"] = resolution
        if is_pal != true
        	cal_info["is_pal"] = false
        else
            cal_info["is_pal"] = true
      	end
		cal_info["ref_file"] = cal_files[resolution]
        
        @my_qm_dll_driver.Calibrate(get_dotnet_hash(cal_info))
    end
    
    #Encodes a file using Q-Master's H264 encoder. Takes input_file (string) path of the avi file to be encoded, output_file (string) path of the encoded .mpeg4 file, and encoder_setting (hash) that contains the h264 encoder settings.
    def h264_encode_file(input_file, output_file, encoder_settings = {})
     @my_qm_dll_driver.H264EncodeFile(input_file, output_file, get_dotnet_hash(encoder_settings))
    end
    
    #Encodes a file using Q-Master's MPEG4 encoder. Takes input_file (string) path of the avi file to be encoded, output_file (string) path of the encoded .mpeg4 file, and encoder_setting (hash) that contains the mpeg4 encoder settings.
    def mpeg4_encode_file(input_file, output_file, encoder_setting = {})
      @my_qm_dll_driver.Mpeg4EncodeFile(input_file, output_file, get_dotnet_hash(encoder_settings))
    end 
    
    #Decodes a file using Q-Master's H264 decoder. Takes input_file (string) path of the h264 file to be decoded, output_file (string) path of the decoded .yuv file, and decoder_setting (hash) that contains the h264 decoder settings.
    def h264_decode_file(input_file, output_file, decoder_settings ={})
      @my_qm_dll_driver.H264DecodeFile(input_file, output_file, get_dotnet_hash(decoder_settings))
    end
    
    #Decodes a file using Q-Master's MPEG4 decoder. Takes input_file (string) path of the mpeg4 file to be decoded, output_file (string) path of the decoded .yuv file, and decoder_setting (hash) that contains the mpeg4 decoder settings.
    def mpeg4_decode_file(input_file, output_file, decoder_settings = {})
       @my_qm_dll_driver.Mpeg4DecodeFile(input_file, output_file, get_dotnet_hash(decoder_settings))
    end
    
    def get_codesrc_h264_encoded_file(avi_ref_file,h264_codesrc_file,encoder_settings ={})
      @my_qm_dll_driver.GetCodesrcH264EncodedFile(avi_ref_file,h264_codesrc_file,get_dotnet_hash(encoder_settings))
    end 
    
    def get_codesrc_mpeg4_encoded_file(avi_ref_file,mpeg4_codesrc_file,encoder_settings ={})
      @my_qm_dll_driver.GetCodesrcMpeg4EncodedFile(avi_ref_file,h264_codesrc_file,get_dotnet_hash(encoder_settings))  
    end
    
    #Runs a test comparing ref_clip (string) which is played through composite-out, to test_clip (string) captured through composite-in, using the video pal (if is_pal = true) or ntsc (if is_pal=false)
    def composite_out_to_composite_in_test(ref_clip,test_clip, is_pal)
      @my_qm_dll_driver.CompositeOutToCompositeInTest(ref_clip,test_clip, is_pal)
    end
    
    #Runs a test comparing the ref_file (string), with test_clip (string) which is received through composite-in. The ref_file can be pre-defined (is_pre_defined = true) or user-defeined (is_pre_defined = false), and the clip can be received in two standards pal (is_pal = true) or NTSC (is_pal = false)
    def file_to_composite_in_test(ref_file,test_clip, is_pre_defined, is_pal, is_composite = true)
	  @my_qm_dll_driver.FileToCompositeInTest(ref_file,test_clip, is_pre_defined, is_pal, is_composite)
    end
    
    #Runs a test comparing two stored files ref_file (string) and (test_file). The test cam be performed with (use_markers =true) or without markers (use_markers = false)
    def file_to_file_test(ref_file,test_file, use_markers = false)
      @my_qm_dll_driver.FileToFileTest(ref_file,test_file, use_markers)
    end
    
    #Play the clip in src_clip (string) through composite-out in pal (is_pal = true) or NTSC format (is_pal = false)
    def play_composite_out(src_clip, is_pal)
      @my_qm_dll_driver.PlayCompositeOut(src_clip, is_pal)
    end
    
    
    #Generic function used to run a test. See q-master docs Remote Control chapter for parameter explanation. Takes
    #:ref_file (string): reference file used for comparison, 
    #:test_file (string): processed file that will be tested, 
    #:transmitter_ip: (string XXX.XXX.XXX.XXX format) transmitter's ip address for streaming, 
    #:transmitter_mask: (string XXX.XXX.XXX.XXX format) transmitter's network mask for streaming, 
    #:transmitter_gateway: (string XXX.XXX.XXX.XXX format) transmitter's gateway for streaming, 
    #:receiver_ip: (string XXX.XXX.XXX.XXX format) receiver's ip address for streaming, 
    #:receiver_mask: (string XXX.XXX.XXX.XXX format) receiver's mask for streaming, 
    #:receiver_gateway: (string XXX.XXX.XXX.XXX format) receiver's gateway for streaming,
    #:stream_protocol: (number) streaming protocol TCP (0) or UDP(1),
    #:video_io_mode (number): video io mode that will be used,
    #:multicast_addr: (string XXX.XXX.XXX.XXX format) for streaming ,
    #:ref_file_type (number): type of refence file depending on the test
    #:video_calibration (number): 1 calibrate analog IO, 0 do not calibrate
    #:video_out_pal: true means analog format is pal, false means analog format is NTSC
    #:uncompref_ref: (string) uncompref fiel used for video playout
    #:timeout : not used right now
    def test_video(params)
      @my_qm_dll_driver.TestVideo(get_dotnet_hash(params))
    end
    
    #Returns the MOS score of the last completed test	
    def get_mos_score
      @my_qm_dll_driver.GetMosScore
    end
	  
    #Returns the mean jerkiness score of the last completed test	
    def get_jerkiness_score
      @my_qm_dll_driver.GetJerkinessScore
    end
	  
    #Returns the mean level score of the last completed test	
	  def get_level_score
		  @my_qm_dll_driver.GetLevelScore
	  end
	  
    #Returns the mean blockiness score or the blockiness score of a particular frame (if a frame number is specified) of the last completed test 	
	  def get_blocking_score(frame = nil)
		  if frame
			  @my_qm_dll_driver.GetBlockingScore(frame)
		  else
			  @my_qm_dll_driver.GetBlockingScore
		  end
    end
	  
    #Returns the mean blurring score or the blurring score of a particular frame (if a frame number is specified)	of the last completed test
	  def get_blurring_score(frame = nil)
		  if frame
			  @my_qm_dll_driver.GetBlurringScore(frame)
		  else
			  @my_qm_dll_driver.GetBlurringScore
		  end
	  end
	  
    #Returns the total frames lost or the frames until frame (if a frame number is specified)	of the last completed test
	  def get_frame_lost_count(frame = nil)
		  if frame
			  @my_qm_dll_driver.GetFrameLostCount(frame)
		  else
			  @my_qm_dll_driver.GetFrameLostCount
		  end
	  end
	  
    #Returns the mean psnr score or the psnr score of a particular frame (if a frame number is specified)	of the last completed test
	  def get_psnr_score(frame = nil)
		  if frame
			  @my_qm_dll_driver.GetPsnrScore(frame)
		  else
			  @my_qm_dll_driver.GetPsnrScore
		  end
	  end
	  
    #Returns an array containing the blockiness score of each frame
	def get_blocking_scores
		@my_qm_dll_driver.GetBlockingScores
    end
	  
    #Returns an array containing the blurring score of each frame
	  def get_blurring_scores
		  @my_qm_dll_driver.GetBlurringScores
	  end
	  
    #Returns an array containing the frames lost until each of the frame received was captured 
	  def get_frames_lost_count
		  @my_qm_dll_driver.GetFramesLostCount
	  end
	  
    #Returns an array containing the psnr score of each frame
	  def get_psnr_scores
		  @my_qm_dll_driver.GetPsnrScores
	  end
    
    def get_jitter_score
    	@my_qm_dll_driver.GetJitterScore
    end
    
    def wait_for_analog_test_ack(timeout)
        @my_qm_dll_driver.WaitForAnalogTestAck(timeout)
    end
    
    def wait_for_ack(timeout)
        @my_qm_dll_driver.WaitForAck(timeout)
    end
    
    #Aborts a test that has already started
    def abort_test
      @my_qm_dll_driver.QmAbort
    end
    
    def expect(expected_regex,timeout)
       @my_qm_dll_driver.QmExpect(expected_regex,timeout)
    end
    
    def get_expect_string
       @my_qm_dll_driver.GetExpectString
    end
	
	def disconnect
	   @my_qm_dll_driver.EndSession if @my_qm_dll_driver
	end
        
       private
    
    def get_dotnet_hash(ruby_hash = nil)
        result = Hashtable.new
        ruby_hash.each{|key,val| result.Add(key,val)} if ruby_hash
        result
    end
   
  end
end

