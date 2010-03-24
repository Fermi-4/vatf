require File.dirname(__FILE__)+'/dvtb_linux_client'

module DvtbHandlers
    
    
    class DvtbLinuxClientDM365 < DvtbHandlers::DvtbLinuxClient
        
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
            when 'audio': 
              case params['Param'].strip.downcase
                when 'device' : 'plughw:0,0'
                when 'channels': '2' #get_audio_channels(params['Value'].to_s.downcase)
                when 'format': get_audio_alsa_data_dormat(params['Value'].strip.downcase)
                when 'type' : get_audio_device_mode(params['Value'].to_s)
                else params['Value']
              end
            when 'vpfe': 
              case params['Param']
                when 'device' : '/dev/video0'
                #when 'standard' : '4'
                when 'format' : get_driver_chroma_format(params['Value'].strip.downcase)
                when 'input'  : get_vpfe_iface_type(params['Value'].to_s)
                when 'height' : get_video_format_height(params['Value'].to_s)
                when 'width'  : get_video_format_width(params['Value'].to_s).to_s
                else params['Value']
              end
            when 'vpbe': 
              case params['Param']
                when 'device' : '/dev/video2'
                when 'standard' : get_vpbe_standard(params['Value'].to_s)
                when 'format' : get_driver_chroma_format(params['Value'].strip.downcase)
                #when 'output' : get_vpbe_iface_type(params['Value'].to_s)
                else params['Value']
              end
            when 'engine': 
              case params['Param']
                when 'name' : 'encodedecode'
                else params['Value']
              end     
            when /vid[end]+c/   
              case params['Param']
                when 'codec' : get_codec_type(params['Value'].strip.downcase)
                when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                when /contenttype/i :  get_video_content_type(params['Value'].downcase.strip)
                when 'encodingPreset' :  get_encoder_preset(params['Value'].downcase.strip)
                when 'rateControlPreset' : get_rate_control_preset(params['Value'].downcase.strip)
                when 'forceIFrame' : '0'
                else params['Value']
              end
            when /mpeg4ext[end]+c/ 
              case params['Param']
                when 'codec' : get_codec_type(params['Value'].strip.downcase)
                when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                when /contenttype/i : get_video_content_type(params['Value'].downcase.strip)
                when /encodingPreset/i : get_encoder_preset(params['Value'].downcase.strip)
                when /rateControlPreset/i : get_rate_control_preset(params['Value'].downcase.strip)  
                when /meAlgo/i : get_mpeg4_me_algo(params['Value'].downcase.strip)
                when /skipMBAlgo/i : get_mb_skip_algo(params['Value'].downcase.strip)
                when /encodeMode/i : get_mpeg4_enc_mode(params['Value'].downcase.strip)
                when /IntraAlgo/i : get_intra_algo(params['Value'].downcase.strip)
                when 'forceFrame' : get_video_frame_type(params['Value'].downcase.strip)
                when /qchange$/i : get_q_change(params['Value'].downcase.strip)
                when /rotation/i : get_video_rotation(params['Value'].downcase.strip)
                when 'EncQuality_mode':get_mpeg4_enc_quality(params['Value'].downcase.strip)
                when 'levelIdc' : get_mpeg4_level(params['Value'].to_s)
                when 'profileIdc' : get_mpeg4_profile(params['Value'].to_s)
                when 'aspectRatio' : get_mpeg4_aspect_ratio(params['Value'].to_s)
                when 'pixelRange' : get_mpeg4_pel_range(params['Value'].to_s)
                when 'rcAlgo' : get_mpeg4_rcalgo(params['Value'].to_s)
                when 'maxInterFrameInterval' : (params['Value'].to_i+1).to_s
                when 'displayWidth' : (params['Value'].to_i*2).to_s
                else params['Value']
              end
            when 'h264extenc', 'h264extdec' 
              case params['Param']
                when 'codec' : get_codec_type(params['Value'].strip.downcase)
                when /ChromaFormat/i : get_xdm_chroma_format(params['Value'].strip.downcase)
                when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
                when 'frameSkipMode' : get_skip_mode(params['Value'].strip.downcase)
                when 'frameOrder' : get_video_display_order(params['Value'].to_s)
                when /contenttype/i :  get_video_content_type(params['Value'].downcase.strip)
                when 'encodingPreset' :  get_encoder_preset(params['Value'].downcase.strip)
                when 'rateControlPreset' : get_rate_control_preset(params['Value'].downcase.strip)
                when 'profileIdc' : get_h264_profile(params['Value'].downcase.strip)
                when 'entropyCodingMode' : get_h264_entropy_coding(params['Value'].downcase.strip)
                when /maxBytesPerSlice/i : (params['Value'].strip.to_i*8).to_s
                when /seqScalingFlag/i : get_seq_scaling(params['Value'].strip)
                when /rcalgo/i : get_rc_algo(params['Value'])
                when /meAlgo/i : get_h264_me_algo(params['Value'])
                when /encQuality/i : get_h264_enc_quality(params['Value'])
                when 'forceFrame' : get_video_frame_type(params['Value'].downcase.strip)
                when 'displayWidth' : (params['Value'].to_i*2).to_s
                else params['Value']
              end  
            when /sph[end]+c/: 
              case params['Param']
                when 'numframes' : (params['Value'].to_i/8).to_s
                when /companding/i : get_speech_companding(params['Value'].strip.downcase)
                when 'codec' : params['Value']+'1'
                else params['Value']
              end
            when /jpeg[endxt]+c/   
              case params['Param']
                when 'codec' : get_codec_type(params['Value'].strip.downcase)
                when /ChromaFormat/ : get_xdm_chroma_format(params['Value'].strip.downcase)
                when /endianness/i : get_xdm_data_format(params['Value'].strip.downcase)
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
          exec_func(params.merge({"function" => "viddec2", 'threadId' => get_codec_type(params['threadId'])}))
        end
    
        def video_encoding(params)
          exec_func(params.merge({"function" => "videnc1", 'threadId' => get_codec_type(params['threadId'])}))
        end
        
        def video_encoding_decoding(params = {})
          exec_func(params.merge({"function" => "vidloopback1", 'threadId' => get_codec_type(params['threadId'])}))
        end

        def speech_decoding(params)
          exec_func(params.merge({"function" => "sphdec1"}))
        end
    
        def speech_encoding(params)
          exec_func(params.merge({"function" => "sphenc1"}))
        end
        
        def image_decoding(params)
          exec_func(params.merge({"function" => "imgdec1", 'threadId' => 'jpegdec1'}))
          sleep 10
          send_cmd("\n")
        end

        def image_encoding(params)
          exec_func(params.merge({"function" => "imgenc1", 'threadId' => 'jpegenc1'}))
        end
       
        def video_capture(params)
            exec_func(params.merge({"function" => "videnc1", "cmd_tail" => '--nodsp'}))
        end
  
        def video_play(params)
            exec_func(params.merge({"function" => "viddec2", "cmd_tail" => '--nodsp'}))
        end
        
        def speech_capture(params)
            exec_func(params.merge({"function" => "sphenc1", "cmd_tail" => '--nodsp'}))
        end

        def speech_play(params)
            exec_func(params.merge({"function" => "sphdec1", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_speech.dat'}))
        end
        
        def h264ext_encoding(params)
          exec_func(params.merge({"function" => "h264enc1",  'threadId' => 'h264enc1'}))
        end
        
        def h264ext_decoding(params)
          exec_func(params.merge({"function" => "h264dec2", 'threadId' => 'h264dec2'}))
        end
        
        def mpeg4ext_encoding(params)
          exec_func(params.merge({"function" => "mpeg4enc1", 'threadId' => 'mpeg4enc1'}))
        end
        
        def mpeg4ext_decoding(params)
          exec_func(params.merge({"function" => "mpeg4dec2", 'threadId' => 'mpeg4dec2'}))
        end
        
        def jpegext_encoding(params)
          exec_func(params.merge({"function" => "jpegenc1", 'threadId' => 'jpegenc1'}))
        end
        
        def jpegext_decoding(params)
          exec_func(params.merge({"function" => "jpegdec1", 'threadId' => 'jpegdec1'}))
          sleep 10
          send_cmd("\n")
        end
        
        private
      
        
        
        def get_file_ext(threadId)
          case threadId
            when /264/ : '.264'
            else '.mpeg4'
          end
        end
        
        def get_vpbe_standard(signal_format)
          case signal_format.strip.downcase
            when '625' : '2'
            when '525' : '1'
            when '720p60' : '0'
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
              'forceFrame'      => 'forceFrame',
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
              'airRate'     => 'airRate',
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
              'intraSliceNum' => 'intraSliceNum',
              'meMultiPart' => 'meMultiPart',
              'enableBufSEI' => 'enableBufSEI',
              'enablePicTimSEI' => 'enablePicTimSEI',
              'intraThrQF' => 'intraThrQF',
              'perceptualRC' => 'perceptualRC',
              'idrFrameInterval'  =>  'idrFrameInterval',
              'mvSADoutFlag'      => 'mvSADoutFlag',
              'disableMVDCostFactor' => 'disableMVDCostFactor',
              'resetHDVICPeveryFrame' => 'resetHDVICPeveryFrame',
              'enableARM926Tcm' => 'enableARM926Tcm',
            },
            'h264extdec' => {
              'displayDelay' => 'displayDelay',
              'hdvicpHandle' => 'hdvicpHandle',
              'resetHDVICPeveryFrame' => 'resetHDVICPeveryFrame',
              'disableHDVICPeveryFrame' =>  'disableHDVICPeveryFrame',
            },
            'mpeg4extenc' => {
              'encodeMode'   =>  'extMPEG4_mode',
              'levelIdc'   =>  'extlevelIdc',
              'useVOS'   =>  'extuseVOS',
              'useGOV'   =>  'extuseGOV',
              'useDataPartition'   =>  'extuseDataPartition',
              'useRVLC'   =>  'extuseRVLC',
              'aspectRatio'   =>  'extaspectRatio',
              'pixelRange'   =>  'extpixelRange',
              'timerResolution'   =>  'exttimerResolution',
              'meAlgo'   =>  'extME_Type',
              'useUMV'   =>  'extUMV',
              'EncQuality_mode'   =>  'extEncQuality_mode',
              'Four_MV_mode'   =>  'extFour_MV_mode',
              'PacketSize'   =>  'extPacketSize',
              'qpIntra'   =>  'extqpIntra',
              'qpInter'   =>  'extqpInter',
              'airRate'   =>  'extairRate',
              'useHEC'   =>  'extuseHEC',
              'useGOBSync'   =>  'extuseGOBSync',
              'rcAlgo'   =>  'extRcAlgo',
              'qpMax'   =>  'extQPMax',
              'qpMin'   =>  'extQPMin',
              'maxDelay'   =>  'extmaxDelay',
              'qpInit'   =>  'extqpInit',
              'perceptualRC'   =>  'extPerceptualRC',
              'reset_vIMCOP_every_frame'   =>  'extreset_vIMCOP_every_frame',
              'mvSADoutFlag'   =>  'extmvSADoutFlag',
            },
            'mpeg4extdec' => {
              'displayDelay'   =>  'extdisplayDelay',
              'disableHDVICPeveryFrame'   =>  'extdisableHDVICPeveryFrame',
              'outloopDeblocking'   =>  'extoutloopDeblocking',
              'outloopDeRinging'   =>  'extoutloopDeRinging',
              'resetHDVICPeveryFrame'   =>  'extresetHDVICPeveryFrame',
            },
            'jpegextenc' => {
              'halfBufCB'   =>  'halfBufCB',  #not possible to use with dvtb
              'halfBufCBarg'   =>  'halfBufCBarg', #not possible to use with dvtb
              'dynParamsRstInterval'   =>  'extDynParamsRstInterval',
              'dynParamsDisableEOI'   =>  'extDynParamsDisableEOI',
              'dynParamsRotation'   =>  'extDynParamsRotation',
              'customQ'   =>  'customQ', #not possible to use with dvtb
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
            when 'composite' : '0'
            when 'svideo' : '1'
            when 'component' : '2'
            else io_type 
          end
        end
        
        def get_vpbe_iface_type(io_type)
          case io_type.strip.downcase
            when 'composite' : '1'
            #when 'svideo' : '2'
            when 'component' : '0'
            else io_type 
          end
        end
        
        def get_codec_type(codec)
          case codec.strip.downcase
            when /h264(ext){0,1}enc/i : 'h264enc1'
            when /h264(ext){0,1}dec/i : 'h264dec2'
            when /mpeg4(ext){0,1}enc/i : 'mpeg4enc1'
            when /mpeg4(ext){0,1}dec/i : 'mpeg4dec2'
            when /jpeg(ext){0,1}enc/i : 'jpegenc1'
            when /jpeg(ext){0,1}dec/i : 'jpegdec1'
            when /mpeg2(ext){0,1}enc/i : 'mpeg2enc1'
            when /mpeg2(ext){0,1}dec/i : 'mpeg2dec2'
            else codec 
          end
        end
        
        def get_driver_chroma_format(format)
          case format.strip.downcase
            when '422i' : '1'
            when '420sp' : '0'
            else format
          end
        end
        
        def get_seq_scaling(scaling)
          case scaling.strip.downcase
            when 'disable' : '0'
            when 'auto' : '1'
            when 'low' : '2'
            when 'moderate' : '3'
            when 'high' : '4'
            else scaling
          end
        end
        
        def get_rc_algo(algo)
          case algo.strip.downcase
            when 'cbr' : '0'
            when 'vbr' : '1'
            when 'fixed_qp' : '2'
            else algo
          end
        end
        
        def get_h264_me_algo(algo)
          case algo.strip.downcase
            when 'normal_full' : '0'
            when 'low_power' : '1'
            else algo
          end
        end
        
        def get_mpeg4_me_algo(algo)
          case algo.downcase.strip
            when 'me_lq_hp' : '3'
            when 'me_mq_mp' : '0'
            when 'me_hq_mp' : '1'
            when 'me_hq_lp' : '2'
            else algo
          end
        end
        
        def get_h264_enc_quality(quality)
          case quality.strip.downcase
            when 'high' : '1'
            when 'standard' : '0'
            else quality
          end
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
            when 'svh' : '0'
            when 'mpeg4' : '1'
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
        
        def get_mpeg4_enc_quality(qual)
          case qual.strip.downcase
            when 'high':'0'
            when 'std':'1'
            else qual
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
        
    end
end


      




