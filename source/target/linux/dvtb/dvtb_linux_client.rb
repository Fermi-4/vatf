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

        def connect
            raise "Method NOT Supported"
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
            when 'byte' : '1'
            when 'le_16' : '2'
            when 'le_32' : '3'
            when 'le_64' : '4'
            when 'be_16' : '5'
            when 'be_32' : '6'
            when 'be_64' : '7'
            else format
          end
        end
        
        def get_audio_alsa_data_dormat(format)
            case format 
            	when 'byte' : '0'
                when 'le_16' : '2'
                when 'le_32' : '10'
                when 'le_64' : '16'
                when 'be_16' : '3'
                when 'be_32' : '11'
                when 'be_64' : '17'
                else format
        	end
        end
        
        def get_xdm_chroma_format(format)
          case format 
        		when '422i','default' : '4'
            when '420p' : '1'
            when '422p' : '2'
            when '422i_be' : '3'
            when '444p' : '5'
            when '411p' : '6'
            when 'gray' : '7'
            when 'rgb'  : '8'
            when '420sp' : '9'
            else format
        	end
        end
        
        def get_skip_mode(mode)
            case mode 
            	when 'no_skip' : '0'
				when 'skip_p' : '1' 
				when 'skip_i' : '3'
				when 'skip_b' : '2'
				when 'skip_ip' : '4'
				when 'skip_ib' : '5'
				when 'skip_pb' : '6'
				when 'skip_ipb' : '7'
				when 'skip_idr' : '8'
                else mode
        	end
        end
        
        def get_speech_companding(companding)
            case companding
    		    when 'linear' : '0'
			    when 'alaw' : '1'
			    when 'ulaw' : '2'
				else companding
            end
        end
        
        def get_video_content_type(type)
            case type 
                when 'progressive' : '0'    # Progressive frame. */
                when 'interlaced' : '1' 	# Interlaced frame. */
                when 'top_field' : '2'    	# Interlaced picture, top field. */
                when 'bottom_field' : '3'   # Interlaced picture, bottom field.
                else type
            end
        end
        
        def get_audio_type(audio)
            case audio 
            	# Uncomment below and comment out current for 0.9 XDM audio support
                #when 'mono' : '0'        	#< Single channel. */
                #when 'stereo' : '1'      	#< Two channel. */
                #when '3.0' : '2'  			#< Three channel. */
                #when '5.0' : '3'   		#< Five channel. */
                #when '5.1' : '4'    		#< 5.1 channel. */
                #when '7.1' : '5'    		#< 7.1 channel. */
				when 'mono' : '0'        	#< Mono. */
    			when 'stereo' : '1'      	#< Stereo. */
    			when 'dualmono' : '2'       #< Dual Mono.
                when '3.0' : '3'  			#< Left, Right, Center. */
                when '2.1' : '4'         #< Left, Right, Sur. */
                when '3.1' : '5'         #< Left, Right, Center, Sur. */
                when '2.2' : '6'         #< Left, Right, SurL, SurR. */
                when '3.2' : '7'         #< Left, Right, Center, SurL, SurR. */
                when '2.3' : '8'         #< Left, Right, SurL, SurR, surC. */
                when '3.3' : '9'         #< Left, Right, Center, SurL, SurR, surC. */
                when '3.4' : '10'        #< Left, Right, Center, SurL, SurR, sideL, sideR.
                else audio
			end
        end
        
        def get_audio_channels(audio)
            case audio
            	when 'mono' : '1'        	#< Mono. */
    			when 'stereo', 'dualmono' : '2'      	#< Stereo. */ ; #< Dual Mono. 
                when '3.0', '2.1' : '3'  			#< Left, Right, Center. */;  #< Left, Right, Sur. */      
                when '3.1', '2.2' : '4'         #< Left, Right, Center, Sur. */ ; #< Left, Right, SurL, SurR. */         
                when '3.2' , '2.3' : '5'         #< Left, Right, Center, SurL, SurR. */ ; #< Left, Right, SurL, SurR, surC. */         
                when '3.3' , '3.4' : '6'         #< Left, Right, Center, SurL, SurR, surC. */ ; #< Left, Right, Center, SurL, SurR, sideL, sideR.       
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
                when 'cbr' : '1'   			#IVIDEO_LOW_DELAY    /**< CBR rate control for video conferencing. */
                when 'vbr' : '2'	  		#IVIDEO_STORAGE      /**< VBR rate control for local storage (DVD)
                when 'two_pass' : '3' 		#IVIDEO_TWOPASS      /**< Two pass rate control for non real time
                when 'none'	: '4'  			#IVIDEO_NONE         /**< No configurable video rate control
                when 'user_defined' : '5' 	#IVIDEO_USER_DEFINED /**< User defined configuration using extended
                when 'vbr_rate_fix' : '6'
                else preset
            end	
        end
        
        def get_encoder_preset(preset)
            case preset
                when 'default' : '0' 		#XDM_DEFAULT        /**< Default setting of encoder.  See
                when 'high_quality' : '1'	#XDM_HIGH_QUALITY   /**< High quality encoding. */
    		    when 'high_speed' : '2'		#XDM_HIGH_SPEED     /**< High speed encoding. */
    		    when 'user_defined' : '3'	#XDM_USER_DEFINED   /**< User defined configuration, using
                else preset
            end
        end
        
        def get_h264_profile(profile)
            case profile.downcase.strip
            	when 'baseline' : '66'
            	when 'main' : '77'
            	when 'extended' : '88'
                when 'high' : '100'
                when 'high_10', 'high_10_intra' : '110'
                when 'high_422', 'high_422_intra' : '122'
                when 'high_444_pred', 'high_444_intra' : '244'
                when 'cavlc_444_intra' : '44'
        		else profile
        	end
        end
        
        def get_h264_rcalgo(algorithm)
            case algorithm
            	when 'dces_tm5' : '0'
            	when 'plr' : '1'
        		else algorithm
        	end
        end
        
        def get_mpeg4_rcalgo(algorithm)
            case algorithm
            	when 'disable' : '0'
            	when 'tm5' : '1'
            	when 'plr1' : '3'
            	when 'plr3' : '4'
            	when 'vbr'  : '7'
            	when 'plr4', 'default' : '8'
        		else algorithm
        	end
        end
        
        def get_mpeg4_enc_mode(mode)
            case mode.strip.downcase
            	when 'h263' : '0'
            	when 'mpeg4' : '1'
        	else mode
        	end
        end
        
        def get_h264_entropy_coding(coding)
            case coding
            	when 'cavlc' : '0'
                when 'cabac' : '1'
                else coding
        	end
        end
        
        def get_vpbe_standard(signal_format)
            case signal_format.strip.downcase
                when '625' : '4'
                when '525' : '1'
                when '1080i50', '1080i30' : '6' 
                when '720p50' : '5'
                when '720p60' : '3'
                when '1080i60', "1080i25" : '2'
                when '480p' : '7'
                when '576p' : '8'
                else signal_format 
            end
        end
        
        def get_vpfe_standard(signal_format)
            case signal_format.strip.downcase
                when '625' : '2'
                when '525' : '1'
                when 'secam': '3' 
                else '0' 
            end
        end
        
        def get_video_driver_data_format(format)
            case format 
        		when '422i' : '1'
                when '420p' : '2'
                when '422p' : '3'
                when '410'  : '4'
                when 'rgb'  : '6'
                when '422sp': '7'
                else format
        	end
        end
        
        def get_vpbe_iface_type(io_type)
            case io_type.strip.downcase
                when 'composite' : '1'
                when 'component' : '2'
                when 'svideo' : '3'
                else io_type 
            end
        end 
        
        def get_vpfe_iface_type(io_type)
            case io_type.strip.downcase
                when 'composite' : '0'
                when 'svideo' : '1'
                else io_type 
            end
        end
        
        def get_dual_mono_mode(mode)
            case mode.strip.to_s
            	when 'left' : '1'
            	when 'right' : '2'
            	when 'left_right' : '0'
            	when 'mix' : '3'
                else mode
        	end
        end
        
        def get_acc_encode_mode(mode)
            case mode.strip.to_s
            	when 'cbr' : '0'
            	when 'vbr' : '1'
            	else mode
        	end
        end
        
        def get_aac_bit_rate_mode(mode)
            case mode.strip.to_s
            	when 'vbr1' : '1'
            	when 'vbr2' : '2'
                when 'vbr3' : '3'
                when 'vbr4' : '4'
                when 'vbr5' : '5'
            	else mode
        	end
        end 
        
        def get_acc_output_object_type(type)
            case type.strip.to_s
            	when 'lc' : '2'
            	when 'heaac' : '5'
                when 'ps' : '29'
                else type
        	end
        end 
        
        def get_aac_file_format(format)
            case format.strip.to_s
            	when 'raw' : '0'
            	when 'adif' : '1'
                when 'adts' : '2'
                else format
        	end
        end
        
        def get_bits_per_sample(audio_type)
            audio_type.strip.downcase == 'stereo' ? '32' : '16'
        end
        
        def get_video_format_width(format)
            case format.strip.to_s
            	when /1080/ : '1920'
            	when '525', '625' : '720'
                when /720/ : '1280'
                else format
        	end
        end
        
        def get_video_format_height(format)
            case format.strip.to_s
            	when /1080/ : '1080'
            	when '525' : '480'
                when '625' : '576'
                when /720/ : '720'
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
          FileUtils.cp(params['Source'], "#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\#{params['loc_source']}") if params["Source"]
          command += " -s #{@executable_path}/#{params['loc_source']}" if (params["Source"] || params["TempSource"])
          command += " -t #{@executable_path}/#{params['loc_target']}" if (params["Target"] || params["TempTarget"])
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
                  FileUtils.cp("#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\#{params['loc_target']}", params["Target"])
                  FileUtils.rm("#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\#{params['loc_target']}")
              end
              Thread.critical = true
              @active_threads -= 1
              puts "\n\n*********** Thread for #{command} completed"
              Thread.critical = false
          }    
        end  
        
    end
end

