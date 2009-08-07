require 'net/telnet'
require 'rubygems'
require 'fileutils'
require File.dirname(__FILE__)+'/../../target/lsp_target_controller'
require File.dirname(__FILE__)+'/dvtb_default_client'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module DvtbHandlers
    
    
    class DvtbLinuxClientDM365 < DvtbHandlers::DvtbDefaultClient
        
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
          connect
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
                when 'width'  : get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
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
                when 'name' : params['Value'] == 'encdec'? 'loopback' :  params['Value']
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
                when 'captureWidth'  : get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                when /width/i : get_adjusted_width(params['Value'].strip).to_s
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
                when /qchange$/i : get_q_change(params['Value'].downcase.strip)
                when /rotation/i : get_video_rotation(params['Value'].downcase.strip)
                when 'captureWidth' : get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                when /width/i : get_adjusted_width(params['Value'].strip).to_s
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
                when 'forceIFrame' : '0'
                when 'entropyCodingMode' : get_h264_entropy_coding(params['Value'].downcase.strip)
                when 'captureWidth'  : get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                when /width/i : get_adjusted_width(params['Value'].strip).to_s
                when /maxBytesPerSlice/i : (params['Value'].strip.to_i*8).to_s
                when /seqScalingFlag/i : get_seq_scaling(params['Value'].strip)
                when /rcalgo/i : get_rc_algo(params['Value'])
                when /meAlgo/i : get_h264_me_algo(params['Value'])
                when /encQuality/i : get_h264_enc_quality(params['Value'])
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
                when /resize/i : get_jpeg_scale_factor(params['Value'].strip.downcase)
                when 'captureWidth'  : get_adjusted_width(get_video_format_width(params['Value'].to_s)).to_s
                when /width/i : get_adjusted_width(params['Value'].strip).to_s
                else params['Value']
              end  
            else params['Value']
          end 
        end
        
        def connect
          send_cmd("cd #{@executable_path}",@prompt)
          send_cmd("./dvtb_loadmodules_hd.sh", @prompt)   
          send_cmd("./dvtb-r",/$/)
          @load_modules_flag = true
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
            @response = listener.response_buffer
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
          exec_func(params.merge({"function" => "imgdec1", "loc_source" => 'dec_source_img_file.dat', "loc_target" => 'dec_target_img_file.dat', 'threadId' => 'jpegdec1'}))
          sleep 10
          send_cmd("\n")
        end

        def image_encoding(params)
          exec_func(params.merge({"function" => "imgenc1", "loc_source" => 'enc_source_img_file.dat', "loc_target" => 'enc_target_img_file.dat', 'threadId' => 'jpegenc1'}))
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
        
        def get_vpbe_standard(signal_format)
          case signal_format.strip.downcase
            when '625' : '2'
            when '525' : '1'
            when '720p60' : '0'
            else signal_format 
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
            when /h264enc/i : 'h264enc1'
            when /h264dec/i : 'h264dec2'
            when /mpeg4enc/i : 'mpeg4enc1'
            when /mpeg4dec/i : 'mpeg4dec2'
            when /jpegenc/i : 'jpegenc1'
            when /jpegdec/i : 'jpegdec1'
            else codec 
          end
        end
        
        def get_adjusted_width(width)
          width.to_i+(width.to_i % 32)
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
            when 'normal' : '0'
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
    end
end


      




