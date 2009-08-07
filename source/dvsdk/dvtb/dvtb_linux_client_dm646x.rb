require 'net/telnet'
require 'rubygems'
require 'fileutils'
require File.dirname(__FILE__)+'/../../target/lsp_target_controller'
require File.dirname(__FILE__)+'/dvtb_default_client'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module DvtbHandlers
    
    
    class DvtbLinuxClientDM646x < DvtbHandlers::DvtbDefaultClient
        
        def initialize(platform_info, log_path = nil)
            super(platform_info, log_path)
            @active_threads = 0
            @file_ops = Array.new
            @dvtb_class.merge!({
                'videnc'	=> 'videnc1',
                'viddec'	=> 'viddec2',
                'auddec' 	=> 'auddec1',
                'audenc'	=> 'audenc1',
                'sphenc'	=> 'sphenc1',
                'sphdec'	=> 'sphdec1',
                'h264extenc'=> 'h264enc1',
                'aacextenc' => 'aacheenc1',})
            @dvtb_param = {
                'audio' => {
                    'device'		=> 'device',
                    'samplerate'	=> 'samplerate',
                    'channels'		=> 'channels',
                    'format'		=> 'format',
                    'type'			=> 'type'
                },
                'vpfe' => {
                    'device'		=> 'device',
                    'standard'		=> 'standard',
                    'format'		=> 'format',
                    'input'			=> 'input',
                    'width'			=> 'width',
                    'height'		=> 'height',
                },
                'vpbe' => {
                    'device'		=> 'device',
                    'width'			=> 'width',
                    'height'		=> 'height',
                    'standard'		=> 'std',
                    'output'		=> 'output'
                },
                'engine' => {
                    'name'		=> 'name',
                },
                'viddec' => {
                    'codec'				=> 'codec',
                    'maxHeight'			=> 'maxHeight',
                    'maxWidth'			=> 'maxWidth',
                    'maxFrameRate'		=> 'maxFrameRate',
                    'maxBitRate'		=> 'maxBitRate',
                    'dataEndianness'	=> 'dataEndianness',
                    'forceChromaFormat'	=> 'forceChromaFormat',
                    'decodeHeader'		=> 'decodeHeader',
                    'displayWidth'		=> 'displayWidth',
                    'frameSkipMode'		=> 'frameSkipMode',
                    'frameOrder'		=> 'frameOrder',
                    'newFrameFlag'		=> 'newFrameFlag',
					'mbDataFlag'		=> 'mbDataFlag',
					'numframes'			=> 'numFrames',
                },
                'videnc' => get_base_parameters('videnc'),
                'sphdec' => {
                    'codec'			=> 'codec',
                    'compandingLaw'	=> 'compandingLaw',
                    'packingType'	=> 'packingType',
                    'codecSelection'=> 'codecSelection',
                    'bitRate'		=> 'bitRate',
                    'inbufsize'		=> 'inbufsize',
                    'outbufsize'	=> 'outbufsize',
                },
                'sphenc' => {
                    'codec'			=> 'codec',
                    'seconds'		=> 'seconds',
                    'frameSize'		=> 'frameSize',
                    'compandingLaw'	=> 'compandingLaw',
                    'packingType'	=> 'packingType',
                    'vadSelection'	=> 'vadSelection',
                    'codecSelection'=> 'codecSelection',
                    'bitRate'		=> 'bitRate',
                    'vadFlag'		=> 'vadFlag',
                    'inbufsize'		=> 'inbufsize',
                    'outbufsize'	=> 'outbufsize',
                },
                'auddec' => {
                    'codec'                 =>  'codec',
					'outputPCMWidth'        =>  'outputPCMWidth',
					'pcmFormat'             =>  'pcmFormat',
					'dataEndianness'        =>  'dataEndianness',
					'desiredChannelMode'	=>  'desiredChannelMode',
					'downSampleSbrFlag'     =>  'downSampleSbrFlag',
					'inbufsize'             =>  'inbufsize',
					'outbufsize'            =>  'outbufsize',
                },
                'audenc' => get_base_parameters('audenc'),
                'h264extenc' => get_base_parameters(['videnc','h264extenc']),
                'aacextenc'	 => get_base_parameters(['audenc','aacextenc']),
            }
            connect
        end
        
        def translate_value(params)
            case params['Class']
                when 'audio': 
                    case params['Param'].strip.downcase
                    when 'device' : 'plughw:0,0'
                    when 'channels': '2' #get_audio_channels(params['Value'].to_s.downcase)
                    when 'format'
                        get_audio_alsa_data_dormat(params['Value'].strip.downcase)
                    when 'type' : get_audio_device_mode(params['Value'].to_s)
                    else params['Value']
                    end
                when 'vpfe': 
                    case params['Param']
                    when 'device' : '/dev/video0'
                    when 'standard' : '4'
                    when 'format' : '7'
                    when 'input'  : get_vpfe_iface_type(params['Value'].to_s)
                    when 'height' : get_video_format_height(params['Value'].to_s)
                    when 'width'  : get_video_format_width(params['Value'].to_s)
                    else params['Value']
                    end
                when 'vpbe': 
                    case params['Param']
                    when 'device' : '/dev/video2'
                    when 'standard' : get_vpbe_standard(params['Value'].to_s)
                    when 'output' : get_vpbe_iface_type(params['Value'].to_s)
                    when 'height' : get_video_format_height(params['Value'].to_s)
                    when 'width'  : get_video_format_width(params['Value'].to_s)
                    else params['Value']
                    end
                when 'engine': 
                    case params['Param']
                    when 'name' : params['Value'] == 'encdec'? 'loopback' :  params['Value']
                    else params['Value']
                    end     
                when /vid[end]+c/   
                   	case params['Param']
                    when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                    when /contenttype/i :  get_video_content_type(params['Value'].downcase.strip)
                    when 'encodingPreset' :  get_encoder_preset(params['Value'].downcase.strip)
                    when 'rateControlPreset' : get_rate_control_preset(params['Value'].downcase.strip)
                    when 'forceIFrame' : '0'
                    when 'framePitch' : get_video_format_width(params['Value'].to_s)
                    else params['Value']
                    end
                when 'h264extenc' 
                    case params['Param']
                   	when 'codec' : 'h264enc'
                    when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                    when /contenttype/i :  get_video_content_type(params['Value'].downcase.strip)
                    when 'encodingPreset' :  get_encoder_preset(params['Value'].downcase.strip)
                    when 'rateControlPreset' : get_rate_control_preset(params['Value'].downcase.strip)
                    when 'profileIdc' : get_h264_profile(params['Value'].downcase.strip)
                    when 'forceIFrame' : '0'
                    when 'entropyCodingMode' : get_h264_entropy_coding(params['Value'].downcase.strip)
                    when 'framePitch' : get_video_format_width(params['Value'].to_s) 
                    else params['Value']
                    end  
                when /sph[end]+c/: 
                    case params['Param']
                        when 'numframes' : (params['Value'].to_i/8).to_s
                        when /companding/i : get_speech_companding(params['Value'].strip.downcase)
                        when 'codec' : params['Value']+'1'
                        else params['Value']
                    end
                when /auddec/:
                    case params['Param']
                    	when 'pcmFormat' : get_audio_data_format(params['Value'].to_s)
                    	when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                        when 'codec' : params['Value'].downcase.include?('dec') ? 'aachedec1' : 'aacheenc1' 
                    else params['Value']
                    end
                when 'aacextenc', 'audenc'
                    case params['Param']
                    	when 'codec' : 'aacheenc'
                    	when 'pcmFormat', 'inputFormat' : get_audio_data_format(params['Value'].to_s)
                    	when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                        when /[cC]hannelMode/ : get_audio_type(params['Value'].strip.downcase)
                        when /encMode/ : get_acc_encode_mode(params['Value'].strip.downcase)
                        when /[iI]nputBitsPerSample/ : '16' #get_bits_per_sample(params['Value'].strip.downcase)
                        when /[dD]ualMonoMode/ : get_dual_mono_mode(params['Value'].strip.downcase)
                        when /[oO]utObjectType/ : get_acc_output_object_type(params['Value'].strip.downcase)
                        when /[oO]utFileFormat/ : get_aac_file_format(params['Value'].strip.downcase)
                        when /[bB]itRateMode/ : get_aac_bit_rate_mode(params['Value'].strip.downcase)
                    else params['Value']
                    end   
        	    else params['Value']
            end 
        end
        
        def connect
            send_cmd("cd #{@executable_path}",@prompt)
            send_cmd("./dvtb_loadmodules.sh", @prompt) 	
            send_cmd("./dvtb-r",/$/)
        end
    
        def disconnect
            send_cmd("exit",@prompt)
            super
        end

        def send_cmd(command, expected_match=/.*/, timeout=10)
            @is_timeout = false
            listener = DvtbListener.new(command, expected_match)
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
            	remove_listener(listener)
      	end
      	
        def wait_for_threads(timeout=180)
            puts "\n---> Wait for threads is going to wait #{timeout} seconds\n"
            status = Timeout::timeout(timeout) {
                while (@active_threads!=0) do
                    #puts "Waiting for threads. #{@active_threads} active threads"
                    sleep 5
                end
            }
            rescue Timeout::Error => e
        		log_error("Timeout waiting for Threads to complete")
        		raise
        end

        def set_max_number_of_sockets(video_num_sockets,audio_num_sockets,params=nil)
            # TODO
        end
        
        # DVTB-Server-Dependant Methods
  
        def get_param(params)
            if params.kind_of?(Hash) && @dvtb_class.has_key?(params['Class']) &&  @dvtb_param[params['Class']].has_key?(params['Param'])
    		    string = @dvtb_class[params['Class']]+' '+@dvtb_param[params['Class']][params['Param']].to_s  
            elsif params.kind_of?(String)
            	string = params
            else
                log_warning("#{params['Param']} Parameter on #{params['Class']} Class is Not Supported on this release")
                return 0
            end
            #send_cmd("getp "+string, /PASS:\s*getp/m,1)
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

        def video_decoding(params)
          exec_func(params.merge({"function" => "viddec2", "loc_source" => 'dec_source_file.dat', "loc_target" => 'dec_target_file.dat'}))
        end
    
        def video_encoding(params)
          exec_func(params.merge({"function" => "videnc1", "loc_source" => 'enc_source_file.dat', "loc_target" => 'enc_target_file.dat'}))
        end
        
        def video_encoding_decoding(params = {})
          exec_func(params.merge({"function" => "vidloopback1", "loc_source" => 'vidloop_enc_source_file.dat', "loc_target" => 'vidloop_dec_target_file.dat'}))
        end

        def speech_decoding(params)
          	exec_func(params.merge({"function" => "sphdec1", "loc_source" => 'dec_source_sph_file.dat', "loc_target" => 'dec_target_sph_file.dat'}))
        end
    
        def speech_encoding(params)
          	exec_func(params.merge({"function" => "sphenc1", "loc_source" => 'enc_source_sph_file.dat', "loc_target" => 'enc_target_sph_file.dat'}))
        end
		   
        #def video_capture(params)
            #exec_func(params.merge({"function" => "videnc1", "cmd_tail" => '--nodsp'}))
        #end
	
        #def video_play(params)
            #exec_func(params.merge({"function" => "viddec2", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_video.dat'}))
        #end
        
        #def speech_capture(params)
            #exec_func(params.merge({"function" => "sphenc1", "cmd_tail" => '--nodsp'}))
        #end

        #def speech_play(params)
            #exec_func(params.merge({"function" => "sphdec1", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_speech.dat'}))
        #end
        
        def audio_decoding(params)
            exec_func(params.merge({"function" => 'auddec1', "loc_source" => 'dec_source_aud_file.dat', "loc_target" => 'dec_target_aud_file.dat'}))
        end
        
        #def audio_play(params)
            #exec_func(params.merge({"function" => 'auddec1', "cmd_tail" => '--nodsp', 'loc_source' => 'raw_audio.dat'}))
        #end
        
        def audio_encoding(params)
            exec_func(params.merge({"function" => 'audenc1', "loc_source" => 'enc_source_aud_file.dat', "loc_target" => 'enc_target_aud_file.dat'}))
        end
        
        #def audio_capture(params)
            #exec_func(params.merge({"function" => 'audenc1', "cmd_tail" => '--nodsp'}))
        #end
        
        def h264ext_encoding(params)
            exec_func(params.merge({"function" => "h264enc1", "loc_source" => 'enc_source_h264ext_file.dat', "loc_target" => 'enc_target_h264ext_file.dat'}))
        end
        
        def aacext_encoding(params)
            exec_func(params.merge({"function" => "aacheenc1", "loc_source" => 'enc_source_aacext_file.dat', "loc_target" => 'enc_target_aacext_file.dat'}))
        end
                
        private
      
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
        
        def get_file_ext(threadId)
            case threadId
            when /264/ : '.264'
            else '.mpeg4'
            end
        end
        
        def get_standard(signal_format)
            case signal_format.strip.downcase
                when '625' : '4'
                when '525' : '1'
                when '1080i50' : '6' 
                when '720p50' : '5'
                when '720p60' : '3'
                when '1080i60' : '2'
                when '480p'  : '7'
                when '576p'  : '8'
                else signal_format 
            end
        end
        
        #def get_tvp5147_standard(signal_format)
            #case signal_format.strip.downcase
            	#when 'auto' : '0'
                #when '625' : '4'
                #when '525' : '1'
                #when '1080i50' : '6' 
                #when '720p50' : '5'
                #when '720p60' : '3'
                #when '1080i60' : '2'
                #when '480p'  : '7'
                #when '576p'  : '8'
                #else signal_format 
            #end
        #end
        
        #def get_tvp7002_standard(signal_format)
            #case signal_format.strip.downcase
                #when '625' : '4'
                #when '525' : '1'
                #when '1080i50' : '6' 
                #when '720p50' : '5'
                #when '720p60' : '3'
                #when '1080i60' : '2'
                #when '480p'  : '7'
                #when '576p'  : '8'
                #else signal_format 
            #end
        #end  
        
        def get_base_parameters(param, prefix = nil)
            base_params = {
                'videnc' => {
                    'codec'					=> 'codec',
                    'encodingPreset'		=> 'encodingPreset',
                    'rateControlPreset'		=> 'rateControlPreset',
                    'maxHeight'				=> 'maxHeight',
                    'maxWidth'				=> 'maxWidth',
                    'maxFrameRate'			=> 'maxFrameRate',
                    'maxBitRate'			=> 'maxBitRate',
                    'dataEndianness'		=> 'dataEndianness',
                    'maxInterFrameInterval'	=> 'maxInterFrameInterval',
                    'inputChromaFormat'		=> 'inputChromaFormat',
                    'inputContentType'		=> 'inputContentType',
                    'reconChromaFormat'		=> 'reconChromaFormat',
                    'inputHeight'			=> 'inputHeight',
                    'inputWidth'			=> 'inputWidth',
                    'refFrameRate'			=> 'refFrameRate',
                    'targetFrameRate'		=> 'targetFrameRate',
                    'targetBitRate'			=> 'targetBitRate',
                    'intraFrameInterval'	=> 'intraFrameInterval',
                    'generateHeader'		=> 'generateHeader',
                    'captureWidth'			=> 'captureWidth',
                    'forceIFrame'			=> 'forceFrame',
                    'interFrameInterval'	=> 'interFrameInterval',
					'mbDataFlag'			=> 'mbDataFlag',
					'framePitch'			=> 'framePitch',
                    'numframes'				=> 'numFrames',
                },
                'audenc' => {
                    'codec'								=>	'codec',
                    'seconds'							=>	'seconds',
                    'sampleRate'						=>	'sampleRate',
                    'bitRate'							=>	'bitRate',
                    'channelMode'						=>	'channelMode',
                    'dataEndianness'					=>	'dataEndianness',
                    'encMode'							=>	'encMode',
                    'inputFormat'						=>	'inputFormat',
                    'inputBitsPerSample'				=>	'inputBitsPerSample',
                    'maxBitRate'						=>	'maxBitRate',
                    'dualMonoMode'						=>	'dualMonoMode',
                    'crcFlag'							=>	'crcFlag',
                    'ancFlag'							=>	'ancFlag',
                    'lfeFlag'							=>	'lfeFlag',
                    'dynParamsSampleRate'				=>	'dynamicparams.sampleRate',
                    'dynParamsBitRate'					=>	'dynamicparams.bitRate',
                    'dynParamsChannelMode'				=>	'dynamicparams.channelMode',
                    'dynParamsLfeFlag'					=>	'dynamicparams.lfeFlag',
                    'dynParamsDualMonoMode'				=>	'dynamicparams.dualMonoMode',
                    'dynParamsInputBitsPerSample'		=>	'dynamicparams.inputBitsPerSample',  
                },
                'h264extenc' => {
                	'profileIdc'			=>	'profileIdc',
					'levelIdc'				=>	'levelIdc',
					'entropyCodingMode'		=>	'EntropyCodingMode',
					'qpIntra'				=>	'QPISlice',
					'qpInter'				=>	'QPSlice',
					'qpMax'					=>	'RateCtrlQpMax',
					'qpMin'					=>	'RateCtrlQpMin',
					'numRowsInSlice'		=>	'NumRowsInSlice',
					'lfDisableIdc'			=>	'LfDisableIdc',
					'filterOffsetA'			=>	'LFAlphaC0Offset',
					'filterOffsetB'			=>	'LFBetaOffset',
					'chromaQPIndexOffset'	=>	'ChromaQPOffset',
					'secChromaQPOffset'		=>	'SecChromaQPOffset',  
                },
                'aacextenc' => {
                    'outObjectType'			=> 'outObjectType',
                    'outFileFormat'			=> 'outFileFormat',
                    'useTns'				=> 'useTns',
                    'usePns'				=> 'usePns',
                    'downMixFlag'			=> 'downMixFlag',
                    'bitRateMode'			=> 'bitRateMode',
                    'ancRate'				=> 'ancRate',  
                    'dynParamsUseTns'		=> 'dynamicparams.useTns',
                    'dynParamsUsePns'		=> 'dynamicparams.usePns',
                    'dynParamsDownMixFlag'	=> 'dynamicparams.downMixFlag',
                   # 'dynParamsBitRateMode'	=> 'dynamicparams.bitRateMode',
                    'dynParamsAncRate'		=> 'dynamicparams.ancRate',
                },
            }
            param = [param] if !param.kind_of?(Array)
            result = Hash.new
            prefix = [prefix] if prefix && !prefix.kind_of?(Array)
            param.each do |current_param|
            	base_params[current_param].each do |key, val| 
                    if prefix 
                        prefix.each { |current_prefix| result[current_prefix.to_s+key.capitalize] = current_prefix.to_s+val.capitalize} 
                    else
                        result[key] = val
                    end
                end
            end
            result
        end
        
        def get_vpfe_iface_type(io_type)
            case io_type.strip.downcase
                when 'composite' : '0'
                when 'component' : '1'
                else io_type 
            end
        end
    end
end


      




