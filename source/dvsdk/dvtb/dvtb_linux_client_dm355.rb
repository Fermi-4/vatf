require 'net/telnet'
require 'rubygems'
require 'fileutils'
require File.dirname(__FILE__) + '/../../target/lsp_target_controller'
require File.dirname(__FILE__) + '/dvtb_default_client'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module DvtbHandlers
    
    
    class DvtbLinuxClientDM355 < DvtbHandlers::DvtbDefaultClient
        
        def initialize(platform_info, log_path = nil)
           	super(platform_info, log_path)
            @active_threads = 0
            @file_ops = Array.new
            @dvtb_class.merge!({
                'videnc'		=> 'videnc1',
                'viddec'		=> 'viddec2',
                'jpegenc'		=> 'imgenc1',
                'jpegdec'		=> 'imgdec1',
                'mpeg4extenc'	=> 'mpeg4spenc1',
                'mpeg4extdec'	=> 'mpeg4spdec2',
                'jpegextenc' 	=> 'jpegenc1',
                'jpegextdec' 	=> 'jpegdec1',
                'ipncuc0'		=> 'IPNCUC0',
                'ipncuc1'		=> 'IPNCUC1',
                'ipncuc2'		=> 'IPNCUC2',
                'dvruc0'		=> 'DVRUC0',
                'dvrenc'		=> 'DVREnc',
                'dvrencdec'		=> 'DVREncDec'})
            @dvtb_param = {
                'audio' => {
                    'device'		=> 'device',
                    'samplesize'	=> 'samplesize',
                    'samplerate'	=> 'samplerate',
                    'channels'		=> 'channels',
                    'source'		=> 'source'
                },
                'vpfe' => {
                    'device'		=> 'device',
                    'standard'		=> 'standard',
                    'format'		=> 'format',
                    'input'			=> 'input',
                    'width'			=> 'width',
                    'height'		=> 'height'
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
                    'trace'		=> 'trace',
                },
                'viddec' => get_base_parameters('viddec'),
                'videnc' => get_base_parameters('videnc'),
                'sphdec' => {
                    'codec'			=> 'codec',
                    'compandingLaw'	=> 'compandingLaw',
                    'packingType'	=> 'packingType',
                    'inbufsize'		=> 'inbufsize',
                    'outbufsize'	=> 'outbufsize',
                    'dataEnable'	=> 'dataEnable',
                    'postFilter'	=> 'postFilter'
                },
                'sphenc' => {
                    'codec'					=> 'codec',
                    'seconds'				=> 'seconds',
                    'frameSize'				=> 'ParamsframeSize',
                    'compandingLaw'			=> 'compandingLaw',
                    'vadSelection'			=> 'vadSelection',
                    'packingType'			=> 'packingType',
                    'inbufsize'				=> 'inbufsize',
                    'outbufsize'			=> 'outbufsize',
                    'dynParamsFrameSize' 	=> 'DynParamsframeSize',
                    'bitRate'				=> 'bitRate',
                    'mode'					=> 'mode',
                    'vadFlag'				=> 'vadFlag',
                    'noiseSuppressionMode'  => 'noiseSuppressionMode',
					'ttyTddMode'			=> 'ttyTddMode',
					'dtmfMode'				=> 'dtmfMode',
					'dataTransmit'			=> 'dataTransmit',
					'homingMode'			=> 'homingMode',
                },
                'jpegdec' => get_base_parameters('jpegdec'),
                'jpegenc' => get_base_parameters('jpegenc'),
                'mpeg4extenc' => get_base_parameters(['videnc','mpeg4extenc']),
                'mpeg4extdec' => get_base_parameters(['viddec','mpeg4extdec']),
                'jpegextenc' => get_base_parameters(['jpegenc','jpegextenc']),
                'jpegextdec' => get_base_parameters(['jpegdec','jpegextdec']),
                'ipncuc0'	=> get_base_parameters(['videnc','mpeg4extenc'],['720p','SIF']),
                'ipncuc1'	=> get_base_parameters(['videnc','mpeg4extenc'],['D1','SIF']).merge(get_base_parameters('jpegenc','JPEGD1')),
                'ipncuc2'	=> get_base_parameters(['videnc','mpeg4extenc'],['720p','SIF']).merge(get_base_parameters('jpegenc','JPEGD1')),
                'dvruc0'	=> get_base_parameters(['videnc','mpeg4extenc'],['1D1', '2D1']),
                'dvrenc'	=> get_base_parameters(['videnc','mpeg4extenc'],['Inst[1]','Inst[2]','Inst[3]','Inst[4]','Inst[5]','Inst[6]','Inst[7]']),
                'dvrencdec'	=> get_base_parameters(['videnc','mpeg4extenc'],['EncInst[0]','EncInst[1]','EncInst[2]','EncInst[3]']).merge(get_base_parameters(['viddec', 'mpeg4extdec'],['DecInst[0]','DecInst[1]','DecInst[2]','DecInst[3]'])),
            }
            connect
        end
        
        def translate_value(params)
            case params['Class']
                when 'audio': 
                    case params['Param'].strip.downcase
                    when 'device' : 'plughw:0,0' #'/dev/dsp'
                    when 'channels': '2' #get_audio_channels(params['Value'].to_s.downcase)
                    when 'format'
                        get_audio_alsa_data_dormat(params['Value'].strip.downcase)
                    when 'type' : get_audio_device_mode(params['Value'].to_s)
                    else params['Value']
                    end
                when 'vpfe': 
                    case params['Param']
                    when 'device' : '/dev/video0' #'/dev/v4l/video0'
                    when 'standard' : get_vpfe_standard(params['Value'].to_s)
                    when 'format' : get_video_driver_data_format(params['Value'].to_s)
                    when 'input'  : get_vpfe_iface_type(params['Value'].to_s)
                    else params['Value']
                    end
                when 'vpbe': 
                    case params['Param']
                    when 'device' : '/dev/video2'
                    when 'standard' : get_vpbe_standard(params['Value'].to_s)
                    when 'output' : get_vpbe_iface_type(params['Value'].to_s)    
                    else params['Value']
                    end
                when 'engine': 
                    case params['Param']
                    when 'name' : params['Value'] == 'encdec'? 'loopback' :  params['Value']
                    else params['Value']
                    end     
                when /vid[end]+c/, /mpeg4ext[end]+c/   
                    case params['Param']
                    when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                    when /contenttype/i : get_video_content_type(params['Value'].downcase.strip)
                    when /encodingPreset/i : get_encoder_preset(params['Value'].downcase.strip)
                    when /rateControlPreset/i : get_rate_control_preset(params['Value'].downcase.strip)  
                    when /meAlgo/i : get_me_algo(params['Value'].downcase.strip)
                    when /skipMBAlgo/i : get_mb_skip_algo(params['Value'].downcase.strip)
                    when /encodeMode/i : get_mpeg4_enc_mode(params['Value'].downcase.strip)
                    when /IntraAlgo/i : get_intra_algo(params['Value'].downcase.strip)
                    when /iidc/i : get_blk_size(params['Value'].downcase.strip)
                    when /qchange$/i : get_q_change(params['Value'].downcase.strip)
                    when /rotation/i : get_video_rotation(params['Value'].downcase.strip)
                    else params['Value']
                    end  
                when /jpeg[endxt]+c/   
                    case params['Param']
                    when /ChromaFormat/ : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when /resize/i : get_jpeg_scale_factor(params['Value'].strip.downcase)
                    else params['Value']
                    end  
                when 'sphdec': 
                    case params['Param']
                        when 'numframes' : (params['Value'].to_i/8).to_s
                        when /companding/i
                            get_speech_companding(params['Value'].strip.downcase)
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
            elsif params.kind_of?(Hash) && @dvtb_class.has_key?(params['Class']) && params['Param'].to_s.strip == ''
                string = @dvtb_class[params['Class']]
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
			#send_cmd("setp "+string)
        end

        def video_decoding(params)
			exec_func(params.merge({"function" => "viddec2", "loc_source" => 'dec_source_file.dat', "loc_target" => 'dec_target_file.dat'}))
        end
    
        def video_encoding(params)
			exec_func(params.merge({"function" => "videnc1", "loc_source" => 'enc_source_file.dat', "loc_target" => 'enc_target_file.dat'}))
        end
        
        def mpeg4ext_encoding(params)
            exec_func(params.merge({"function" => "mpeg4spenc1", "loc_source" => 'enc_source_mpeg4ext_file.dat', "loc_target" => 'enc_target_mpeg4ext_file.dat'}))
        end
        
        def mpeg4ext_decoding(params)
            exec_func(params.merge({"function" => "mpeg4spdec2", "loc_source" => 'dec_source_mpeg4ext_file.dat', "loc_target" => 'dec_target_mpeg4ext_file.dat'}))
        end
        
        def jpegext_encoding(params)
            exec_func(params.merge({"function" => "jpegenc1", "loc_source" => 'enc_source_jpegext_file.dat', "loc_target" => 'enc_target_jpegext_file.dat'}))
        end
        
        def jpegext_decoding(params)
            exec_func(params.merge({"function" => "jpegdec1", "loc_source" => 'dec_source_jpegext_file.dat', "loc_target" => 'dec_target_jpegext_file.dat'}))
        end
        
        def video_encoding_decoding(params)
            temp_file = 'temp'+get_file_ext(params["threadIdEnc"])
            p_enc = {}.merge!(params); p_enc.delete("Target") ; p_enc['TempTarget'] = temp_file ; p_enc["threadId"] = params["threadIdEnc"]
            p_dec = {}.merge!(params); p_dec.delete("Source") ; p_dec['TempSource'] = temp_file ; p_dec["threadId"] = params["threadIdDec"]
            exec_func(p_enc.merge({"function" => "videnc1", "loc_source" => 'enc_source_file.dat', "loc_target" => temp_file}))
          	wait_for_threads
          	exec_func(p_dec.merge({"function" => "viddec2", "loc_source" => temp_file, "loc_target" => 'dec_target_file.dat'}))
        end

        def speech_decoding(params)
          	exec_func(params.merge({"function" => "sphdec", "loc_source" => 'dec_source_sph_file.dat', "loc_target" => 'dec_target_sph_file.dat'}))
        end
    
        def speech_encoding(params)
          	exec_func(params.merge({"function" => "sphenc", "loc_source" => 'enc_source_sph_file.dat', "loc_target" => 'enc_target_sph_file.dat'}))
        end
	
        def image_decoding(params)
            exec_func(params.merge({"function" => "imgdec1", "loc_source" => 'dec_source_img_file.dat', "loc_target" => 'dec_target_img_file.dat'}))
        end

        def image_encoding(params)
            exec_func(params.merge({"function" => "imgenc1", "loc_source" => 'enc_source_img_file.dat', "loc_target" => 'enc_target_img_file.dat'}))
        end
		   
        def video_capture(params)
            exec_func(params.merge({"function" => "videnc1", "cmd_tail" => '--nodsp'}))
        end
	
        def video_play(params)
            exec_func(params.merge({"function" => "viddec2", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_video.dat'}))
        end
        
        def speech_capture(params)
            exec_func(params.merge({"function" => "sphenc", "cmd_tail" => '--nodsp'}))
        end

        def speech_play(params)
            exec_func(params.merge({"function" => "sphdec", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_speech.dat'}))
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
        
        def get_base_parameters(param, prefix = nil)
            base_params = {
                'jpegdec' => {
                    'codec'					=> 'codec',
                    'maxHeight'				=> 'maxHeight',
                    'maxWidth'				=> 'maxWidth',
                    'maxScans'				=> 'maxScans',
                    'dataEndianness'		=> 'dataEndianness',
                    'forceChromaFormat'		=> 'forceChromaFormat',
                    'numAU'					=> 'numAU',
                    'decodeHeader'			=> 'decodeHeader',
                    'displayWidth'			=> 'displayWidth',
                },
                'jpegenc' => {
                    'codec'					=> 'codec',
                    'maxHeight'				=> 'maxHeight',
                    'maxWidth'				=> 'maxWidth',
                    'maxScans'				=> 'maxScans',
                    'dataEndianness'		=> 'dataEndianness',
                    'forceChromaFormat'		=> 'forceChromaFormat',
                    'numAU'					=> 'numAU',
                    'inputChromaFormat'		=> 'inputChromaFormat',
                    'inputHeight'			=> 'inputHeight',
                    'inputWidth'			=> 'inputWidth',
                    'captureWidth'			=> 'captureWidth',
                    'generateHeader'		=> 'generateHeader',
                    'qValue'				=> 'qValue',
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
                    'numframes'			=> 'numFrames',
                    'frameOrder'		=> 'frameOrder',
                    'newFrameFlag'		=> 'newFrameFlag',
					'mbDataFlag'		=> 'mbDataFlag',
                },
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
                    'reconChromaFormat'		=> 'reconChromaFormat',
                },
                'mpeg4extenc' => {
                    'subWindowHeight'	=>	'extParamsSubWindowHeight',
                    'subWindowWidth'	=>	'extParamsSubWindowWidth',
                    'intraPeriod'	=>	'extParamsIntraPeriod',
                    'intraDcVlcThr'	=>	'extParamsIntraDcVlcThr',
                    'rotation'	=>	'extParamsRotation',
                    'intraThres'	=>	'extParamsIntraThres',
                    'intraAlgo'	=>	'extParamsIntraAlgo',
                    'numMBRows'	=>	'extParamsNumMBRows',
                    'initQ'	=>	'extParamsInitQ',
                    'rcQ_MAX'	=>	'extParamsRcQ_MAX',
                    'rcQ_MIN'	=>	'extParamsRcQ_MIN',
                    'qChange'	=>	'extParamsRateFix',
                    'qChangeRange'	=>	'extParamsRateFixRange',
                    'vbvBufferSize'	=>	'extParamsVBV_size',
                    'initQ_P'	=>	'extParamsInitQ_P',
                    'meRange'	=>	'extParamsMeRange',
                    'meAlgo'	=>	'extParamsMeAlgo',
                    'skipMBAlgo'	=>	'extParamsSkipMBAlgo',
                    'useUMV'	=>	'extParamsUMV',
                    'iidc'	=>	'extParamsIidc',
                    'encodeMode'	=>	'extParamsSVH',
                    'dynParamsIntraDcVlcThr'	=>	'extDynParamsIntraDcVlcThr',
                    'dynParamsIntraThres'	=>	'extDynParamsIntraThres',
                    'dynParamsIntraAlgo'	=>	'extDynParamsIntraAlgo',
                    'dynParamsNumMBRows'	=>	'extDynParamsNumMBRows',
                    'dynParamsInitQ'	=>	'extDynParamsInitQ',
                    'dynParamsRcQ_MAX'	=>	'extDynParamsRcQ_MAX',
                    'dynParamsRcQ_MIN'	=>	'extDynParamsRcQ_MIN',
                    'dynParamsQChange'	=>	'extDynParamsRateFix',
                    'dynParamsQChangeRange'	=>	'extDynParamsRateFixRange',
                    'dynParamsInitQ_P'	=>	'extDynParamsInitQ_P',
                    'dynParamsMeRange'	=>	'extDynParamsMeRange',
                    'dynParamsMeAlgo'	=>	'extDynParamsMeAlgo',
                    'dynParamsSkipMBAlgo'	=>	'extDynParamsSkipMBAlgo',
                    'dynParamsUseUMV'	=>	'extDynParamsUMV',
                    'dynParamsIidc'	=>	'extDynParamsIidc',
                    'dynParamsMVDataEnable'	=>	'extDynParamsMVDataEnable',
                },
                'mpeg4extdec' => {
                    'meRange'	=>	'extParamsMeRange',
                    'displayWidth'	=>	'extParamsDisplayWidth',
                    'decRotation'	=>	'extParamsDecRotation',
                    'umv'	=>	'extParamsUMV',
                },
                'jpegextenc' => {
                    'dynParamsRstInterval'	=>	'extDynParamsRstInterval',
					'dynParamsDisableEOI'	=>	'extDynParamsDisableEOI',
					'dynParamsRotation'	=>	'extDynParamsRotation',
                },
                'jpegextdec' => {
                    'dynParamsDisableEOI'	=>	'extDynParamsDisableEOI',
                    'dynParamsResizeOption'	=>	'extDynParamsResizeOption',
                    'dynParamsSubRegUpLeftX'	=>	'extDynParamsSubRegUpLeftX',
                    'dynParamsSubRegUpLeftY'	=>	'extDynParamsSubRegUpLeftY',
                    'dynParamsSubRegDownRightX'	=>	'extDynParamsSubRegDownRightX',
                    'dynParamssubRegDownRightY'	=>	'extDynParamssubRegDownRightY',
                    'dynParamsRotation'	=>	'extDynParamsRotation',
                }
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
        
        def get_intra_algo(algo)
            case algo.downcase.strip
            	when 'ii_lq_hp' : '0'
                when 'ii_hq_lp' : '1'
        		else algo
        	end
        end
        
        def get_q_change(q_change)
            case q_change.downcase.strip
            	when 'mb' : '0'
                when 'picture' : '1'
        		else q_change
        	end
        end
        
        def get_me_algo(algo)
            case algo.downcase.strip
            	when 'me_lq_hp' : '3'
                when 'me_mq_mp' : '0'
                when 'me_hq_mp' : '1'
                when 'me_hq_lp' : '2'
        		else algo
        	end
        end
        
        def get_mb_skip_algo(algo)
            case algo.downcase.strip
            	when 'mb_lq_hp' : '0'
                when 'mb_hq_lp' : '1'
        		else algo
        	end
        end
        
        def get_blk_size(blk_size)
            case blk_size.strip.downcase
            	when 'blk_lq_hp' : '0'
            	when 'blk_hq_lp' : '1'
        		else blk_size
        	end
        end
        
        def get_mpeg4_enc_mode(mode)
            case mode.strip.downcase
            	when 'svh' : '1'
            	when 'mpeg4' : '0'
        		else mode
        	end
        end
        
        def get_video_rotation(rotation)
            case rotation.strip.to_i
            	when 0 : '0'
            	when 90 : '1'
            	when 180 : '2'
            	when 270 : '3'
            	else rotation
            end
        end
        
        def get_jpeg_scale_factor(factor)
            case factor.strip.to_i
            	when 1 : '3'
            	when 2 : '2'
            	when 3 : '4'
            	when 4 : '1'
            	when 5 : '5'
            	when 6 : '6'
            	when 7 : '7'
                else '0'
        	end
        end
        
        def get_rate_control_preset(preset)
            case preset
                when 'user_defined', 'vbr_rate_fix' : '6' 	#IVIDEO_USER_DEFINED /**< User defined configuration using extended
                else base(presest)
            end	
        end
    end
end


      




