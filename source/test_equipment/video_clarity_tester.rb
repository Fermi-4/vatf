require File.dirname(__FILE__)+'/video_clarity'

class VideoClarityInfo
  attr_reader :telnet_ip, :samba_root_path
  
  def initialize
    @telnet_ip = '10.0.0.57'
  end
end

def get_scores(a)
  components = ['y','cb','cr']
  components.each do |cur_comp|
	 puts a.get_psnr_score.to_s
	 puts a.get_psnr_score({'component' => cur_comp}).to_s
	 puts a.get_psnr_score({'component' => cur_comp, 'frame' => 23}).to_s
     puts a.get_psnr_scores({'component' => cur_comp}).to_s
  end
  components = ['y','chroma']
  components.each do |cur_comp|
	 puts a.get_jnd_score.to_s
	 puts a.get_jnd_score({'component' => cur_comp}).to_s
	 puts a.get_jnd_score({'component' => cur_comp, 'frame' => 23}).to_s
     puts a.get_jnd_scores({'component' => cur_comp}).to_s
  end
end

def run_test(test_num, a)
    puts case test_num
			when 0
				puts 'PLAY VIDEO TEST'
				case rand(2)
					when 0
						puts a.play_video_out({'src_clip' => 'C:\Video_tools\bus_176x144_420p_75frames.yuv','video_height' => 144, 'video_width' => 176, 'data_format' => '420p', 'play_type' => 'repeat'}){}
					when 1
						puts a.play_video_out({'src_clip' => 'C:\Video_tools\4CIF_football_704x480_MPp_1mbps_30fps_150frames.264'}){}
				end
				sleep 10
 				a.stop_video
			when 1
				puts 'VIDEO OUT TO VIDEO IN TEST'
				puts a.video_out_to_video_in_test({'ref_clip' => 'C:\Video_tools\bus_176x144_420p_75frames.yuv', 'test_clip' => 'C:\\atest.avi', 'data_format' => '420p', 'video_height' => 144 , 'video_width' => 176, 'num_frames' => 75, 'metric_window' => [0,0,176,144]}){}
				get_scores(a)
			when 2
				puts 'FILE TO VIDEO IN TEST'
				puts a.file_to_video_in_test({'ref_clip' => 'C:\Video_tools\4CIF_football_704x480_MPp_1mbps_30fps_150frames.264', 'test_clip' => 'C:\\test.avi', 'metric_window' => [0,0,704,480]}){}
				get_scores(a)
			when 3
				puts 'FILE TO FILE TEST NORMAL FORMAT'
				a.file_to_file_test({'ref_file' => 'C:\Video_tools\4CIF_football_704x480_MPp_1mbps_30fps_150frames.264', 'test_file' => 'C:\Video_tools\4CIF_football_704x480_MPp_1mbps_30fps_150frames.264', 'metric_window' => [0,0,704,480]})
				get_scores(a)
			when 4
				puts 'FILE TO FILE TEST CUSTOM FORMAT'
				a.file_to_file_test({'ref_file' => 'C:\Video_tools\bus_176x144_420p_75frames.yuv', 'test_file' => 'C:\Video_tools\bus_176x144_420p_75frames.yuv', 'data_format' => '420p', 'format' => [176,144,30],'video_height' => 144 , 'video_width' => 176, 'num_frames' => 75, 'metric_window' => [0,0,176,144]})
				get_scores(a)
			when 5
				puts 'VIDEO OUT TO FILE TEST'
				a.video_out_to_file_test({'ref_clip' => 'C:\Video_tools\4CIF_football_704x480_MPp_1mbps_30fps_150frames.264', 'test_file' => 'C:\Video_tools\4CIF_football_704x480_MPp_1mbps_30fps_150frames.264', 'metric_window' => [0,0,704,480]}){}
				get_scores(a)
		 end
end

num_times = 1
a = TestEquipment::VideoClarity.new(VideoClarityInfo.new, "C:/vc_log.txt")
num_times.times do |iter|
    puts 'TEST '+iter.to_s 
    #run_test(rand(6),a)
    run_test(1,a)
end
puts a.response.to_s
a.stop_logger
