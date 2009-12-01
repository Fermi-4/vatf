require File.dirname(__FILE__)+'/dvtb_linux_client'

module DvtbHandlers
    
    
    class DvtbLinuxClientDM357 < DvtbHandlers::DvtbLinuxClient
        
        def initialize(platform_info, log_path = nil)
            super(platform_info, log_path)
            @active_threads = 0
            @file_ops = Array.new
            @dvtb_class.merge!({
                'jpegdec' 	=> 'imgdec',
                'jpegenc' 	=> 'imgenc',})
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
                    'width'			=> 'imageWidth',
                    'height'		=> 'imageHeight',
                    'screenWidth'	=> 'screenWidth',
                    'screenHeight'	=> 'screenHeight'
                },
                'engine' => {
                    'name'		=> 'name',
                    'trace'		=> 'trace',
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
                    'forceIFrame'			=> 'forceIFrame',
                    'numframes'				=> 'numFrames',
                },
                'sphdec' => {
                    'codec'			=> 'codec',
                    'compandingLaw'	=> 'compandingLaw',
                    'packingType'	=> 'packingType',
                    'inbufsize'		=> 'inbufsize',
                    'outbufsize'	=> 'outbufsize',
                },
                'sphenc' => {
                    'codec'			=> 'codec',
                    'seconds'		=> 'seconds',
                    'frameSize'		=> 'frameSize',
                    'compandingLaw'	=> 'compandingLaw',
                    'vadSelection'	=> 'vadSelection',
                    'packingType'	=> 'packingType',
                    'inbufsize'		=> 'inbufsize',
                    'outbufsize'	=> 'outbufsize',
                },
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
            }
            connect
        end
        
        def translate_value(params)
            case params['Class']
                when 'audio': 
                    case params['Param']
                    when 'device' : '/dev/dsp'
                    else params['Value']
                    end
                when 'vpfe': 
                    case params['Param']
                    when 'device' : '/dev/v4l/video0'
                    when 'standard' : params['Value'].to_s.include?('625') ? '2' : '0'
                    else params['Value']
                    end
                when 'vpbe': 
                    case params['Param']
                    when 'device' : '/dev/fb/3'
                    else params['Value']
                    end
                when 'engine': 
                    case params['Param']
                    when 'name' : params['Value'] == 'encdec'? 'loopback' :  params['Value']
                    else params['Value']
                    end     
                when /vid[end]+c/   
                    case params['Param']
                    when /ChromaFormat/ : params['Value'].to_s.include?('p') ? '1' : '4'
                    else params['Value']
                    end  
                when /jpeg[end]+c/   
                    case params['Param']
                    when /ChromaFormat/ : params['Value'].to_s.include?('p') ? '2' : '4'
                    else params['Value']
                    end  
                when 'sphdec': 
                    case params['Param']
                    when 'numframes' : (params['Value'].to_i/8).to_s
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
    
        # DVTB-Server-Dependant Methods

        def video_decoding(params)
          exec_func(params.merge({"function" => "viddec", "loc_source" => 'dec_source_file.dat', "loc_target" => 'dec_target_file.dat'}))
        end
    
        def video_encoding(params)
          exec_func(params.merge({"function" => "videnc", "loc_source" => 'enc_source_file.dat', "loc_target" => 'enc_target_file.dat'}))
        end
        
        def video_encoding_decoding(params)
            temp_file = 'temp'+get_file_ext(params["threadIdEnc"])
            p_enc = {}.merge!(params); p_enc.delete("Target") ; p_enc['TempTarget'] = temp_file ; p_enc["threadId"] = params["threadIdEnc"]
            p_dec = {}.merge!(params); p_dec.delete("Source") ; p_dec['TempSource'] = temp_file ; p_dec["threadId"] = params["threadIdDec"]
            exec_func(p_enc.merge({"function" => "videnc", "loc_source" => 'enc_source_file.dat', "loc_target" => temp_file}))
          	wait_for_threads
          	exec_func(p_dec.merge({"function" => "viddec", "loc_source" => temp_file, "loc_target" => 'dec_target_file.dat'}))
        end

        def speech_decoding(params)
          	exec_func(params.merge({"function" => "sphdec", "loc_source" => 'dec_source_sph_file.dat', "loc_target" => 'dec_target_sph_file.dat'}))
        end
    
        def speech_encoding(params)
          	exec_func(params.merge({"function" => "sphenc", "loc_source" => 'enc_source_sph_file.dat', "loc_target" => 'enc_target_sph_file.dat'}))
        end
	
        def image_decoding(params)
            exec_func(params.merge({"function" => "imgdec", "loc_source" => 'dec_source_img_file.dat', "loc_target" => 'dec_target_img_file.dat'}))
        end

        def image_encoding(params)
            exec_func(params.merge({"function" => "imgenc", "loc_source" => 'enc_source_img_file.dat', "loc_target" => 'enc_target_img_file.dat'}))
        end
		   
        def video_capture(params)
            exec_func(params.merge({"function" => "videnc", "cmd_tail" => '--nodsp'}))
        end
	
        def video_play(params)
            exec_func(params.merge({"function" => "viddec", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_video.dat'}))
        end
        
        def speech_capture(params)
            exec_func(params.merge({"function" => "sphenc", "cmd_tail" => '--nodsp'}))
        end

        def speech_play(params)
            exec_func(params.merge({"function" => "sphdec", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_speech.dat'}))
        end
                
        private  
        def get_file_ext(threadId)
            case threadId
            when /264/ : '.264'
            else '.mpeg4'
            end
        end
    end
end


      




