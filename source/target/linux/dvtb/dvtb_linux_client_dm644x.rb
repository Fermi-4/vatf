require File.dirname(__FILE__)+'/dvtb_linux_client'

module DvtbHandlers
    
    
    class DvtbLinuxClientDM644x < DvtbHandlers::DvtbLinuxClient
        
        def initialize(platform_info, log_path = nil)
            super(platform_info, log_path)
            @active_threads = 0
            @file_ops = Array.new
            @dvtb_class.merge!({
                'videnc'	=> 'videnc1',
                'viddec'	=> 'viddec2',
                'auddec' 	=> 'auddec1',
                'sphenc'	=> 'sphenc1',
                'sphdec'	=> 'sphdec1'})
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
                    'inbufsize'		=> 'inbufsize',
                    'outbufsize'	=> 'outbufsize',
                },
                'auddec' => {
                    'codec'                 =>  'codec',
					'outputPCMWidth'        =>  'outputPCMWidth',
					'pcmFormat'             =>  'pcmFormat',
					'dataEndianness'        =>  'dataEndianness',
					'downSampleSbrFlag'     =>  'downSampleSbrFlag',
					'inbufsize'             =>  'inbufsize',
					'outbufsize'            =>  'outbufsize',
                },
            }
            
        end
        
        def translate_value(params)
            case params['Class']
                when 'audio' 
                    case params['Param'].strip.downcase
                    when 'device' then 'plughw:0,0'
                    when 'channels' then '2' #get_audio_channels(params['Value'].to_s.downcase)
                    when 'format'
                        get_audio_alsa_data_dormat(params['Value'].strip.downcase)
                    when 'type' then get_audio_device_mode(params['Value'].to_s)
                    else params['Value']
                    end
                when 'vpfe' 
                    case params['Param']
                    when 'device' then '/dev/video0' #'/dev/v4l/video0'
                    when 'standard' then get_vpfe_standard(params['Value'].to_s)
                    when 'format' then get_video_driver_data_format(params['Value'].to_s)
                    when 'input'  then get_vpfe_iface_type(params['Value'].to_s)
                    when 'height' then get_video_format_height(params['Value'].to_s)
                    when 'width'  then get_video_format_width(params['Value'].to_s)
                    else params['Value']
                    end
                when 'vpbe' 
                    case params['Param']
                    when 'device' then '/dev/video2'
                    when 'standard' then get_vpbe_standard(params['Value'].to_s)
                    when 'output' then get_vpbe_iface_type(params['Value'].to_s)
                    when 'height' then get_video_format_height(params['Value'].to_s)
                    when 'width'  then get_video_format_width(params['Value'].to_s)
                    else params['Value']
                    end
                when 'engine' 
                    case params['Param']
                    when 'name' then params['Value'] == 'encdec'? 'loopback' :  params['Value']
                    else params['Value']
                    end     
                when /vid[end]+c/   
                    case params['Param']
                    when /reconChromaFormat/i then '-1'
                    when /ChromaFormat/i
                        get_xdm_chroma_format(params['Value'].strip.downcase)
                    when /endianness/i
                        get_xdm_data_format(params['Value'].strip.downcase)
                    when 'frameSkipMode'
                       	get_skip_mode(params['Value'].strip.downcase)
                    when 'frameOrder' then  get_video_display_order(params['Value'].to_s)
                    when /contenttype/i 
                        get_video_content_type(params['Value'].downcase.strip)
                    when /encodingPreset/i
                        get_encoder_preset(params['Value'].downcase.strip)
                    when /rateControlPreset/i
                        get_rate_control_preset(params['Value'].downcase.strip) 
                    else params['Value']
                    end  
                when /sph[end]+c/ 
                    case params['Param']
                        when 'numframes' then (params['Value'].to_i/8).to_s
                        when /companding/i
                            get_speech_companding(params['Value'].strip.downcase)
                        else params['Value']
                    end
                when /aud[end]+c/
                    case params['Param']
                      when 'codec' then params['Value'].strip.downcase.include?('aac') ? params['Value'].sub('aac','aache') : params['Value'].to_s
                      when 'pcmFormat' then get_audio_data_format(params['Value'].to_s)
                      when /endianness/i then get_xdm_data_format(params['Value'].strip.downcase)
                    else params['Value']
                    end
        	else params['Value']
            end 
        end
        
        def connect(params)
            super(params)
            send_cmd("cd #{@executable_path}",@prompt)
            send_cmd("./dvtb_loadmodules.sh", @prompt) 	
            send_cmd("./dvtb-r",/$/)
        end
    
        # DVTB-Server-Dependant Methods
        def video_decoding(params)
          exec_func(params.merge({"function" => 'viddec2', "loc_source" => 'dec_source_file.dat', "loc_target" => 'dec_target_file.dat'}))
        end
    
        def video_encoding(params)
          exec_func(params.merge({"function" => 'videnc1', "loc_source" => 'enc_source_file.dat', "loc_target" => 'enc_target_file.dat'}))
        end
        
        def video_encoding_decoding(params = {})
          exec_func(params.merge({"function" => "vidloopback1", "loc_source" => 'vidloop_enc_source_file.dat', "loc_target" => 'vidloop_dec_target_file.dat'}))
        end

        def speech_decoding(params)
          exec_func(params.merge({"function" => 'sphdec1', "loc_source" => 'dec_source_sph_file.dat', "loc_target" => 'dec_target_sph_file.dat'}))
        end
    
        def speech_encoding(params)
          exec_func(params.merge({"function" => 'sphenc1', "loc_source" => 'enc_source_sph_file.dat', "loc_target" => 'enc_target_sph_file.dat'}))
        end
	
        def video_capture(params)
          exec_func(params.merge({"function" => 'videnc1', "cmd_tail" => '--nodsp'}))
        end
	
        def video_play(params)
          exec_func(params.merge({"function" => 'viddec2', "cmd_tail" => '--nodsp', 'loc_source' => 'raw_video.dat'}))
        end
        
        def speech_capture(params)
          exec_func(params.merge({"function" => 'sphenc1', "cmd_tail" => '--nodsp'}))
        end

        def speech_play(params)
          exec_func(params.merge({"function" => 'sphdec1', "cmd_tail" => '--nodsp', 'loc_source' => 'raw_speech.dat'}))
        end
        
        def audio_decoding(params)
          exec_func(params.merge({"function" => 'auddec1', "loc_source" => 'dec_source_aud_file.dat', "loc_target" => 'dec_target_aud_file.dat'}))
        end
        
        def audio_play(params)
          exec_func(params.merge({"function" => 'auddec1', "cmd_tail" => '--nodsp'}))
        end
                
        private  
        def get_file_ext(threadId)
            case threadId
            when /264/ then '.264'
            else '.mpeg4'
            end
        end
        
    end
end


      




