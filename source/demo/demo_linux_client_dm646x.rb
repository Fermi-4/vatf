require 'net/telnet'
require 'rubygems'
require 'fileutils'
require File.dirname(__FILE__)+'/../target/lsp_target_controller'
require File.dirname(__FILE__)+'/demo_default_client'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module DemoHandlers
    class DemoLinuxClientDM646x < DemoHandlers::DemoDefaultClient
        
        def initialize(platform_info, log_path = nil)
            @active_threads = 0
            @thread_lists = Array.new
            super(platform_info)
            @encode_params = {
                'command_name'			=> 'encode',
                'speech_file' 			=> {'name' => '-s', 'values' => ''},
                'audio_file' 			=> {'name' => '-a', 'values' => ''},
                'video_file'			=> {'name' => '-v', 'values' => ''},
                'video_resolution'		=> {'name' => '-r', 'values' => ''},
                'video_bitrate'		 	=> {'name' => '-b', 'values' => ''},
                'audio_bitrate'		 	=> {'name' => '-p', 'values' => ''},
                'audio_samplerate'		=> {'name' => '-u', 'values' => ''},		
                #'video_signal_format'	=> {'name' => '-y', 'values' => {'525' => '1', '625' => '2'}},
                #'display_out'			=> {'name' => '-O', 'values' => {'composite' => 'composite', 'component' => 'component', 'svideo' => 's-video'}},
                'time'					=> {'name' => '-t', 'values' => ''},
                'audio_input'			=> {'name' => '', 'values' => {'line_in' => '-l', 'mic' => ''}},
                #'disable_deinterlace'	=> {'name' => '', 'values' => {'yes' => '-d', 'no' => ''}},
                'enable_osd'			=> {'name' => '', 'values' => {'yes' => '-o', 'no' => ''}},
                'enable_keyboard'		=> {'name' => '', 'values' => {'yes' => '-k', 'no' => ''}},
                'enable_remote'			=> {'name' => '', 'values' => {'yes' => '-i', 'no' => ''}},
                #'video_input'			=> {'name' => '', 'values' => {'composite' => '', 'svideo' => '-x'}},
            }
=begin
            @multi_encode_params = {
                'command_name'			=> 'multiencode',
                'speech_file' 			=> {'name' => '-s', 'values' => ''},
                'video_file'			=> {'name' => '-v', 'values' => ''},
                'image_file'			=> {'name' => '-j', 'values' => ''},
                'image_resolution'		=> {'name' => '-m', 'values' => ''},
                'image_qvalue'			=> {'name' => '-q', 'values' => ''},
                'video_resolution'		=> {'name' => '-r', 'values' => ''},
                'video_bitrate'		 	=> {'name' => '-b', 'values' => ''},
                'video_signal_format'	=> {'name' => '-y', 'values' => {'525' => '1', '625' => '2'}},
                'display_out'			=> {'name' => '-O', 'values' => {'composite' => 'composite', 'component' => 'component', 'svideo' => 's-video'}},
                'time'					=> {'name' => '-t', 'values' => ''},
                'audio_input'			=> {'name' => '', 'values' => {'line_in' => '-l', 'mic' => ''}},
                'disable_deinterlace'	=> {'name' => '', 'values' => {'yes' => '-d', 'no' => ''}},
                'enable_osd'			=> {'name' => '', 'values' => {'yes' => '-o', 'no' => ''}},
                'enable_keyboard'		=> {'name' => '', 'values' => {'yes' => '-k', 'no' => ''}},
                'enable_remote'			=> {'name' => '', 'values' => {'yes' => '-i', 'no' => ''}},
                'video_input'			=> {'name' => '', 'values' => {'composite' => '', 'svideo' => '-x'}},
            }
=end
            @decode_params = {
                'command_name'			=> 'decode',
                'audio_file' 			=> {'name' => '-a', 'values' => ''},
                'speech_file'			=> {'name' => '-s', 'values' => ''},
                'video_file'			=> {'name' => '-v', 'values' => ''},
                'video_signal_format'	=> {'name' => '-y', 'values' => {'525' => '1', '625' => '2', '720p60' => '3', '720p50' => '4', '1080i60' => '5', '1080i50' => '6'}},
                'display_out'			=> {'name' => '-O', 'values' => {'composite' => 'composite', 'component' => 'component', 'svideo' => 's-video'}},
                'time'					=> {'name' => '-t', 'values' => ''},
                'enable_osd'			=> {'name' => '', 'values' => {'yes' => '-o', 'no' => ''}},
                'loop'					=> {'name' => '', 'values' => {'yes' => '-l', 'no' => ''}},
                'enable_frameskip'		=> {'name' => '', 'values' => {'yes' => '-f', 'no' => ''}},
                'enable_keyboard'		=> {'name' => '', 'values' => {'yes' => '-k', 'no' => ''}},
                'enable_remote'			=> {'name' => '', 'values' => {'yes' => '-i', 'no' => ''}},
            }
            @encode_decode_params = {
                'command_name'			=> 'encodedecode',
                'video_resolution'		=> {'name' => '-r', 'values' => ''},
                'video_bitrate' 		=> {'name' => '-b', 'values' => ''},
                'video_signal_format'	=> {'name' => '-y', 'values' => {'525' => '1', '625' => '2', '720p60' => '3', '720p50' => '4'}},
                'display_out'			=> {'name' => '-O', 'values' => {'composite' => 'composite', 'component' => 'component', 'svideo' => 's-video'}},
                'time'					=> {'name' => '-t', 'values' => ''},
                #'disable_deinterlace'	=> {'name' => '', 'values' => {'yes' => '-d', 'no' => ''}},
                'passthrough'			=> {'name' => '', 'values' => {'yes' => '-p', 'no' => ''}},
                'enable_osd'			=> {'name' => '', 'values' => {'yes' => '-o', 'no' => ''}},
                'enable_keyboard'		=> {'name' => '', 'values' => {'yes' => '-k', 'no' => ''}},
                'enable_remote'			=> {'name' => '', 'values' => {'yes' => '-i', 'no' => ''}},
                #'video_input'			=> {'name' => '', 'values' => {'composite' => '', 'svideo' => '-x'}},
            }
            @target = LspTargetHandlers::LspTargetController.new(platform_info, log_path)
            connect
        end
        
        def connect
            @target.send_cmd("cd #{@target.executable_path}",@target.prompt)
        #    @target.send_cmd("./loadmodules.sh", @target.prompt) 	
        end
    
        def disconnect
            @target.disconnect
        end

        def start_logger(log_path)
            @target.start_logger(log_path)
        end
        
        def stop_logger
            @target.stop_logger
        end
        
        def wait_for_threads(timeout=120)
            status = Timeout::timeout(timeout) {
                while (@active_threads>0) do
                    puts "Waiting for threads. #{@active_threads} active threads"
                    sleep 1
                end
            }
            @thread_lists.each {|th|
                th.join
            }
            rescue Timeout::Error => e
        		@target.log_error("Timeout waiting for Threads to complete")
        		raise
        end
        
        def set_max_number_of_sockets(video_num_sockets,audio_num_sockets,params=nil)
            # TODO
        end
        
        # Demo-Dependant Methods
  		def encode(params)
            @thread_lists << exec_func(params.merge({"function" => "encode"}))
        end
        
        def decode(params)
			@thread_lists << exec_func(params.merge({"function" => "decode"}))
        end

        def encode_decode(params)
          	@thread_lists << exec_func(params.merge({"function" => "encode_decode"}))
        end
        
        private
        def translate_params(params)
            command=''
            if params.kind_of?(Hash) 
                params_name = self.instance_variable_get("@#{params['function']}_params")
                command = "./#{params_name['command_name']} "
                params.each {|key,value| 
                    if params_name[key]
                        next if ((key.include?("_file")) && (!value or params['passthrough'] == 'yes')) # Do not add switches to the command if video or audio are disable or passthrough enable
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
		
        def exec_func(params)
            module_name = params["function"] == 'multi_encode'? 'loadmodules_multiencode.sh' : 'loadmodules.sh'
            @target.send_cmd("rmmod dsplinkk", @target.prompt)
            @target.send_cmd("rmmod cmemk", @target.prompt)
            @target.send_cmd("./#{module_name}", @target.prompt)
            command = translate_params(params)
            time = params.has_key?('time')? params['time'].to_i+30 : 40 
            if params["speech_file"] && params["function"] == 'decode'
        		FileUtils.cp(params['speech_file'], "#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['speech_file'])}")
    		end
    		if params["audio_file"] && params["function"] == 'decode'
        		FileUtils.cp(params['audio_file'], "#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['audio_file'])}")
    		end
    		if params["video_file"] && params["function"] == 'decode'
        		FileUtils.cp(params['video_file'], "#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['video_file'])}")
    		end
            t = Thread.new {
                begin
                    Thread.critical = true
                    @active_threads += 1
                    puts "\n\n*********** Started new thread for #{command}"
                    Thread.critical = false
            	    @target.send_cmd(command,@target.prompt,time)
            	    if params["speech_file"] && (params["function"] == 'encode' || params["function"] == 'multi_encode')
                        FileUtils.cp("#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['speech_file'])}", params["speech_file"])
                        FileUtils.rm("#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['speech_file'])}")
                    end
                    if params["audio_file"] && (params["function"] == 'encode' || params["function"] == 'multi_encode')
                        FileUtils.cp("#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['audio_file'])}", params["audio_file"])
                        FileUtils.rm("#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['audio_file'])}")
                    end
                    if params["video_file"] && (params["function"] == 'encode' || params["function"] == 'multi_encode')
                        FileUtils.cp("#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['video_file'])}", params["video_file"])
                        FileUtils.rm("#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['video_file'])}")
                    end
                    if params["image_file"] && (params["function"] == 'encode' || params["function"] == 'multi_encode')
                        FileUtils.cp_r("#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['image_file'])}", params["image_file"])
                        FileUtils.rm_r("#{@target.samba_root_path}#{@target.executable_path.gsub(/\//,'\\')}\\#{File.basename(params['image_file'])}")
                    end
                	rescue Exception => e
                        @target.log_error(e.to_s)
                        raise
                    ensure
                        Thread.critical = true
                        @active_threads -= 1
                        puts "\n\n*********** Thread for #{command} completed"
                        Thread.critical = false
                        
                end
                
            }
        end  
    end
end


      




