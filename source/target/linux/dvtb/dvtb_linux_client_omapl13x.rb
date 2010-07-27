require File.dirname(__FILE__)+'/dvtb_linux_client'

module DvtbHandlers
    
    
    class DvtbLinuxClientOmapL13x < DvtbHandlers::DvtbLinuxClient
        
        def initialize(platform_info, log_path = nil)
          super(platform_info, log_path)
          @active_threads = 0
          @file_ops = Array.new
          @dvtb_class.merge!({
            'videnc'  => 'videnc1',
            'viddec'  => 'viddec2',
            'jpegenc' => 'imgenc1',
            'jpegdec' => 'imgdec1',
            'sphenc'  => 'sphenc1',
            'sphdec'  => 'sphdec1',
            'auddec' 	=> 'auddec1',
            'h264extenc' => 'h264enc1',
            'h264extdec' => 'h264dec2',
            'mpeg4extenc' => 'mpeg4enc1',
            'mpeg4extdec'  => 'mpeg4dec2',
            'jpegextenc' => 'jpegenc1',
            'jpegextdec' => 'jpegdec1',})
          @dvtb_param = {
            'audio' => {
              'device'    => 'device',
              'samplerate'  => 'samplerate',
              'channels'    => 'channels',
              'format'    => 'format',
              'type'      => 'type'
            },
            'vpfe' => {
              'device'    => 'device',
              #'standard'    => 'standard',
              'format'    => 'pix_fmt',
              'input'      => 'input',
              'width'      => 'width',
              'height'    => 'height',
            },
            'vpbe' => {
              'device'    => 'device',
              'width'      => 'width',
              'height'    => 'height',
              'standard'    => 'standard',
              'format'    => 'pix_fmt',
              #'output'    => 'output'
            },
            'engine' => {
              'name'    => 'name',
              'trace'   => 'trace',
            },
            'viddec' => get_base_parameters('viddec'),
            'videnc' => get_base_parameters('videnc'),
            'auddec' => get_base_parameters('auddec'),
            'sphdec' => {
              'codec'      => 'codec',
              'compandingLaw'  => 'compandingLaw',
              'packingType'  => 'packingType',
              'codecSelection'=> 'codecSelection',
              'bitRate'    => 'bitRate',
              'inbufsize'    => 'inbufsize',
              'outbufsize'  => 'outbufsize',
            },
            'sphenc' => {
              'codec'      => 'codec',
              'seconds'    => 'seconds',
              'frameSize'    => 'frameSize',
              'compandingLaw'  => 'compandingLaw',
              'packingType'  => 'packingType',
              'vadSelection'  => 'vadSelection',
              'codecSelection'=> 'codecSelection',
              'bitRate'    => 'bitRate',
              'vadFlag'    => 'vadFlag',
              'inbufsize'    => 'inbufsize',
              'outbufsize'  => 'outbufsize',
            },
            'jpegdec' => get_base_parameters('jpegdec'),
            'jpegenc' => get_base_parameters('jpegenc'),
            'h264extenc' => get_base_parameters(['videnc','h264extenc']),
            'h264extdec' => get_base_parameters(['viddec','h264extdec']),
            'mpeg4extenc' => get_base_parameters(['videnc','mpeg4extenc']),
            'mpeg4extdec' => get_base_parameters(['viddec','mpeg4extdec']),
            'jpegextenc' => get_base_parameters(['jpegenc','jpegextenc']),
            'jpegextdec' => get_base_parameters(['jpegdec','jpegextdec']),
          }
          
        end
        
        def translate_value(params)
          case params['Class']
            when 'audio'  
              case params['Param'].strip.downcase
                when 'device' then 'plughw:0,0'
                when 'channels' then '2' #get_audio_channels(params['Value'].to_s.downcase)
                when 'format' then get_audio_alsa_data_dormat(params['Value'].strip.downcase)
                when 'type' then get_audio_device_mode(params['Value'].to_s)
                else params['Value']
              end
            when 'vpfe' 
              case params['Param']
                when 'device' then '/dev/video0'
                #when 'standard' then '4'
                when 'format' then get_driver_chroma_format(params['Value'].strip.downcase)
                when 'input'  then get_vpfe_iface_type(params['Value'].to_s)
                when 'height' then get_video_format_height(params['Value'].to_s)
                when 'width'  then get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                else params['Value']
              end
            when 'vpbe' 
              case params['Param']
                when 'device' then '/dev/video2'
                when 'standard' then get_vpbe_standard(params['Value'].to_s)
                when 'format' then get_driver_chroma_format(params['Value'].strip.downcase)
                #when 'output' then get_vpbe_iface_type(params['Value'].to_s)
                else params['Value']
              end
            when 'engine' 
              case params['Param']
                when 'name' then params['Value'] == 'encdec'? 'encodedecode' :  'encodedecode'
                else params['Value']
              end     
            when /vid[end]+c/   
              case params['Param']
                when 'codec' then get_codec_type(params['Value'].strip.downcase)
                when /reconChromaFormat/i then "-1"
                when /ChromaFormat/i then get_xdm_chroma_format(params['Value'].strip.downcase)
                when /endianness/i then get_xdm_data_format(params['Value'].strip.downcase)
                when 'frameSkipMode' then get_skip_mode(params['Value'].strip.downcase)
                when 'frameOrder' then get_video_display_order(params['Value'].to_s)
                when /contenttype/i then  get_video_content_type(params['Value'].downcase.strip)
                when 'encodingPreset' then  get_encoder_preset(params['Value'].downcase.strip)
                when 'rateControlPreset' then get_rate_control_preset(params['Value'].downcase.strip)
                when 'forceIFrame' then '0'
                when 'captureWidth'  then get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                when /width/i then get_adjusted_width(params['Value'].strip).to_s
                else params['Value']
              end
            when /aud[end]+c/
              case params['Param']
                when 'codec' then params['Value'].strip.downcase.include?('aac') ? params['Value'].sub('aac','aache') : params['Value'].to_s
                when 'pcmFormat' then get_audio_data_format(params['Value'].to_s)
                when /endianness/i then get_xdm_data_format(params['Value'].strip.downcase)
                when /ChannelMode/i then get_audio_channel_mode(params['Value'].to_s)
                else params['Value']
              end  
            when /mpeg4ext[end]+c/ 
              case params['Param']
                when 'codec' then get_codec_type(params['Value'].strip.downcase)
                when /ChromaFormat/i then get_xdm_chroma_format(params['Value'].strip.downcase)
                when /endianness/i then get_xdm_data_format(params['Value'].strip.downcase)
                when 'frameSkipMode' then get_skip_mode(params['Value'].strip.downcase)
                when 'frameOrder' then get_video_display_order(params['Value'].to_s)
                when /contenttype/i then get_video_content_type(params['Value'].downcase.strip)
                when /encodingPreset/i then get_encoder_preset(params['Value'].downcase.strip)
                when /rateControlPreset/i then get_rate_control_preset(params['Value'].downcase.strip)  
                when /meAlgo/i then get_mpeg4_me_algo(params['Value'].downcase.strip)
                when /skipMBAlgo/i then get_mb_skip_algo(params['Value'].downcase.strip)
                when /encodeMode/i then get_mpeg4_enc_mode(params['Value'].downcase.strip)
                when /IntraAlgo/i then get_intra_algo(params['Value'].downcase.strip)
                when /qchange$/i then get_q_change(params['Value'].downcase.strip)
                when /rotation/i then get_video_rotation(params['Value'].downcase.strip)
                when 'captureWidth' then get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                when /width/i then get_adjusted_width(params['Value'].strip).to_s
                else params['Value']
              end
            when 'h264extenc', 'h264extdec' 
              case params['Param']
                when 'codec' then get_codec_type(params['Value'].strip.downcase)
                when /reconChromaFormat/i then "-1"
                when /ChromaFormat/i then get_xdm_chroma_format(params['Value'].strip.downcase)
                when /endianness/i then get_xdm_data_format(params['Value'].strip.downcase)
                when 'frameSkipMode' then get_skip_mode(params['Value'].strip.downcase)
                when 'frameOrder' then get_video_display_order(params['Value'].to_s)
                when /contenttype/i then  get_video_content_type(params['Value'].downcase.strip)
                when 'encodingPreset' then  get_encoder_preset(params['Value'].downcase.strip)
                when 'rateControlPreset' then get_rate_control_preset(params['Value'].downcase.strip)
                when 'profileIdc' then get_h264_profile(params['Value'].downcase.strip)
                when 'forceIFrame' then '0'
                when 'entropyCodingMode' then get_h264_entropy_coding(params['Value'].downcase.strip)
                when 'captureWidth'  then get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                when /width/i then get_adjusted_width(params['Value'].strip).to_s
                when /maxBytesPerSlice/i then (params['Value'].strip.to_i*8).to_s
                when /seqScalingFlag/i then get_seq_scaling(params['Value'].strip)
                when /rcalgo/i then get_rc_algo(params['Value'])
                when /meAlgo/i then get_h264_me_algo(params['Value'])
                when /encQuality/i then get_h264_enc_quality(params['Value'])
                else params['Value']
              end  
            when /sph[end]+c/ 
              case params['Param']
                when 'numframes' then (params['Value'].to_i/8).to_s
                when /companding/i then get_speech_companding(params['Value'].strip.downcase)
                when 'codec' then params['Value']+'1'
                else params['Value']
              end
            when /jpeg[endxt]+c/   
              case params['Param']
                when 'codec' then get_codec_type(params['Value'].strip.downcase)
                when /ChromaFormat/ then get_xdm_chroma_format(params['Value'].strip.downcase)
                when /endianness/i then get_xdm_data_format(params['Value'].strip.downcase)
                when /resize/i then get_jpeg_scale_factor(params['Value'].strip.downcase)
                when 'captureWidth'  then '0' #get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                when /width/i then get_adjusted_width(params['Value'].strip).to_s
                else params['Value']
              end  
            else params['Value']
          end 
        end
        
        def connect(params)
          super(params)
          send_cmd("cd #{@executable_path}",@prompt)
          send_cmd("./loadmodules.sh", @prompt)   
          send_cmd("./dvtb-r",/$/)
          @load_modules_flag = true
        end
    
        # DVTB-Server-Dependant Methods

        def video_decoding(params)
          exec_func(params.merge({"function" => "viddec2", "loc_source" => 'dec_source_file.dat', "loc_target" => 'dec_target_file.dat', 'threadId' => get_codec_type(params['threadId'])}))
        end
    
        def video_encoding(params)
          exec_func(params.merge({"function" => "videnc1", "loc_source" => 'enc_source_file.dat', "loc_target" => 'enc_target_file.dat', 'threadId' => get_codec_type(params['threadId'])}))
        end
        
        def video_encoding_decoding(params = {})
          exec_func(params.merge({"function" => "vidloopback1", "loc_source" => 'vidloop_enc_source_file.dat', "loc_target" => 'vidloop_dec_target_file.dat', 'threadId' => get_codec_type(params['threadId'])}))
        end

        def speech_decoding(params)
          exec_func(params.merge({"function" => "sphdec1", "loc_source" => 'dec_source_sph_file.dat', "loc_target" => 'dec_target_sph_file.dat'}))
        end
    
        def speech_encoding(params)
          exec_func(params.merge({"function" => "sphenc1", "loc_source" => 'enc_source_sph_file.dat', "loc_target" => 'enc_target_sph_file.dat'}))
        end
        
        def image_decoding(params)
          exec_func(params.merge({"function" => "imgdec1", "loc_source" => 'dec_source_img_file.dat', "loc_target" => 'dec_target_img_file.dat', 'threadId' => get_codec_type(params['threadId'])}))
          sleep 10
          send_cmd("\n")
        end

        def image_encoding(params)
          exec_func(params.merge({"function" => "imgenc1", "loc_source" => 'enc_source_img_file.dat', "loc_target" => 'enc_target_img_file.dat', 'threadId' => get_codec_type(params['threadId'])}))
        end
       
        def video_capture(params)
            exec_func(params.merge({"function" => "videnc1", "cmd_tail" => '--nodsp'}))
        end
  
        def video_play(params)
            exec_func(params.merge({"function" => "viddec2", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_video.dat'}))
        end
        
        def speech_capture(params)
            exec_func(params.merge({"function" => "sphenc1", "cmd_tail" => '--nodsp'}))
        end

        def speech_play(params)
            exec_func(params.merge({"function" => "sphdec1", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_speech.dat'}))
        end
        
        def h264ext_encoding(params)
          exec_func(params.merge({"function" => "h264enc1", "loc_source" => 'enc_source_h264ext_file.dat', "loc_target" => 'enc_target_h264ext_file.dat', 'threadId' => 'h264enc1'}))
        end
        
        def h264ext_decoding(params)
          exec_func(params.merge({"function" => "h264dec2", "loc_source" => 'dec_source_h264ext_file.dat', "loc_target" => 'dec_target_h264ext_file.dat', 'threadId' => 'h264dec2'}))
        end
        
        def mpeg4ext_encoding(params)
          exec_func(params.merge({"function" => "mpeg4enc1", "loc_source" => 'enc_source_mpeg4ext_file.dat', "loc_target" => 'enc_target_mpeg4ext_file.dat', 'threadId' => 'mpeg4enc1'}))
        end
        
        def mpeg4ext_decoding(params)
          exec_func(params.merge({"function" => "mpeg4dec2", "loc_source" => 'dec_source_mpeg4ext_file.dat', "loc_target" => 'dec_target_mpeg4ext_file.dat', 'threadId' => 'mpeg4dec2'}))
        end
        
        def jpegext_encoding(params)
          exec_func(params.merge({"function" => "jpegenc1", "loc_source" => 'enc_source_jpegext_file.dat', "loc_target" => 'enc_target_jpegext_file.dat', 'threadId' => 'jpegenc1'}))
        end
        
        def jpegext_decoding(params)
          exec_func(params.merge({"function" => "jpegdec1", "loc_source" => 'dec_source_jpegext_file.dat', "loc_target" => 'dec_target_jpegext_file.dat', 'threadId' => 'jpegdec1'}))
          sleep 10
          send_cmd("\n")
        end
        
        def audio_decoding(params)
          exec_func(params.merge({"function" => 'auddec1', "loc_source" => 'dec_source_aud_file.dat', "loc_target" => 'dec_target_aud_file.dat'}))
        end
        
        private
      
        def get_file_ext(threadId)
          case threadId
            when /264/ then '.264'
            else '.mpeg4'
          end
        end
        
        def get_vpbe_standard(signal_format)
          case signal_format.strip.downcase
            when '625' then '2'
            when '525' then '1'
            when '720p60' then '0'
            else signal_format 
          end
        end
        
        def get_base_parameters(param, prefix = nil)
          base_params = {
            'videnc' => {
              'codec'          => 'codec',
              'encodingPreset'    => 'encodingPreset',
              'rateControlPreset'    => 'rateControlPreset',
              'maxHeight'        => 'maxHeight',
              'maxWidth'        => 'maxWidth',
              'maxFrameRate'      => 'maxFrameRate',
              'maxBitRate'      => 'maxBitRate',
              'dataEndianness'    => 'dataEndianness',
              'maxInterFrameInterval'  => 'maxInterFrameInterval',
              'inputChromaFormat'    => 'inputChromaFormat',
              'inputContentType'    => 'inputContentType',
              'reconChromaFormat'    => 'reconChromaFormat',
              'topFieldFirstFlag'   => 'topFieldFirstFlag',
              'inputHeight'      => 'inputHeight',
              'inputWidth'      => 'inputWidth',
              'refFrameRate'      => 'refFrameRate',
              'targetFrameRate'    => 'targetFrameRate',
              'targetBitRate'      => 'targetBitRate',
              'intraFrameInterval'  => 'intraFrameInterval',
              'generateHeader'    => 'generateHeader',
              'captureWidth'      => 'captureWidth',
              'forceIFrame'      => 'forceFrame',
              'interFrameInterval'  => 'interFrameInterval',
              'mbDataFlag'      => 'mbDataFlag',
              'numframes'        => 'numFrames',
            },
            'viddec' => {
              'codec'        => 'codec',
              'maxHeight'      => 'maxHeight',
              'maxWidth'      => 'maxWidth',
              'maxFrameRate'    => 'maxFrameRate',
              'maxBitRate'    => 'maxBitRate',
              'dataEndianness'  => 'dataEndianness',
              'forceChromaFormat'  => 'forceChromaFormat',
              'decodeHeader'    => 'decodeHeader',
              'displayWidth'    => 'displayWidth',
              'frameSkipMode'    => 'frameSkipMode',
              'frameOrder'    => 'frameOrder',
              'newFrameFlag'    => 'newFrameFlag',
              'mbDataFlag'    => 'mbDataFlag',
              'numframes'      => 'numFrames',
            },
            'auddec' => {
              'codec'                 =>  'codec',
              'outputPCMWidth'        =>  'outputPCMWidth',
              'pcmFormat'             =>  'pcmFormat',
              'dataEndianness'        =>  'dataEndianness',
              'downSampleSbrFlag'     =>  'downSampleSbrFlag',
              'inbufsize'             =>  'inbufsize',
              'outbufsize'            =>  'outbufsize',
              'desiredChannelMode'    =>  'desiredChannelMode'
            },
            'jpegdec' => {
              'codec'          => 'codec',
              'maxHeight'        => 'maxHeight',
              'maxWidth'        => 'maxWidth',
              'maxScans'        => 'maxScans',
              'dataEndianness'    => 'dataEndianness',
              'forceChromaFormat'    => 'forceChromaFormat',
              'numAU'          => 'numAU',
              'decodeHeader'      => 'decodeHeader',
              'displayWidth'      => 'displayWidth',
            },
            'jpegenc' => {
              'codec'          => 'codec',
              'maxHeight'        => 'maxHeight',
              'maxWidth'        => 'maxWidth',
              'maxScans'        => 'maxScans',
              'dataEndianness'    => 'dataEndianness',
              'forceChromaFormat'    => 'forceChromaFormat',
              'numAU'          => 'numAU',
              'inputChromaFormat'    => 'inputChromaFormat',
              'inputHeight'      => 'inputHeight',
              'inputWidth'      => 'inputWidth',
              'captureWidth'      => 'captureWidth',
              'generateHeader'    => 'generateHeader',
              'qValue'        => 'qValue',
            },
            'h264extenc' => {
              'profileIdc'      =>  'profileIdc',
              'levelIdc'        =>  'levelIdc',
              'entropyCodingMode' =>  'EntropyMode',
              'qpIntra'        =>  'intraFrameQP',
              'qpInter'        =>  'interPFrameQP',
              'qpMax'          =>  'rcQMax',
              'qpMin'          =>  'rcQMin',
              'rcAlgo'         =>  'rcAlgo',
              'lfDisableIdc'      =>  'lfDisableIdc',
              'airMbPeriod'     => 'airRate',
              'transform8x8FlagIntraFrame' => 'Transform8x8FlagIntraFrame',
              'transform8x8FlagInterFrame' => 'Transform8x8FlagInterFrame',
              'aspectRatioX' => 'AspectRatioX',
              'aspectRatioY' => 'AspectRatioY',
              'pixelRange' => 'PixelRange',
              'timeScale' => 'TimeScale',
              'numUnitsInTicks' => 'NumUnitsInTicks',
              'enableVUIparams' => 'EnableVUIparams',
              'reset_vIMCOP_every_frame' => 'reset_vIMCOP_every_frame',
              'disableHDVICPeveryFrame' => 'disableHDVICPeveryFrame',
              'meAlgo' => 'meAlgo',
              'umv' => 'UMV',
              'seqScalingFlag' => 'SeqScalingFlag',
              'encQuality' => 'EncQuality',
              'maxBytesPerSlice' => 'sliceSize',
              'initQ' => 'initQ',
              'maxDelay' => 'maxDelay',
              'sliceRefreshNumber' => 'intraSliceNum',
              'meMultiPart' => 'meMultiPart',
              'enableBufSEI' => 'enableBufSEI',
              'enablePicTimSEI' => 'enablePicTimSEI',
              'intraThrQF' => 'intraThrQF',
              'perceptualRC' => 'perceptualRC',
              'idrFrameInterval'  =>  'idrFrameInterval',
            },
            'h264extdec' => {
              'displayDelay' => 'displayDelay',
              'hdvicpHandle' => 'hdvicpHandle',
              'resetHDVICPeveryFrame' => 'resetHDVICPeveryFrame',
              'disableHDVICPeveryFrame' =>  'disableHDVICPeveryFrame',
            },
            'mpeg4extenc' => {
              'subWindowHeight'  =>  'extParamsSubWindowHeight',
              'subWindowWidth'  =>  'extParamsSubWindowWidth',
              'rotation'  =>  'extParamsRotation',
              'vbvBufferSize'  =>  'extParamsVBV_size',
              'encodeMode'  =>  'extParamsSVH',
              'dynParamsIntraAlgo'  =>  'extDynParamsIntraAlgo',
              'dynParamsNumMBRows'  =>  'extDynParamsNumMBRows',
              'dynParamsInitQ'  =>  'extDynParamsInitQ',
              'dynParamsRcQ_MAX'  =>  'extDynParamsRcQ_MAX',
              'dynParamsRcQ_MIN'  =>  'extDynParamsRcQ_MIN',
              'dynParamsQChange'  =>  'extDynParamsRateFix',
              'dynParamsQChangeRange'  =>  'extDynParamsRateFixRange',
              'dynParamsMeAlgo'  =>  'extDynParamsMeAlgo',
              'dynParamsSkipMBAlgo'  =>  'extDynParamsSkipMBAlgo',
              'dynParamsUseUMV'  =>  'extDynParamsUMV',
              'dynParamsMVDataEnable'  =>  'extDynParamsMVDataEnable',
              'dynIntraFrameQP'    => 'extDynIntraFrameQP',
              'dynInterFrameQP'    => 'extDynInterFrameQP', 
            },
            'mpeg4extdec' => {
              'meRange'  =>  'meRange',
              'displayWidth'  =>  'displayWidth',
              'decRotation'  =>  'rotation',
              'umv'  =>  'UMV',
            },
            'jpegextenc' => {
              'dynParamsHalfBufCB' => 'halfBufCB',   #not possible to use with dvtb
              'dynParamsHalfBufCBarg' => 'halfBufCBarg', # not possible to use with dvtb
              'dynParamsRstInterval'  =>  'rstInterval',
              'dynParamsDisableEOI'  =>  'disableEOI',
              'dynParamsRotation'  =>  'rotation',
              'dynParamsCustomQ' => 'customQ' # not possible to use with dvtb
              
            },
            'jpegextdec' => {
              'dynParamsDisableEOI'  =>  'disableEOI',
              'dynParamsResizeOption'  =>  'resizeOption',
              'dynParamsSubRegUpLeftX'  =>  'subRegionUpLeftX',
              'dynParamsSubRegUpLeftY'  =>  'subRegionUpLeftY',
              'dynParamsSubRegDownRightX'  =>  'subRegionDownRightX',
              'dynParamssubRegDownRightY'  =>  'subRegionDownRightY',
              'dynParamsRotation'  =>  'rotation',
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
            when 'composite' then '0'
            when 'svideo' then '1'
            when 'component' then '2'
            else io_type 
          end
        end
        
        def get_vpbe_iface_type(io_type)
          case io_type.strip.downcase
            when 'composite' then '1'
            #when 'svideo' then '2'
            when 'component' then '0'
            else io_type 
          end
        end
        
        def get_codec_type(codec)
          case codec.strip.downcase
            when /h264enc/i then 'h264enc'
            when /h264dec/i then 'h264dec'
            when /mpeg4enc/i then 'mpeg4enc'
            when /mpeg4dec/i then 'mpeg4dec'
            when /jpegenc/i then 'jpegenc'
            when /jpegdec/i then 'jpegdec'
            else codec 
          end
        end
        
        def get_adjusted_width(width)
          #width.to_i+(width.to_i % 32)
          width.to_i
        end
        
        def get_driver_chroma_format(format)
          case format.strip.downcase
            when '422i' then '1'
            when '420sp' then '0'
            else format
          end
        end
        
        def get_seq_scaling(scaling)
          case scaling.strip.downcase
            when 'disable' then '0'
            when 'auto' then '1'
            when 'low' then '2'
            when 'moderate' then '3'
            when 'high' then '4'
            else scaling
          end
        end
        
        def get_rc_algo(algo)
          case algo.strip.downcase
            when 'cbr' then '0'
            when 'vbr' then '1'
            when 'fixed_qp' then '2'
            else algo
          end
        end
        
        def get_h264_me_algo(algo)
          case algo.strip.downcase
            when 'normal' then '0'
            when 'low_power' then '1'
            else algo
          end
        end
        
        def get_mpeg4_me_algo(algo)
          case algo.downcase.strip
            when 'me_lq_hp' then '3'
            when 'me_mq_mp' then '0'
            when 'me_hq_mp' then '1'
            when 'me_hq_lp' then '2'
            else algo
          end
        end
        
        def get_h264_enc_quality(quality)
          case quality.strip.downcase
            when 'high' then '1'
            when 'standard' then '0'
            else quality
          end
        end
        
        def get_intra_algo(algo)
          case algo.downcase.strip
            when 'ii_lq_hp' then '0'
            when 'ii_hq_lp' then '1'
            else algo
          end
        end
        
        def get_q_change(q_change)
          case q_change.downcase.strip
            when 'mb' then '0'
            when 'picture' then '1'
            else q_change
          end
        end
        
        def get_me_algo(algo)
          case algo.downcase.strip
            when 'me_lq_hp' then '3'
            when 'me_mq_mp' then '0'
            when 'me_hq_mp' then '1'
            when 'me_hq_lp' then '2'
            else algo
          end
        end
        
        def get_mb_skip_algo(algo)
          case algo.downcase.strip
            when 'mb_lq_hp' then '0'
            when 'mb_hq_lp' then '1'
            else algo
          end
        end
        
        def get_blk_size(blk_size)
          case blk_size.strip.downcase
            when 'blk_lq_hp' then '0'
            when 'blk_hq_lp' then '1'
            else blk_size
          end
        end
        
        def get_mpeg4_enc_mode(mode)
          case mode.strip.downcase
            when 'svh' then '1'
            when 'mpeg4' then '0'
            else mode
          end
        end
        
        def get_video_rotation(rotation)
          case rotation.strip.to_i
            when 0 then '0'
            when 90 then '1'
            when 180 then '2'
            when 270 then '3'
            else rotation
          end
        end
        
        def get_jpeg_scale_factor(factor)
          case factor.strip.to_i
            when 1 then '3'
            when 2 then '2'
            when 3 then '4'
            when 4 then '1'
            when 5 then '5'
            when 6 then '6'
            when 7 then '7'
            else '0'
          end
        end
        
        def get_audio_channel_mode(mode)
          case mode
            when /mono/i then   '0'
            when /stereo/i then '1'
            else '2'
          end
        end
    end
end


      




