require File.dirname(__FILE__)+'/../dvsdk_linux_base_client'
require 'fileutils'

module DmaiHandlers
    
    class DmaiLinuxClient < DvsdkHandlers::DvsdkLinuxBaseClient
        def initialize(platform_info, log_path = nil)
          @active_threads = 0
          @thread_lists = Array.new
          @load_modules = "loadmodules.sh" if !@load_modules
          @base_params = {
            'command_name'			=> nil,
            'codec'			=> {'name' => '-c', 'values' => ''},
            'input_file'			=> {'name' => '-i', 'values' => ''},
            'output_file' => {'name'=> '-o','values' => ''},
            'benchmark' => {'name' => '--benchmark', 'values' => ''},
            'cache'     => {'name' => '--cache', 'values' => ''},
            'engine'    => {'name' => '-e', 'values' => ''},
          }
          
          @video_encode_params = @base_params.merge({
            'codec'			=> {'name' => '-c', 'values' => {'h264' => 'h264enc', 'mpeg4' => 'mpeg4enc', 'mpeg2' => 'mpeg2enc'}},
            'resolution' => {'name' => '-r','values'=>''},
            'bit_rate' => {'name'=> '-b','values'=>''},
            'num_of_frames'	=> {'name' => '-n', 'values' => ''},
          })
          
          @video_decode_params = @base_params.merge({
            'codec'			=> {'name' => '-c', 'values' => {'h264' => 'h264dec', 'mpeg4' => 'mpeg4dec', 'mpeg2' => 'mpeg2dec'}},
            'num_of_frames'	=> {'name' => '-n', 'values' => ''},
            'start_frame' => {'name' => '--startframe', 'values' => ''}
          })
    
          @audio_encode_params = @base_params.merge({
            'codec'			=> {'name' => '-c', 'values' => {'aac' => 'aacheenc', 'mp3' => 'mp3enc'}},
            'num_of_frames'	=> {'name' => '-n', 'values' => ''},
            'bit_rate'     => {'name' => '-b', 'values' => ''},
            'samplerate'   => {'name' => '-s', 'values' => ''},
          })
            
          @audio_decode_params = @base_params.merge({
            'codec'			=> {'name' => '-c', 'values' => {'aac' => 'aachedec', 'mp3' => 'mp3dec'}},
            'num_of_frames'	=> {'name' => '-n', 'values' => ''},
            'start_frame' => {'name' => '--startframe', 'values' => ''}
          })
            
          @image_encode_params = @base_params.merge({
            'codec'			=> {'name' => '-c', 'values' => {'jpeg' => 'jpegenc'}},
            'output_color_space' => {'name' => '--oColorSpace','values'=> {'422p'=>'1', 'default' =>'1', '420p'=> '2', '422i'=> '3', '444p'=>'4', 'gray'=>'5'}},
            'input_color_space' => {'name' => '--iColorSpace','values'=> {'422p'=>'1', 'default' =>'1', '420p'=> '2', '422i'=> '3', '444p'=>'4', 'gray'=>'5'}},
            'image_qvalue' => {'name' => '--qValue','values'=>''},
            'image_resolution' => {'name' => '-r','vaules'=>''},
          })
          
          @image_decode_params = @base_params.merge({
            'codec'			=> {'name' => '-c', 'values' => {'jpeg' => 'jpegdec'}},
            'output_color_space' => {'name' => '--oColorSpace','values'=> {'422p'=>'4', 'default' =>'1', '420p'=> '5', '422i'=> '1', '444p'=>'3', 'gray'=>'6'}},
          })
          
          @speech_encode_params = @base_params.merge({
            'codec'			=> {'name' => '-c', 'values' => {'g711' => 'g711enc'}},
            'num_of_frames'	=> {'name' => '-n', 'values' => ''},
            'companding' => {'name' => '--compandinglaw', 'values' => (Hash.new(){|h,k| h[k] = k}).merge({'linear' => 'lin'})},
            'start_frame' => {'name' => '--startframe', 'values' => ''}
          })
          
          @speech_decode_params = @base_params.merge({
            'codec'			=> {'name' => '-c', 'values' => {'g711' => 'g711dec'}},
            'num_of_frames'	=> {'name' => '-n', 'values' => ''},
            'companding' => {'name' => '--compandinglaw', 'values' => (Hash.new(){|h,k| h[k] = k}).merge({'linear' => 'lin'})},
            'start_frame' => {'name' => '--startframe', 'values' => ''}
          })
          
          @speech_decode1_params = @speech_decode_params.merge({'ouput_file' => nil})
          
          @video_display_params = {
            'command_name'			=> nil,
            'standard' => {'name' => '-y', 'values' => {'525' => '1', '625' => '2', '480p60' => '3', '576p50' => '4', '720p60' => '5', '720p50' => '6', '1080i30' => '7', '1080i25' => '8', '1080p30' => '9', '1080p25' => '10', '1080p24' => '11', 'vga' => '12', '1080p60' => '13', '1080p50' => '14'}}, 
            'output' => {'name' => '-O', 'values' => ''},
            'benchmark' => {'name' => '--benchmark', 'values' => ''},
            'num_of_frames' => {'name' => '-n', 'values' => ''},
          }
          
          @video_multi_chan_encode_params = @video_encode_params.merge({
            'num_of_channels' => {'name' => '-C', 'values' => ''},
          })
          
          @video_loopback_copy_params = {
            'command_name'   => nil,
            'use_accelerator' => {'name' => '-a', 'values' => Hash.new(){|h,k| h[k] = ''}},
            'output_position' => {'name' => '--position', 'values' => ''},
            'resolution' => {'name' => '-r', 'values' => ''},
            'input_position' => {'name' => '--input_position' , 'values' => ''},
            'enable_smooth' => {'name' => '--smooth' , 'values' => {'yes' => ''}},
            'crop' => {'name' => '--crop', 'values' => Hash.new(){|h,k| h[k] = ''}},
            'benchmark' => {'name' => '--benchmark', 'values' => ''},
            'display_output' => {'name' => '-O', 'values' => Hash.new(){|h,k| h[k] = k}},
            'display_standard' => {'name' => '--display_standard', 'values' => {'fbdev' => '1', 'v4l2' => '2'}},
            #'display_device' => {'name' => '--display_device', 'values' => ''},
            'display_num_buff' => {'name' => '--display_num_bufs' , 'values' => ''},
            'num_of_frames' => {'name' => '-n', 'values' => ''}
          }
          
          @video_loopback_params = {
            'command_name'   => nil,
            'benchmark' => {'name' => '--benchmark', 'values' => ''},
            'display_output' => {'name' => '-O', 'values' => Hash.new(){|h,k| h[k] = k}},
            'num_of_frames' => {'name' => '-n', 'values' => ''}
          }
          
          @video_loopback_resize_params = {
            'command_name' => nil,
            'benchmark' => {'name' => '--benchmark', 'values' => ''},
            'display_standard' => {'name' => '-y', 'values' => {'525' => '1', '625' => '2', '480p60' => '3', '576p50' => '4', '720p60' => '5', '720p50' => '6', '1080i30' => '7', '1080i25' => '8'}}, 
            'display_output' => {'name' => '-O', 'values' => ''},
            'capture_ualloc' => {'name' => '', 'values' => {'yes' => '--capture_ualloc', 'no' => ''}},
            'display_ualloc' => {'name' => '', 'values' => {'yes' => '--display_ualloc', 'no' => ''}},
            'output_position' => {'name' => '--position', 'values' => ''},
            'output_resolution' => {'name' => '-r', 'values' => ''},
            'input_position' => {'name' => '--input_position' , 'values' => ''},
            'input_resolution' => {'name' => '--input_resolution' , 'values' => ''},
            'crop' => {'name' => '', 'values' => {'yes' => '--crop', 'no' => ''}},
            'num_of_frames' => {'name' => '-n', 'values' => ''}
          }
          
          @audio_encode1_params = {
            'command_name' => nil,
            'codec'        => {'name' => '-c', 'values' => {'aac' => 'aacheenc'}},
            'bit_rate'     => {'name' => '-b', 'values' => ''},
            'samplerate'   => {'name' => '-s', 'values' => ''},
            'audio_input'  => {'name' => '--soundinput', 'values' => {'mic' => 'mic', 'line-in' => 'linein'}},
            'output_file' => {'name'=> '-o','values' => ''},
            'num_of_frames'	=> {'name' => '-n', 'values' => ''},
            'start_frame' => {'name' => '--startframe', 'values' => ''}
          }
          
          @audio_decode1_params = {
            'command_name' => nil,
            'codec'			=> {'name' => '-c', 'values' => {'aac' => 'aachedec'}},
            'input_file'			=> {'name' => '-i', 'values' => ''},
            'cache'     => {'name' => '--cache', 'values' => ''},
            'engine'    => {'name' => '-e', 'values' => ''},
            'num_of_frames'	=> {'name' => '-n', 'values' => ''},
            'start_frame' => {'name' => '--startframe', 'values' => ''}
          }
          
          @speech_encode1_params = @speech_encode_params.merge({'audio_input'  => {'name' => '--soundinput', 'values' => {'mic' => 'mic', 'line-in' => 'linein'}}})
          
          @video_loopback_blend_params = {
            'command_name'   => nil,
            'display_output' => {'name' => '-O', 'values' => Hash.new(){|h,k| h[k] = k}},
            'in_place' => {'name' => '', 'values' => {'yes' => '--in_place', 'no' => ''}},
            'output_position' => {'name' => '--position', 'values' => ''},
            'resolution' => {'name' => '-r', 'values' => ''},
            'input_position' => {'name' => '--input_position' , 'values' => ''},
            'benchmark' => {'name' => '--benchmark', 'values' => ''},
            'num_of_frames' => {'name' => '-n', 'values' => ''},
            'bitmap_position' => {'name' => '--bitmap_position', 'values' => ''},
            'bitmap_resolution' => {'name' => '--bitmap_resolution', 'values' => ''},
          }
          
          @video_loopback_convert_params = {
            'display_output' => {'name' => '-O', 'values' => ''},
            'capture_ualloc' => {'name' => '', 'values' => {'yes' => '--capture_ualloc', 'no' => ''}},
            'display_ualloc' => {'name' => '', 'values' => {'yes' => '--display_ualloc', 'no' => ''}},
            'input_accel' => {'name' => '', 'values' => {'yes' => '--ccvin_accel', 'no' => ''}},
            'output_accel' => {'name' => '', 'values' => {'yes' => '--ccvout_accel', 'no' => ''}},
            'num_of_frames' => {'name' => '-n', 'values' => ''},
            'output_position' => {'name' => '--position', 'values' => ''},
            'resolution' => {'name' => '-r', 'values' => ''},
            'input_position' => {'name' => '--input_position', 'values' => ''},
          }
          
          super(platform_info, log_path)  
        end
        
        def wait_for_threads(timeout=1200)
          puts "\n---> Wait for threads is going to wait #{timeout} seconds\n"
          status = Timeout::timeout(timeout) {
              while (@active_threads!=0) do
                 puts "Waiting for threads. #{@active_threads} active threads"
                  sleep 5
              end
          }
          rescue Timeout::Error => e
          log_error("Timeout waiting for Threads to complete")
          raise
        end
        
        def connect(params)
          super(params)
          send_cmd("echo 3 > /proc/sys/kernel/printk",@prompt)
          send_cmd("cd #{@executable_path}/dmai")
          send_cmd("./#{@load_modules}")
          send_cmd("cat /dev/zero > /dev/fb2")
        end
        
        def send_cmd(command, expected_match=/.*/, timeout=10)
          @is_timeout = false
          listener = DvsdkHandlers::DvsdkLinuxBaseListener.new(command, expected_match)
          add_listener(listener)
          super(command)
          status = Timeout::timeout(timeout) {
              while (!listener.match) 
                  sleep 3
              end
          }
          rescue Timeout::Error => e
            log_error("dmai send cmd On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s)
            @is_timeout = true
        	ensure
              @response = listener.response_buffer
            	remove_listener(listener)
      	end
        
        def video_encode(params)
           @thread_lists << exec_func(params.merge({"function" => "video_encode"}))
           wait_for_threads(params["timeout"].to_i+20)
        end
        
        def video_decode(params)
          @thread_lists << exec_func(params.merge({"function" => "video_decode"}))
          wait_for_threads(params["timeout"].to_i)
        end
        
        def video_decode1(params)
          @thread_lists << exec_func(params.merge({"function" => "video_decode1"}))
          wait_for_threads(params["timeout"].to_i)
        end
		
        def audio_encode(params)
           @thread_lists << exec_func(params.merge({"function" => "audio_encode"}))
           wait_for_threads(params["timeout"].to_i)
        end
        
        def audio_encode1(params)
           @thread_lists << exec_func(params.merge({"function" => "audio_encode1"}))
           wait_for_threads(params["timeout"].to_i)
        end
        
        def audio_decode(params)
          @thread_lists << exec_func(params.merge({"function" => "audio_decode"}))
          wait_for_threads(params["timeout"].to_i)
        end
        
        def audio_decode1(params)
          @thread_lists << exec_func(params.merge({"function" => "audio_decode1"}))
          wait_for_threads(params["timeout"].to_i)
        end
		
        def image_encode(params)
          @thread_lists << exec_func(params.merge({"function" => "image_encode"}))
          wait_for_threads
        end
        
        def image_decode(params)      
          @thread_lists << exec_func(params.merge({"function" => "image_decode"}))
          wait_for_threads
        end
        
        def speech_encode(params)
          @thread_lists << exec_func(params.merge({"function" => "speech_encode"}))
          wait_for_threads(params["timeout"].to_i)
        end
        
        def speech_encode1(params)
          @thread_lists << exec_func(params.merge({"function" => "speech_encode1"}))
        end
        
        def speech_decode(params) 
          @thread_lists << exec_func(params.merge({"function" => "speech_decode"}))
          wait_for_threads(params["timeout"].to_i)
        end
        
        def speech_decode1(params) 
          @thread_lists << exec_func(params.merge({"function" => "speech_decode1"}))
          wait_for_threads(params["timeout"].to_i)
        end
        
        def video_display(params)      
          @thread_lists << exec_func(params.merge({"function" => "video_display", 'threadId' => @prompt}))
          wait_for_threads
        end
        
        def video_loopback(params)      
          @thread_lists << exec_func(params.merge({"function" => "video_loopback", 'threadId' => @prompt}))
          wait_for_threads(params["timeout"].to_i)
        end
        
        def video_loopback_copy(params)      
          @thread_lists << exec_func(params.merge({"function" => "video_loopback_copy", 'threadId' => @prompt}))
        end
        
        def video_loopback_resize(params)      
          @thread_lists << exec_func(params.merge({"function" => "video_loopback_resize", 'threadId' => @prompt}))
          wait_for_threads(params["timeout"].to_i)
        end

        def video_loopback_blend(params)
          @thread_lists << exec_func(params.merge({"function" => "video_loopback_blend", 'threadId' => @prompt}))
          wait_for_threads(params["timeout"].to_i)
        end
        
        def video_loopback_convert(params)
          @thread_lists << exec_func(params.merge({"function" => "video_loopback_convert", 'threadId' => @prompt}))
          wait_for_threads(params["timeout"].to_i)
        end

        private
        def translate_params(params)
          command=''
          if params.kind_of?(Hash) 
              params_name = self.instance_variable_get("@#{params['function']}_params")
              command = "./#{params_name['command_name']} "
              params.each {|key,value| 
                  if params[key] && params_name[key] && value.to_s.strip.downcase != 'default' && value.to_s.strip.downcase != 'no'
                      param_value = params_name[key]['values'].kind_of?(Hash) ? "#{params_name[key]['values'][value]}" : key.include?("_file") ? File.basename(value) : value 
                      command += "#{params_name[key]['name']} #{param_value} "
                  end 
              }
          elsif params.kind_of?(String)
            command = params
          else
              raise "Invalid parameters passed to function: #{params.to_s}"
          end
          command
        end
		
        def exec_func(exec_params)
          dmai_dir = "#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\dmai\\"
          params = {'threadId' => /End of application\./}.merge(exec_params)
          time_to_wait = params.has_key?("timeout")? params["timeout"].to_i : 10  
          command = translate_params(params)
          FileUtils.cp(params['input_file'], "#{dmai_dir}#{File.basename(params['input_file'])}") if params["input_file"] && (File.size(params["input_file"]) != File.size?("#{dmai_dir}#{File.basename(params['input_file'])}"))
          t = Thread.new {
            Thread.critical = true
            @active_threads += 1
            puts "\n\n*********** Started new thread for #{command} waiting for #{params["threadId"]}"
            Thread.critical = false
            send_cmd(command,/#{params["threadId"]}/m,time_to_wait)
            sleep 5
            if params["output_file"]  && File.exists?("#{dmai_dir}#{File.basename(params['output_file'])}")
              FileUtils.cp("#{dmai_dir}#{File.basename(params['output_file'])}", params["output_file"])
              FileUtils.rm("#{dmai_dir}#{File.basename(params['output_file'])}")
            end
            if params["input_file"] 
              #FileUtils.rm("#{dmai_dir}#{File.basename(params['input_file'])}") #Uncomment this line if copying the file everytime is desired
            end
            Thread.critical = true
            @active_threads -= 1
            puts "\n\n*********** Thread for #{command} completed"
            Thread.critical = false
          }		
        end  
        
        def convert_420sp_to_420p(in_file, out_file, resolution, num_frames)
          input_file = File.new(in_file,"rb")
          output_file = File.new(out_file,"wb")
          width = resolution.split('x')[0].to_i
          height = resolution.split('x')[1].to_i
          0.upto(num_frames-1) do |i|
            #puts 'frame '+i.to_s
            u = []
            v = []
            y = input_file.read(width*height)
            u_v = input_file.read(width*height/2)
            break if y == nil || u_v == nil
            0.upto(width*height/4 - 1) do |a|
                u << u_v[a*2].chr
                v << u_v[a*2+1].chr
            end
            output_file.write(y)
            output_file.write(u)
            output_file.write(v)
          end
          ensure
            input_file.close
            output_file.close
        end
    end
end