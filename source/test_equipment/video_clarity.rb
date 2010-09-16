require 'net/telnet'
require 'fileutils'
require File.dirname(__FILE__)+'/video_tester'

module TestEquipment
   
  class VideoClarity < VideoTester
    Logger = Log4r::Logger
    attr_reader :response
    
    #Constructor of the class set all the values needed to use video clarity: shared drives, ip address, video clarity's client path, etc.
    def initialize(video_clarity_info, log_path =nil)
      @vc_exe = '"C:\\Program Files\\Automation Studio\\VideoClarity\\cv"'
      @vc_config = "C:\\Program Files\\Automation Studio\\VideoClarity\\config"
      @vc_test_dir = "H:\\Recorded"
      @vc_src_dir = "G:\\Source"
      @response = ''
      super(video_clarity_info)
      @vc_res_dir = "\\\\#{@telnet_ip}\\Recorded\\"
      start_logger(log_path) if log_path
      log_info('Starting Video Clarity test session')
        config_file = File.new(@vc_config,'w+')
      config_file.puts video_clarity_info.telnet_ip.strip
      config_file.close
      raise 'Unable to reset Video Clarity' if !reset
      set_video_output
      rescue Exception => e
        log_error(e.to_s)
        raise
    end
    
    #Empty function created for compatibility with existing older video quality scripts (could be removed in the future).
    def calibrate(is_pal)
    end
  
    #This function resets video clarity to it's startup state
    def reset
      vc_exec('reset')
    end
    
    #This function sets video clarity's operational mode. Takes vidout_params a hash with 'device' as key and a string with one of the three types of output allowed, broadcast (default), dvi or none, as value.  
    def set_video_output(vidout_params = {})
      params = {'device' => 'broadcast'}.merge(vidout_params)
      vc_exec('videoOutput', params['device'])
    end
    
    #This function is used to enable or disable VANC transmission during  video playback
    def enable_vanc(vanc_flag = false)
      vanc_val = vanc_flag ? 1 : 0
      vc_exec('vanc', vanc_val)
    end
    
    #This function set the video format used. Takes vidout_params a hash with 'format' as key and for values either: 
    #   - A string with one of the standard types of format allowed: 
    #          '525': for 525 59.95Hz. 
    #          '625': for 625 50.00 Hz. 
    #          '1080i50': for 1080i 50.00 Hz.
    #          '1080i59': for 1080i 59.94 Hz. 
    #          '1080i60': for 1080i 60.00 Hz. 
    #          '720p50': for 720p 50.00 Hz. 
    #          '720p59': for 720p 59.94 Hz.
    #          '720p60': for 720p 60.00 Hz. 
    #          '1080p23': for 1080p 23.98 Hz. 
    #          '1080p24': for 1080p 24.00 Hz.
    #          '1080p25': for 1080p 25.00 Hz. 
    #          '1080p29': for 1080p 29.97 Hz. 
    #          '1080p30': for 1080p 30.00 Hz. 
    #          '1080p50': for 1080p 50.00 Hz. 
    #          '1080p59': for 1080p 59.94 Hz. 
    #          '1080p60': for 1080p 60.00 Hz
    #   - An array containing the following structure [width, height, frame rate]
    def set_output_format(vidout_params = {})
      params = {'format' => '720p59'}.merge(vidout_params)
      if params['format'].kind_of?(Array)
        vc_exec('customVideoFormat',"#{params['format'][0]} #{params['format'][1]} #{params['format'][2]}")
      else
        vc_exec('videoFormat', params['format'].to_s)
      end
    end
    
    # This function sets the format the images in any raw data file being uploaded to a video library. 
    # Takes fm_params a hash with 'format' as key and a string with one of the 7 allowed image formats ('YCbCr8' for YCbCr 8bpc, 'YCbCr10' for YCbCr 10bpc, 'ARGB' for ARGB 8bpc, 'RGBA' for RGBA 8bpc,
    # 'RGB8' for RGB 8bpc, 'BGR8' for BGR 8bpc or 'RGB10' for RGB 10bpc)  as value.
    def set_image_format(fm_params={})
      params = {'format' => 'YCbCr8'}.merge(fm_params)
      vc_exec('imageFormat', params['format'].downcase)
    end
    
    # This function time aligns the video loaded in port A with respect to the video loaded in port B
    def time_align_videos
      vc_exec('autoalign')
    end
    
    # This function spatially aligns the video frames in port A with respect to the video frames in port B
    def spatial_align_videos
      port_a_frames = get_first_and_last_frame({'port' => 'A'})
      port_b_frames = get_first_and_last_frame({'port' => 'B'})
      set_first_and_last_frame({'port' => 'A', 'first' => ((port_a_frames[0].to_i+port_a_frames[1].to_i)/2).floor, 'last' => port_a_frames[1].to_i})
      set_first_and_last_frame({'port' => 'B', 'first' => ((port_b_frames[0].to_i+port_b_frames[1].to_i)/2).floor, 'last' => port_b_frames[1].to_i})
      goto_first
      vc_exec('spatialAlign')
      set_first_and_last_frame({'port' => 'A', 'first' => port_a_frames[0], 'last' => port_a_frames[1]})
      set_first_and_last_frame({'port' => 'B', 'first' => port_b_frames[0], 'last' => port_b_frames[1]})
      goto_first
    end
    
    # This funtion perform a temporal and spatial alignment between the video loaded in port A and the video loaded in port B
    def align_videos
      result = goto_first && time_align_videos
      port_a_frames = get_first_and_last_frame({'port' => 'A'})
      port_b_frames = get_first_and_last_frame({'port' => 'B'})
      result = result && set_first_and_last_frame({'port' => 'A', 'first' => port_a_frames[0].to_i+1, 'last' => port_a_frames[1].to_i}) && 
      set_first_and_last_frame({'port' => 'B', 'first' => port_b_frames[0].to_i+1, 'last' => port_b_frames[1].to_i}) && goto_first &&
      spatial_align_videos
    end
    
    # This function load a given video into the video port specified. Takes l_params a hash containing the following key => <value> pairs:
    #     - 'port' => <port id> to specify the video port where the clip is going to be loaded, port id can be either 'A' or 'B'
    #     - 'video' => <video path> path where the video that is going to be uploaded is located.
    def load_video(l_params)
      params = {'port' => 'A', 'video' => ''}.merge(l_params)
      vc_exec("map#{params['port'].upcase}", params['video'], -1, -1, 1)
    end
    
    # This function set the video play-out settings. Takes mode_params a hash containing the following key => <value> pairs:
    #     - 'play_type' => <play mode> to specify the play mode. Can be one of the following values: 'Once' to Play Once, 'Repeat' to loop the video indefinitely, 'Ping' to Ping forward/backwards, or 'Alternate' to Alternate betwwen port A and port B. 
    #     - 'port' => <port id> to specify the video port used for playout, port id can be either 'A' or 'B'
    #     - 'speed' => <play speed> number (multiplier) to specify the playout speed
    #     - 'field_mode' => <mode> to specify the video port field play-out mode. Can be one of the following values: 'Frame' to Play entire frame, 'F1' to play Field 1 Only, 'F2' to play Field 2 Only, or 'F1F2' to play interchange betwwen F1 and F2. 
    def set_play_mode(mode_params = {})
      params = {'play_type' => 'Repeat', 'port' => 'A', 'speed' => 1, 'field_mode' => 'Frame'}.merge(mode_params)
      result = vc_exec('playmode', params['play_type'].capitalize)
      result = result && vc_exec('speed',params['port'].upcase.sub('A','0').sub('B','1'), params['speed'])
      result && vc_exec('fieldmode', params['port'].upcase.sub('A','0').sub('B','1'), params['field_mode'].capitalize)
    end
    
    # This function is used to start playing out video with video clarity
    def play_video
      vc_exec('play')
    end
    
    # This function is used to stop any function being executed by video clarity
    def stop_video
      vc_exec('stop')
    end
    
    # This function is used to pause video play-out
    def pause_video
      vc_exec('pause')
    end
    
    # This function is used to move to video sequence to the frame specified. Takes goto_params a hash with the following key => <value> pairs:
    #     - 'port' => <port id> to specify the video port used as reference, port id can be either 'A' or 'B'
    #     - 'frame' => <frame number> a number to specify the frame to go to. The frame number has to be between 0 and the number of frames contained in the clip loaded on the port specified in 'port' 
    def goto_frame(goto_params = {})
      params = {'frame' => 0, 'port' => 'A'}.merge(goto_params)
      vc_exec('goto', params['port'].upcase.sub('A','0').sub('B','1'), params['frame'])
    end
    
    # This function moves the video sequences in all the ports to the first frame.
    def goto_first
      vc_exec('first')
    end
    
    # This function causes video clarity to scan forward the video sequences in both ports the number of frames specified by num_frames
    def forward_scan(num_frames = 1)
      num_frames.to_i.times {vc_exec('jogFwd')}
    end
    
    # This function causes video clarity to scan backwards the video sequences in both ports the number of frames specified by num_frames
    def reverse_scan(num_frames = 1)
      num_frames.to_i.times {vc_exec('jogRev')}
    end
    
    # This function specifies the area used for measurement within each frame in the video sequence. Takes window_params a hash containing the following key => <value> pairs:
    #    - 'x_offset' => <x offset> the x coordinate offset of the upper left corner of the measurement area in number of pixels
    #    - 'y_offset' => <y offset> the y coordinate offset of the upper left corner of the measurement area in number of pixels
    #    - 'width' => <width> the width of the measurement area in number of pixels
    #    - 'height' => <height> the height of the measurement area in number of pixels
    def set_metric_window(window_params = {})
      params = {'x_offset' => 0, 'y_offset' => 0, 'width' => 720, 'height' => 480}.merge(window_params)
      vc_exec('metricWindow',params['x_offset'], params['y_offset'], params['width'], params['height'])
    end
    
    # This function is used to set the spatial offset of the frame in port 'A' with respect to the frame in port 'B'. Takes offset_params a hash containing the following key => <value> pairs:
    #     - 'x_offset' => <x offset> the x coordinate offset between the frame in port 'A' with respect to the frame in port 'B' in number of pixels 
    #     - 'y_offset' => <y offset> the y coordinate offset between the frame in port 'A' with respect to the frame in port 'B' in number of pixels 
    def set_spatial_offsets(offset_params)
      params = {'x_offset' => 0, 'y_offset' => 0}.merge(offset_params)
      vc_exec('spatialOffsets', params['x_offset'], params['y_offset'])
    end
    
    # This function causes video clarity to normalize the video sequences in the video ports using the luminance, chrominance, spatial offset, time alignment values that have been set or measured previously.
    def normalize_videos
      vc_exec('normalize')
    end
    
    # This function is used to set the luminance and chrominance values that will be used for normalization when the normalize_videos function is called. Takes norm_params a hash containing the following key => <value> pairs:
    #     - 'y' => <luminance> number specifying the luminance value used for normalization.
    #     - 'cb' => <diff blue> number specifying the cb value used for normalization.
    #     - 'cr' => <diff red> number specifying the cb value used for normalization.
    def set_normalized_offset(norm_params)
      params = {'y' => 0, 'cb' => 0, 'cr' => '0'}.merge(norm_params)
      vc_exec('normalizeOffsets', params['y'], params['cb'], params['cr'])
    end
    
    # This function is used to upload a video clip into a video library. Takes import_params a hash containing the following key => <value> pairs:
    #     - 'src_clip' => <src clip path> a string containing the path of the video clip that is going to be uploaded
    #     - 'data_format' => <format> a string containing the format of the video data in the file being imported valid values are: 
    #           '420p': for Planar YCbCr in YV12.
    #           '422p': for Planar YCbCr 4:2:2 subsampling
    #           '422i': for 8 bit YCbCr UYVY.
    #           '422i_10' for 10 bit YCbCr UYVY.
    #           '411i' for 8 bit interleaved 4:1:1 subsampling
    #           '411p' for 8 bit planar 4:1:1 subsampling
    #           '444i': for YUV 444 subsampling.     
    #     - 'video_height' => <height> height of the frames in number of pixels
    #     - 'video_width' => <width> width of the frames in number of pixels
    #     - 'num_frames' => <a number> number of frames contained in the clip
    #     - 'frame_rate' => <frame rate> number specifying the frame rate associated with the clip in frames per second
    #     - 'type' => <0 or 1> 0 one field per data segment, 1 for 1 frame per data segment
    #     - 'lib_path' => <path> string containing the path of hte video library where the clip will be uploaded.
    #     - 'seq_name' => <sequence name> string containing the name given to clip once it has been uploaded into the library
    def import_video(import_params = {})
      params = {'src_clip' => '', 'data_format' => nil, 'video_height' => nil, 'video_width' => nil, 'num_frames' => 0, 'frame_rate' => 30, 'type' => 1, 'lib_path' => @vc_src_dir, 'seq_name' => 'ref_sequence'}.merge(import_params)
      clip_base_name = File.basename(params['src_clip'])
      src_clip = "\\\\#{@telnet_ip}\\#{params['lib_path'].sub(/^[\w:]+/,'')}\\#{clip_base_name}"
      seq_name = params['seq_name']
      delete_video_sequence({'lib_path' => params['lib_path'], 'seq_name' => seq_name})
      File.delete(src_clip) if File.exists?(src_clip) && params['lib_path'] == @vc_test_dir
      File.copy(params['src_clip'],src_clip) if File.exists?(params['src_clip']) && File.size?(src_clip) != File.size(params['src_clip'])
      if params['data_format'] && params['video_height'] && params['video_width'] && params['type'] && params['frame_rate']
          info_file = File.new(File.dirname(src_clip)+'\default.hdr','w+')
          file_content = [   '% Color Format (YUV420, YUV422, YUV422P, YUV422_10, RGB, RGBA)',
                    get_video_data_format(params['data_format'].to_s),
                    '% Image Size (NbRows,NbCols) (576 720, 486 720, 720 1280, 1080 1920)',
                    params['video_height'].to_s + ' ' + params['video_width'].to_s,
                    '% Number of Fields per Image (1 -> progressive, 2 -> interlaced)',
                    params['type'],
                    '% Number of Images',
                    params['num_frames'].to_s+' % If greater then actual, reader will correct',
                    '% Frames per second',
                    params['frame_rate'].to_s,
                    '% Video Alignment',
                    '% no alignment',
                    '% timecode',
                    '01:00:00;00 D',
                    '% userbits',
                    'FAAFB00B',
                    '% Start Frame',
                    '0',
                  ]
          file_content.each{ |current_line| info_file.puts(current_line)}
          info_file.close
      end
      if !vc_exec('import', "\"#{params['lib_path']+'\\'+clip_base_name}\"", "\"#{seq_name}\"", params['to_disk'])
        File.delete(src_clip) if File.exists?(src_clip)
        raise 'Unable to import file '+params['src_clip']
      end 
      seq_name
    end
    
    # This funtion is used to upload a reference sequence with a unique frame as the first frame into a library. Takes source_params a hash containing the following key => <value> pairs:
    #     - 'pattern_file' => <pattern path> a string containing the path to a bmp file containing the unique frame.
    #     - 'src_clip' => <src clip path> a string containing the path of the video clip that is going to be uploaded
    #     - 'data_format' => <format> a string containing the format of the video data in the file being imported valid values are: 
    #           '420p': for Planar YCbCr in YV12.
    #           '422p': for Planar YCbCr 4:2:2 subsampling
    #           '422i': for 8 bit YCbCr UYVY.
    #           '422i_10' for 10 bit YCbCr UYVY.
    #           '411i' for 8 bit interleaved 4:1:1 subsampling
    #           '411p' for 8 bit planar 4:1:1 subsampling
    #           '444i': for YUV 444 subsampling.   
    #     - 'video_height' => <height> height of the frames in number of pixels
    #     - 'video_width' => <width> width of the frames in number of pixels
    #     - 'num_frames' => <a number> number of frames contained in the clip
    #     - 'frame_rate' => <frame rate> number specifying the frame rate associated with the clip in frames per second
    #     - 'type' => <0 or 1> 0 one field per data segment, 1 for 1 frame per data segment
    #     - 'lib_path' => <path> string containing the path of hte video library where the clip will be uploaded.
    #     - 'seq_name' => <sequence name> string containing the name given to clip once it has been uploaded into the library    
    def create_source_sequence(source_params)
      params = {'pattern_file' => @vc_src_dir+"\\Test.bmp" ,'src_clip' => '', 'data_format' => nil, 'video_height' => nil, 'video_width' => nil, 'num_frames' => 0, 'frame_rate' => 30, 'type' => 1, 'lib_path' => @vc_src_dir, 'seq_name' => 'source_sequence'}.merge(source_params)
      source_seq = import_video(params)
      pattern_seq = import_video({'src_clip' => params['pattern_file'], 'seq_name' => 'vc_pattern_sequence'})
      seq_name = 'ref_sequence'
      temp_seq = 'intermediate_'+seq_name
      File.delete("\\\\#{@telnet_ip}\\Source\\#{temp_seq}.cvp") if File.exists?("\\\\#{@telnet_ip}\\Source\\#{temp_seq}.cvp")
      playlist = File.new("\\\\#{@telnet_ip}\\Source\\#{temp_seq}.cvp",'w+')
      playlist.puts(pattern_seq+"\t-1\t-1\t1")
      playlist.puts(source_seq+"\t-1\t-1\t1")
      playlist.close
      play_list_cmds = [',','Viewport ', 'Received: ', 'Failures = ', 'Failures = ', 'Failures = ', ',', ',', ':']
      vc_telnet = @target = Net::Telnet::new( "Host" => @telnet_ip, "Port" => 23, "Waittime" => 0, "Telnetmode" => true, "Binmode" => false, "Prompt" => />/)
      vc_telnet.login({"PasswordPrompt" => /password[: ]*/i, "Name" => 'User', "Password" => 'gguser', "LoginPrompt" => /login/i })
      play_list_cmds.each do |current_cmd|
        response = ''
        command = "echo Received: Success: Viewport = 0: First = 0 Last = #{params['num_frames'].to_i - 1} | #{@vc_src_dir}\\sbs2.com 1 \"#{current_cmd}\" \"\""
        log_info('Command: '+command)
        vc_telnet.cmd(command){ |rec_data|
          response += rec_data
        }
        log_info('Response: '+response)
      end
      delete_video_sequence({'lib_path' => params['lib_path'], 'seq_name' => seq_name})
      delete_video_sequence({'lib_path' => params['lib_path'], 'seq_name' => temp_seq})
      raise 'Unable to create source sequence' if !vc_exec('import', "\"#{@vc_src_dir}\\#{temp_seq}.cvp\"", "\"#{temp_seq}\"", params['to_disk'])
      load_video({'port' => 'A', 'video' => temp_seq}) && set_viewing_mode({'mode' => 'A'}) && set_video_input({'type' => 'clearView', 'rec_mode' => 'single'})
      record_video({'files' => [{'lib_path' => params['lib_path'], 'seq_name' => seq_name}], 'num_frames' => params['num_frames']+1})
      seq_name
      ensure
        vc_telnet.close if vc_telnet
    end
    
    # This function is used to obtain the alignment frame between two videos loaded into the video ports when there is no distinctive frame in the video sequences. Takes seq_params a hash containing the following key => <value> pairs:
    #     - 'ref_seq' => <path> string containing a path where the reference video sequence is located. 
    #     - 'test_seq' => <path> string containing a path where the test video sequence is located.
    #     - 'ref_seq_1st_frame' => <frame number> number to indicate the first frame used for alignment of the reference video sequence. 
    #     - 'test_seq_1st_frame' => <frame number> number to indicate the first frame used for alignment of the test video sequence.
    #     - 'y_thresh' => <number> Y threshold that if execeeded increments the Y threshold exceeded counter
    #     - 'cb_thresh' => <number> Cb threshold that if execeeded increments the Cb threshold exceeded counter
    #     - 'cr_thresh' => <number> Cr threshold that if execeeded increments the Cr threshold exceeded counter
    #     - 'no_ref' => <0 or 1> flag to indicate if a reference sequence should be used, 1 do not use reference, 0 use reference
    #     - 'use_spatial' => <0 or 1> flag to indicate if the spatial aligment values should be used, 0 disable, 1 enable
    #     - 'normalize' => <0 or 1> flag to indicate if normalization should be done, 0 disable, 1 enable
    def get_alignment_frame(seq_params)
      stop_video
      params = {'ref_seq' => '', 'test_seq' => '', 'ref_seq_1st_frame' => 0, 'test_seq_1st_frame' => 0, 'y_thresh' => 0, 'cb_thresh' => 0, 'cr_thresh' => 0, 'no_ref' => 1, 'use_spatial' => 0, 'normalize' => 0}.merge(seq_params)
      temp_results = Array.new
      seq_hash = {params['ref_seq'] => params['ref_seq_1st_frame'], params['test_seq'] => params['test_seq_1st_frame']}
      seq_hash.each do |current_seq, first_frame|
          res_path = @vc_res_dir+current_seq+'.temporal'
          load_video({'port' => 'A','video' => current_seq})
          load_video({'port' => 'B','video' => current_seq})
          set_first_frame({'port' => 'A', 'frame' => first_frame})
          set_first_frame({'port' => 'B', 'frame' => first_frame})
          File.delete(res_path) if File.exists?(res_path)         
          if vc_exec('temporal', "\"#{@vc_test_dir+"\\"+current_seq+'.temporal'}\"", params['y_thresh'], params['cb_thresh'], params['cr_thresh'], params['no_ref'], params['use_spatial'], params['normalize']) 
			temp_results << [get_temp_vals(res_path), first_frame]
		  else
            return nil    
          end
      end
	  alignment_frame = 0
	  max_cross_correlation = 0
	  long_seq_id = 0
	  short_seq_id = 1
	  if temp_results[0][0]['y']['frame_results'].length < temp_results[1][0]['y']['frame_results'].length
		long_seq_id = 1 
		short_seq_id = 0
	  end
	  long_seq = temp_results[long_seq_id][0]['y']['frame_results']
	  short_seq = temp_results[short_seq_id][0]['y']['frame_results'][1..temp_results[short_seq_id][0]['y']['frame_results'].length-1]
	  short_seq_mean = get_mean(short_seq)
	  test_var = get_variance(short_seq)
	  short_seq_norm = []
	  short_seq.each{|t| short_seq_norm << (t-short_seq_mean)/Math.sqrt(test_var)}
	  start_point = long_seq.length - short_seq.length
	  (start_point).downto(1) do |i|
		  current_ref = long_seq[i..(i+short_seq.length-1)]
		  ref_seq_mean = get_mean(current_ref)
		  ref_var = get_variance(current_ref)
		  ref_seq_norm = []
		  current_ref.each{|t| ref_seq_norm << (t-ref_seq_mean)/Math.sqrt(ref_var)}
		  ref_seq_magnitude = ref_seq_norm[0]**2
		  current_min_y = ref_seq_norm[0]*short_seq_norm[0]
		  1.upto(short_seq_norm.length-1) do |j|
			  ref_seq_magnitude += ref_seq_norm[j]**2
			  current_min_y += ref_seq_norm[j] * short_seq_norm[j]
		  end
		  current_cross_corr = current_min_y/ref_seq_magnitude
		  if current_cross_corr >= max_cross_correlation
			  alignment_frame = i
			  max_cross_correlation = current_cross_corr
		  end
	  end
	  alignment_frame + temp_results[long_seq_id][1] - 1
    end
    
    #This function is used to export a video sequence from a video clarity library to a file. Takes export_params  a hash containing the following key => <value> pairs:
    #     - 'dst_file' => <path> string containing the path to a file where the exported sequence will be saved.
    #     - 'seq_name' => <name> string containing the name of sequence that will be exported to a file
    #     - 'first_frame' => <number> number of the first frame that will be exported to the file.
    #     - 'last_frame' => <number> number of the last frame that will be exported to the file.
    #     - 'type' => <format> data format of the exported file, valid values are: BMP for Bitmap, AVI for .avi files, or  RAW for raw yuv files
    #     - 'frame_rate' => <frame rate> (Optional) frame rate associated with the file in frames per second. Used only if 'type' is set to 'AVI'
    def export_video_file(export_params = {})
      params = {'dst_file' => '', 'seq_name' => '', 'first_frame' => 0, 'last_frame' => 1000, 'type' => 'RAW' , 'frame_rate' => 30}.merge(export_params)
      vc_exec('configExport', params['type'], params['frame_rate'], '0', '1', '1', '1') && vc_exec('export', "\"#{params["seq_name"]}\"", params['first_frame'], params['last_frame'], "\"#{params["dst_file"]}\"", params['type'], params['frame_rate'])
    end
    
    #This fucntion is used to activate a video library in video clarity. Takes lib_params a hash containing the folloiwing key => <value> pairs:
    #     - 'lib_path' => <path> string containing the path of the video library that will be activated.
    def activate_lib(lib_params = {})
      params = {'lib_path' => @vc_src_dir}.merge(lib_params)
      vc_exec('libraryActivate', "\"#{params['lib_path']}\"")
    end
    
    # This function is used to remove a video sequence from a library. Takes del_params a hash containing the following key => <value> pairs:
    #     - 'lib_path' => <path> string containing the path of the library whose video sequence will be deleted.
    #     - 'seq_name' => <name> string contatining the name of the video sequence that will be deleted.
    def delete_video_sequence(del_params)
      params = {'lib_path' => '', 'seq_name' => ''}.merge(del_params)
      vc_exec('seqDelete', "\"#{params['lib_path']}\"", "\"#{params['seq_name']}\"")
    end
    
    # This function is used to set video clarity's viewing mode. Takes view_params a hash containing the following key => <value> pairs:
    #     - 'mode' => <viewing mode> a string indicating the desired viewing mode, valid values are:
    #           'A': to view only the video in port 'A'.
    #           'B': to view only the video in port 'B'
    #           'Side': to video the video in port A and the video in port B Side-by-Side.
    #           'Seamless': to video the left portion of the video from port A and the right portion of the video from port B in a Seamless-Split view.
    #           'Mirror': to view the view the video in port B as the mirror image of the video in port A as in a Split-Mirror 
    #           'AMinusB': to view the difference between the video in port with the video in port B as in A-B video.
    def set_viewing_mode(view_params = {})
      params = {'mode' => 'A'}.merge(view_params)
      vc_exec('viewmode', params['mode'])
    end
    
    # This function is used to set the lumminance and chrominance threshholds for A-B video operations. Takes config_params a hash containing the following key => <value> pairs:
    #       - 'use_threshold' => <0 or 1> flag to indicate if the threshhold value should be used, 0 use threshhold, 1 do not use threhhold.
    #       - 'threshold' => <number> number indicating the luminance and chrominance threhholds
    #       - 'chroma_on' => <0 or 1> flag to indicate if the chrominance difference should be calculated
    #       - 'add_back_on' => <0 or 1> flag to indicate if the difference should be amplified for visual detection, 0 enable 1 disable
    def config_a_minus_b(config_params = {})
      params = {'use_threshold' => 0, 'threshold' => 10, 'chroma_on' => 0, 'add_back_on' => 0}.merge(config_params)
      vc_exec('aMinusBConfig', params['use_threshold'], params['threshold'], params['chroma_on'], params['add_back_on'])
    end
    
    # This function is used to setup video clarity for recording. Takes dev_params a hash containing the following key => value pairs:
    #       - 'type' => <io mode> sets video clarity's io operational mode. Valid values 'broadcast' for broadcast (allows play and record); 
    #                   'clearView' for ClearView mode (software only mode no external io); or 'dvi' for dvi output mode.
    #       - 'rec_mode' => <recording mode> string specifying the video recording mode valid values are 'InOut' for simmultaneous play-out an record;
    #                       'single' to perform record only operations on one input; or 'dual' as in dual mode to record simmulatenously on two channels (used for high data rate format 1080p60, 1080p 50, etc).
    #       - 'input' => <number> number specifying the video board's logical input used for recording.
    #       - 'board' => <number> number specifying the board whose input is going to be used for recording
    #       - 'src_format' => <signal format> string specifying the type of io signal, valid values (depending of the type of video board in the system) are:
    #               SDI Input Options:
    #              'SDI': for SDI Input 1. 
    #              'SDI2' – SDI Input 2'SDI2', 'audio_input' => 'None'
    #               Analog Input Options (Only for LH Configuration):
    #              '525ComponentBetaUS': for 525 Component Beta US
    #              '525ComponentSMPTEUS': for 525 Component SMPTE US
    #              '525S-VideoUS': for 525 S-Video US
    #              '525CompositeUS': for 525 Composite US 
    #              '525ComponentBetaJapan': for 525 Component Beta Japan 
    #              '525S-VideoJapan': for 525 S-Video Japan
    #              '525CompositeJapan': for 525 Composite Japan
    #              '625ComponentBeta': for 625 Component Beta
    #              '625ComponentSMPTE': for 625 Component SMPTE
    #              '625S-Video': for 625 S-Video
    #              '625Composite': for 625 composite
    #              '720p60': for 720p 60Hz
    #              '1080i30': for 1080i 30Hz
    #              '720p50': for 720p 50Hz
    #              '1080i25': for 1080i 25Hz
    #     - 'audio_input' => <audio input> string specifying the type of input signal if any, valid values (depending of the type of video board in the system) are:
    #              'None': for no audio signal
    #              SDI inputs:
    #              'SDI': for SDI audio
    #              Analog inputs:
    #              'AES': for AES
    #              'Analog': for generic analog signals
    def set_video_input(dev_params = {})
      params = {'type' => 'broadcast', 'rec_mode' => 'InOut', 'input' => 0, 'board' => 0, 'src_format' => 'SDI', 'audio_input' => 'None'}.merge(dev_params)
      vc_exec('videoInput', params['type'].downcase, params['rec_mode'], params['input'], params['board'], params['src_format'].upcase, params['audio_input'])
    end
    
    # This functions causes video clarity to start recording video. Takes rec_params a hash containing the following key => value pairs:
    #     - 'files' => [{'lib_path' => '', 'seq_name' => ''}]
    #     - 'num_frames' => <num frame to record> number specifying the number of frames that will be recorded.
    #     - 'abort_on_drop' => <0 or 1> flag to indicate if the video recording operation should be aborted if a frame drop is detected. 0 do not abort, 1 abort 
    #     - 'save_to_mem' => <0 or 1> flag to indicate if the video recorde shoud be saved in memory or to disk. 0 save to disk, 1 save in memory.
    def record_video(rec_params = {})
      file_args = ''
      params = {'files' => [{'lib_path' => '', 'seq_name' => ''}], 'num_frames' => 1, 'abort_on_drop' => 0, 'save_to_mem' => 0}.merge(rec_params)
      params['files'].each do |current_params| 
        delete_video_sequence({'lib_path' => current_params['lib_path'], 'seq_name' => current_params['seq_name']})
        file_args += " \"#{current_params['lib_path']}\" \"#{current_params['seq_name']}\""
      end
      vc_exec('record', file_args, params['num_frames'].to_i, params['abort_on_drop'], params['save_to_mem'])
    end
  
    
    # This function is used to perform a video out to video in test. In this type of test video clarity plays out a video clip to the dut's input and records the video returned by the dut to video clarity's input.
    # This test is executed in the following steps: 1. video clarity's output is connected to the dut's input and video clarity's input so that a reference clip can be recorded. 2. This function is called. 
    # 3. When this function yields the dut's output is connected to video clarity's input so that the test clip can be recorded. This function takes test_params  a hash containing the following key => value pairs:
    #     - 'ref_clip' => <path> string containing the path of the file that will be uploaded and played-out
    #     - 'test_clip' => <path> string containing the path where the test clip recorded will be saved
    #     - 'play_type' => <play mode> string specifying the play mode valid values are: 'Once' to Play Once, 'Repeat' to loop the video indefinitely, 'Ping' to Ping forward/backwards, or 'Alternate' to Alternate betwwen port A and port B.
    #     - 'format' => <signal format> string specifying the format of the video signal valid values are:
    #           '525': for 525 59.95Hz. 
    #           '625': for 625 50.00 Hz. 
    #           '1080i50': for 1080i 50.00 Hz.
    #           '1080i59': for 1080i 59.94 Hz. 
    #           '1080i60': for 1080i 60.00 Hz. 
    #           '720p50': for 720p 50.00 Hz. 
    #           '720p59': for 720p 59.94 Hz.
    #           '720p60': for 720p 60.00 Hz. 
    #           '1080p23': for 1080p 23.98 Hz. 
    #           '1080p24': for 1080p 24.00 Hz.
    #           '1080p25': for 1080p 25.00 Hz. 
    #           '1080p29': for 1080p 29.97 Hz. 
    #           '1080p30': for 1080p 30.00 Hz. 
    #           '1080p50': for 1080p 50.00 Hz. 
    #           '1080p59': for 1080p 59.94 Hz. 
    #           '1080p60': for 1080p 60.00 Hz
    #     - 'data_format' => <data format> string specifying the format of the data in the video file being uploaded for playout. Valid values are:
    #           '420p': for Planar YCbCr in YV12.
    #           '422p': for Planar YCbCr 4:2:2 subsampling
    #           '422i': for 8 bit YCbCr UYVY.
    #           '422i_10' for 10 bit YCbCr UYVY.
    #           '411i' for 8 bit interleaved 4:1:1 subsampling
    #           '411p' for 8 bit planar 4:1:1 subsampling
    #           '444i': for YUV 444 subsampling.      
    #     - 'video_height' => <height> number specifying the height if each frame in number of pixels
    #     - 'image_format' => <image format> string specifying the format of the video sequence once the reference video has been uploaded. Valid values are: 'YCbCr8' for YCbCr 8bpc;
    #                         'YCbCr10' for YCbCr 10bpc; 'ARGB' for ARGB 8bpc; 'RGBA' for RGBA 8bpc; 'RGB8' for RGB 8bpc; 'BGR8' for BGR 8bpc; 'RGB10' for RGB 10bpc.
    #     - 'video_width' => <width> number specifying the width if each frame in number of pixels
    #     - 'num_frames' => <number of frames> number specifying the number of frames to be recorded.
    #     - 'frame_rate' => <frame rate> number specifying the frame rate (in frames per second) associated with the clip if any.
    #     - 'enable_vanc' => true if vanc should be transmitted during playback, false otherwise.
    def video_out_to_video_in_test(test_params = {})
      params = {'ref_clip' => '', 'test_clip' => '', 'play_type' => 'Repeat','format' => 525,'data_format' => '422i', 'video_height' => 480, 'image_format' => 'YCbCr8', 'video_width' => 720, 'num_frames' => 300, 'frame_rate' => 30, 'enable_vanc' => false}.merge(test_params)
      result = activate_lib && set_output_format({'format' => params['format']}) 
      params['ref_seq'] = create_source_sequence(params.merge({'src_clip' => params['ref_clip']}))
      test_seq, test_seq_ref, test_clip, ref_result = get_ref_file(params)
      result = result && ref_result && goto_frame({'port' => 'A', 'frame' => 0}) && enable_vanc(params['enable_vanc'])
      yield 
	  result = result && record_video({'files' => [{'lib_path' => @vc_test_dir, 'seq_name' => test_seq}], 'num_frames' => (params['num_frames'].to_i+10).ceil}) &&
      activate_lib({'lib_path' => @vc_test_dir}) && load_video({'port' => 'B','video' => test_seq_ref}) && load_video({'port' => 'A','video' => test_seq}) && set_first_frame({'port' => 'B', 'frame' => 0}) && 
      alignment_frame = get_alignment_frame({'ref_seq' => test_seq_ref, 'test_seq' => test_seq, 'ref_seq_1st_frame' => 2, 'test_seq_1st_frame' => 0})
      result = result && alignment_frame && load_video({'port' => 'B','video' => test_seq_ref}) && load_video({'port' => 'A','video' => test_seq})
      test_seq_frames = get_first_and_last_frame({'port' => 'B'})
      result = result && set_first_and_last_frame({'port' => 'A', 'first' => alignment_frame, 'last' => alignment_frame.to_i + test_seq_frames[1].to_i - 2}) && set_first_frame({'port' => 'B','frame' => 2})
      set_viewing_mode({'mode' => 'Seamless'}) && set_metric_window({'x_offset' => params['metric_window'][0], 'y_offset' => params['metric_window'][1], 'width' => params['metric_window'][2], 'height' => params['metric_window'][3]}) && spatial_align_videos
      get_psnr_results({'res_path' => @vc_test_dir+'\\'+'psnr_results.psnr'}) if result
      get_jnd_results({'res_path' => @vc_test_dir+'\\'+'jnd_results.jnd'}) if result
      get_dmos_results({'res_path' => @vc_test_dir+'\\'+'dmos_results.mos'}) if result
      result = result && stop_video 
      export_video_file({'dst_file' => test_clip+'_exp.avi', 'seq_name' => test_seq, 'first_frame' => 0, 'last_frame' => params['num_frames'].to_i - 1, 'type' => 'AVI' , 'frame_rate' => params['frame_rate']}) 
      File.copy(@vc_res_dir+test_seq+'_exp.avi', params['test_clip']) if File.exists?(@vc_res_dir+test_seq+'_exp.avi') 
      result
    end
    
    # This function is used to perform a file to video in test. In this type of test the dut's plays-out an encoded clip to video clarity's input where it is recorded and analyzed.
    # This test is executed in the following steps: 1. video clarity's output is connected to video clarity's input so that a reference clip can be recorded. 2. This function is called. 
    # 3. When this function yields the dut's output is connected to video clarity's input so that the test clip can be recorded. This function takes test_params  a hash containing the following key => value pairs:
    #     - 'ref_clip' => <path> string containing the path of the file that will be uploaded and played-out
    #     - 'test_clip' => <path> string containing the path where the test clip recorded will be saved
    #     - 'play_type' => <play mode> string specifying the play mode valid values are: 'Once' to Play Once, 'Repeat' to loop the video indefinitely, 'Ping' to Ping forward/backwards, or 'Alternate' to Alternate betwwen port A and port B.
    #     - 'format' => <signal format> string specifying the format of the video signal valid values are:
    #           '525': for 525 59.95Hz. 
    #           '625': for 625 50.00 Hz. 
    #           '1080i50': for 1080i 50.00 Hz.
    #           '1080i59': for 1080i 59.94 Hz. 
    #           '1080i60': for 1080i 60.00 Hz. 
    #           '720p50': for 720p 50.00 Hz. 
    #           '720p59': for 720p 59.94 Hz.
    #           '720p60': for 720p 60.00 Hz. 
    #           '1080p23': for 1080p 23.98 Hz. 
    #           '1080p24': for 1080p 24.00 Hz.
    #           '1080p25': for 1080p 25.00 Hz. 
    #           '1080p29': for 1080p 29.97 Hz. 
    #           '1080p30': for 1080p 30.00 Hz. 
    #           '1080p50': for 1080p 50.00 Hz. 
    #           '1080p59': for 1080p 59.94 Hz. 
    #           '1080p60': for 1080p 60.00 Hz
    #     - 'data_format' => <data format> string specifying the format of the data in the video file being uploaded for playout. Valid values are:
    #           '420p': for Planar YCbCr in YV12.
    #           '422p': for Planar YCbCr 4:2:2 subsampling
    #           '422i': for 8 bit YCbCr UYVY.
    #           '422i_10' for 10 bit YCbCr UYVY.
    #           '411i' for 8 bit interleaved 4:1:1 subsampling
    #           '411p' for 8 bit planar 4:1:1 subsampling
    #           '444i': for YUV 444 subsampling.     
    #     - 'video_height' => <height> number specifying the height if each frame in number of pixels
    #     - 'image_format' => <image format> string specifying the format of the video sequence once the reference video has been uploaded. Valid values are: 'YCbCr8' for YCbCr 8bpc;
    #                         'YCbCr10' for YCbCr 10bpc; 'ARGB' for ARGB 8bpc; 'RGBA' for RGBA 8bpc; 'RGB8' for RGB 8bpc; 'BGR8' for BGR 8bpc; 'RGB10' for RGB 10bpc.
    #     - 'video_width' => <width> number specifying the width if each frame in number of pixels
    #     - 'num_frames' => <number of frames> number specifying the number of frames to be recorded.
    #     - 'frame_rate' => <frame rate> number specifying the frame rate (in frames per second) associated with the clip if any.
    #     - 'rec_mode'  => <recording mode> string specifying the recording mode. Valid values are 'single' only one video clarity input channel is used for recording; or 'dual' as in dual mode 
    #                      two input channels are used for recording (typically used for high data rate format 1080p10, etc).
    def file_to_video_in_test(test_params = {})
      params = {'ref_clip' => '', 'test_clip' =>'', 'format' => '525', 'play_type' => 'Repeat', 'data_format' => nil, 'image_format' => 'YCbCr8', 'video_height' => nil, 'video_width' => nil, 'num_frames' => 300, 'rec_mode' => 'single', 'frame_rate' => 30, 'rec_delay' => 1}.merge(test_params)
      result = set_output_format({'format' => params['format']})
      dummy_test_seq, test_seq_ref, dummy_test_clip, ref_result = get_ref_file(params)
      test_seq =  'current_test'
      test_clip = @vc_test_dir+'\\'+test_seq
      File.delete(@vc_res_dir+test_seq+'_exp.avi') if File.exists?(@vc_res_dir+test_seq+'_exp.avi')
      result = result && ref_result && activate_lib({'lib_path' => @vc_test_dir}) && set_video_input({'rec_mode' => params['rec_mode']})  
      yield
      sleep [params['rec_delay'].to_f,0.1].max
      result = result && record_video({'files' => [{'lib_path' => @vc_test_dir, 'seq_name' => test_seq}], 'num_frames' => params['num_frames']-(params['rec_delay'] * 30)}) 
      alignment_frame = get_alignment_frame({'ref_seq' => test_seq_ref, 'test_seq' => test_seq, 'ref_seq_1st_frame' => 0, 'test_seq_1st_frame' => 3})
      result = result && alignment_frame && load_video({'port' => 'B','video' => test_seq_ref}) && load_video({'port' => 'A','video' => test_seq})
      test_seq_frames = get_first_and_last_frame({'port' => 'A'})
      result = result && set_first_and_last_frame({'port' => 'B', 'first' => alignment_frame, 'last' => alignment_frame.to_i + test_seq_frames[1].to_i - 3}) && set_first_frame({'port' => 'A','frame' => 3})
      export_video_file({'dst_file' => test_clip+'_exp.avi', 'seq_name' => test_seq, 'first_frame' => 0, 'last_frame' => params['num_frames'].to_i - 1, 'type' => 'AVI' , 'frame_rate' => params['frame_rate']}) 
      result = result && set_viewing_mode({'mode' => 'Seamless'}) && set_metric_window({'x_offset' => params['metric_window'][0], 'y_offset' => params['metric_window'][1], 'width' => params['metric_window'][2], 'height' => params['metric_window'][3]}) && spatial_align_videos 
      get_psnr_results({'res_path' => @vc_test_dir+'\\'+'psnr_results.psnr'}) if result
      get_jnd_results({'res_path' => @vc_test_dir+'\\'+'jnd_results.jnd'}) if result
      get_dmos_results({'res_path' => @vc_test_dir+'\\'+'dmos_results.mos'}) if result
      result = result && stop_video
      File.copy(@vc_res_dir+test_seq+'_exp.avi', params['test_clip']) if File.exists?(@vc_res_dir+test_seq+'_exp.avi') && result 
      result     
    end
    
    # This function is sued to perform a file to file test. In this type of test a reference and a test file are uploaded, compared an analyzed. This test is executed in the following steps:
    # 1. A reference file containing a raw data video clip is passed to the dut for processing. 2. the reference and the processed file are passed to this function for analysis. Takes test_params a hash containing
    # the following key => value pairs:
    #     - 'ref_clip' => <path> string containing the path of the file that will be uploaded and played-out
    #     - 'test_clip' => <path> string containing the path where the test clip recorded will be saved
    #     - 'play_type' => <play mode> string specifying the play mode valid values are: 'Once' to Play Once, 'Repeat' to loop the video indefinitely, 'Ping' to Ping forward/backwards, or 'Alternate' to Alternate betwwen port A and port B.
    #     - 'format' => <video clip format> an array specifying the format of the video signal used for uploading the reference and test clip. The arry is of the form [signal width, signal height, signal frame rate] 
    #     - 'data_format' => <data format> string specifying the format of the data in the video file being uploaded for playout. Valid values are:
    #           '420p': for Planar YCbCr in YV12.
    #           '422p': for Planar YCbCr 4:2:2 subsampling
    #           '422i': for 8 bit YCbCr UYVY.
    #           '422i_10' for 10 bit YCbCr UYVY.
    #           '411i' for 8 bit interleaved 4:1:1 subsampling
    #           '411p' for 8 bit planar 4:1:1 subsampling
    #           '444i': for YUV 444 subsampling.      
    #     - 'video_height' => <height> number specifying the height if each frame in number of pixels
    #     - 'image_format' => <image format> string specifying the format of the video sequence once the reference video has been uploaded. Valid values are: 'YCbCr8' for YCbCr 8bpc;
    #                         'YCbCr10' for YCbCr 10bpc; 'ARGB' for ARGB 8bpc; 'RGBA' for RGBA 8bpc; 'RGB8' for RGB 8bpc; 'BGR8' for BGR 8bpc; 'RGB10' for RGB 10bpc.
    #     - 'video_width' => <width> number specifying the width if each frame in number of pixels
    #     - 'num_frames' => <number of frames> number specifying the number of frames to be recorded.
    #     - 'frame_rate' => <frame rate> number specifying the frame rate (in frames per second) associated with the clip if any.
    def file_to_file_test(test_params = {})
      params = {'ref_file' => '', 'test_file' =>'', 'image_format' => 'YCbCr8', 'format' => [720,486,30], 'data_format' => nil, 'video_height' => nil, 'video_width' => nil, 'num_frames' => 300, 'frame_rate' => 30}.merge(test_params)
      test_seq =  'current_test'
      test_clip = @vc_test_dir+'\\'+test_seq
      result = activate_lib && set_video_output({'device' => 'None'}) && set_output_format({'format' => params['format']}) && set_image_format({'format' => params['image_format']})
      src_clip = params['ref_file']
      src_clip = import_video({'src_clip' => params['ref_file'], 'data_format' => params['data_format'], 'video_height' => params['video_height'], 'video_width' => params['video_width'], 'num_frames' => [params['num_frames'].to_i,1000].max, 'frame_rate' => params['frame_rate']})
      result = result && activate_lib({'lib_path' => @vc_test_dir})
      tst_clip = import_video({'lib_path' => @vc_test_dir, 'seq_name' => test_seq,'src_clip' => params['test_file'], 'data_format' => params['data_format'], 'video_height' => params['video_height'], 'video_width' => params['video_width'], 'num_frames' => [params['num_frames'].to_i,1000].max, 'frame_rate' => params['frame_rate']})
      result = result && activate_lib && load_video({'port' => 'B','video' => src_clip})&& set_first_frame({'port' => 'B', 'frame' => 0})
      get_psnr_results({'res_path' => @vc_test_dir+'\\'+'psnr_results.psnr'}) if result
      get_jnd_results({'res_path' => @vc_test_dir+'\\'+'jnd_results.jnd'})  if result
      get_dmos_results({'res_path' => @vc_test_dir+'\\'+'dmos_results.mos'}) if result
      result && stop_video
    end
    
    # This function is used to play-out video with video clarity. Takes play_params a hash containing the following key => value pairs:
    #     - 'src_clip' => <path> string containing the path of the file that will be uploaded and played-out
    #     - 'play_type' => <play mode> string specifying the play mode valid values are: 'Once' to Play Once, 'Repeat' to loop the video indefinitely, 'Ping' to Ping forward/backwards, or 'Alternate' to Alternate betwwen port A and port B.
    #     - 'format' => <signal format> string specifying the format of the video signal valid values are:
    #           '525': for 525 59.95Hz. 
    #           '625': for 625 50.00 Hz. 
    #           '1080i50': for 1080i 50.00 Hz.
    #           '1080i59': for 1080i 59.94 Hz. 
    #           '1080i60': for 1080i 60.00 Hz. 
    #           '720p50': for 720p 50.00 Hz. 
    #           '720p59': for 720p 59.94 Hz.
    #           '720p60': for 720p 60.00 Hz. 
    #           '1080p23': for 1080p 23.98 Hz. 
    #           '1080p24': for 1080p 24.00 Hz.
    #           '1080p25': for 1080p 25.00 Hz. 
    #           '1080p29': for 1080p 29.97 Hz. 
    #           '1080p30': for 1080p 30.00 Hz. 
    #           '1080p50': for 1080p 50.00 Hz. 
    #           '1080p59': for 1080p 59.94 Hz. 
    #           '1080p60': for 1080p 60.00 Hz
    #     - 'data_format' => <data format> string specifying the format of the data in the video file being uploaded for playout. Valid values are:
    #           '420p': for Planar YCbCr in YV12.
    #           '422p': for Planar YCbCr 4:2:2 subsampling
    #           '422i': for 8 bit YCbCr UYVY.
    #           '422i_10' for 10 bit YCbCr UYVY.
    #           '411i' for 8 bit interleaved 4:1:1 subsampling
    #           '411p' for 8 bit planar 4:1:1 subsampling
    #           '444i': for YUV 444 subsampling.  
    #     - 'video_height' => <height> number specifying the height if each frame in number of pixels
    #     - 'image_format' => <image format> string specifying the format of the video sequence once the reference video has been uploaded. Valid values are: 'YCbCr8' for YCbCr 8bpc;
    #                         'YCbCr10' for YCbCr 10bpc; 'ARGB' for ARGB 8bpc; 'RGBA' for RGBA 8bpc; 'RGB8' for RGB 8bpc; 'BGR8' for BGR 8bpc; 'RGB10' for RGB 10bpc.
    #     - 'video_width' => <width> number specifying the width if each frame in number of pixels
    #     - 'num_frames' => <number of frames> number specifying the number of frames to be recorded.
    #     - 'frame_rate' => <frame rate> number specifying the frame rate (in frames per second) associated with the clip if any. 
    #     - 'enable_vanc' => true if vanc should be transmitted during playback, false otherwise.    
    def play_video_out(play_params = {})
      params = {'src_clip' => '', 'data_format' => '422i', 'play_type' => 'Once','format' => 525,'image_format' => 'YCbCr8','video_height' => 480, 'video_width' => 720, 'num_frames' => 1000, 'frame_rate' => 30, 'enable_vanc' => false}.merge(play_params)
      result = activate_lib && set_video_output && set_output_format({'format'=>params['format'].to_s}) && set_image_format({'format' => params['image_format'].to_s}) && set_viewing_mode({'mode' => 'A'}) && set_play_mode({'play_type'=>params['play_type']})
      src_clip = enable_vanc(params['enable_vanc']) && import_video({'src_clip' => params['src_clip'],  'data_format' => params['data_format'], 'video_height' => params['video_height'], 'video_width' => params['video_width'], 'num_frames' => params['num_frames'].to_i, 'frame_rate' => params['frame_rate']})
      result && load_video({'video' => src_clip}) && play_video
    end
    
    # This function is used to perform a video out to file in test. In this type of test video clarity plays out a video clip to the dut's input, the dut captures and encodes the clip, then both the reference and encode are
    # passed to video clarity for analysis. This test is executed in the following steps: 1. video clarity's output is connected to the dut's input and video clarity's input so that a reference clip can be recorded. 
    # 2. This function is called. 3. When this function yields the dut's start recording the test clip. Once the dut finishes then reference and test clip are passed to video clarity for analysins.
    # This function takes test_params a hash containing the following key => value pairs:
    #     - 'ref_clip' => <path> string containing the path of the file that will be uploaded and played-out
    #     - 'test_clip' => <path> string containing the path where the test clip recorded will be saved
    #     - 'play_type' => <play mode> string specifying the play mode valid values are: 'Once' to Play Once, 'Repeat' to loop the video indefinitely, 'Ping' to Ping forward/backwards, or 'Alternate' to Alternate betwwen port A and port B.
    #     - 'format' => <signal format> string specifying the format of the video signal valid values are:
    #           '525': for 525 59.95Hz. 
    #           '625': for 625 50.00 Hz. 
    #           '1080i50': for 1080i 50.00 Hz.
    #           '1080i59': for 1080i 59.94 Hz. 
    #           '1080i60': for 1080i 60.00 Hz. 
    #           '720p50': for 720p 50.00 Hz. 
    #           '720p59': for 720p 59.94 Hz.
    #           '720p60': for 720p 60.00 Hz. 
    #           '1080p23': for 1080p 23.98 Hz. 
    #           '1080p24': for 1080p 24.00 Hz.
    #           '1080p25': for 1080p 25.00 Hz. 
    #           '1080p29': for 1080p 29.97 Hz. 
    #           '1080p30': for 1080p 30.00 Hz. 
    #           '1080p50': for 1080p 50.00 Hz. 
    #           '1080p59': for 1080p 59.94 Hz. 
    #           '1080p60': for 1080p 60.00 Hz
    #     - 'data_format' => <data format> string specifying the format of the data in the video file being uploaded for playout. Valid values are:
    #           '420p': for Planar YCbCr in YV12.
    #           '422p': for Planar YCbCr 4:2:2 subsampling
    #           '422i': for 8 bit YCbCr UYVY.
    #           '422i_10' for 10 bit YCbCr UYVY.
    #           '411i' for 8 bit interleaved 4:1:1 subsampling
    #           '411p' for 8 bit planar 4:1:1 subsampling
    #           '444i': for YUV 444 subsampling.     
    #     - 'video_height' => <height> number specifying the height if each frame in number of pixels
    #     - 'image_format' => <image format> string specifying the format of the video sequence once the reference video has been uploaded. Valid values are: 'YCbCr8' for YCbCr 8bpc;
    #                         'YCbCr10' for YCbCr 10bpc; 'ARGB' for ARGB 8bpc; 'RGBA' for RGBA 8bpc; 'RGB8' for RGB 8bpc; 'BGR8' for BGR 8bpc; 'RGB10' for RGB 10bpc.
    #     - 'video_width' => <width> number specifying the width if each frame in number of pixels
    #     - 'num_frames' => <number of frames> number specifying the number of frames to be recorded.
    #     - 'frame_rate' => <frame rate> number specifying the frame rate (in frames per second) associated with the clip if any.
    #     - 'test_file_data_format'  => <data format> string specifying the format of the data in the encoded video file. Valid values are:
    #           '420p': for Planar YCbCr in YV12.
    #           '422p': for Planar YCbCr 4:2:2 subsampling
    #           '422i': for 8 bit YCbCr UYVY.
    #           '422i_10' for 10 bit YCbCr UYVY.
    #           '411i' for 8 bit interleaved 4:1:1 subsampling
    #           '411p' for 8 bit planar 4:1:1 subsampling
    #           '444i': for YUV 444 subsampling.
    #     - 'enable_vanc' => true if vanc should be transmitted during playback, false otherwise. 
    def video_out_to_file_test(test_params = {})
      params = {'ref_clip' => '', 'test_file' =>  '', 'play_type' => 'Repeat','format' => 525,'data_format' => '422i', 'video_height' => 486, 'image_format' => 'YCbCr8', 'video_width' => 720, 'num_frames' => 300, 'frame_rate' => 30, 'test_file_data_format' => '420p', 'enable_vanc' => false}.merge(test_params)
      result = set_output_format({'format' => params['format']})
      params['ref_seq'] = create_source_sequence(params.merge({'src_clip' => params['ref_clip']}))
      test_seq, test_seq_ref, test_clip, ref_result = get_ref_file({'src_clip' => params['ref_clip']}.merge(params))
      result = result && ref_result && enable_vanc(params['enable_vanc']) && goto_frame({'port' => 'A', 'frame' => 0}) && set_play_mode({'play_type'=>'Repeat'}) && play_video
      yield
      result = result && stop_video && activate_lib({'lib_path' => @vc_test_dir})
      tst_clip = import_video({'lib_path' => @vc_test_dir, 'seq_name' => test_seq,'src_clip' => params['test_file'], 'data_format' => params['test_file_data_format'], 'video_height' => params['video_height'], 'video_width' => params['video_width'], 'num_frames' => [params['num_frames'].to_i,1000].max, 'frame_rate' => params['frame_rate']})
      result = result && load_video({'port' => 'A','video' => tst_clip}) && load_video({'port' => 'B','video' => test_seq_ref}) && goto_frame({'port' => 'A', 'frame' => (params['num_frames'].to_i/2).floor}) && goto_frame({'port' => 'B', 'frame' => 0}) && set_viewing_mode({'mode' => 'Seamless'}) && set_metric_window({'x_offset' => params['metric_window'][0], 'y_offset' => params['metric_window'][1], 'width' => params['metric_window'][2], 'height' => params['metric_window'][3]}) && align_videos
      get_psnr_results({'res_path' => @vc_test_dir+'\\'+'psnr_results.psnr'}) if result
      get_jnd_results({'res_path' => @vc_test_dir+'\\'+'jnd_results.jnd'}) if result
      get_dmos_results({'res_path' => @vc_test_dir+'\\'+'dmos_results.mos'}) if result
      result && stop_video 
    end
    
    # This function is used perform a jnd analysis on the two video sequences currently loaded into the video ports. Takes jnd_params a hash containing the following key => value pairs:
    #       - 'res_path' => <result path> string containing the path of a file where the jnd results will be stored.,
    #       - 'y_thresh' => <number> number specifying the the luminance threshold if a frame's jnd luminance result is above this threshhold then this frame is considered to have failed.
    #       - 'chroma_thresh' => <number> number specifying the the chrominance threshold if a frame's jnd chrominance result is above this threshhold then this frame is considered to have failed.
    #       - 'use_spatial' => <0 or 1> flag to enable or disable the used of the spatial alignment settings when performing a jnd analysis. 0 do not use settings, 1 use settingd.
    #       - 'normalize' => <0 or 1> flag to enable normalization of the clips when performing a jnd analysis. 0 enable normalization, 1 disable normalization.
    def get_jnd_results(jnd_params)
      @jnd_results = get_quality_index_results(jnd_params){|params| vc_exec('jnd', "\"#{params['res_path']}\"", params['y_thresh'], params['chroma_thresh'], params['use_spatial'], params['normalize'])}
    end
    
    # This function is used perform a jnd analysis on the two video sequences currently loaded into the video ports. Takes jnd_params a hash containing the following key => value pairs:
    #       - 'res_path' => <result path> string containing the path of a file where the jnd results will be stored.,
    #       - 'y_thresh' => <number> number specifying the the luminance threshold if a frame's jnd luminance result is above this threshhold then this frame is considered to have failed.
    #       - 'chroma_thresh' => <number> number specifying the the chrominance threshold if a frame's jnd chrominance result is above this threshhold then this frame is considered to have failed.
    #       - 'use_spatial' => <0 or 1> flag to enable or disable the used of the spatial alignment settings when performing a jnd analysis. 0 do not use settings, 1 use settingd.
    #       - 'normalize' => <0 or 1> flag to enable normalization of the clips when performing a jnd analysis. 0 enable normalization, 1 disable normalization.
    def get_dmos_results(dmos_params)
      # @dmos_results = get_quality_index_results(dmos_params){|params| vc_exec('dmos', "\"#{params['res_path']}\"", params['y_thresh'], params['chroma_thresh'], params['use_spatial'], params['normalize'])}
      @dmos_results = @jnd_results
    end
    
    # This function is used perform a jnd analysis on the two video sequences currently loaded into the video ports. Takes jnd_params a hash containing the following key => value pairs:
    #       - 'res_path' => <result path> string containing the path of a file where the jnd results will be stored.,
    #       - 'y_thresh' => <number> number specifying the the luminance threshold if a frame's jnd luminance result is above this threshhold then this frame is considered to have failed.
    #       - 'chroma_thresh' => <number> number specifying the the chrominance threshold if a frame's jnd chrominance result is above this threshhold then this frame is considered to have failed.
    #       - 'use_spatial' => <0 or 1> flag to enable or disable the used of the spatial alignment settings when performing a jnd analysis. 0 do not use settings, 1 use settingd.
    #       - 'normalize' => <0 or 1> flag to enable normalization of the clips when performing a jnd analysis. 0 enable normalization, 1 disable normalization.
    def get_quality_index_results(jnd_params)
      stop_video
      params = {'res_path' => '', 'y_thresh' => 10, 'chroma_thresh' => 10, 'use_spatial' => 1, 'normalize' => 0}.merge(jnd_params)
      quality_results = {
               'y' =>  { 
                    'frame_results' => Array.new,
                    'min' => -1,
                    'max' => -1,
                    'avg' => -1
                   },
               'chroma' =>  { 
                    'frame_results' => Array.new,
                    'min' => -1,
                    'max' => -1,
                    'avg' => -1
                    }, 
              }
      res_path = @vc_res_dir+File.basename(params['res_path'])
      File.delete(res_path) if File.exists?(res_path)
      if yield params
        result_file = File.new(res_path,'r')
        result_lines = result_file.readlines
        result_lines.each do |current_line|
          case current_line
            when /Sequence\s+Metric.*/im
              metric_array = current_line.downcase.split(/[\s:]+/)
              quality_results[metric_array[2].sub('cb','chroma')][metric_array[3]] = metric_array[4].to_f
            when /([\d\.]+\s+){4}\d+/
              metric_array = current_line.downcase.split(/[\s:]+/)
              quality_results['y']['frame_results'][metric_array[0].to_i] = metric_array[1].to_f
              quality_results['chroma']['frame_results'][metric_array[0].to_i] = metric_array[2].to_f
          end
        end
        result_file.close
      end
      quality_results
    end
    
    # This function is used perform a psnr analysis on the two video sequences currently loaded into the video ports. Takes psnr_params a hash containing the following key => value pairs:
    #       - 'res_path' => <result path> string containing the path of a file where the psnr results will be stored.,
    #       - 'y_thresh' => <number> number specifying the luminance threshold, if a frame's psnr luminance result is above this threshhold then this frame is considered to have failed.
    #       - 'cb_thresh' => <number> number specifying the the cb threshold, if a frame's psnr cb result is above this threshhold then this frame is considered to have failed.
    #       - 'cr_thresh' => <number> number specifying the the cr threshold, if a frame's psnr cr result is above this threshhold then this frame is considered to have failed.
    #       - 'use_spatial' => <0 or 1> flag to enable or disable the used of the spatial alignment settings when performing a psnr analysis. 0 do not use settings, 1 use settingd.
    #       - 'normalize' => <0 or 1> flag to enable normalization of the clips when performing a psnr analysis. 0 enable normalization, 1 disable normalization.
    def get_psnr_results(psnr_params)
      stop_video
      params = {'res_path' => '', 'y_thresh' => 0, 'cb_thresh' => 0, 'cr_thresh' => 0, 'no_ref' => 0, 'use_spatial' => 1, 'normalize' => 0}.merge(psnr_params)
      @psnr_results = {
               'y' =>  { 
                    'frame_results' => Array.new,
                    'min' => -1,
                    'max' => -1,
                    'avg' => -1
                   },
               'cb' =>  { 
                    'frame_results' => Array.new,
                    'min' => -1,
                    'max' => -1,
                    'avg' => -1
                    },
               'cr' =>  { 
                    'frame_results' => Array.new,
                    'min' => -1,
                    'max' => -1,
                    'avg' => -1
                   }, 
              }
      res_path = @vc_res_dir+File.basename(params['res_path'])
      File.delete(res_path) if File.exists?(res_path)         
      if vc_exec('psnr', "\"#{params['res_path']}\"", params['y_thresh'], params['cb_thresh'], params['cr_thresh'], params['no_ref'], params['use_spatial'], params['normalize']) 
        psnr_file = File.new(res_path,'r')
        psnr_lines = psnr_file.readlines
        psnr_lines.each do |current_line|
          case current_line
            when /Sequence\s+Metric.*/im
              metric_array = current_line.downcase.split(/[\s:]+/)
              @psnr_results[metric_array[2]][metric_array[3]] = metric_array[4].to_f
            when /([\d\.]+\s+){12}\d+/
              metric_array = current_line.downcase.split(/[\s:]+/)
              @psnr_results['y']['frame_results'][metric_array[0].to_i] = metric_array[7].to_f
              @psnr_results['cb']['frame_results'][metric_array[0].to_i] = metric_array[8].to_f
              @psnr_results['cr']['frame_results'][metric_array[0].to_i] = metric_array[9].to_f
          end
        end
        psnr_file.close
      end
    end
    
    # This function can be used to retrieve the min, max or average jnd result of a clip or the jnd result of a frame in a clip after get_jnd_results has been called. Takes jnd_params a hash containing the following key => <value> pairs:
    #     - 'component' => <component type> string specifying the component for which the jnd result(s) should be retrieved. Valid values are 'y' for luminance; or 'chroma' for chrominance
    #     - 'type' => <type of value> (Required if frame is not specified) string specifying the type of jnd value desired for the component valid values are 'avg' for average; 'min' for minimum; or 'max' for maximum.
    #     - 'frame' => <number> (optional) number specifying the frame for which the jnd score is wanted.
    # At least one of the two optional arguments must be specifed.    
    def get_jnd_score(jnd_params = {})
      params = {'component' => 'y', 'type' => 'avg', 'frame' => nil}.merge(jnd_params)
      if params['frame']
        @jnd_results[params['component']]['frame_results'][params['frame'].to_i]
      else
        @jnd_results[params['component']][params['type']]
      end
    end
  
    # This function can be used to retrieve the min, max or average psnr result of a clip or the psnr result of a frame in a clip after get_jnd_results has been called. Takes jnd_params a hash containing the following key => <value> pairs:
    #     - 'component' => <component type> string specifying the component for which the psnr result(s) should be retrieved. Valid values are 'y' for luminance; 'cb' for difference blue; or 'cr' for difference red.
    #     - 'type' => <type of value> (Required if frame is not specified) string specifying the type of psnr value desired for the component valid values are 'avg' for average; 'min' for minimum; or 'max' for maximum.
    #     - 'frame' => <number> (optional) number specifying the frame for which the psnr score is wanted.    
    def get_psnr_score(psnr_params = {})
      params = {'component' => 'y', 'type' => 'avg', 'frame' => nil}.merge(psnr_params)
      if params['frame']
        @psnr_results[params['component']]['frame_results'][params['frame'].to_i]
      else
       @psnr_results[params['component']][params['type']]
      end
    end
    
    # This function can be used to retrieve the min, max or average dmos result of a clip or the dmos result of a frame in a clip after get_dmos_results has been called. Takes dmos_params a hash containing the following key => <value> pairs:
    #     - 'component' => <component type> string specifying the component for which the dmos result(s) should be retrieved. Valid values are 'y' for luminance; or 'chroma' for chrominance
    #     - 'type' => <type of value> (Required if frame is not specified) string specifying the type of dmos value desired for the component valid values are 'avg' for average; 'min' for minimum; or 'max' for maximum.
    #     - 'frame' => <number> (optional) number specifying the frame for which the dmos score is wanted.
    # At least one of the two optional arguments must be specifed.    
    def get_dmos_score(dmos_params = {})
      params = {'component' => 'y', 'type' => 'avg', 'frame' => nil}.merge(dmos_params)
      if params['frame']
        @dmos_results[params['component']]['frame_results'][params['frame'].to_i]
      else
        @dmos_results[params['component']][params['type']]
      end
    end
    
    # This function ireturns an array with the jnd scores of each frame in a clip after get_jnd_results has been called. Takes jnd_params a hash containing the following key => <value> pairs:
    #     - 'component' => <image component> a string containing the image component for which the values are wanted. Valid values are 'y' for luminance; or 'chroma' for chrominance 
    def get_jnd_scores(jnd_params = {})
      params = {'component' => 'y'}.merge(jnd_params)
      @jnd_results[params['component']]['frame_results']
    end
    
    # This function returns an array with the psnr scores of each frame in a clip after get_psnr_results has been called. Takes psnr_params a hash containing the following key => <value> pairs:
    #     - 'component' => <image component> a string containing the image component for which the values are wanted. Valid values are 'y' for luminance; 'cb' for difference blue; or 'cr' for difference red. 
    def get_psnr_scores(psnr_params = {})
      params = {'component' => 'y'}.merge(psnr_params)
      @psnr_results[params['component']]['frame_results']
    end
    
    # This function ireturns an array with the dmos scores of each frame in a clip after get_jnd_results has been called. Takes dmos_params a hash containing the following key => <value> pairs:
    #     - 'component' => <image component> a string containing the image component for which the values are wanted. Valid values are 'y' for luminance; or 'chroma' for chrominance 
    def get_dmos_scores(dmos_params = {})
      params = {'component' => 'y'}.merge(dmos_params)
      @dmos_results[params['component']]['frame_results']
    end
    
    # This function aborts an action that has been previously started. 
    def abort_test
      stop_video
    end
    
    # This fucntions returns the width of a frame, in number of pixels, that corresponds to the video signal specified. Takes signal_params a hash containing the following key => <value> pairs:
    #     - 'format' => <signal format> string spesifying the signal format. Valid values are:
    #           '525': for 525 59.95Hz. 
    #           '625': for 625 50.00 Hz. 
    #           '1080i50': for 1080i 50.00 Hz.
    #           '1080i59': for 1080i 59.94 Hz. 
    #           '1080i60': for 1080i 60.00 Hz. 
    #           '720p50': for 720p 50.00 Hz. 
    #           '720p59': for 720p 59.94 Hz.
    #           '720p60': for 720p 60.00 Hz. 
    #           '1080p23': for 1080p 23.98 Hz. 
    #           '1080p24': for 1080p 24.00 Hz.
    #           '1080p25': for 1080p 25.00 Hz. 
    #           '1080p29': for 1080p 29.97 Hz. 
    #           '1080p30': for 1080p 30.00 Hz. 
    #           '1080p50': for 1080p 50.00 Hz. 
    #           '1080p59': for 1080p 59.94 Hz. 
    #           '1080p60': for 1080p 60.00 Hz    
    def get_video_signal_width(signal_params ={})
      params = {'format' => '525'}.merge(signal_params)
      
      case params['format']
        when /525/
          720
        when /625/
          720
        when /720.+/
          1280
        when /1080.+/
          1920
        else
          params['format'].scan(/\d+/)[0].to_i*16/9
      end
    end
    
    # This fucntions returns the height of a frame, in number of pixels, that corresponds to the video signal specified. Takes signal_params a hash containing the following key => <value> pairs:
    #     - 'format' => <signal format> string spesifying the signal format. Valid values are:
    #           '525': for 525 59.95Hz. 
    #           '625': for 625 50.00 Hz. 
    #           '1080i50': for 1080i 50.00 Hz.
    #           '1080i59': for 1080i 59.94 Hz. 
    #           '1080i60': for 1080i 60.00 Hz. 
    #           '720p50': for 720p 50.00 Hz. 
    #           '720p59': for 720p 59.94 Hz.
    #           '720p60': for 720p 60.00 Hz. 
    #           '1080p23': for 1080p 23.98 Hz. 
    #           '1080p24': for 1080p 24.00 Hz.
    #           '1080p25': for 1080p 25.00 Hz. 
    #           '1080p29': for 1080p 29.97 Hz. 
    #           '1080p30': for 1080p 30.00 Hz. 
    #           '1080p50': for 1080p 50.00 Hz. 
    #           '1080p59': for 1080p 59.94 Hz. 
    #           '1080p60': for 1080p 60.00 Hz  
    def get_video_signal_height(signal_params ={})
      params = {'format' => '525'}.merge(signal_params)
      
      case params['format']
        when /525/
              486
        when /625/
              576
        when /720.+/
              720
          when /1080.+/
              1080
          else
              params['format'].scan(/\d+/)[0].to_i
      end
    end

    # This function returns an array containing the numbers of the frames that are currently set as the first and last frame of the video loaded in the given port. Takes find_params a hash containing the following
    # key => value pairs:
    #     - 'port' => <port id> string containing the port id for which the frame numbers are desired. Valid values are 'A' or 'B'
    def get_first_and_last_frame(find_params)
      params = {'port' => 'A'}.merge(find_params)
      result = nil
      if vc_exec('inout',params['port'].upcase.sub('A','0').sub('B','1'))
        result = @response.match(/First\s*=\s*(\d+)\s*Last\s*=\s*(\d+)/).captures
      end
      result
    end
    
    # This function is used to set the the first and last frame of the video loaded in the given port. Takes seq_params a hash containing the following
    # key => value pairs:
    #     - 'port' => <port id> string containing the port id where the first and last frame are going to be set. Valid values are 'A' or 'B'
    #     - 'first' => <number> number specifying which frame is to be set as the first frame.
    #     - 'last' => <number> number specifying which frame is to be set as the last frame.
    def set_first_and_last_frame(seq_params)
      params = {'port' => 'A', 'first' => 0, 'last' => 1}.merge(seq_params)
      vc_exec('inout',params['port'].upcase.sub('A','0').sub('B','1'), params['first'], params['last'])
    end
    
    # This function is used to set the the first frame of the video loaded in the given port. Takes seq_params a hash containing the following
    # key => value pairs:
    #     - 'port' => <port id> string containing the port id where the first and last frame are going to be set. Valid values are 'A' or 'B'
    #     - 'first' => <number> number specifying which frame is to be set as the first frame.
    def set_first_frame(seq_params)
      params = {'port' => 'A', 'frame' => 0}.merge(seq_params)
      first_and_last_frame =  get_first_and_last_frame(params)   
      set_first_and_last_frame(params.merge({'first' => params['frame'], 'last' => first_and_last_frame[1].to_i}))
    end
    
    private
    #Generic execution commmand. Takes command_args the arguments that will be used to execute a command, and command (string)  as parameters.
    def vc_exec(*command_params)
      cmd = ''
      command_params.each do |cmd_param|
        cmd+=" #{cmd_param.to_s}"
      end
      log_info('Command: cv'+cmd)
      @response = `#{@vc_exe}#{cmd}`
      log_info('Response '+@response)
      /Received:\s+Success/im.match(@response) != nil
      rescue Exception => e
        log_error(e.to_s)
        raise
    end
    
    # This function is used to convert TI's yuv values to video clarity yuv values. Takes chroma_format a string specifying a TI yuv value. return a video clarity yuv value
    def get_video_data_format(chroma_format)
      case(chroma_format)
          when '420p'
            'YUV420'
          when '411p'
            'YUV411P'
          when '422p'
            'YUV422P'
          when '411i'
            'YUV411'
          when '422i'
            'YUV422'
          when '422i_10'
            'YUV422_10'
          when '444i'
            'YUVA444'
          else
            chroma_format.strip.upcase
      end
    end
    
    # This function is used to upload a reference file into a library. This function is used in all full reference tests.  
    def get_ref_file(params)
      result = activate_lib && set_video_output && set_output_format({'format' => params['format'].to_s}) && set_image_format({'format' => params['image_format']}) && set_viewing_mode({'mode' => 'A'})
      src_clip = params['ref_seq'] 
      src_clip = import_video({'src_clip' => params['ref_clip'],  'data_format' => params['data_format'], 'video_height' => params['video_height'], 'video_width' => params['video_width'], 'num_frames' => params['num_frames'].to_i, 'frame_rate' => params['frame_rate']}) if !src_clip
      test_seq =  'current_test'
      test_seq_ref = 'current_test_ref'
      test_clip = @vc_test_dir+'\\'+test_seq
      File.delete(@vc_res_dir+test_seq+'_exp.avi') if File.exists?(@vc_res_dir+test_seq+'_exp.avi')
      result = result && set_play_mode({'play_type'=>params['play_type']}) && load_video({'video' => src_clip}) && set_video_input && play_video
      sleep 1
      result = result && stop_video && goto_frame({'port' => 'A', 'frame' => 0}) && record_video({'files' => [{'lib_path' => @vc_test_dir, 'seq_name' => test_seq_ref}], 'num_frames' => params['num_frames'].to_i})
      [test_seq, test_seq_ref, test_clip, result]
    end
    
    # This function is used to perform a temporal analysis on a video sequence.
    def get_temp_vals(res_path)
      temp_results = {
           'y' =>  { 
                'frame_results' => Array.new,
                'min' => -1,
                'max' => -1,
                'avg' => -1
               },
           'cb' =>  { 
                'frame_results' => Array.new,
                'min' => -1,
                'max' => -1,
                'avg' => -1
                },
           'cr' =>  { 
                'frame_results' => Array.new,
                'min' => -1,
                'max' => -1,
                'avg' => -1
               }, 
      }
      temp_file = File.new(res_path,'r')
      temp_lines = temp_file.readlines
      temp_lines.each do |current_line|
        case current_line
          when /Sequence\s+Metric.*/im
            metric_array = current_line.downcase.split(/[\s:]+/)
            temp_results[metric_array[2]][metric_array[3]] = metric_array[4].to_f
          when /([\d\.]+\s+){12}\d+/
            metric_array = current_line.downcase.split(/[\s:]+/)
            temp_results['y']['frame_results'][metric_array[0].to_i] = metric_array[1].to_f
            temp_results['cb']['frame_results'][metric_array[0].to_i] = metric_array[2].to_f
            temp_results['cr']['frame_results'][metric_array[0].to_i] = metric_array[3].to_f
        end
      end
      temp_file.close
      temp_results
    end
    
    # This function is used to compute the mean value in an array
    def get_mean(an_array)
      sum = 0
      an_array.each{|element| sum+= element}
      sum/(an_array.length)
    end
    
    # This function is used to compute the variance of the values in an array
    def get_variance(an_array)
      mean = get_mean(an_array)
      sum = 0
      an_array.each{|element| sum+= (element-mean)**2}
      sum/(an_array.length-1)    
    end
  end
end

