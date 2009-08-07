
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require 'rexml/document'
require 'ftools'

module TestEquipment
include Log4r
include REXML
   
  class QMaster
    Logger = Log4r::Logger
    @@mapped_drive = "Z:"
    def initialize(qmaster_info, log_path =nil)
      password = "optimum"
      username = "remote"
      start_logger(log_path) if log_path
      @qmaster_log.info("Starting Q-Master Session") if @qmaster_log
	    @video_scores_path = @@mapped_drive+"\\Support Files\\video_pesq.xml"
      @exe_path = @@mapped_drive+"\\Support Files\\"
      if !/(OK|Disconnected)\s*Z:\s*\\\\#{qmaster_info.telnet_ip}\\Q-Master Video/.match(`net use`)
        @qmaster_log.info("Command: "+"NET USE #{@@mapped_drive} \"\\\\#{qmaster_info.telnet_ip}\\Q-Master Video\" #{password} /USER:#{username} /PERSISTENT:YES")
        net_drive_response = `NET USE #{@@mapped_drive} \"\\\\#{qmaster_info.telnet_ip}\\Q-Master Video\" #{password} /USER:#{username} /PERSISTENT:YES`
        @qmaster_log.info("Response: "+net_drive_response)
        raise "Unable to map drive #{@@mapped_drive} of Q-Master" if !net_drive_response.include?("The command completed successfully.")
      end      
      rescue Exception => e
        if @qmaster_log
          @qmaster_log.error(e.to_s+"\n"+net_drive_response)
        else
          puts e.to_s+"\n"+net_drive_response
        end
        raise
    end
    
    #Starts the logger for the session. Takes the log file path as parameter (string).
    def start_logger(file_path)
      if @qmaster_log
        stop_logger
      end
      Logger.new('qmaster_log')
      @qmaster_log_outputter = Log4r::FileOutputter.new("qmaster_log_out",{:filename => file_path.to_s , :truncate => false})
      @qmaster_log = Logger['qmaster_log']
      @qmaster_log.level = Log4r::DEBUG
      @qmaster_log.add  @qmaster_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @qmaster_log_outputter.formatter = @pattern_formatter     
    end
      
    #Stops the logger.
    def stop_logger
      @qmaster_log_outputter = nil if @qmaster_log_outputter
      @qmaster_log = nil if @qmaster_log
    end
    
    def calibrate(is_pal)
        if is_pal != true
        	is_pal = false
      	end
      	
        #Defining the test files that can be used
        ref_files = [
            "football_704x480_420p_150frames_30fps.avi",
            "sheilds_720x480_420p_252frames_30fps.avi",
            ]
        
        ref_files.each do |ref_file|
            codesrc_ref_file,uncomp_ref_file,ref_base,src_type = create_codesrc_file(ref_file)
        	raise "Unable to calibrate Q-Master for file "+ref_file if test_video({:ref_file => codesrc_ref_file, :test_file => "cal_clip.avi", :video_io_mode => 7, :ref_file_type => 1, :uncompress_ref => uncomp_ref_file, :video_out_pal => is_pal, :video_calibration => true}) != 0
        	resolution = /\w*_(\d+x\d+)_\w*/i.match(ref_base.downcase).captures[0] if /\w*_(\d+x\d+)_\w*/i.match(ref_base.downcase)
        	if File.exist?(@@mapped_drive+"\\Support Files\\CalReport.txt") && resolution
      			File.copy(@@mapped_drive+"\\Support Files\\CalReport.txt",@@mapped_drive+"\\Support Files\\"+resolution+"_CalReport.txt") 
            else
                raise "Unable to calibrate Q-Master with file "+ref_file
            end
        end
    end
    
    #Encodes a file using Q-Master's H264 encoder. Takes input_file (string) path of the avi file to be encoded, output_file (string) path of the encoded .mpeg4 file, and encoder_setting (hash) that contains the h264 encoder settings.
    def h264_encode_file(input_file, output_file, encoder_settings = {})
      h264_guid_hash = {"enc_preset" => "EMC_PRESET",    
     				    "video_format" => "EH264VE_VideoFormat",
    				    "enc_profile" => "EMC_PROFILE",
    				    "enc_level" => "EMC_LEVEL",
    				    "enc_avg_bitrate" => "EMC_BITRATE_AVG",
    				    "enc_bitrate_mode" => "EMC_BITRATE_MODE",
					    "enc_max_bitrate" => "EMC_BITRATE_MAX",
					    "enc_stream_type" => "EH264VE_stream_type"
                       }
                      
      enc_settings = {"enc_preset" => 0,  # values: 0 VideoType_BASELINE, 1 VideoType_CIF, 2 VideoType_MAIN, 3 VideoType_SVCD, 4 VideoType_D1, 5 VideoType_HIGH, 6 VideoType_DVD, 7 VideoType_HD_DVD, 8 VideoType_BD, 9 VideoType_BD_HDMV, 10 VideoType_PSP, 11 VideoType_HDV_HD1, 12 VideoType_HDV_HD2, 13 VideoType_iPOD
       				  "video_format" => 0, # values: 0 VideoFormat_Auto, 1 VideoFormat_PAL, 2 VideoFormat_NTSC, 3 VideoFormat_SECAM, 4 VideoFormat_MAC, 5 VideoFormat_Unspecified 
       				  "enc_profile" => 0, # values: 0 Profile_Baseline, 1 Profile_Main, 3 Profile_High
       				  "enc_level" => 100, # values: 10 Level_1, 11 Level_1.1, 12 Level_1.2, 13 Level_1.3, 20 Level_2, 21 Level_2.1, 22 Level_2.2, 30 Level_3, 31 Level_3.1, 32 Level_3.2, 40 Level_4, 41 Level_4.1, 42 Level_4.2, 50 Level_5, 51 Level_5.1, 100 Level_Auto      
					  "enc_avg_bitrate" => 6000000, # values: [1024,288000000]
					  "enc_bitrate_mode" => 2, # values: 0 BitRateMode_CBR Constant bitrate, 1 BitRateMode_CQT Constant quantization parameter, 2 BitRateMode_VBR Variable bitrate.
					  "enc_max_bitrate" => 	1149952, #values: [enc_avg_bitrate, 288000000]
					  "enc_stream_type" => 2 #values: 0 StreamTypeI Stream type I according to AVC/H.264 specification, 1 StreamTypeIplusSEI - Stream type I plus SEI messages, 2 StreamTypeII - Stream type II			
					  }.merge(encoder_settings)
					  
	  enc_input_file = File.new(@@mapped_drive+"\\Support Files\\H264_Enc_Input.txt","w")
	  @qmaster_log.info("Encoder Settings")
	  enc_settings.each do |key,val|
		  @qmaster_log.info("#{key} #{val}") 
		  enc_input_file.puts "#{h264_guid_hash[key]} #{val}"
	  end  
	  enc_input_file.close
      encode_decode_file("h264",true,input_file, output_file)
    end
    
    #Encodes a file using Q-Master's MPEG4 encoder. Takes input_file (string) path of the avi file to be encoded, output_file (string) path of the encoded .mpeg4 file, and encoder_setting (hash) that contains the mpeg4 encoder settings.
    def mpeg4_encode_file(input_file, output_file, encoder_setting = {})
      mpeg4_guid_hash = {"enc_quality" => "EM4VE_Quality",    
    				     "enc_avg_bitrate" => "EMC_BITRATE_AVG",
    				     "enc_bitrate_mode" => "EMC_BITRATE_MODE",
    				     "enc_profile" => "EMC_PROFILE",
					     "enc_level" => "EMC_LEVEL",					    
                        }
                      
      enc_settings = {"enc_quality" => 13,  # values: [0,15] , 0 low, 15 high
       				  "enc_avg_bitrate" => 6000000, # values: Level restricted, 
       				  "enc_bitrate_mode" => 2, # values: 0 CBR, 1 VBR, 2 Const Quality, 3 Const quantizer 
       				  "enc_profile" => 0, # values: 0 - Simple; 1 - Advanced simple 
       				  "enc_level" => 3, # values: [0 - 3] 
  					  }.merge(encoder_settings)
					  
	  enc_input_file = File.new(@@mapped_drive+"\\Support Files\\MPEG4_Enc_Input.txt","wt")
	  @qmaster_log.info("Encoder Settings")
	  enc_settings.each do |key,val|
		  @qmaster_log.info("#{key} #{val}") 
		  enc_input_file.puts "#{mpeg4_guid_hash[key]} #{val}"
	  end  
	  enc_input_file.close
      encode_decode_file("mpeg4",true,input_file, output_file)
    end 
    
    #Decodes a file using Q-Master's H264 decoder. Takes input_file (string) path of the h264 file to be decoded, output_file (string) path of the decoded .yuv file, and decoder_setting (hash) that contains the h264 decoder settings.
    def h264_decode_file(input_file, output_file, decoder_settings ={})
      h264_guid_hash = {"dec_skip_mode" => "EH264VD_SkipMode",    
     				    "dec_error_resilience" => "EH264VD_ErrorResilience",
    				    "dec_deblocking" => "EH264VD_Deblock",
    				    "dec_deinterlace" => "EH264VD_Deinterlace",
    				    "dec_upsampling" => "EH264VD_HQUpsample",
    				    "dec_double_rate" => "EH264VD_DoubleRate",
					    "dec_fields_reordering" => "EH264VD_FieldsReordering",
					    "dec_reorder_condition" => "EH264VD_FieldsReorderingCondition",
					    "dec_synch" =>"EH264VD_SYNCHRONIZING"
                       }
                      
      dec_settings = {"dec_skip_mode" => 1,  # values: [0,4], 0 Respect quality messages from upstream filter, 1 Decode all frames do not skip, 2 Skip all non-reference frames, 3 Skip B frames even if they are used as reference, 4 Skip P and B frames even if they are used as reference.
       				  "dec_error_resilience" => 2, # values: [0, 2], 0 If bit stream error is detected skip all slices until first intra slice, 1 If bit stream error is detected skip all slices until first IDR slice, 2 Ignore bit stream errors 
       				  "dec_deblocking" => 0, # values: [0, 2], 0 Respect in-loop filter control parameters specified by the bit stream, 1 Run in-loop filter only for reference pictures, 3 Skip in-loop filter for all pictures
       				  "dec_deinterlace" => 0, # values: [0, 4], 0 Do not deinterlace output interleaved fields, 1 Deinterlace by vertical smooth filter, 2 Deinterlace by interpolation one field from another, 3 Deinterlace by means of VMR (Video Mixing Renderer). It is possible only if the filter is connected to VMR or OveralyMixer, 4 Automatic deinterlace if type of picture is field or MBAFF. If decoder works in DXVA mode then the VMR deinterlace will be applied. If decoder works in software mode then the field interpolation deinterlace will be applied      
					  "dec_upsampling" => 0, # values: [0, 1], 0 Sets the fast mode, 1 Sets the polyphase filter use. 
					  "dec_double_rate" => 0, # values: [0, 1], 0 Feature is disabled, 1 Feature is enabled
					  "dec_fields_reordering" => 0, #values: [0, 2],  0 Feature is disabled, 1 Fields are reordered by inverting the specific media sample flags, 2 Fields are reordered by exchanging the fields in picture 
					  "dec_reorder_condition" => 2, #values: [0, 2], 0 Always, 1 If TopFirst flag is TRUE, 2 If TopFirst flag is FALSE			
					  "dec_synch" => 0, # values: [0, 2], 0 Synchronizing_PTS, 1 Synchronizing_IgnorePTS_NotRef, 2 Synchronizing_IgnorePTS_All 
					  }.merge(decoder_settings)
					  
	  dec_input_file = File.new(@@mapped_drive+"\\Support Files\\H264_Dec_Input.txt","w")
	  @qmaster_log.info("Decoder Settings")
	  dec_settings.each do |key,val|
		  @qmaster_log.info("#{key} #{val}") 
		  dec_input_file.puts "#{h264_guid_hash[key]} #{val}"
	  end  
	  dec_input_file.close
      encode_decode_file("h264",false,input_file, output_file)
    end
    
    #Decodes a file using Q-Master's MPEG4 decoder. Takes input_file (string) path of the mpeg4 file to be decoded, output_file (string) path of the decoded .yuv file, and decoder_setting (hash) that contains the mpeg4 decoder settings.
    def mpeg4_decode_file(input_file, output_file, decoder_settings = {})
      mpeg4_guid_hash = {"dec_skip_mode" => "EM4VD_SkipOutOfTimeFrames",    
     				    "dec_post_processing" => "EM4VD_PostProcessing",
    				    "dec_brightness" => "EM4VD_Brightness",
    				    "dec_contrast" => "EM4VD_Contrast",
    				    "dec_gop_mode" => "EM4VD_GopDecMode",
                       }
                      
      dec_settings = {"dec_skip_mode" => 0,  # values: [0,1], 0 All the frames should be decoded, 1 skip out of time B-frames
       				  "dec_post_processing" => 0, # values: [0, 1], 0 dont't use post processing, 1 Deblocking filter must be applied to decoded pictures
       				  "dec_brightness" => 750, # values: [0, 10000], brightness
       				  "dec_contrast" => 10000, # values: [0, 20000], contrast
					  "dec_gop_mode" => 0, # values: [0, 2], 0 Decode all types of vops, 1 decode I and P-Vops, 2 decode only I-VOPs 
					  }.merge(decoder_settings)
					  
	  dec_input_file = File.new(@@mapped_drive+"\\Support Files\\MPEG4_Dec_Input.txt","w")
	  @qmaster_log.info("Decoder Settings")
	  dec_settings.each do |key,val|
		  @qmaster_log.info("#{key} #{val}") 
		  dec_input_file.puts "#{mpeg4_guid_hash[key]} #{val}"
	  end  
	  dec_input_file.close
      encode_decode_file("mpeg4",false,input_file, output_file)
    end
    
    def get_codesrc_h264_encoded_file(avi_ref_file,h264_codesrc_file,encoder_settings ={})
      codesrc_ref_file = get_codesrc_file_path(avi_ref_file)
      raise "codesrc file does not exist for "+avi_ref_file if !codesrc_ref_file
      h264_encode_file(codesrc_ref_file,h264_codesrc_file, encoder_settings)
    end 
    
    def get_codesrc_mpeg4_encoded_file(avi_ref_file,mpeg4_codesrc_file,encoder_settings ={})
      codesrc_ref_file = get_codesrc_file_path(avi_ref_file)
      raise "codesrc file does not exist for "+avi_ref_file if !codesrc_ref_file
      mpeg4_encode_file(codesrc_ref_file,mpeg4_codesrc_file, encoder_settings)  
    end
    
    #Runs a test comparing ref_clip (string) which is played through composite-out, to test_clip (string) captured through composite-in, using the video pal (if is_pal = true) or ntsc (if is_pal=false)
    def composite_out_to_composite_in_test(ref_clip,test_clip, is_pal)
      codesrc_ref_file,uncomp_ref_file,ref_base,src_type =  create_codesrc_file(ref_clip)
      
      if is_pal != true
        is_pal = false
      end
      
      res = test_video({:ref_file => codesrc_ref_file, :test_file => test_clip, :video_io_mode => 7, :ref_file_type => 1, :uncompress_ref => uncomp_ref_file, :video_out_pal => is_pal})
       #WORKAROUND
       res = file_to_file_test("workaround_ref_"+ref_base+".avi", "#{@@mapped_drive}\\Video\\User Defined Files\\Test Files\\"+test_clip,false) if res == 0 
       res
      #END WORKAROUND
    end
    
    #Runs a test comparing the ref_file (string), with test_clip (string) which is received through composite-in. The ref_file can be pre-defined (is_pre_defined = true) or user-defeined (is_pre_defined = false), and the clip can be received in two standards pal (is_pal = true) or NTSC (is_pal = false)
    def file_to_composite_in_test(ref_file,test_clip, is_pre_defined, is_pal, is_composite = true)
	  if is_pre_defined != true
       ref_file_type = 1
      else
       ref_file_type = 0
      end
            
      codesrc_ref_file,uncomp_ref_file,ref_base,src_type =  create_codesrc_file(ref_file)
      
      if is_pal != true
        is_pal = false
      end
      
      if is_composite == true
          video_mode = 1
      elsif is_composite == false
          video_mode = 2
      end
       res = test_video({:ref_file => codesrc_ref_file, :test_file => test_clip, :video_io_mode => video_mode, :ref_file_type => 1, :uncompress_ref => uncomp_ref_file, :video_out_pal => is_pal})
        #WORKAROUND
       res = file_to_file_test("workaround_ref_"+ref_base+".avi", "#{@@mapped_drive}\\Video\\User Defined Files\\Test Files\\"+test_clip,false) if res == 0 
       res
      #END WORKAROUND
   #   result = test_video({:ref_file => ref_file, :test_file => test_clip, :video_io_mode => video_mode, :ref_file_type => ref_file_type})
    end
    
    #Runs a test comparing two stored files ref_file (string) and (test_file). The test cam be performed with (use_markers =true) or without markers (use_markers = false)
    def file_to_file_test(ref_file,test_file, use_markers = false)
      result = -1
      ref_file_name = File.basename(ref_file)
      test_file_name = File.basename(test_file)
      if use_markers == false
          files_dir = "#{@@mapped_drive}\\Video\\File Mode\\"
          if !File.exist?(files_dir+'Reference Files\\'+ref_file_name)
            File.copy(ref_file,files_dir+'Reference Files\\')
          end
          File.copy(test_file,files_dir+'Test Files\\')
          result = test_video({:ref_file => ref_file_name, :test_file => test_file_name, :video_io_mode => 0, :ref_file_type => 2})
      else
          io_mode = 1002
          files_dir = "#{@@mapped_drive}\\Video\\User Defined Files\\"
          codesrc_ref_file,uncomp_ref_file,ref_base,src_type =  create_codesrc_file(ref_file)
          File.copy(test_file,files_dir+'Test Files\\qresult.avi')
          result = test_video({:ref_file =>  codesrc_ref_file, :test_file => test_file_name, :video_io_mode => 1002, :ref_file_type => 2, :uncompress_ref => uncomp_ref_file})
      end              
      ensure
        File.delete(files_dir+'Test Files\\'+test_file_name) if File.exist?(files_dir+'Test Files\\'+test_file_name)
        result
    end
    
    #Play the clip in src_clip (string) through composite-out in pal (is_pal = true) or NTSC format (is_pal = false)
    def play_composite_out(src_clip, is_pal)
      result = -1
      codesrc_ref_file,uncomp_ref_file,ref_base,src_type =  create_codesrc_file(src_clip)
      if is_pal != true
       is_pal = false
      end           
      result = test_video({:ref_file => codesrc_ref_file, :test_file => "playout.avi", :video_io_mode => 1001, :ref_file_type => 1,:uncompress_ref => uncomp_ref_file, :video_out_pal => is_pal})
      ensure
        result
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
      params = {:transmitter_ip => "",:transmitter_mask => "",:multicast_addr => "", :ref_file_type => 1, :video_calibration => false, :transmitter_gateway => "", :receiver_ip => "", :receiver_mask => "", :receiver_gateway => "", :stream_protocol => 1, :video_out_pal => false, :uncompress_ref => "",:timeout => 0}.merge!(params)
      params.each do |key,val|
        if params[key] == true || params[key] == false
          if params[key]
            params[key] = to_arg(1)
          else
            params[key] = to_arg(0)
          end
        else
          params[key] = to_arg(val)
        end 
      end
      resolution = /\w*_(\d+x\d+)_\w*/i.match(params[:ref_file].downcase).captures[0] if /\w*_(\d+x\d+)_\w*/i.match(params[:ref_file].downcase)
      File.copy(@@mapped_drive+"\\Support Files\\"+resolution+"_CalReport.txt",@@mapped_drive+"\\Support Files\\CalReport.txt") if File.exist?(@@mapped_drive+"\\Support Files\\"+resolution+"_CalReport.txt") && resolution
      File.delete(@video_scores_path) if File.exist?(@video_scores_path)
      qmaster_command = params[:ref_file]+params[:test_file]+params[:transmitter_ip]+params[:transmitter_mask]+params[:transmitter_gateway]+ 
                        params[:receiver_ip]+params[:receiver_mask]+params[:receiver_gateway]+params[:stream_protocol]+params[:video_io_mode]+
                        params[:multicast_addr]+params[:ref_file_type]+params[:video_calibration]+params[:video_out_pal]+params[:uncompress_ref]+
						            params[:timeout]

      test_process = qmaster_exec(qmaster_command)
      
      expect_result = qm_expect(test_process, "OK",200)
      result = case expect_result
                when 0
                  expect_result
                when 1
                  cal_result = test_video(params.merge({:video_calibration => true}))
                  if cal_result != 0
                   3
                  else
                   1
                  end
                when 2
                  abort_test
                  expect_result
                else
                  @qmaster_log.error("Received unexpected answer from qmaster")
                  raise "Received unexpected answer from qmaster"
      end  
      test_process.puts("exit") if test_process
      result
    end
    
    #Returns the MOS score of the last completed test	
	  def get_mos_score
		  get_scores('MOS')[0]
    end
	  
    #Returns the mean jerkiness score of the last completed test	
	  def get_jerkiness_score
		  get_scores('Jerkiness')[0]
	  end
	  
    #Returns the mean level score of the last completed test	
	  def get_level_score
		  get_scores('Level')[0]
	  end
	  
    #Returns the mean blockiness score or the blockiness score of a particular frame (if a frame number is specified) of the last completed test 	
	  def get_blocking_score(frame = nil)
		  if frame
			  get_scores('FrameBlocking')[frame]
		  else
			  get_scores('BlockDistortion')[0]
		  end
    end
	  
    #Returns the mean blurring score or the blurring score of a particular frame (if a frame number is specified)	of the last completed test
	  def get_blurring_score(frame = nil)
		  if frame
			  get_scores('FrameBlurring')[frame]
		  else
			  get_scores('Blurring')[0]
		  end
	  end
	  
    #Returns the total frames lost or the frames until frame (if a frame number is specified)	of the last completed test
	  def get_frame_lost_count(frame = nil)
		  if frame
			  get_scores('FrameLostCount')[frame]
		  else
			  get_scores('LostFrames')[0]
		  end
	  end
	  
    #Returns the mean psnr score or the psnr score of a particular frame (if a frame number is specified)	of the last completed test
	  def get_psnr_score(frame = nil)
		  if frame
			  get_scores('FramePSNR')[frame]
		  else
			  get_scores('PSNR')[0]
		  end
	  end
	  
    #Returns an array containing the blockiness score of each frame
	  def get_blocking_scores
		  get_scores('FrameBlocking')
    end
	  
    #Returns an array containing the blurring score of each frame
	  def get_blurring_scores
		  get_scores('FrameBlurring')
	  end
	  
    #Returns an array containing the frames lost until each of the frame received was captured 
	  def get_frames_lost_count
		  get_scores('FrameLostCount')
	  end
	  
    #Returns an array containing the psnr score of each frame
	  def get_psnr_scores
		  get_scores('FramePSNR')
	  end
    
    #Aborts a test that has already started
    def abort_test
      abort_process = qmaster_exec("")
    end
        
    private
    #Generic function to retrieve the video quality scores. Takes metric (string the desired video quality metric as paramter.
    #Returns an array containing the desired metric
	  def get_scores(metric)
		  video_scores = Array.new
		  file = File.new(@video_scores_path)
		  video_scores_file = REXML::Document.new file
      video_scores_file.root.elements[metric].each do |scores|
			if scores.respond_to?(:each) 
				scores.each{|value|	video_scores << value.to_s.strip.to_f}
			elsif scores.to_s.strip.length > 0
				video_scores << scores.to_s.strip.to_f
			end
		end
      file.close
		  video_scores
    end
    
    #Returns a string containing a double quoted representation of val
	  def to_arg(val)
		  %Q! "#{val.to_s}"!
	  end
    
    #Function used to wait for a given string from a test/process. Takes qm_pipe handle to the test/process, expect_string (string) the acknowledgement that will be waited for, and expect_timeout (number) the amount of time to wait in seconds  as parameters.
    def qm_expect(qm_pipe, expect_string, expect_timeout)
      Timeout::timeout(expect_timeout) do
        while(true)
          r,w,e = select([qm_pipe],nil,nil,1)
    	  if r != nil
    	      pipe_output = qm_pipe.readline
              case pipe_output.to_s
                when /#{expect_string}/i
                  @qmaster_log.info("Response: "+pipe_output.to_s)
                  return 0
                when /QMaster\s*is\s*uncalibrated/i
                  @qmaster_log.info("Response: "+pipe_output.to_s)
                  return 1
                when /VQUAD\s*failed\s*error/i
                  @qmaster_log.info("Response: "+pipe_output.to_s)
                  return 2
                else
                  @qmaster_log.info("Response: "+pipe_output.to_s)
              end
          end
        end
      end
     rescue Timeout::Error
      return 2
   end 
   
   #Generic encode/decode function. Takes encoder_type (string) indicating the type of codec to use, encode (bool) true if encode false otherwise, input_file (string) the file that will be encoded, and output_file (string) the path were the encoded file will be stored  as parameters..
   def encode_decode_file(encoder_type, encode, input_file, output_file)
     files_dir = "#{@@mapped_drive}\\Video\\File Mode\\"
     File.delete(@exe_path+"cmdout.txt") if File.exist?(@exe_path+"cmdout.txt")
     codec_command = case encoder_type
                      when /h264/i
                        "H264"
                      when /mpeg4/i
                        "MPG4"
                      else
                        raise ArgumentError, "Unsupported codec specified"
                      end
                      
     if encode != true
      codec_command +="Decoder.exe"
      input_dir = files_dir+"Encoded Files"
      File.copy(input_file,input_dir)
      output_dir = files_dir+"Decoded Files"
     else
      codec_command += "Encoder.exe"
      input_dir = files_dir+"Decoded Files"
      File.copy(input_file,input_dir)
      output_dir = files_dir+"Encoded Files"
     end
     in_file = File.basename(input_file)
     out_file = File.basename(output_file)
     codec_process = qmaster_exec("-i #{in_file} -o #{out_file}",codec_command)    
      Timeout::timeout(400, "Timedout waiting to process file") do
        while !File.exist?(@exe_path+"cmdout.txt")
          sleep 4
        end
      end
     cmd_lines = IO.readlines(@exe_path+"cmdout.txt")
     cmd_lines.each{|line| @qmaster_log.info("Response: "+line)}
     raise "Unable to code/decode file" if !cmd_lines.include?("Done!\n") 
     File.copy(output_dir+"\\"+out_file, output_file) if File.exist?(output_dir+"\\"+out_file)
     rescue Exception => e
      @qmaster_log.error(e.to_s)
      raise e
     ensure
      File.delete(output_dir+"\\"+out_file) if out_file && File.exist?(output_dir+"\\"+out_file)
      File.delete(input_dir+"\\"+in_file) if in_file && File.exist?(input_dir+"\\"+in_file)
      codec_process.puts  "exit" if codec_process
   end
   
   #Generic execution commmand. Takes exe_args (string) the arguments that will be usd to execute a command, and command (string)  the command that will be runned (default is Qmcommandline.exe) as parameters.
   def qmaster_exec(exe_args, command = nil)
      qm_command = "QMCommandLine.exe"
      if command
        exe_args = " -r \"#{command} #{exe_args}\""
      end
      @qmaster_log.info("Command: \"#{@exe_path+qm_command}\" #{exe_args}") 
      qmaster_process = IO.popen("cmd","r+")
      qmaster_process.puts("\"#{@exe_path+qm_command}\" #{exe_args}")     
      qmaster_process  
   end
   
   def create_codesrc_file(ref_clip)
      files_dir = "#{@@mapped_drive}\\Video\\User Defined Files\\"
      ref_base, src_type = /[\\\/]*(\w+)(_codesrc){0,1}\.avi *$/i.match(ref_clip).captures
      codesrc_ref_file = ref_base.strip+"_codesrc.avi"
      uncomp_ref_file = ref_base.strip+"_uncompref.avi"
      if !File.exist?(files_dir+'Source Files\\'+codesrc_ref_file) || !File.exist?(files_dir+'Uncompressed Reference Files\\'+uncomp_ref_file)
        if !File.exist?(files_dir+'Source Files\\'+ref_base+'.avi')
          File.copy(ref_clip,files_dir+'Source Files\\')
        end
        marker_process = qmaster_exec(ref_base+'.avi')
        marker_res = qm_expect(marker_process, "OK",400)
        marker_process.puts "exit" if marker_process
        raise "Unable to create files with markers"  if marker_res != 0       
      end
      
      [codesrc_ref_file, uncomp_ref_file, ref_base, src_type]
   end
   
   def get_codesrc_file_path(ref_clip)
      files_dir = "#{@@mapped_drive}\\Video\\User Defined Files\\"
      codesrc_ref_file = (File.basename(ref_clip)).gsub('.avi','_codesrc.avi')
      uncomp_ref_file = (File.basename(ref_clip)).gsub('.avi','_uncompref.avi') 
      if !File.exist?(files_dir+'Source Files\\'+codesrc_ref_file) || !File.exist?(files_dir+'Uncompressed Reference Files\\'+uncomp_ref_file)
         nil
      else
         files_dir+'Source Files\\'+codesrc_ref_file 
      end    
   end
   
  end
end

