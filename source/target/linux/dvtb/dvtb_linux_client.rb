require File.dirname(__FILE__)+'/../dvsdk_linux_base_client'
require 'fileutils'

module DvtbHandlers  
        
    class DvtbLinuxClient < DvsdkHandlers::DvsdkLinuxBaseClient
        def initialize(platform_info, log_path = nil)
          @active_threads = 0
          @thread_lists = Array.new
          @dvtb_class = {
              'audio' 	=> 'audio',
              'vpfe' 		=> 'vpfe',
              'vpbe' 		=> 'vpbe',
              'engine' 	=> 'engine',
              'viddec' 	=> 'viddec',
              'videnc' 	=> 'videnc',
              'auddec' 	=> 'auddec',
              'audenc' 	=> 'audenc',
              'sphdec' 	=> 'sphdec',
              'sphenc' 	=> 'sphenc',
              'imgdec' 	=> 'imgdec',
              'imgenc' 	=> 'imgenc',
          }
          super(platform_info, log_path)  
        end

        def get_param(params)
          if params.kind_of?(Hash) && @dvtb_class.has_key?(params['Class']) && (@dvtb_param[params['Class']].has_key?(params['Param']) || @dvtb_param[params['Class']][params['Param']].to_s.strip == '' )
            string = @dvtb_class[params['Class']]+' '+@dvtb_param[params['Class']][params['Param']].to_s  
          elsif params.kind_of?(String)
            string = params
          else
              log_warning("#{params['Param']} Parameter on #{params['Class']} Class is Not Supported on this release")
              return 0
          end
          send_cmd("getp "+string)
        end

        def set_param(params)
          if params.kind_of?(Hash) && @dvtb_class.has_key?(params['Class']) &&  @dvtb_param[params['Class']].has_key?(params['Param'])
            string = @dvtb_class[params['Class']]+' '+@dvtb_param[params['Class']][params['Param']].to_s+' '+translate_value(params)   
          elsif params.kind_of?(String)
            string = params
          else
              log_warning("#{params['Param']} Parameter on #{params['Class']} Class is Not Supported on this release")
              return 0
          end
          send_cmd("setp "+string, /PASS:\s*setp/m,10)
        end
  
        def disconnect
          send_cmd("exit",@prompt)
          super()
        end
        
        def set_max_number_of_sockets(video_num_sockets,audio_num_sockets,params=nil)
            # Does nothing by default. Only used by DLL DVTB client (Kailash)
        end
        
        # DVTB-Server-Dependant Methods
  
        def video_decoding(params)
            raise "Method NOT Supported"
        end

        def video_encoding(params)
            raise "Method NOT Supported"
        end

        def audio_encoding(params)
            raise "Method NOT Supported"
        end

        def audio_decoding(params)
            raise "Method NOT Supported"
        end

        def speech_decoding(params)
            raise "Method NOT Supported"
        end

        def speech_encoding(params)
            raise "Method NOT Supported"
        end
	
        def image_decoding(params)
            raise "Method NOT Supported"
        end

        def image_encoding(params)
            raise "Method NOT Supported"
        end
		   
        def video_encoding_decoding(params = nil)
            raise "Method NOT Supported"
        end
        
        def audio_encoding_decoding(params = nil)
            raise "Method NOT Supported"
        end

        def speech_encoding_decoding(params = nil)
            raise "Method NOT Supported"
        end
	
        def image_encoding_decoding(params = nil)
            raise "Method NOT Supported"
        end
		
        def video_loopback(params = nil)
            raise "Method NOT Supported"
        end
	
        def video_capture(params)
            raise "Method NOT Supported"
        end
	
        def video_play(params)
            raise "Method NOT Supported"
        end
        
        def audio_loopback(params = nil)
            raise "Method NOT Supported"
        end
        
        def audio_capture(params)
            raise "Method NOT Supported"
        end

        def audio_play(params)
            raise "Method NOT Supported"
        end
        
        def speech_capture(params)
            raise "Method NOT Supported"
        end

        def speech_play(params)
            raise "Method NOT Supported"
        end
        
        def speech_loopback(params)
            raise "Method NOT Supported"
        end
        
        def h264ext_encoding_decoding(params = nil)
            raise "Method NOT Supported"
        end
        
        def h264ext_encoding(params)
            raise "Method NOT Supported"
        end
        
        def mpeg4ext_encoding_decoding(params = nil)
            raise "Method NOT Supported"
        end
        
        def mpeg4ext_encoding(params)
            raise "Method NOT Supported"
        end
        
        def aacext_encoding(params)
            raise "Method NOT Supported"
        end
        
        def get_xdm_data_format(format)
          case format
            when 'byte' then '1'
            when 'le_16' then '2'
            when 'le_32' then '3'
            when 'le_64' then '4'
            when 'be_16' then '5'
            when 'be_32' then '6'
            when 'be_64' then '7'
            else format
          end
        end
        
        def get_audio_alsa_data_dormat(format)
            case format 
            	when 'byte' then '0'
                when 'le_16' then '2'
                when 'le_32' then '10'
                when 'le_64' then '16'
                when 'be_16' then '3'
                when 'be_32' then '11'
                when 'be_64' then '17'
                else format
        	end
        end
        
        def get_xdm_chroma_format(format)
          case format 
        	when '422i','default' then '4'
            when '420p' then '1'
            when '422p' then '2'
            when '422i_be' then '3'
            when '444p' then '5'
            when '411p' then '6'
            when 'gray' then '7'
            when 'rgb'  then '8'
            when '420sp' then '9'
            when 'na' then '-1'
            else format
        	end
        end
        
        def get_skip_mode(mode)
            case mode 
            	when 'no_skip' then '0'
				when 'skip_p' then '1' 
				when 'skip_i' then '3'
				when 'skip_b' then '2'
				when 'skip_ip' then '4'
				when 'skip_ib' then '5'
				when 'skip_pb' then '6'
				when 'skip_ipb' then '7'
				when 'skip_idr' then '8'
                else mode
        	end
        end
        
        def get_speech_companding(companding)
            case companding
    		    when 'linear' then '0'
			    when 'alaw' then '1'
			    when 'ulaw' then '2'
				else companding
            end
        end
        
        def get_video_content_type(type)
            case type 
                when 'progressive' then '0'    # Progressive frame. */
                when 'interlaced' then '1' 	# Interlaced frame. */
                when 'top_field' then '2'    	# Interlaced picture, top field. */
                when 'bottom_field' then '3'   # Interlaced picture, bottom field.
                else type
            end
        end
        
        def get_video_frame_type(type)
          case type.strip.downcase
            when 'na' then ' -1'
            when 'i' then ' 0'
            when 'p' then ' 1'
            when 'b' then ' 2'
            when 'idr' then ' 3'
            when 'ii' then ' 4'
            when 'ip' then ' 5'
            when 'ib' then ' 6'
            when 'pi' then ' 7'
            when 'pp' then ' 8'
            when 'pb' then ' 9'
            when 'bi' then ' 10'
            when 'bp' then ' 11'
            when 'bb' then ' 12'
            when 'mbaff_i' then ' 13'
            when 'mbaff_p' then ' 14'
            when 'mbaff_b' then ' 15'
            when 'mbaff_idr' then ' 16'
            else type
          end
        end
        
        def get_audio_type(audio)
            case audio 
            	# Uncomment below and comment out current for 0.9 XDM audio support
                #when 'mono' then '0'        	#< Single channel. */
                #when 'stereo' then '1'      	#< Two channel. */
                #when '3.0' then '2'  			#< Three channel. */
                #when '5.0' then '3'   		#< Five channel. */
                #when '5.1' then '4'    		#< 5.1 channel. */
                #when '7.1' then '5'    		#< 7.1 channel. */
				when 'mono' then '0'        	#< Mono. */
    			when 'stereo' then '1'      	#< Stereo. */
    			when 'dualmono' then '2'       #< Dual Mono.
                when '3.0' then '3'  			#< Left, Right, Center. */
                when '2.1' then '4'         #< Left, Right, Sur. */
                when '3.1' then '5'         #< Left, Right, Center, Sur. */
                when '2.2' then '6'         #< Left, Right, SurL, SurR. */
                when '3.2' then '7'         #< Left, Right, Center, SurL, SurR. */
                when '2.3' then '8'         #< Left, Right, SurL, SurR, surC. */
                when '3.3' then '9'         #< Left, Right, Center, SurL, SurR, surC. */
                when '3.4' then '10'        #< Left, Right, Center, SurL, SurR, sideL, sideR.
                else audio
			end
        end
        
        def get_audio_channels(audio)
            case audio
            	when 'mono' then '1'        	#< Mono. */
    			when 'stereo', 'dualmono' then '2'      	#< Stereo. */ ; #< Dual Mono. 
                when '3.0', '2.1' then '3'  			#< Left, Right, Center. */;  #< Left, Right, Sur. */      
                when '3.1', '2.2' then '4'         #< Left, Right, Center, Sur. */ ; #< Left, Right, SurL, SurR. */         
                when '3.2' , '2.3' then '5'         #< Left, Right, Center, SurL, SurR. */ ; #< Left, Right, SurL, SurR, surC. */         
                when '3.3' , '3.4' then '6'         #< Left, Right, Center, SurL, SurR, surC. */ ; #< Left, Right, Center, SurL, SurR, sideL, sideR.       
                else audio
            end
        end
        
        def get_audio_device_mode(mode)
            mode.downcase.include?('blocking') ? '0' : '1'
        end
        
        def get_video_display_order(order)
            order.downcase.include?('display') ? '0' : '1'
        end
        
        def get_audio_data_format(format)
            format.include?('interleaved') ? '1' : '0'
        end
        
        def get_rate_control_preset(preset)
            case preset
                when 'cbr' then '1'   			#IVIDEO_LOW_DELAY    /**< CBR rate control for video conferencing. */
                when 'vbr' then '2'	  		#IVIDEO_STORAGE      /**< VBR rate control for local storage (DVD)
                when 'two_pass' then '3' 		#IVIDEO_TWOPASS      /**< Two pass rate control for non real time
                when 'none'	then '4'  			#IVIDEO_NONE         /**< No configurable video rate control
                when 'user_defined' then '5' 	#IVIDEO_USER_DEFINED /**< User defined configuration using extended
                when 'vbr_rate_fix' then '6'
                else preset
            end	
        end
        
        def get_encoder_preset(preset)
            case preset
                when 'default' then '0' 		#XDM_DEFAULT        /**< Default setting of encoder.  See
                when 'high_quality' then '1'	#XDM_HIGH_QUALITY   /**< High quality encoding. */
    		    when 'high_speed' then '2'		#XDM_HIGH_SPEED     /**< High speed encoding. */
    		    when 'user_defined' then '3'	#XDM_USER_DEFINED   /**< User defined configuration, using
                else preset
            end
        end
        
        def get_h264_profile(profile)
            case profile.downcase.strip
            	when 'baseline' then '66'
            	when 'main' then '77'
            	when 'extended' then '88'
                when 'high' then '100'
                when 'high_10', 'high_10_intra' then '110'
                when 'high_422', 'high_422_intra' then '122'
                when 'high_444_pred', 'high_444_intra' then '244'
                when 'cavlc_444_intra' then '44'
        		else profile
        	end
        end
        
        def get_h264_rcalgo(algorithm)
            case algorithm
            	when 'dces_tm5' then '0'
            	when 'plr' then '1'
        		else algorithm
        	end
        end
        
        def get_h264_me_algo(algorithm)
          case algorithm
            when 'normal_full' then '0'
            when 'low_power' then '1'
            when 'hybrid' then '2'
            else algorithm
          end
        end
        
        def get_h264_scaling_type(type)
          case type
            when 'auto' then '0'
            when 'low' then '1'
            when 'moderate' then '2'
            when 'high' then '3'
            when 'disable' then '4'
            else type
          end
        end
        
        def get_mpeg4_rcalgo(algorithm)
            case algorithm
            	when 'disable' then '0'
            	when 'tm5' then '1'
            	when 'plr1' then '3'
            	when 'plr3' then '4'
            	when 'vbr'  then '7'
            	when 'plr4', 'default' then '8'
        		else algorithm
        	end
        end
        
        def get_mpeg4_enc_mode(mode)
          case mode.strip.downcase
            when 'h263' then '0'
            when 'mpeg4' then '1'
            else mode
        	end
        end
        
        def get_h264_entropy_coding(coding)
          case coding
            when 'cavlc' then '0'
            when 'cabac' then '1'
            else coding
        	end
        end
        
        def get_vpbe_standard(signal_format)
            case signal_format.strip.downcase
                when '625' then '4'
                when '525' then '1'
                when '1080i50', '1080i30' then '6' 
                when '720p50' then '5'
                when '720p60' then '3'
                when '1080i60', "1080i25" then '2'
                when '480p' then '7'
                when '576p' then '8'
                else signal_format 
            end
        end
        
        def get_vpfe_standard(signal_format)
            case signal_format.strip.downcase
                when '625' then '2'
                when '525' then '1'
                when 'secam' then ' 3' 
                else '0' 
            end
        end
        
        def get_video_driver_data_format(format)
            case format 
        		when '422i' then '1'
                when '420p' then '2'
                when '422p' then '3'
                when '410'  then '4'
                when 'rgb'  then '6'
                when '422sp' then '7'
                else format
        	end
        end
        
        def get_vpbe_iface_type(io_type)
            case io_type.strip.downcase
                when 'composite' then '1'
                when 'component' then '2'
                when 'svideo' then '3'
                else io_type 
            end
        end 
        
        def get_vpfe_iface_type(io_type)
            case io_type.strip.downcase
                when 'composite' then '0'
                when 'svideo' then '1'
                else io_type 
            end
        end
        
        def get_dual_mono_mode(mode)
            case mode.strip.to_s
            	when 'left' then '1'
            	when 'right' then '2'
            	when 'left_right' then '0'
            	when 'mix' then '3'
                else mode
        	end
        end
        
        def get_acc_encode_mode(mode)
            case mode.strip.to_s
            	when 'cbr' then '0'
            	when 'vbr' then '1'
            	else mode
        	end
        end
        
        def get_aac_bit_rate_mode(mode)
            case mode.strip.to_s
            	when 'vbr1' then '1'
            	when 'vbr2' then '2'
                when 'vbr3' then '3'
                when 'vbr4' then '4'
                when 'vbr5' then '5'
            	else mode
        	end
        end 
        
        def get_acc_output_object_type(type)
            case type.strip.to_s
            	when 'lc' then '2'
            	when 'heaac' then '5'
                when 'ps' then '29'
                else type
        	end
        end 
        
        def get_aac_file_format(format)
            case format.strip.to_s
            	when 'raw' then '0'
            	when 'adif' then '1'
                when 'adts' then '2'
                else format
        	end
        end
        
        def get_bits_per_sample(audio_type)
            audio_type.strip.downcase == 'stereo' ? '32' : '16'
        end
        
        def get_video_format_width(format)
            case format.strip.to_s
            	when /1080/ then '1920'
            	when '525', '625' then '720'
                when /720/ then '1280'
                else format
        	end
        end
        
        def get_video_format_height(format)
            case format.strip.to_s
            	when /1080/ then '1080'
            	when '525' then '480'
                when '625' then '576'
                when /720/ then '720'
                else format
        	end
        end
        
        def send_cmd(command, expected_match=/.*/, timeout=10)
          @is_timeout = false
          listener = DvsdkHandlers::DvsdkLinuxBaseListener.new(command, expected_match)
          add_listener(listener)
          super(command)
          status = Timeout::timeout(timeout) {
              while (!listener.match) 
                  sleep 0.5
              end
          }
          rescue Timeout::Error => e
            log_error("On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s)
            @is_timeout = true
          ensure
            @response = listener.response_buffer
            remove_listener(listener)
        end
        
        def wait_for_threads(timeout=180)
          puts "\n---> Wait for threads is going to wait #{timeout} seconds\n"
          status = Timeout::timeout(timeout) {
              while (@active_threads!=0) do
                  #puts "Waiting for threads. #{@active_threads} active threads"
                  sleep 2
              end
          }
          rescue Timeout::Error => e
          log_error("Timeout waiting for Threads to complete")
          raise
        end
        
        def exec_func(params)
          time_to_wait = params.has_key?("timeout")? params["timeout"].to_i : 180  
          command = "func "+params["function"]
          FileUtils.cp(params['Source'], "#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\dvtb\\#{File.basename(params['Source'])}") if params["Source"] && (File.size(params["Source"]) != File.size?("#{@samba_root_path}#{(@executable_path+'/dvtb').gsub(/\//,'\\')}\\#{File.basename(params['Source'])}"))
          command += " -s #{@executable_path}/dvtb/#{File.basename(params['Source'])}" if params["Source"]
          command += " -t #{@executable_path}/dvtb/#{File.basename(params['Target'])}" if params["Target"]
          command += ' ' + params['cmd_tail'] if params['cmd_tail']  
          threadId = params.has_key?("threadId") ? params["threadId"] : '.+'
          t = Thread.new {
              Thread.critical = true
              @active_threads += 1
              puts "\n\n*********** Started new thread for #{command}"
              Thread.critical = false
              send_cmd(command,/<#{threadId}>\s*[cC]losed/m,time_to_wait)
              sleep 5
              if params["Target"] 
                  FileUtils.cp("#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\dvtb\\#{File.basename(params['Target'])}", params["Target"])
                  FileUtils.rm("#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\dvtb\\#{File.basename(params['Target'])}")
              end
              Thread.critical = true
              @active_threads -= 1
              puts "\n\n*********** Thread for #{command} completed"
              Thread.critical = false
          }    
        end  
        
    end
end

