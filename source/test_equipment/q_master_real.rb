gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require 'rexml/document'


module TestEquipment
include Log4r
include REXML
Logger = Log4r::Logger
  class QMaster
    @@mapped_drive = "Z:"
    def initialize(qmaster_info, log_path =nil)
      password = "optimum"
      username = "remote"
      start_logger(log_path) if log_path
      @qmaster_log.info("Starting Q-Master Session") if @qmaster_log
	  @video_scores_path = @@mapped_drive+"\\Support Files\\video_pesq.xml"
      if !/OK|Disconnected\s*Z:\s*\\\\#{qmaster_info.telnet_ip}\\Q-Master Video/.match(`net use`)
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
    
    def qmaster_exec(command, remote = false)
      if remote
        option = "-r"
        command = to_arg(command)
      end
      @qmaster_log.info("Command: \"#{@@mapped_drive}\\Support Files\\QMCommandLine.exe\" #{option}#{command}") 
      qmaster_process = IO.popen("cmd","r+")
      qmaster_process.puts("\"#{@@mapped_drive}\\Support Files\\QMCommandLine.exe\" #{option}#{command}")     
      qmaster_process  
    end 
    
    def encode_file
      encode_decode_parse_ack
    end 
    
    def decode_file
      encode_decode_parse_ack
    end
    
    def composite_out_to_composite_in_test(ref_file,test_file,pre_defined)
      test_video({:ref_file => ref_file.gsub(".avi","_codesrc.avi"), :test_file => test_file, :video_io_mode => 7, :ref_file_type => 1, :uncompress_ref => ref_file.gsub(".avi","_uncompref.avi")})
    end
    
    #:ref_file, 
    #:test_file, 
    #:transmitter_ip, 
    #:transmitter_mask, 
    #:transmitter_gateway, 
    #:receiver_ip, 
    #:receiver_mask, 
    #:receiver_gateway,
    #:stream_protocol,
    #:video_io_mode,
    #:multicast_addr,
    #:ref_file_type
    #:video_calibration
    #:video_out_pal
    #:uncompref_ref
    #:timeout 
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
                  test_video(params) if cal_result == 0
                when 2
                  abort_test
                  expect_result
                else
                  @qmaster_log.error("Received unexpected answer from qmaster")
                  raise "Received unexpected answer from qmaster"
      end   
      result
    end
    	
	  def get_mos_score
		  get_scores('MOS')
    end
	
	  def get_jerkiness_score
		  get_scores('Jerkiness')
	  end
	
	  def get_level_score
		  get_scores('Level')
	  end
	
	  def get_blocking_score(frame = nil)
		  if frame
			  get_scores('FrameBlocking')[frame]
		  else
			  get_scores('BlockDistortion')
		  end
    end
	
	  def get_blurring_score(frame = nil)
		  if frame
			  get_scores('FrameBlurring')[frame]
		  else
			  get_scores('Blurring')
		  end
	  end
	
	  def get_frame_lost_count(frame = nil)
		  if frame
			  get_scores('FrameLostCount')[frame]
		  else
			  get_scores('LostFrames')
		  end
	  end
	
	  def get_psnr_score(frame = nil)
		  if frame
			  get_scores('FramePSNR')[frame]
		  else
			  get_scores('PSNR')
		  end
	  end
	
	  def get_blocking_scores
		  get_scores('FrameBlocking')
    end
	
	  def get_blurring_scores
		  get_scores('FrameBlurring')
	  end
	
	  def get_frames_lost_count
		  get_scores('FrameLostCount')
	  end
	
	  def get_psnr_scores
		  get_scores('FramePSNR')
	  end
    
    def abort_test
      abort_process = qmaster_exec("")
    end
    
    def change_avi_to_yuv(avi_file, yuv_file)
      file_converter =  
      cmd = "mencoder #{avi_file} "
      response = ``
      @qmaster_long.info("Response: "+response)
    end
    
    def change_yuv_to_avi(yuv_file, avi_file)
      cmd = ""
      response = ``
      @qmaster_long.info("Response: "+response)
    end
    
    private
	  def get_scores(metric)
		  video_scores = Array.new
		  file = File.new(@video_scores_path)
		  video_scores_file = REXML::Document.new file
		  video_scores_file.root.elements[metric].each do |scores|
			if scores.respond_to?(:each) 
				scores.each{|value|	video_scores << value.to_s.strip}
			elsif scores.to_s.strip.length > 0
				video_scores << scores.to_s.strip
			end
		end
		  video_scores
    end
	  def to_arg(val)
		  %Q! "#{val.to_s}"!
	  end

	  def encode_decode_parse_ack
		  result = `type "#{@@mapped_drive}\\Support Files\\cmdout.txt"`
		  @qmaster_log.info("Response: "+result)
		  result = `del "#{@@mapped_drive}\\Support Files\\cmdout.txt"`
		  result
	  end
    
    def qm_expect(qm_pipe, expect_string, expect_timeout)
      expect_interval = 4
      expect_times = (expect_timeout/expect_interval).round
      1.upto(expect_times) do    
        pipe_output = qm_pipe.readline if qm_pipe 
        case pipe_output.to_s
          when /#{expect_string}/i
            @qmaster_log.info("Response: "+pipe_output.to_s)
            return 0
          when /QMaster\s*is\s*uncalibrated/i
            @qmaster_log.info("Response: "+pipe_output.to_s)
            return 1
          else
            @qmaster_log.info("Response: "+pipe_output.to_s)
            sleep expect_interval
        end
      end
      return 2
    end
  end
end
