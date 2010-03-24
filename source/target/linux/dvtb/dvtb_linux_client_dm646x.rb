require File.dirname(__FILE__)+'/dvtb_linux_client'

module DvtbHandlers
    
    
    class DvtbLinuxClientDM646x < DvtbHandlers::DvtbLinuxClient
        
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
                'jpegenc' => 'imgenc1',
                'jpegdec' => 'imgdec1',
                'h264extenc' => 'h264enc1',
                'h264extdec' => 'h264dec2',
                'h264fhdextenc' => 'h264fhdenc1',
                'h264fhdextdec' => 'h2641080pdec2',
                'mpeg4extenc' => 'mpeg4enc1',
                'mpeg4extdec'  => 'mpeg4dec2',
                'mpeg2extdec'  => 'mpeg2dec2',
                'jpegextenc' => 'jpegenc1',
                'jpegextdec' => 'jpegdec1',
                #'aacextenc'  => 'aacheenc1',
                'aacextdec'  => 'aachedec1',})
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
                'viddec' => get_base_parameters('viddec'),
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
                'jpegdec' => get_base_parameters('jpegdec'),
                'jpegenc' => get_base_parameters('jpegenc'),
                'auddec' => get_base_parameters('auddec'),
                'audenc' => get_base_parameters('audenc'),
                'h264extenc' => get_base_parameters(['videnc','h264extenc']),
                'h264fhdextenc' => get_base_parameters(['videnc','h264fhdextenc']),
                'mpeg4extenc' => get_base_parameters(['videnc','mpeg4extenc']),
                #'aacextenc'	 => get_base_parameters(['audenc','aacextenc']),
                'aacextdec'	 => get_base_parameters(['auddec','aacextdec']),
                'jpegextenc' => get_base_parameters(['jpegenc','jpegextenc']),
                'h264extdec' => get_base_parameters(['viddec','h264extdec']),
                'h264fhdextdec' => get_base_parameters(['viddec','h264fhdextdec']),
                'mpeg4extdec' => get_base_parameters(['viddec','mpeg4extdec']),
                'mpeg2extdec' => get_base_parameters(['viddec','mpeg2extdec']),
                'jpegextdec' => get_base_parameters(['jpegdec','jpegextdec']),
            }
            
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
                    when 'name' : "encodedecode"
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
                    when 'forceFrame' : get_video_frame_type(params['Value'].downcase.strip)
                    else params['Value']
                    end
                when /h264(fhd){0,1}extenc/ 
                  case params['Param']
                   	when 'codec' : params['Value'].include?('fhd') ? 'h264fhdvenc' : 'h264enc'
                    when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                    when /contenttype/i :  get_video_content_type(params['Value'].downcase.strip)
                    when 'encodingPreset' :  get_encoder_preset(params['Value'].downcase.strip)
                    when 'rateControlPreset' : get_rate_control_preset(params['Value'].downcase.strip)
                    when 'profileIdc' : get_h264_profile(params['Value'].downcase.strip)
                    when 'forceFrame' : get_video_frame_type(params['Value'].downcase.strip)
                    when 'entropyCodingMode' : get_h264_entropy_coding(params['Value'].downcase.strip)
                    when 'framePitch' : get_video_format_width(params['Value'].to_s) 
                    when 'meAlgo' : get_h264_me_algo(params['Value'].to_s)
                    when 'seqScalingFlag' : get_h264_scaling_type(params['Value'].to_s)
                    when 'scalingFactor' : params['Value'].to_s.strip.downcase == 'auto' ? '0' : params['Value']
                    when 'sliceMode' : get_h264_slice_mode(params['Value'].to_s)
                    when 'sliceCodingPreset' : get_h264_slice_coding_preset(params['Value'].to_s)
                    when 'intra4x4EnableFlag' : get_h264_intra4x4_flag(params['Value'].to_s)
                    when 'chromaConversionMode' : get_h264_chroma_conv_mode(params['Value'].to_s)
                    when 'streamFormat' : get_h264_stream_format(params['Value'].to_s)
                    else params['Value']
                  end
                when /h264extdec/
                  case params['Param']
                    when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                    when /contenttype/i :  get_video_content_type(params['Value'].downcase.strip)
                    when 'encodingPreset' :  get_encoder_preset(params['Value'].downcase.strip)
                    when 'rateControlPreset' : get_rate_control_preset(params['Value'].downcase.strip)
                    when 'forceFrame' : get_video_frame_type(params['Value'].downcase.strip)
                    when 'presetLevelIdc' : get_h264dec_level(params['Value'].downcase.strip)
                    when 'presetProfileIdc' : get_h264dec_prof(params['Value'].downcase.strip)
                    else params['Value']
                  end
                when /mpeg4extenc/ 
                  case params['Param']
                    when 'codec':'mpeg4enc'
                    when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                    when /contenttype/i :  get_video_content_type(params['Value'].downcase.strip)
                    when 'encodingPreset' :  get_encoder_preset(params['Value'].downcase.strip)
                    when 'rateControlPreset' : get_rate_control_preset(params['Value'].downcase.strip)
                    when 'forceFrame' : get_video_frame_type(params['Value'].downcase.strip)
                    when 'encodeMode' : get_mpeg4_mode(params['Value'].downcase.strip)
                    when 'rcAlgo' : get_mpeg4_rcalgo(params['Value'].to_s)
                    when 'levelIdc' : get_mpeg4_level(params['Value'].to_s)
                    when 'profileIdc' : get_mpeg4_profile(params['Value'].to_s)
                    when 'aspectRatio' : get_mpeg4_aspect_ratio(params['Value'].to_s)
                    when 'pixelRange' : get_mpeg4_pel_range(params['Value'].to_s)
                    else params['Value']
                  end
                when /mpeg4extdec/
                  case params['Param']
                    when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                    when 'displayWidth' : '0'
                    else params['Value']
                  end
                when /mpeg2extdec/
                  case params['Param']
                    when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                    when 'displayWidth' : '0'
                    when 'deBlocking' : get_deblocking_flag(params['Value'].to_s)
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
                when 'jpegextenc'
                    case params['Param']
                    	when 'codec' : 'jpegenc'
                    	when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                      when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                    else params['Value']
                    end
                when 'jpegextdec'
                    case params['Param']
                      when 'codec' : 'jpegdec'
                      when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                      when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                      when 'RGB_Format' : get_jpg_rgb_fmt(params['Value'].to_s)
                      when 'outImgRes' : get_jpg_out_img_res(params['Value'].to_s)
                    else params['Value']
                    end
                when 'aacextdec'
                    case params['Param']
                      when 'desiredChannelMode' : get_aac_desire_ch_mode(params['Value'].to_s)
                      when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                      when 'pcmFormat' : get_audio_data_format(params['Value'].to_s) 
                      when 'nProfile' : get_aac_profile(params['Value'].to_s)
                      when 'ulSamplingRateIdx' : get_ul_sampling_rate(params['Value'])
                      else params['Value']
                    end
        	    else params['Value']
            end 
        end
        
        def connect(params)
            super(params)
            send_cmd("cd #{@executable_path}/dvtb",@prompt)
            send_cmd("./dvtb_loadmodules.sh", @prompt) 	
            send_cmd("./dvtb-r",/$/)
        end
    
        # DVTB-Server-Dependant Methods

        def video_decoding(params)
          exec_func(params.merge({"function" => "viddec2"}))
        end
    
        def video_encoding(params)
          exec_func(params.merge({"function" => "videnc1"}))
        end
        
        def video_encoding_decoding(params = {})
          exec_func(params.merge({"function" => "vidloopback1"}))
        end

        def speech_decoding(params)
          	exec_func(params.merge({"function" => "sphdec1"}))
        end
    
        def speech_encoding(params)
          	exec_func(params.merge({"function" => "sphenc1"}))
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
            exec_func(params.merge({"function" => 'auddec1'}))
        end
        
        #def audio_play(params)
            #exec_func(params.merge({"function" => 'auddec1', "cmd_tail" => '--nodsp', 'loc_source' => 'raw_audio.dat'}))
        #end
        
        def audio_encoding(params)
            exec_func(params.merge({"function" => 'audenc1'}))
        end
        
        #def audio_capture(params)
            #exec_func(params.merge({"function" => 'audenc1', "cmd_tail" => '--nodsp'}))
        #end
        
        def h264ext_encoding(params)
            exec_func(params.merge({"function" => "h264enc1"}))
        end
        
        def mpeg4ext_encoding(params)
            exec_func(params.merge({"function" => "mpeg4enc1"}))
        end
        
        def h264fhdext_encoding(params)
            exec_func(params.merge({"function" => "h264fhdenc1"}))
        end
        
        def jpegext_encoding(params)
            exec_func(params.merge({"function" => "jpegenc1"}))
        end
        
        def aacext_encoding(params)
            exec_func(params.merge({"function" => "aacheenc1"}))
        end
        
        def h264ext_decoding(params)
            exec_func(params.merge({"function" => "h264dec2"}))
        end
        
        def mpeg4ext_decoding(params)
            exec_func(params.merge({"function" => "mpeg4dec2"}))
        end
        
        def jpegext_decoding(params)
            exec_func(params.merge({"function" => "jpegdec1"}))
        end
        
        def mpeg2ext_decoding(params)
            exec_func(params.merge({"function" => "mpeg2dec2"}))
        end
        
        def aacext_decoding(params)
            exec_func(params.merge({"function" => "aachedec1"}))
        end
        
        private
        
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
                    'forceFrame'			=> 'forceFrame',
                    'interFrameInterval'	=> 'interFrameInterval',
                    'mbDataFlag'			=> 'mbDataFlag',
                    'framePitch'			=> 'framePitch',
                    'numframes'				=> 'numFrames',
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
                'auddec' => {
                    'codec'                 =>  'codec',
                    'maxSampleRate'        =>  'maxSampleRate',
                    'maxBitrate'             =>  'maxBitrate',
                    'maxNoOfCh'        =>  'maxNoOfCh',
                    'dataEndianness'	  =>  'dataEndianness',
                    'outputFormat'     =>  'outputFormat',
                    'inbufsize'             =>  'inbufsize',
                    'outbufsize'            =>  'outbufsize',
                },
                'jpegenc' => {
                  'codec'             => 'codec',
                  'maxHeight'         => 'maxHeight',
                  'maxWidth'          => 'maxWidth',
                  'maxScans'          => 'maxScans',
                  'dataEndianness'    => 'dataEndianness',
                  'forceChromaFormat' => 'forceChromaFormat',
                  'numAU'             => 'numAU',
                  'inputChromaFormat' => 'inputChromaFormat',
                  'inputHeight'       => 'inputHeight',
                  'inputWidth'        => 'inputWidth',
                  'captureWidth'      => 'captureWidth',
                  'generateHeader'    => 'generateHeader',
                  'qValue'            => 'qValue',
                },
                'jpegdec' => {
                  'codec'             => 'codec',
                  'maxHeight'         => 'maxHeight',
                  'maxWidth'          => 'maxWidth',
                  'maxScans'          => 'maxScans',
                  'dataEndianness'    => 'dataEndianness',
                  'forceChromaFormat' => 'forceChromaFormat',
                  'numAU'             => 'numAU',
                  'decodeHeader'      => 'decodeHeader',
                  'displayWidth'      => 'displayWidth',
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
                  'meAlgo'             => 'METype',
                  'seqScalingFlag'     => 'ScalingMatType',
                  'scalingFactor'      => 'ScalingFactor',
                  'outBufSize'         => 'OutBufSize',                 
                },
                'h264fhdextenc' => {
                  'profileIdc'   =>  'profileIdc',
                  'levelIdc'   =>  'levelIdc',
                  'entropyCodingMode'   =>  'EntropyCodingMode',
                  'sliceCodingPreset'   =>  'sliceCodingPreset',
                  'sliceMode'   =>  'sliceMode',
                  'sliceUnitSize'   =>  'sliceUnitSize',
                  'sliceStartOffset[0]'   =>  'sliceStartOffset[0]',
                  'sliceStartOffset[1]'   =>  'sliceStartOffset[1]',
                  'sliceStartOffset[2]'   =>  'sliceStartOffset[2]',
                  'sliceStartOffset[3]'   =>  'sliceStartOffset[3]',
                  'streamFormat'   =>  'streamFormat',
                  'outBufSize'   =>  'OutBufSize',
                  'qPISlice'   =>  'QPISlice',
                  'qPSlice'   =>  'QPSlice',
                  'rateCtrlQpMax'   =>  'RateCtrlQpMax',
                  'rateCtrlQpMin'   =>  'RateCtrlQpMin',
                  'numRowsInSlice'   =>  'NumRowsInSlice',
                  'lfDisableIdc'   =>  'LfDisableIdc',
                  'lFAlphaC0Offset'   =>  'LFAlphaC0Offset',
                  'lFBetaOffset'   =>  'LFBetaOffset',
                  'chromaQPOffset'   =>  'ChromaQPOffset',
                  'secChromaQPOffset'   =>  'SecChromaQPOffset',
                  'picAFFFlag'   =>  'PicAFFFlag',
                  'picOrderCountType'   =>  'PicOrderCountType',
                  'adaptiveMBs'   =>  'AdaptiveMBs',
                  'enableBufSEI'   =>  'SEIParametersFlag',
                  'enableVUIparams'   =>  'VUIParametersFlag',
                  'skipStartCodesInCallback'   =>  'SkipStartCodesInCallback',
                  'intra4x4EnableFlag'   =>  'Intra4x4EnableFlag',
                  'blockingCallFlag'   =>  'BlockingCallFlag',
                  'meAlgo'   =>  'MESelect',
                  'me1080iMode'   =>  'ME1080iMode',
                  'mvDataFlag'   =>  'MVDataFlag',
                  'transform8x8DisableFlag'   =>  'Transform8x8DisableFlag',
                  'transform8x8FlagIntraFrame'   =>  'Intra8x8EnableFlag',
                  'interlaceReferenceMode'   =>  'InterlaceReferenceMode',
                  'chromaConversionMode'   =>  'ChromaConversionMode',
                },
                'mpeg4extenc' => {
                    'encodeMode' => 'MPEG4_mode',
                    'levelIdc' => 'levelIdc',
                    'profileIdc' => 'profileIdc',
                    'useVOS' => 'useVOS',
                    'useGOV' => 'useGOV',
                    'useVOLatGOV' => 'useVOLatGOV',
                    'useQpel' => 'useQpel',
                    'useInterlace' => 'useInterlace',
                    'aspectRatio' => 'aspectRatio',
                    'pixelRange' => 'pixelRange',
                    'timerResolution' => 'timerResolution',
                    'reset_vIMCOP_every_frame' => 'reset_vIMCOP_every_frame',
                    'useUMV' => 'UMV',
                    'Four_MV_mode' => 'Four_MV_mode',
                    'PacketSize' => 'PacketSize',
                    'qpIntra' => 'qpIntra',
                    'qpInter' => 'qpInter',
                    'useHEC' => 'useHEC',
                    'useGOBSync' => 'useGOBSync',
                    'rcAlgo' => 'RcAlgo',
                    'qpMax' => 'QPMax',
                    'qpMin' => 'QPMin',
                    'maxDelay' => 'maxDelay',
                    'qpInit' => 'qpInit',
                    'mv_accessFlag' => 'MVaccessFlag',
                    'meAlgo' => 'ME_Type',
                    'perceptualRC' => 'PerceptualRC',
                    'insert_End_Seq_code' => 'Insert_End_Seq_code',
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
                'jpegextenc' => {
                    'maxthumbnail_h_size_app0' => 'MaxThumbnail_H_size_App0',
                    'maxthumbnail_v_size_app0' => 'MaxThumbnail_V_size_App0',
                    'maxthumbnail_h_size_app1' => 'MaxThumbnail_H_size_App1',
                    'maxthumbnail_v_size_app1' => 'MaxThumbnail_V_size_App1',
                    'maxthumbnail_h_size_app13' => 'MaxThumbnail_H_size_App13',
                    'maxthumbnail_v_size_app13' => 'MaxThumbnail_V_size_App13',
                    'captureHeight' => 'captureHeight',
                    'dynParamsRstInterval' => 'DRI_Interval',
                    'thumbnail_index_app0' => 'Thumbnail_Index_App0',
                    'thumbnail_index_app1' => 'Thumbnail_Index_App1',
                    'thumbnail_index_app13' => 'Thumbnail_Index_App13',
                    'appn0_numbufs' => 'APPN0_numBufs',
                    'appn1_numbufs' => 'APPN1_numBufs',
                    'appn13_numbufs' => 'APPN13_numBufs',
                    'appn0_startbuf' => 'APPN0_startBuf',
                    'appn1_startbuf' => 'APPN1_startBuf',
                    'appn13_startbuf' => 'APPN13_startBuf',
                    'comment_insert' => 'COMMENT_insert',
                    'thumbnail_h_size_app1' => 'Thumbnail_H_size_App1',
                    'thumbnail_v_size_app1' => 'Thumbnail_V_size_App1',
                    'thumbnail_h_size_app0' => 'Thumbnail_H_size_App0',
                    'thumbnail_v_size_app0' => 'Thumbnail_V_size_App0',
                    'thumbnail_h_size_app13' => 'Thumbnail_H_size_App13',
                    'thumbnail_v_size_app13' => 'Thumbnail_V_size_App13',
                },
                'h264extdec' => {
                	 'displayDelay'                    =>  'displayDelay',
                   'presetLevelIdc'                  =>  'presetLevelIdc',
                   'presetProfileIdc'                =>  'presetProfileIdc',
                   'temporalDirModePred'             =>  'temporalDirModePred',
                },
                'h264fhdextdec' => {
                	 
                },
                'mpeg4extdec' => {
                    'displayDelay' => 'display_delay',
                    'reset_vIMCOP_every_frame' => 'reset_vIMCOP_every_frame',
                    'outloopDeblocking' => 'outloopDeblocking',
                    'outloopDeRinging' => 'outloopDeRinging',
                },
                'jpegextdec' => {
                    'progDisplay' => 'progDisplay',
                    'dynParamsResizeOption' => 'resizeOption',
                    'RGB_Format' => 'RGB_Format',
                    'numMCU_row' => 'numMCU_row',
                    'dynParamsSubRegUpLeftX' => 'x_org',
                    'dynParamsSubRegUpLeftY' => 'y_org',
                    'x_length' => 'x_length',
                    'y_length' => 'y_length',
                    'alpha_rgb' => 'alpha_rgb',
                    'outImgRes' => 'outImgRes',
                    'progressiveDecFlag' => 'progressiveDecFlag',
                },
                'mpeg2extdec' => {
                  'deBlocking' => 'DeBlocking',
                  'bottom_fld_DDR_Opt' => 'bottom_fld_DDR_Opt',
                  'mb_error_reporting' => 'mb_error_reporting',
                  'errorConceal' => 'errorConceal',
                },
                'aacextdec'  => {
                    'outputPCMWidth' => 'outputPCMWidth',
                    'pcmFormat' => 'pcmFormat',
                    'dataEndianness' => 'dataEndianness',
                    'desiredChannelMode' => 'desiredChannelMode',
                    'downSampleSbrFlag' => 'downSampleSbrFlag',
                    'sixChannelMode' => 'sixChannelMode',
                    'enablePS' => 'enablePS',
                    'ulSamplingRateIdx' => 'ulSamplingRateIdx',
                    'nProfile' => 'nProfile',
                    'bRawFormat' => 'bRawFormat',
                    'pseudoSurroundEnableFlag' => 'pseudoSurroundEnableFlag',
                    'enableARIBDownmix' => 'enableARIBDownmix',
                    'inbufsize' => 'inbufsize',
                    'outbufsize' => 'outbufsize',
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
        
        def get_vpfe_iface_type(io_type)
            case io_type.strip.downcase
                when 'composite' : '0'
                when 'component' : '1'
                else io_type 
            end
        end
        
        def get_h264_slice_mode(mode)
          case mode.strip.downcase
            when 'none': '0' # IH264_SLICEMODE_NONE 0: No multiple slices Default setting
            when 'mbunit' : '1' # IH264_SLICEMODE_MBUNIT 1: Slices are controlled based on the number of macro blocks.
            when 'bytes' : '2' # IH264_SLICEMODE_BYTES 2: Slices are controlled based on number of bytes
            when 'offset' : '3' # IH264_SLICEMODE_OFFSET 3: Slices are controlled based on user defined offset in unit of rows. Not supported in this version of H264 Encoder
            when 'default' : '' # IH264_SLICEMODE_DEFAULT Default slice coding mode single slice.
            when 'max': '' # IH264_SLICEMODE_MAX Reserved
            else mode
          end
        end
        
        def get_h264_slice_coding_preset(preset)
          case preset.strip.downcase
            when 'default' : '0' # IH264_SLICECODING_DEFAULT 0: Default slice coding params.
            when 'user_defined' : '1' # IH264_SLICECODING_USERDEFINED 1: User defined slice coding params. 
            when 'existing' : '2' # IH264_SLICECODING_EXISTING 2: Keep the slice coding params as existing.
            when 'max' : '3' # IH264_SLICECODING_MAX 3: 
            else preset
          end
        end
        
        def get_h264_intra4x4_flag(flag)
          case flag.strip.downcase 
            when 'disable': '0' # 0: Disable 4x4 modes
            when 'i_picture' : '1' # 1: Enable 4x4 intra modes in I-picture
            when 'p_picture' : '2' # 2: Enable 4x4 intra modes in P-picture
            when 'ip_picture' : '3' # 3: Enable 4x4 intra modes in both I and P Pictures
            else flag
          end
        end
        
        def get_h264_chroma_conv_mode(mode)
          case mode.strip.downcase
            when 'line' : '0'
            when 'avg' : '1'
            else mode
          end
        end
        
        def get_h264_stream_format(format)
          case format.strip.downcase
            when 'byte' : '0' # IH264_BYTE_STREAM 0: bit-stream contains the start code identifier. 
            when 'nalu' : '1' # IH264_NALU_STREAM 1: bit-stream does not contain the start code identifier. 
            when 'default' : '' # IH264_STREAM_FORMAT_DEFAULT Default slice coding mode is byte-stream. Default is IH264_BYTE_STREAM . 
            when 'max' : '' # IH264_STREAM_FORMAT_MAX
            else format
          end
        end
        
        def get_mpeg4_level(level)
          case level.strip.downcase
            when 'mpeg4_0': '0'
            when 'mpeg4_1': '1'
            when 'mpeg4_2': '2'
            when 'mpeg4_3': '3'
            when 'mpeg4_4': '4'
            when 'mpeg4_5': '5'
            when 'mpeg4_0b': '9'
            when 'h263_10': '10'
            when 'h263_20': '20'
            when 'h263_30': '30'
            when 'h263_40': '40'
            when 'h263_45': '45'
            else level
          end
        end
        
        def get_mpeg4_profile(prof)
          case prof.strip.downcase
            when 'sp': '0'
            when 'asp': '1'
            else prof
          end
        end
        
        def get_mpeg4_rcalgo(algorithm)
            case algorithm
            	when 'none' : '0'
            	when 'cbr' : '4'
            	when 'vbr'  : '8'
            else algorithm
        	end
        end
        
        def get_mpeg4_aspect_ratio(ratio)
          case ratio.strip.downcase
            when '1:1':'1'
            when '12:11':'2'
            when '10:11':'3'
            when '16:11':'4'
            when '40:33':'5'
            else ratio
          end
        end
        
        def get_mpeg4_pel_range(range)
          case range.strip.downcase
            when '16_235':'0'
            when '0_255':'1'
            else range
          end
        end
        
        def get_mpeg4_mode(mode)
          case mode.strip.downcase
            when 'svh': '0'
            when 'mpeg4': '1'
            else mode
          end
        end
        
        def get_h264dec_level(level)
          case level.strip.downcase
            when '1' : '0'
            when '1.1' : '1'
            when '1.2' : '2'
            when '1.3' : '3'
            when '1b' : '4'
            when '2' : '5'
            when '2.1' : '6'
            when '2.2' : '7'
            when '3' : '8'
            when '3.1' : '9'
            when '3.2' : '10'
            when '4' : '11'
            when '4.1' : '12'
            when '4.2' : '13'
            when '5' : '14'
            when '5.1': '15'
            else level
          end
        end
        
        def get_h264dec_prof(prof)
          case prof.strip.downcase
            when 'baseline' : '0'
            when 'main' : '1'
            when 'high' : '2'
            when 'any' : '3'
            else prof
          end
        end
        
        def get_jpg_rgb_fmt(fmt)
          case fmt.strip.downcase
            when 'bgr24' : '0'
            when 'bgr32' : '1'
            when 'rgb16' : '2'
            else fmt
          end
        end
        
        def get_jpg_out_img_res(res)
          case res.strip.downcase
            when 'actual' : '1'
            when 'even'  : '0'
            else res
          end
        end
        
        def get_deblocking_flag(flg)
          case flg.strip.downcase
            when 'none' : '0'
            when 'deblocking' : '1'
            when 'deblocking+deringing' : '2'
            else flg
          end
        end
        
        def get_aac_desire_ch_mode(mode)
          case mode.strip.downcase
            when 'mono' : '0' # IAUDIO_1_0 = 0,         /**< Mono. */
            when 'stereo' : '1' # IAUDIO_2_0 = 1,         /**< Stereo. */
            when '1.1','dualmono' : '2' # IAUDIO_11_0 = 2,        /**< Dual Mono.
            when '3.0' : '3' #  IAUDIO_3_0 = 3,         /**< Left, Right, Center. */
            when '2.1' : '4' # IAUDIO_2_1 = 4,         /**< Left, Right, Sur. */
            when '3.1' : '5' #    IAUDIO_3_1 = 5,         /**< Left, Right, Center, Sur. */
            when '2.2' : '6' #    IAUDIO_2_2 = 6,         /**< Left, Right, SurL, SurR. */
            when '3.2' : '7' #IAUDIO_3_2 = 7,         /**< Left, Right, Center, SurL, SurR. */
            when '2.3' : '8' #IAUDIO_2_3 = 8,         /**< Left, Right, SurL, SurR, surC. */
            when '3.3' : '9' #IAUDIO_3_3 = 9,         /**< Left, Right, Center, SurL, SurR, surC. */
            when '3.4' : '10' #IAUDIO_3_4 =10          /**< Left,
            else mode
          end
        end
        
        def get_ul_sampling_rate(rate)
          case rate.to_i
            when 96000 : '0'
            when 88200 : '1'
            when 64000 : '2'
            when 48000 : '3'
            when 44100 : '4'
            when 32000 : '5'
            when 24000 : '6'
            when 22050 : '7'
            when 16000 : '8'
            when 12000 : '9'
            when 11025 : '10'
            when 8000 : '11'
            else rate
          end
        end
        
        def get_aac_profile(prof)
          case prof.strip.downcase
            when 'main' : '0'
            when 'lc' : '1'
            when 'ssr' : '2'
            when 'ltp' : '3'
          end
        end
    end
end


      




