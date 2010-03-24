require File.dirname(__FILE__)+'/../dvsdk_linux_base_client'
require 'fileutils'

module DemoHandlers  
    class DemoLinuxClient < DvsdkHandlers::DvsdkLinuxBaseClient
      def initialize(platform_info, log_path = nil)
        @active_threads = 0
        @thread_lists = Array.new
        @encode_params = {}
        @decode_params = {}
        @encode_decode_params = {}  
        @load_modules = "loadmodules.sh" if !@load_modules       
        super(platform_info, log_path)  
        connect
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
        send_cmd("cd #{@executable_path}/demo")
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
                sleep 1
            end
        }
        rescue Timeout::Error => e
          log_error("dmai send cmd On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s)
          @is_timeout = true
        ensure
            @response = listener.response_buffer
            remove_listener(listener)
      end
        
      def set_max_number_of_sockets(video_num_sockets,audio_num_sockets,params=nil)
          # TODO
      end
        
      # Demo-Dependant Methods
      def encode(params)
        if params['video_bitrate'].strip.downcase == 'vbr'
          @encode_params['video_bitrate']  = {'name' => '', 'values' => {params['video_bitrate'] => ''}}
        else
          @encode_params['video_bitrate']  = {'name' => '-b', 'values' => ''}
        end
          exec_func(params.merge({"function" => "encode"}))
      end
    
      def decode(params)
        exec_func(params.merge({"function" => "decode"}))
      end

      def encode_decode(params)
        if params['video_bitrate'].strip.downcase == 'vbr'
          @encode_decode_params['video_bitrate']  = {'name' => '', 'values' => {params['video_bitrate'] => ''}}
        else
          @encode_decode_params['video_bitrate']  = {'name' => '-b', 'values' => ''}
        end
        exec_func(params.merge({"function" => "encode_decode"}))
      end
        
      def translate_params(params)
        command=''
        if params.kind_of?(Hash) 
            params_name = instance_variable_get("@#{params['function']}_params")
            command = "./#{params_name['command_name']} "
            params.each {|key,value| 
                if params_name[key]
                    next if key.include?("_file") && !value     # Do not add switches to the command if video or audio are disable
                    param_value = params_name[key]['values'].kind_of?(Hash) ? "#{params_name[key]['values'][value]}" : key.include?("_file") ? (!params['location'] || params['location'].strip.downcase == 'default' ? File.basename(value) : params['location'].sub(/(\\|\/)$/,'')+'/'+File.basename(value)) : value 
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
        # module_name = params["function"] == 'decode' ? 'loadmodules_hd.sh' : 'loadmodules_sd.sh'
        # send_cmd("./#{module_name}", @prompt)
        command = translate_params(params)
        time = params.has_key?('time')? params['time'].to_i+30 : 40 
        if params["speech_file"] && params["function"] == 'decode' 
          FileUtils.cp(params['speech_file'], "#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['speech_file'])}") if (File.size(params["speech_file"]) != File.size?("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['speech_file'])}"))
          send_cmd("cp -f #{@executable_path+'/demo/'+File.basename(params['speech_file'])} #{params['location']}", @prompt) if params['location'] && params['location'].strip.downcase != 'default' && !check_files(@executable_path+'/demo/'+File.basename(params['speech_file']), params['location'].sub(/\\|\/$/,'')+'/'+File.basename(params['speech_file']))
        end
        if params["audio_file"] && params["function"] == 'decode' 
          FileUtils.cp(params['audio_file'], "#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['audio_file'])}") if (File.size(params["audio_file"]) != File.size?("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['audio_file'])}"))
          send_cmd("cp -f #{@executable_path+'/demo/'+File.basename(params['audio_file'])} #{params['location']}", @prompt) if params['location'] && params['location'].strip.downcase != 'default' && !check_files(@executable_path+'/demo/'+File.basename(params['audio_file']), params['location'].sub(/\\|\/$/,'')+'/'+File.basename(params['audio_file']))
        end
        if params["video_file"] && params["function"] == 'decode'
          FileUtils.cp(params['video_file'], "#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['video_file'])}") if (File.size(params["video_file"]) != File.size?("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['video_file'])}"))
          send_cmd("cp -f #{@executable_path+'/demo/'+File.basename(params['video_file'])} #{params['location']}", @prompt) if params['location'] && params['location'].strip.downcase != 'default' && !check_files(@executable_path+'/demo/'+File.basename(params['video_file']), params['location'].sub(/\\|\/$/,'')+'/'+File.basename(params['video_file']))
        end
        t = Thread.new {
          begin
            Thread.critical = true
            @active_threads += 1
            puts "\n\n*********** Started new thread for #{command}"
            Thread.critical = false
            send_cmd(command,@prompt,time)
            if @is_timeout
              # send_cmd("\cZ",@prompt,5)
              # send_cmd("pkill -9 #{command.sub(/^\.\//,'').split(/ +/)[0]}",@prompt,5)
              raise "Timed-out waiting for #{command} response"
            end
            sleep 5
            if params["speech_file"] && (params["function"] == 'encode' || params["function"] == 'multi_encode')
              send_cmd("cp -f #{params['location'].gsub(/\\/,'/').sub(/\\|\/$/,'')+'/'+File.basename(params['speech_file'])} #{@executable_path+'/demo/'}", @prompt) if params['location'] && params['location'].strip.downcase != 'default'
              FileUtils.cp("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['speech_file'])}", params["speech_file"])
              FileUtils.rm("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['speech_file'])}")
            end
            if params["audio_file"] && (params["function"] == 'encode' || params["function"] == 'multi_encode')
              send_cmd("cp -f #{params['location'].gsub(/\\/,'/').sub(/\\|\/$/,'')+'/'+File.basename(params['audio_file'])} #{@executable_path+'/demo/'}", @prompt) if params['location'] && params['location'].strip.downcase != 'default'
              FileUtils.cp("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['audio_file'])}", params["audio_file"])
              FileUtils.rm("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['audio_file'])}")
            end
            if params["video_file"] && (params["function"] == 'encode' || params["function"] == 'multi_encode')
              send_cmd("cp -f #{params['location'].gsub(/\\/,'/').sub(/\\|\/$/,'')+'/'+File.basename(params['video_file'])} #{@executable_path+'/demo/'}", @prompt) if params['location'] && params['location'].strip.downcase != 'default'
              FileUtils.cp("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['video_file'])}", params["video_file"])
              FileUtils.rm("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['video_file'])}")
            end
            if params["image_file"] && (params["function"] == 'encode' || params["function"] == 'multi_encode')
              send_cmd("cp -f #{params['location'].gsub(/\\/,'/').sub(/\\|\/$/,'')+'/'+File.basename(params['image_file'])} #{@executable_path+'/demo/'}", @prompt) if params['location'] && params['location'].strip.downcase != 'default'
              FileUtils.cp_r("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['image_file'])}", params["image_file"])
              FileUtils.rm_r("#{@samba_root_path}#{(@executable_path+'/demo').gsub(/\//,'\\')}\\#{File.basename(params['image_file'])}")
            end
            rescue Exception => e
              log_error(e.to_s)
              raise
            ensure
              Thread.critical = true
              @active_threads -= 1
              puts "\n\n*********** Thread for #{command} completed"
              Thread.critical = false
          end 
        }
      end  
      
      def check_files(ref, dst)
        send_cmd('ls -s '+dst,@prompt)
        return false if @response.downcase.include?('no such file')
        dst_size = @response.match(/^\s*(\d+)\s+#{dst}/m).captures[0].to_i
        send_cmd('ls -s '+ref,@prompt)
        ref_size = @response.match(/^\s*(\d+)\s+#{ref}/m).captures[0].to_i
        dst_size == ref_size
        rescue Exception => e
          return false
      end
      
    end
end

