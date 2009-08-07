require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'
require 'timeout'

module DvtbHandlers  
    class DvtbListener 
        attr_reader :match, :cmd, :expect, :response_buffer
        def initialize(cmd,expect)
            first_cmd_word = cmd.split(/\s/)[0].to_s
            i = 0
            first_cmd_word.each_byte {|c| 
              first_cmd_word[i] = '.'  if c.to_i < 32
              i+=1
            }
            @cmd = Regexp.new(first_cmd_word)
            @expect = /#{@cmd}.+?#{expect}/m
            @response_buffer = ''
            @match = false
        end
        
        def process_response(data)
            @response_buffer += data
            @match = true   if @expect.match(@response_buffer)
        end
    end
    
    class DvtbDefaultClient 
        include Log4r  
        Logger = Log4r::Logger 
        attr_accessor :host, :port, :waittime
        attr_reader :response, :is_timeout
        
        def initialize(platform_info, log_path = nil)
            @listeners = Array.new
            @keep_listening = true
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
            begin
            start_logger(log_path) if log_path
            log_info("Starting target session") if @targetc_log
            @waittime = 0
            platform_info.instance_variables.each {|var|
                #if platform_info.instance_variable_get(var).kind_of?(String) && platform_info.instance_variable_get(var).to_s.size > 0
                if platform_info.instance_variable_get(var).to_s.size > 0   
                     self.class.class_eval {attr_reader *(var.to_s.gsub('@',''))}
                     self.instance_variable_set(var, platform_info.instance_variable_get(var))
                end
            }
            @target = Net::Telnet::new( "Host" => @telnet_ip,
                                            "Port" => @telnet_port,
                                            "Waittime" => @waittime,
                                            "Prompt" => @prompt,
                                            "Telnetmode" => true,
                                            "Binmode" => false)
            send_cmd("")
            if @telnet_login && @telnet_passwd then
           		@target.login(@telnet_login.to_s, @telnet_passwd){ |c| 
              print c 
              case c
                when /#{@prompt}/
                  break
                when /DVTB/i
                  @target.puts("exit")
                  @target.puts("")
              end
              }
            elsif @telnet_login
            	@target.login(@telnet_login.to_s){ |c| 
                print c 
                case c
                  when /#{@prompt}/
                    break
                  when /DVTB/i
                    @target.puts("exit")
                    @target.puts("")
                end
              }
            end
			
            start_listening
			
            rescue Exception => e
                log_info("Initialize: "+e.to_s)
                raise
            end
        end

        #Starts the logger for the session. Takes the log file path as parameter.
        def start_logger(file_path)
          if @targetc_log
            stop_logger
          end
          Logger.new('targetc_log')
          @targetc_log_outputter = Log4r::FileOutputter.new("switch_log_out",{:filename => file_path.to_s , :truncate => false})
          @targetc_log = Logger['targetc_log']
          @targetc_log.level = Log4r::DEBUG
          @targetc_log.add  @targetc_log_outputter
          @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
          @targetc_log_outputter.formatter = @pattern_formatter  
          @remaining_data = ''   
        end
    
        #Stops the logger.
        def stop_logger
          @targetc_log_outputter = nil if @targetc_log_outputter
          @targetc_log = nil if @targetc_log
        end
        
        def add_listener(listener)
            @listeners << listener
        end
        
        def remove_listener(listener)
            @listeners.delete(listener)
        end
        
        def notify_listeners(data)
            @listeners.each {|listener|
                listener.process_response(data)
            }
            @remaining_data += data
            log_info("Target: " + @remaining_data.slice!(/.*[\r\n]+/m)) if @remaining_data[/.*[\r\n]+/m]
        end
        
        def start_listening
            @listen_thread = Thread.new {
                while @keep_listening
                    if !@target.eof?
                        last_read = @target.preprocess(@target.readpartial(1024))
                        print last_read 
                        #log_info("Target: " + last_read)
                        notify_listeners(last_read)
                    end
                end
			}		
        end
        
        def stop_listening
            @keep_listening = false
            @listen_thread.join(5)
        end
    
        def send_cmd(command)
            begin
            log_info("Host: " + command)
            @target.puts(command)
            rescue Exception => e
           		log_error("On command "+command.to_s+"\n"+e.to_s+"Target: \n" + @response)
            	raise
          	end
        end
    
        def disconnect
            stop_listening 
            @target.close if @target
		    @target = nil
        end
            
        def log_warning(warning)
            @targetc_log.warn(warning) if @targetc_log
        end
    
        def log_info(info)
    	    @targetc_log.info(info) if @targetc_log
        end
  
        def log_error(error)
    	    @targetc_log.error(error) if @targetc_log
        end
  
        def log_debug(debug_info)
    	    @targetc_log.debug(debug_info) if @targetc_log
        end

        def connect
            raise "Method NOT Supported"
        end
        
        def wait_for_threads
            raise "Method NOT Supported"
        end

        def set_max_number_of_sockets(video_num_sockets,audio_num_sockets,params=nil)
            raise "Method NOT Supported"
        end
        
        # DVTB-Server-Dependant Methods
  
        def get_param(params)
            raise "Method NOT Supported"
        end

        def set_param(params)
            raise "Method NOT Supported"
        end

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
        
        # Copy an image from the build server to the tftp server
        # Reboot the dut and load the image into it in the bootloader
        # Boots into the new image, leaving the user at the command prompt 
        # Required Params: 
        # 'image_path' must be defined in the params hash, this is the path to your build directory
        # 'tftp_path' must be defined in the params hash, this is the base path to your tftp server (where the files will be copied)
        # 'tftp_ip' must be defined in the params hash if you have any modules, this is the ip of your tftp server (where the files will be copied & the modules will be copied from)
        def boot(params)
          image_path = params['image_path']
          puts "\n\n====== uImage is at #{image_path} =========="
          boot_args = SiteInfo::Bootargs[params['platform'].downcase.strip]
          boot_args = params['bootargs'] if params['bootargs']
          tmp_path = "#{params['tester'].downcase}/#{params['target'].downcase}/#{params['platform'].downcase}"
          if image_path != nil && File.exists?(image_path) && get_image(image_path, params['samba_path'], params['server'], tmp_path) then
            boot_to_bootloader(params)
            #set bootloader env vars and tftp the image to the unit -- Note: add more commands here if you need to change the environment further
            send_cmd("setenv serverip #{params['tftp_ip']}",@boot_prompt, 30)
            send_cmd("setenv bootcmd 'dhcp;bootm'",@boot_prompt, 30)
            send_cmd("setenv bootfile #{tmp_path}/#{File.basename(image_path)}",@boot_prompt, 30)
            raise 'Unable to set bootfile' if @is_timeout
            send_cmd("setenv nfs_root_path #{params['server'].telnet_ip}:#{params['server'].nfs_root_path}",@boot_prompt, 30)
            raise 'Unable to set nfs root path' if @is_timeout
            send_cmd("setenv bootargs #{boot_args}",@boot_prompt, 30)
            raise 'Unable to set bootargs' if @is_timeout
            send_cmd("saveenv",@boot_prompt, 10)
            raise 'Unable save environment' if @is_timeout
            send_cmd('boot', /login/, 100)
            raise 'Unable to boot platform' if @is_timeout
            # command prompt context commands
            send_cmd(@login, @prompt, 10) # login to the unit
            raise 'Unable to login' if @is_timeout
          else
            raise "image #{image_path} does not exist, unable to copy"
          end
          connect if self.respond_to?(:connect)
        end

        # stop the bootloader after a reboot
        def stop_boot
          0.upto 3 do
          send_cmd("\e", @boot_prompt, 1)
          end
        end
        
        # Reboot the unit to the bootloader prompt
        def boot_to_bootloader(params = {'apc' => nil})
          puts 'rebooting DUT'
          if params['apc'] != nil
          puts 'Resetting DUT using APC'
          params['apc'].reset(@power_port)
          send_cmd("\e", /U-Boot/, 3)
          else
          send_cmd('reboot', /U-Boot/, 40)
          end
          # stop the autobooter from autobooting the box
          #0.upto 30 do
          0.upto 5 do
          send_cmd("\n", @boot_prompt, 1)
          puts 'Sending esc character'
          sleep 1
          break if !@is_timeout
          end
          # now in the uboot prompt
        end
        
        # Boot to the login prompt (will NOT login for you)
        def boot_to_image(params = {'apc' => nil})
          if params['apc'] != nil
          params['apc'].reset(@power_port.to_s)
          else
          send_cmd('reboot', /Hit any key to stop autoboot:/, 30)
          end
        end
        
        # Copy the image files and module.ko files from the build directory into the ftp directory
        def get_image(src, dst_folder, server, tmp_path)
          # puts "copying files from #{src} to #{dst_path}"
          
          # Copy images and modules (.ko) tftp server
          build_files = Array.new
          src_folder = File.dirname(src)
          BuildClient.dir_search(src_folder, build_files)
          dst_folder = "#{dst_folder}\\bin"
          tmp_path = "/#{tmp_path}"
          build_files.each {|f|
          dst_path   = dst_folder+"\\#{File.basename(f)}"    # This is the Windows'samba path
          if f == src 
            puts "copy from: #{f}"
            puts "copy to: #{dst_path}"
            BuildClient.copy(f, dst_path)
            raise "Please specify TFTP path like /tftproot in Linux server in bench file." if server.tftp_path.to_s == ''
            #puts "#{server.nfs_root_path}#{tmp_path}/bin/#{File.basename(f)}"
            server.send_cmd("mkdir -p #{server.tftp_path}#{tmp_path}",server.prompt, 10)
            server.send_cmd("mv -f #{server.nfs_root_path.sub(/(\\|\/)$/,'')}#{tmp_path}/bin/#{File.basename(f)} #{server.tftp_path}#{tmp_path}", server.prompt, 10)
          elsif File.extname(f) == '.ko'
            BuildClient.copy(f, dst_path) 
          end
          
          }
          true 
        end
    end
end

