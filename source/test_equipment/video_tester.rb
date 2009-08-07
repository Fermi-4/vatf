gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'


module TestEquipment
include Log4r

  class VideoTester
    Logger = Log4r::Logger
    attr_accessor :response
    
    def initialize(tester_info)
      tester_info.instance_variables.each {|var|
        	if tester_info.instance_variable_get(var).to_s.size > 0   
             self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
             self.instance_variable_set(var, tester_info.instance_variable_get(var))
         end
      }
    end
	
    #Runs a test comparing ref_clip (string) which is played through video-out, to test_clip (string) captured through video-in
    def video_out_to_video_in_test(test_params = {})
	end
    
    #Runs a test comparing the ref_file (string), with test_clip (string) which is received through video-in. 
    def file_to_video_in_test(test_params = {}) #ref_file,test_clip, is_pre_defined, is_pal, is_composite = true
    end
    
    #Runs a test comparing two stored files ref_file (string) and (test_file)
    def file_to_file_test(test_params = {})#ref_file,test_file, use_markers = false
    end
    
    #Play the clip in src_clip (string)
    def play_video_out(test_params = {}) # src_clip, is_pal
    end
    
    def get_video_signal_width(signal_params ={})
        0
    end
    
    def get_video_signal_height(signal_params ={})
        0
    end
     
    #Returns the MOS score of the last completed test	
	def get_mos_score
    end
	
	def get_jnd_score(jnd_params = {})
	end
	
    #Returns the mean jerkiness score of the last completed test	
	def get_jerkiness_score
	end
	  
    #Returns the mean level score of the last completed test	
	def get_level_score
	end
	  
    #Returns the mean blockiness score or the blockiness score of a particular frame (if a frame number is specified) of the last completed test 	
	def get_blocking_score(blk_params = {})#frame = nil
	end
	  
    #Returns the mean blurring score or the blurring score of a particular frame (if a frame number is specified)	of the last completed test
	def get_blurring_score(blur_params = {})#frame = nil
	end
	  
    #Returns the total frames lost or the frames until frame (if a frame number is specified)	of the last completed test
	def get_frame_lost_count(frm_params = {})#frame = nil
	end
	
    #Returns the mean psnr score or the psnr score of a particular frame (if a frame number is specified)	of the last completed test
	def get_psnr_score(psnr_params = {})
	end
	  
    #Returns an array containing the blockiness score of each frame
	def get_blocking_scores
    end
	  
    #Returns an array containing the blurring score of each frame
	def get_blurring_scores
	end
	  
    #Returns an array containing the frames lost until each of the frame received was captured 
	def get_frames_lost_count
	end
	
	def get_jnd_scores(psnr_params = {})
	end
    
	#Returns an array containing the psnr score of each frame
	def get_psnr_scores(psnr_params = {})
	end
    
    #Aborts a test that has already started
    def abort_test
    end
	
	def wait_for_analog_test_ack(param)
	end
	
	def wait_for_ack(param)
	end
	
	#Starts the logger for the session. Takes the log file path as parameter (string).
    def start_logger(file_path)
      if @video_tester_log
        stop_logger
      end
      Logger.new('video_tester_log')
      @video_tester_log_outputter = Log4r::FileOutputter.new("video_tester_log_out",{:filename => file_path.to_s , :truncate => false})
      @video_tester_log = Logger['video_tester_log']
      @video_tester_log.level = Log4r::DEBUG
      @video_tester_log.add  @video_tester_log_outputter
      @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
      @video_tester_log_outputter.formatter = @pattern_formatter     
    end
      
    #Stops the logger.
    def stop_logger
      @video_tester_log_outputter = nil if @video_tester_log_outputter
      @video_tester_log = nil if @video_tester_log
    end
	
	def log_info(info_msg)
		@video_tester_log.info(info_msg) if @video_tester_log
	end
	
	def log_error(err_msg)
		@video_tester_log.error(err_msg) if @video_tester_log
	end
	
	def log_warning(warn_msg)
		@video_tester_log.warn(warn_msg) if @video_tester_log
	end
	
	def log_debug(dbg_msg)
		@video_tester_log.debug(dbg_msg) if @video_tester_log
	end
	
  end
end

