require 'q_master'
require 'timeout'

class QMasterInfo
  attr_reader :telnet_ip, :telnet_port
  
  def initialize
    @telnet_ip = '10.0.0.20'
  end
end

a = TestEquipment::QMaster.new(QMasterInfo.new, "C:/qmaster_log.txt")
#:ref_file, 
#:test_file, 
#:transmitter_ip, 
#:transmitter_mask, 
#:transmitter_gateway, 
#:receiver_ip, 
#:receiver_mask, 
#:receiver_gateway,
#:stream_protocol,
#:optimum_mode,
#:multicast_addr,
#:user_defined
#:video_calibration
#:video_out_pal   
=begin Uncomment this section to exercise Q-master's testing capabilities
a.calibrate(false)
puts "++++++++++++++++++++++++++ Composite-In to Composite-Out Test for 720x480 Resolution+++++++++++++++++++++++++++++++++++"                                                   
a.composite_out_to_composite_in_test("c:/Video_tools/sheilds_720x480_420p_252frames_30fps.avi","test_sheilds_720x480_420p_252frames_30fps.avi",false)
	puts "mean scores"
	puts a.get_mos_score
	puts a.get_blocking_score
	puts a.get_blurring_score	
	puts a.get_frame_lost_count
	puts a.get_jerkiness_score
	puts a.get_level_score
	puts a.get_psnr_score
	puts "frame scores"
	puts a.get_blocking_score(0)
	puts a.get_blurring_score(1)	
	puts a.get_frame_lost_count(2)
	puts a.get_psnr_score(3)
	puts "array scores"
	puts a.get_blocking_scores
	puts a.get_blurring_scores
	puts a.get_frames_lost_count
	puts a.get_psnr_scores
puts "++++++++++++++++++++++++++ Composite-In to Composite-Out Test for 704x480 Resolution+++++++++++++++++++++++++++++++++++"
a.composite_out_to_composite_in_test("c:/Video_tools/football_704x480_420p_150frames_30fps.avi","test_football_704x480_420p_150frames_30fps.avi",false)
	puts "mean scores"
	puts a.get_mos_score
	puts a.get_blocking_score
	puts a.get_blurring_score	
	puts a.get_frame_lost_count
	puts a.get_jerkiness_score
	puts a.get_level_score
	puts a.get_psnr_score
	puts "frame scores"
	puts a.get_blocking_score(0)
	puts a.get_blurring_score(1)	
	puts a.get_frame_lost_count(2)
	puts a.get_psnr_score(3)
	puts "array scores"
	puts a.get_blocking_scores
	puts a.get_blurring_scores
	puts a.get_frames_lost_count
	puts a.get_psnr_scores
=end
#=begin
puts "++++++++++++++++++++++++++ File to File Test+++++++++++++++++++++++++++++++++++"
a.file_to_file_test("c:/Video_tools/cablenews_320x240_420p_511frames_768000bps_test.avi","c:/Video_tools/cablenews_320x240_420p_511frames_768000bps_test.avi")
	puts "mean scores"
	puts a.get_mos_score
	puts a.get_blocking_score
	puts a.get_blurring_score	
	puts a.get_frame_lost_count
	puts a.get_jerkiness_score
	puts a.get_level_score
	puts a.get_psnr_score
	puts "frame scores"
	puts a.get_blocking_score(0)
	puts a.get_blurring_score(1)	
	puts a.get_frame_lost_count(2)
	puts a.get_psnr_score(3)
	puts "array scores"
	puts a.get_blocking_scores
	puts a.get_blurring_scores
	puts a.get_frames_lost_count
	puts a.get_psnr_scores
#File to composite in test is missing here because it requires that a unit decodes the file and send it back to Q-Master
#=end
=begin
puts "++++++++++++++++++++++++++ Play File Test+++++++++++++++++++++++++++++++++++"	
puts a.play_composite_out("c:/Video_tools/football_704x480_420p_150frames_30fps.avi", false)
=end
=begin Uncomment this section to test q-master's codecs
a.mpeg4_decode_file("/test_amelie_1_720x480_420p_120frames_1mbps_15fps.m4v","/test_amelie_1_720x480_420p_120frames_1mbps_15fps_deg.yuv")
h264_settings = {"enc_avg_bitrate" => 6000000,
			     "enc_max_bitrate" => 6600000
}
a.h264_encode_file('C:\Video_tools\sheilds_720x480_420p_252frames_30fps_codesrc.avi', 'C:\Video_tools\sheilds_720x480_420p_252frames_30fps_codesrc_qmaster_enc.264',h264_settings)
=end
a.stop_logger
